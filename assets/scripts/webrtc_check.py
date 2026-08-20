import socket
import struct
import random
import sys

def get_stun_ip(server="stun.l.google.com", port=19302):
    # STUN Binding Request
    # 0x0001 = Binding Request
    # 0x0000 = Message length
    # 0x2112a442 = Magic Cookie
    # 12-byte Transaction ID
    transaction_id = bytes(random.getrandbits(8) for _ in range(12))
    packet = struct.pack(">HHI12s", 0x0001, 0x0000, 0x2112a442, transaction_id)

    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.settimeout(2.0)
    try:
        sock.sendto(packet, (server, port))
        data, addr = sock.recvfrom(2048)
        
        # Simple parsing of STUN response
        # Attributes start at byte 20
        pos = 20
        while pos < len(data):
            attr_type, attr_len = struct.unpack(">HH", data[pos:pos+4])
            # 0x0001 = MAPPED-ADDRESS, 0x0020 = XOR-MAPPED-ADDRESS
            if attr_type == 0x0001:
                # Family (1 byte), Port (2 bytes), Address (4 bytes)
                family, port, a, b, c, d = struct.unpack(">x B H B B B B", data[pos+4:pos+12])
                return f"{a}.{b}.{c}.{d}"
            elif attr_type == 0x0020:
                # Family (1 byte), Port (2 bytes), XOR Address (4 bytes)
                family, xport, xaddr = struct.unpack(">x B H I", data[pos+4:pos+12])
                # XOR-Address = XORed with Magic Cookie (0x2112a442)
                ip_int = xaddr ^ 0x2112a442
                return socket.inet_ntoa(struct.pack(">I", ip_int))
            
            # Align to 4 bytes
            pos += 4 + attr_len
            if attr_len % 4 != 0:
                pos += (4 - (attr_len % 4))
        return None
    except Exception as e:
        return None
    finally:
        sock.close()

if __name__ == "__main__":
    ip = get_stun_ip()
    if ip:
        print(ip)
    else:
        # Fallback to cloudflare
        ip = get_stun_ip("stun.cloudflare.com", 3478)
        if ip:
            print(ip)
        else:
            sys.exit(1)
