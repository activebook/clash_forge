#!/usr/bin/env bash
# Debug Proxy Detection

check_port() {
    local port=$1
    echo "--- Checking Port $port ---"
    
    echo "1. Checking with lsof:"
    lsof -i :$port || echo "lsof found nothing on $port"
    
    echo "2. Checking with /dev/tcp:"
    if (echo > /dev/tcp/127.0.0.1/$port) >/dev/null 2>&1; then
        echo "   /dev/tcp/127.0.0.1/$port -> OPEN"
    else
        echo "   /dev/tcp/127.0.0.1/$port -> CLOSED/UNREACHABLE"
    fi

    echo "3. Checking with curl (SOCKS5):"
    curl -v --proxy "socks5://127.0.0.1:$port" --max-time 2 "http://www.google.com/generate_204" 2>&1 | head -n 5 || echo "Curl failed"

    echo "4. Checking with curl (HTTP):"
    curl -v --proxy "http://127.0.0.1:$port" --max-time 2 "http://www.google.com/generate_204" 2>&1 | head -n 5 || echo "Curl failed"
    echo ""
}

echo "Starting Diagnostic..."
check_port 7890
check_port 7891
echo "Done."
