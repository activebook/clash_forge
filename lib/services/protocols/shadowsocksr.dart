import 'protocol.dart';
import 'protocol_parser.dart';
import 'protocol_validator.dart';
import 'proxy_url.dart';
import 'utils.dart';

class ShadowsocksRProtocol implements Protocol {
  @override
  String get name => 'ssr';

  static String _safeDecodeBase64(String input) {
    if (input.isEmpty) return '';
    try {
      return Base64Utils.decodeToUtf8(input);
    } catch (_) {
      try {
        return Uri.decodeComponent(input);
      } catch (_) {
        return input;
      }
    }
  }

  @override
  bool canHandle(String url, ProxyUrl? parsed) {
    if (parsed != null) {
      return parsed.protocol == 'ssr';
    }
    return url.toLowerCase().startsWith('ssr://');
  }

  @override
  Map<String, dynamic> parse(String url, {ProxyUrl? parsed}) {
    // If ProxyUrl already parsed SSR data, use it
    if (parsed != null &&
        parsed.protocol == 'ssr' &&
        parsed.params.containsKey('ssr-protocol')) {
      String server = parsed.address;
      int port = parsed.port;
      String protocol = parsed.params['ssr-protocol']!;
      String method = parsed.params['method']!;
      String obfs = parsed.params['obfs']!;
      String passwordBase64 = parsed.params['password-base64']!;
      String password = _safeDecodeBase64(passwordBase64);

      String name = server;
      if (parsed.params.containsKey('remarks')) {
        name = _safeDecodeBase64(parsed.params['remarks']!);
      }

      String protocolParam = '';
      if (parsed.params.containsKey('protoparam')) {
        protocolParam = _safeDecodeBase64(parsed.params['protoparam']!);
      }

      String obfsParam = '';
      if (parsed.params.containsKey('obfsparam')) {
        obfsParam = _safeDecodeBase64(parsed.params['obfsparam']!);
      }

      // Cipher compatibility
      method = method.toLowerCase();
      if (method == 'chacha20-ietf-poly1305') {
        method = 'chacha20-ietf';
      } else if (method == 'rc4') {
        method = 'rc4-md5';
      }

      // Validate cipher
      if (!ProtocolValidator.isValidCipher(method)) {
        return {
          'type': 'ssr',
          'error': 'Unsupported or Legacy cipher detected: $method',
        };
      }

      return {
        'name': name,
        'type': 'ssr',
        'server': server,
        'port': port,
        'cipher': method,
        'password': password,
        'protocol': protocol,
        'obfs': obfs,
        'protocol-param': protocolParam,
        'obfs-param': obfsParam,
        'udp': true,
      };
    }

    // Fallback: parse raw SSR URL
    if (!url.startsWith('ssr://')) {
      throw FormatException('Not a ShadowsocksR URL');
    }

    String base64Part = url.substring(6);
    String decoded;
    try {
      decoded = Base64Utils.decodeToUtf8(base64Part);
    } catch (e) {
      return {'type': 'ssr', 'error': 'Invalid Base64 in SSR URL'};
    }

    // Format: server:port:protocol:method:obfs:password_base64/?params

    int queryIndex = decoded.indexOf('/?');
    String mainPart;
    String queryPart = '';

    if (queryIndex != -1) {
      mainPart = decoded.substring(0, queryIndex);
      queryPart = decoded.substring(queryIndex + 2);
    } else {
      mainPart = decoded;
    }

    List<String> parts = mainPart.split(':');
    if (parts.length < 6) {
      return {'type': 'ssr', 'error': 'Invalid SSR format: insufficient parts'};
    }

    String passwordBase64 = parts.last;
    String obfs = parts[parts.length - 2];
    String method = parts[parts.length - 3];
    String protocol = parts[parts.length - 4];
    int port = int.tryParse(parts[parts.length - 5]) ?? 0;
    String server = parts.sublist(0, parts.length - 5).join(':');
    if (server.startsWith('[') && server.endsWith(']')) {
      server = server.substring(1, server.length - 1);
    }
    String password = _safeDecodeBase64(passwordBase64);

    Map<String, String> params = {};
    if (queryPart.isNotEmpty) {
      List<String> queryParams = queryPart.split('&');
      for (var param in queryParams) {
        int eqIndex = param.indexOf('=');
        if (eqIndex != -1) {
          String key = param.substring(0, eqIndex);
          String value = param.substring(eqIndex + 1);
          params[key] = value;
        }
      }
    }

    String name = server;
    if (params.containsKey('remarks')) {
      name = _safeDecodeBase64(params['remarks']!);
    }

    String protocolParam = '';
    if (params.containsKey('protoparam')) {
      protocolParam = _safeDecodeBase64(params['protoparam']!);
    }

    String obfsParam = '';
    if (params.containsKey('obfsparam')) {
      obfsParam = _safeDecodeBase64(params['obfsparam']!);
    }

    // Right now ClashX Meta doesn't support chacha20-ietf-poly1305 and rc4
    if (method == 'chacha20-ietf-poly1305') {
      method = 'chacha20-ietf';
    } else if (method == 'rc4') {
      method = 'rc4-md5';
    }

    return {
      'name': name,
      'type': 'ssr',
      'server': server,
      'port': port,
      'cipher': method,
      'password': password,
      'protocol': protocol,
      'obfs': obfs,
      'protocol-param': protocolParam,
      'obfs-param': obfsParam,
      'udp': true,
    };
  }
}

// ============================================================================
// ShadowsocksR Parser - handles URL-safe base64 encoded format
// ============================================================================
class ShadowsocksRParser implements ProtocolParser {
  @override
  ProxyUrl parse(String url, String protocol) {
    final protocolSeparator = url.indexOf('://');
    String urlContent = url.substring(protocolSeparator + 3);

    String decoded;
    try {
      decoded = Base64Utils.decodeToUtf8(urlContent);
    } catch (e) {
      throw ArgumentError('Invalid Base64 in SSR URL: $e');
    }

    // SSR format: server:port:protocol:method:obfs:password_base64/?params
    int queryIndex = decoded.indexOf('/?');
    String mainPart;
    Map<String, String> params = {};

    if (queryIndex != -1) {
      mainPart = decoded.substring(0, queryIndex);
      String queryPart = decoded.substring(queryIndex + 2);
      params = UrlParser.parseQueryParams(queryPart);
    } else {
      mainPart = decoded;
    }

    // Parse main parts: server:port:protocol:method:obfs:password_base64
    List<String> parts = mainPart.split(':');
    if (parts.length < 6) {
      throw ArgumentError(
        'Invalid SSR format: expected at least 6 parts, got ${parts.length}',
      );
    }

    String passwordBase64 = parts.last;
    String obfs = parts[parts.length - 2];
    String method = parts[parts.length - 3];
    String ssrProtocol = parts[parts.length - 4];
    int port = int.tryParse(parts[parts.length - 5]) ?? 0;
    String server = parts.sublist(0, parts.length - 5).join(':');
    if (server.startsWith('[') && server.endsWith(']')) {
      server = server.substring(1, server.length - 1);
    }

    if (port < 1 || port > 65535) {
      throw ArgumentError('Invalid SSR port: $port');
    }

    // Store SSR-specific fields in params
    params['ssr-protocol'] = ssrProtocol;
    params['method'] = method;
    params['obfs'] = obfs;
    params['password-base64'] = passwordBase64;

    return ProxyUrl(
      protocol: protocol,
      id: passwordBase64,
      address: server,
      port: port,
      params: params,
      remark: params['remarks'],
      rawUrl: url,
      base64: true,
    );
  }
}
