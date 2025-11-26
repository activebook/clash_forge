#!/usr/bin/env bash
#
# Network Speed Test Script (Multi-Threaded Fixed)
#

set -u # Exit on undefined vars
export LC_NUMERIC=C # Force dot (.) decimals

# Color codes (Updated to use $'' for safe printf usage)
readonly RED=$'\033[0;31m'
readonly GREEN=$'\033[0;32m'
readonly YELLOW=$'\033[1;33m'
readonly BLUE=$'\033[0;34m'
readonly PURPLE=$'\033[0;35m'
readonly CYAN=$'\033[0;36m'
readonly NC=$'\033[0m' # No Color

# Configuration Defaults
TIMEOUT=30
VERBOSE=false
PING_COUNT=5
PING_TARGET="8.8.8.8"
FILE_SIZE="10MB"
PROXY=""
AUTO_DETECT_PROXY=true

# ==========================================
# LOGGING
# ==========================================
log_info()    { echo -e "${BLUE}[INFO]${NC} $*" >&2; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*" >&2; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $*" >&2; }
log_error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_proxy()   { echo -e "${PURPLE}[PROXY]${NC} $*" >&2; }
log_verbose() { [[ "${VERBOSE}" == true ]] && echo -e "${BLUE}[VERBOSE]${NC} $*" >&2; }

show_help() {
    cat << EOF
Network Speed Test Script

Usage: ${0##*/} [OPTIONS]

OPTIONS:
    -h, --help          Show this help
    -t, --timeout N     Timeout in seconds (Default: 30)
    -s, --size SIZE     File size: 1MB, 10MB, 100MB
    -x, --proxy URL     Force a proxy
    --no-proxy          Disable auto-detection
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help) show_help; exit 0 ;;
            -t|--timeout) TIMEOUT="$2"; shift 2 ;;
            -v|--verbose) VERBOSE=true; shift ;;
            -s|--size) FILE_SIZE="$2"; shift 2 ;;
            -x|--proxy) PROXY="$2"; AUTO_DETECT_PROXY=false; shift 2 ;;
            --no-proxy) AUTO_DETECT_PROXY=false; PROXY=""; shift ;;
            *) log_error "Unknown option: $1"; exit 1 ;;
        esac
    done
}

check_dependencies() {
    local deps=(curl ping awk bc)
    for cmd in "${deps[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            log_error "Missing required command: $cmd"
            exit 1
        fi
    done
}

detect_proxy() {
    if [[ "$AUTO_DETECT_PROXY" != true ]]; then return; fi
    log_info "Auto-detecting proxy configuration..."
    
    if [[ -n "${ALL_PROXY:-}" ]]; then
        PROXY="$ALL_PROXY"
        log_proxy "Found in env: $PROXY"
        return
    fi
    
    local ports=("7890" "7891" "7892" "1080" "1081" "8080" "8888")
    for port in "${ports[@]}"; do
        if (echo > /dev/tcp/127.0.0.1/$port) >/dev/null 2>&1; then
            if curl -s --proxy "socks5://127.0.0.1:$port" --max-time 1 "http://www.google.com/generate_204" &>/dev/null; then
                PROXY="socks5://127.0.0.1:$port"
                log_proxy "Found SOCKS5 at port $port"
                return
            fi
            if curl -s --proxy "http://127.0.0.1:$port" --max-time 1 "http://www.google.com/generate_204" &>/dev/null; then
                PROXY="http://127.0.0.1:$port"
                log_proxy "Found HTTP at port $port"
                return
            fi
        fi
    done
    log_info "No local proxy detected."
}

# ==========================================
# DATA FETCHING
# ==========================================

get_ip_info() {
    log_info "Fetching Network Information..."
    
    local cmd=(curl -s --max-time 5)
    if [[ -n "$PROXY" ]]; then cmd+=(--proxy "$PROXY"); fi
    cmd+=("ipinfo.io/json")

    local json
    json=$("${cmd[@]}" 2>/dev/null)

    MY_IP=$(echo "$json" | awk -F'"' '/"ip":/ {print $4}')
    MY_CITY=$(echo "$json" | awk -F'"' '/"city":/ {print $4}')
    MY_REGION=$(echo "$json" | awk -F'"' '/"region":/ {print $4}')
    MY_COUNTRY=$(echo "$json" | awk -F'"' '/"country":/ {print $4}')
    MY_ISP=$(echo "$json" | awk -F'"' '/"org":/ {print $4}')

    MY_IP=${MY_IP:-"Unknown"}
    MY_ISP=${MY_ISP:-"Unknown"}
    MY_LOC="${MY_CITY:-Unknown}, ${MY_COUNTRY:-Unknown}"
}

test_ping() {
    log_info "Testing latency to ${PING_TARGET}..."
    local output
    if [[ "$(uname)" == "Darwin" ]]; then
        output=$(ping -c "$PING_COUNT" -t 5 "$PING_TARGET" 2>&1)
    else
        output=$(ping -c "$PING_COUNT" -w 10 "$PING_TARGET" 2>&1)
    fi
    
    AVG_PING=$(echo "$output" | awk -F '/' '/round-trip|rtt/ {print $(NF-2)}')
    [[ -z "$AVG_PING" ]] && AVG_PING="0"
    
    if [[ "$AVG_PING" != "0" ]]; then
        log_success "Latency: ${AVG_PING} ms"
    else
        log_warning "Ping failed."
    fi
    echo "" >&2
}

test_download_single() {
    local url=$1
    local label=$2
    log_info "Starting thread: ${label}..."
    
    local cmd=(curl -s -L --max-time "$TIMEOUT" --connect-timeout 10)
    cmd+=(-o /dev/null -w "%{speed_download}|%{http_code}")
    if [[ -n "$PROXY" ]]; then cmd+=(--proxy "$PROXY"); fi
    
    local result
    result=$("${cmd[@]}" "$url" 2>/dev/null)
    local speed_bps=$(echo "$result" | cut -d'|' -f1)
    local http_code=$(echo "$result" | cut -d'|' -f2)
    
    if [[ "$http_code" != "200" ]] || [[ ! "$speed_bps" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        echo "0"
        return 1
    fi

    local mbps
    mbps=$(echo "$speed_bps" | awk '{printf "%.2f", ($1 * 8) / 1000000}')
    
    if (( $(echo "$mbps < 0.01" | bc -l) )); then
        echo "0"
        return 1
    fi

    # Only echo the number for the background process capture
    echo "$mbps"
}

run_report() {
    log_info "Starting Multi-Threaded Download Speed Test (${FILE_SIZE})..."
    
    local bytes_size
    case "$FILE_SIZE" in
        1MB)   bytes_size=1000000 ;;
        10MB)  bytes_size=10000000 ;;
        100MB) bytes_size=100000000 ;;
        *)     bytes_size=10000000 ;;
    esac

    local urls=(
        "https://speed.cloudflare.com/__down?bytes=${bytes_size}|Cloudflare CDN"
        "http://speedtest.tele2.net/${FILE_SIZE}.zip|Tele2 (Europe)"
        "https://proof.ovh.net/files/${FILE_SIZE/MB/Mb}.dat|OVH Hosting"
    )

    local total_speed=0
    local count=0
    local -a valid_speeds=()
    
    # Create a temporary directory for thread outputs
    local tmp_dir
    tmp_dir=$(mktemp -d) || exit 1
    
    # FIX: Use double quotes to expand variable immediately, preventing 'unbound variable' error on exit
    trap "rm -rf \"$tmp_dir\"" EXIT

    local pids=()
    local i=0

    # Start downloads in parallel
    for entry in "${urls[@]}"; do
        local url="${entry%%|*}"
        local name="${entry##*|}"
        
        (
            test_download_single "$url" "$name" > "${tmp_dir}/$i.txt"
        ) &
        pids+=($!)
        ((i++))
    done
    
    # Wait for all threads to finish
    wait "${pids[@]}"
    log_success "All threads completed."

    # Aggregate results
    for ((j=0; j<i; j++)); do
        if [[ -f "${tmp_dir}/$j.txt" ]]; then
            local speed
            speed=$(cat "${tmp_dir}/$j.txt")
            
            if [[ "$speed" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
                if (( $(echo "$speed > 0" | bc -l) )); then
                    valid_speeds+=("$speed")
                    total_speed=$(echo "$total_speed + $speed" | bc -l)
                    ((count++))
                fi
            fi
        fi
    done
    
    echo "" >&2
    get_ip_info

    # FINAL REPORT
    echo "" >&2
    echo -e "╔══════════════════════════════════════════════════╗" >&2
    echo -e "║              ${CYAN}NETWORK REPORT${NC}                      ║" >&2
    echo -e "╠══════════════════════════════════════════════════╣" >&2
    
    # Network Details
    echo -e "║ ${YELLOW}Network Details${NC}                                  ║" >&2
    printf "║ %-14s : %-31s ║\n" "Public IP" "$MY_IP" >&2
    printf "║ %-14s : %-31s ║\n" "Location" "${MY_LOC:0:31}" >&2
    printf "║ %-14s : %-31s ║\n" "Provider" "${MY_ISP:0:31}" >&2
    
    if [[ -n "$PROXY" ]]; then
        printf "║ %-14s : ${PURPLE}%-31s${NC} ║\n" "Proxy" "ON (Active)" >&2
    else
        printf "║ %-14s : %-31s ║\n" "Proxy" "OFF" >&2
    fi

    echo -e "╠══════════════════════════════════════════════════╣" >&2
    
    # Speed Results
    # echo -e "║ ${YELLOW}Speed Results${NC}                                    ║" >&2
    # if [[ $count -gt 0 ]]; then
    #     local total_formatted=$(printf "%.2f" "$total_speed")
    #     local max=$(printf '%s\n' "${valid_speeds[@]}" | sort -n | tail -1)

    #     printf "║ %-14s : %-31s ║\n" "Latency" "${AVG_PING} ms" >&2
    #     printf "║ %-14s : ${GREEN}%-31s${NC} ║\n" "Total Speed" "${total_formatted} Mbps" >&2
    #     printf "║ %-14s : ${GREEN}%-31s${NC} ║\n" "Single Max" "${max} Mbps" >&2
    # else
    #     echo -e "║ ${RED}Download tests failed.${NC}                           ║" >&2
    # fi

    echo -e "║ ${YELLOW}Speed Results (Multi-Source)${NC}                     ║" >&2
    if [[ $count -gt 0 ]]; then
        local avg=$(echo "scale=2; $total_speed / $count" | bc -l)
        avg=$(printf "%.2f" "$avg")
        local max=$(printf '%s\n' "${valid_speeds[@]}" | sort -n | tail -1)
        
        printf "║ %-14s : %-31s ║\n" "Latency" "${AVG_PING} ms" >&2
        echo -e "║                                                  ║" >&2
        
        # Show individual server results
        local idx=0
        for entry in "${urls[@]}"; do
            local name="${entry##*|}"
            if [[ -f "${tmp_dir}/${idx}.txt" ]]; then
                local speed=$(cat "${tmp_dir}/${idx}.txt")
                if [[ "$speed" =~ ^[0-9]+(\.[0-9]+)?$ ]] && (( $(echo "$speed > 0" | bc -l) )); then
                    printf "║ %-14s : ${CYAN}%-31s${NC} ║\n" "${name:0:14}" "${speed} Mbps" >&2
                else
                    printf "║ %-14s : ${RED}%-31s${NC} ║\n" "${name:0:14}" "Failed" >&2
                fi
            fi
            ((idx++))
        done
        
        echo -e "║                                                  ║" >&2
        printf "║ %-14s : ${GREEN}%-31s${NC} ║\n" "Peak Speed" "${max} Mbps" >&2
        printf "║ %-14s : %-31s ║\n" "Average Speed" "${avg} Mbps" >&2
        
        # Show aggregate with disclaimer
        local total_formatted=$(printf "%.2f" "$total_speed")
        printf "║ %-14s : ${PURPLE}%-31s${NC} ║\n" "Aggregate" "${total_formatted} Mbps" >&2
        echo -e "║ ${PURPLE}ℹ Aggregate = sum of simultaneous downloads${NC}      ║" >&2
    else
        echo -e "║ ${RED}Download tests failed.${NC}                           ║" >&2
    fi

    echo -e "╚══════════════════════════════════════════════════╝" >&2
}

main() {
    parse_args "$@"
    
    echo "==========================================" >&2
    check_dependencies
    detect_proxy
    
    if [[ -n "$PROXY" ]]; then
        echo -e "${GREEN}✅ Using Proxy: $PROXY${NC}" >&2
    else
        echo -e "${YELLOW}⚠️  Direct Connection (No Proxy)${NC}" >&2
    fi
    echo "==========================================" >&2
    echo "" >&2
    
    test_ping
    run_report
}

main "$@"