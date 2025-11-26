import 'protocol.dart';
import 'proxy_url.dart';
import 'vmess.dart';
import 'vless.dart';
import 'shadowsocks.dart';
import 'trojan.dart';
import 'hysteria2.dart';

import 'shadowsocksr.dart';

class ProtocolManager {
  static final List<Protocol> _protocols = [
    Hysteria2Protocol(), // Check specific ones first
    VlessProtocol(),
    VmessProtocol(),
    TrojanProtocol(),
    ShadowsocksRProtocol(),
    ShadowsocksProtocol(),
  ];

  static Map<String, dynamic> parse(String url) {
    // 1. Sanitize and parse generic URL structure
    String sanitizedUrl = ProxyUrl.sanitizeUri(url);
    ProxyUrl? parsed;
    try {
      parsed = ProxyUrl.parse(sanitizedUrl);
    } catch (_) {
      // Parsing might fail for some legacy formats, but we continue to try protocols
    }

    // 2. Find a matching protocol
    for (final protocol in _protocols) {
      if (protocol.canHandle(sanitizedUrl, parsed)) {
        return protocol.parse(sanitizedUrl, parsed: parsed);
      }
    }

    return {'error': 'Unsupported protocol or invalid URL format'};
  }
}
