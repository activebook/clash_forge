import 'protocol.dart';
import 'proxy_url.dart';
import 'vmess.dart';
import 'vless.dart';
import 'shadowsocks.dart';
import 'trojan.dart';
import 'hysteria2.dart';

import 'shadowsocksr.dart';
import 'tuic.dart';
import 'anytls.dart';

class ProtocolManager {
  static final List<Protocol> _protocols = [
    Hysteria2Protocol(), // Check specific ones first
    TuicProtocol(),
    AnyTlsProtocol(),
    VlessProtocol(),
    VmessProtocol(),
    TrojanProtocol(),
    ShadowsocksRProtocol(),
    ShadowsocksProtocol(),
  ];

  static Map<String, dynamic> parse(String url) {
    // 1. Sanitize and parse generic URL structure
    String sanitizedUrl = UrlSanitizer.sanitize(url);
    ProxyUrl? parsed;
    String err;
    try {
      parsed = ProxyUrl.parse(sanitizedUrl);
      err = parsed.toString();
    } catch (e) {
      // Parsing might fail for some legacy formats, but we continue to try protocols
      err = e.toString();
    }

    // 2. Find a matching protocol
    for (final protocol in _protocols) {
      if (protocol.canHandle(sanitizedUrl, parsed)) {
        var result = protocol.parse(sanitizedUrl, parsed: parsed);
        if (result.containsKey('name') && result['name'] is String) {
          result['name'] = _tryDecode(result['name']);
        }
        return result;
      }
    }

    return {'error': 'Unsupported protocol or invalid URL format:\n$err'};
  }

  static String _tryDecode(String text) {
    try {
      if (text.contains('%')) {
        return Uri.decodeComponent(text);
      }
    } catch (_) {}
    return text;
  }
}
