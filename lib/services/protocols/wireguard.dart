import 'dart:convert';

class WireGuardParser {
  /// Check if the content looks like a WireGuard config
  static bool isWireGuardConfig(String content) {
    final lowerContent = content.toLowerCase();
    return lowerContent.contains('[interface]') &&
        lowerContent.contains('[peer]');
  }

  /// Parse WireGuard INI content into Clash proxy configuration
  static Map<String, dynamic> parse(String content) {
    final lines = LineSplitter.split(content).toList();

    String privateKey = '';
    String ip = '';
    String ipv6 = '';
    String server = '';
    int port = 0;
    String publicKey = '';
    String preSharedKey = '';
    List<int> reserved = [];
    int mtu = 0;
    String name = 'WireGuard';

    String currentSection = '';

    List<String> configDns = [];

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty || line.startsWith('#') || line.startsWith(';')) {
        continue;
      }

      if (line.startsWith('[') && line.endsWith(']')) {
        currentSection = line.substring(1, line.length - 1).toLowerCase();
        continue;
      }

      final parts = line.split('=');
      if (parts.length < 2) continue;

      final key = parts[0].trim().toLowerCase();
      final value = parts.sublist(1).join('=').trim();

      if (currentSection == 'interface') {
        if (key == 'privatekey') {
          privateKey = value;
        } else if (key == 'address') {
          // Handle both IPv4 and IPv6
          final addresses = value.split(',').map((e) => e.trim()).toList();
          for (var addr in addresses) {
            if (addr.contains(':')) {
              ipv6 = addr; // Simple check for IPv6
            } else {
              ip = addr;
            }
          }
        } else if (key == 'dns') {
          configDns =
              value
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
        } else if (key == 'mtu') {
          mtu = int.tryParse(value) ?? 0;
        }
      } else if (currentSection == 'peer') {
        if (key == 'endpoint') {
          final endpointParts = value.split(':');
          if (endpointParts.length >= 2) {
            server = endpointParts[0];
            port = int.tryParse(endpointParts[1]) ?? 0;
          }
        } else if (key == 'publickey') {
          publicKey = value;
        } else if (key == 'presharedkey') {
          preSharedKey = value;
        } else if (key == 'reserved') {
          // Reserved bytes are typically comma-separated integers
          try {
            reserved =
                value.split(',').map((e) => int.parse(e.trim())).toList();
          } catch (_) {}
        }
        // Ignore AllowedIPs
      }
    }

    if (privateKey.isEmpty ||
        server.isEmpty ||
        port == 0 ||
        publicKey.isEmpty) {
      return {'error': 'Invalid WireGuard config: Missing required fields'};
    }

    return {
      'name': name,
      'type': 'wireguard',
      'server': server,
      'port': port,
      'ip': ip,
      if (ipv6.isNotEmpty) 'ipv6': ipv6,
      'private-key': privateKey,
      'public-key': publicKey,
      if (preSharedKey.isNotEmpty) 'pre-shared-key': preSharedKey,
      if (reserved.isNotEmpty) 'reserved': reserved,
      if (mtu > 0) 'mtu': mtu,
      'remote-dns-resolve':
          true, // CRITICAL: Enable remote DNS resolution through tunnel
      'dns': [
        'https://doh.pub/dns-query', // DoH Pub
        'https://dns.pub/dns-query', // DNS Pub
        'https://1.12.12.12/dns-query', // Tencent DoH
        'https://120.53.53.53/dns-query', // CNNIC DoH
        ...configDns,
      ],
      'udp': true, // WireGuard is always UDP
    };
  }
}
