import 'anytls.dart';
import 'hysteria2.dart';
import 'shadowsocks.dart';
import 'shadowsocksr.dart';
import 'trojan.dart';
import 'tuic.dart';
import 'vless.dart';
import 'vmess.dart';

import 'proxy_url.dart';

// ============================================================================
// Protocol Parser Interface
// ============================================================================
abstract class ProtocolParser {
  ProxyUrl parse(String url, String protocol);
}

// ============================================================================
// Factory to get the right parser
// ============================================================================
class ProtocolParserFactory {
  static final Map<String, ProtocolParser> _parsers = {
    'vless': VlessParser(),
    'vmess': VmessParser(),
    'trojan': TrojanParser(),
    'ss': ShadowsocksParser(),
    'ssr': ShadowsocksRParser(),
    'hysteria': HysteriaParser(),
    'hy2': HysteriaParser(),
    'hysteria2': HysteriaParser(),
    'tuic': TuicParser(),
    'anytls': AnyTlsParser(),
  };

  static ProtocolParser? getParser(String protocol) {
    return _parsers[protocol.toLowerCase()];
  }
}

// ============================================================================
// Standard URL Parser - for protocols with standard format:
// protocol://id@host:port?params#remark
// ============================================================================
class CommonProtocolParser implements ProtocolParser {
  @override
  ProxyUrl parse(String url, String protocol) {
    final protocolSeparator = url.indexOf('://');
    final urlWithoutRemark = UrlParser.removeRemark(url);
    final remark = UrlParser.extractRemark(url);

    final urlParts = urlWithoutRemark.substring(protocolSeparator + 3);
    final paramsIndex = urlParts.indexOf('?');
    final connectionPart =
        paramsIndex != -1 ? urlParts.substring(0, paramsIndex) : urlParts;

    final atIndex = connectionPart.indexOf('@');
    if (atIndex == -1) {
      throw ArgumentError('Invalid URL: No @ in URL: [$url]');
    }

    String id = connectionPart.substring(0, atIndex);

    // Decode URL-encoded characters in userinfo
    try {
      id = Uri.decodeComponent(id);
    } catch (_) {
      // If decoding fails, use as-is
    }

    final serverPart = connectionPart.substring(atIndex + 1);
    final (:address, :port) = UrlParser.parseServerAndPort(serverPart, url);

    Map<String, String> params = {};
    if (paramsIndex != -1) {
      final paramsString = urlParts.substring(paramsIndex + 1);
      params = UrlParser.parseQueryParams(paramsString);
    }

    // Allow subclasses to process ID and params
    final processed = processIdAndParams(id, params, protocol);

    return ProxyUrl(
      protocol: protocol,
      id: processed.id,
      address: address,
      port: port,
      params: processed.params,
      remark: remark,
      rawUrl: url,
    );
  }

  // Hook for protocol-specific processing
  ({String id, Map<String, String> params}) processIdAndParams(
    String id,
    Map<String, String> params,
    String protocol,
  ) {
    return (id: id, params: params);
  }
}
