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
    String server = '';
    int port = 0;
    String publicKey = '';
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
          ip = value;
        } else if (key == 'dns') {
          configDns =
              value
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
        }
        // Ignore MTU
      } else if (currentSection == 'peer') {
        if (key == 'endpoint') {
          final endpointParts = value.split(':');
          if (endpointParts.length >= 2) {
            server = endpointParts[0];
            port = int.tryParse(endpointParts[1]) ?? 0;
          }
        } else if (key == 'publickey') {
          publicKey = value;
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
      'private-key': privateKey,
      'public-key': publicKey,
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
