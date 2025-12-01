import 'dart:convert';
import 'protocol.dart';
import 'protocol_parser.dart';
import 'protocol_validator.dart';
import 'proxy_url.dart';
import 'utils.dart';

class ShadowsocksRProtocol implements Protocol {
  @override
  String get name => 'ssr';

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
      String password = Base64Utils.decodeToUtf8(passwordBase64);

      String name = server;
      if (parsed.params.containsKey('remarks')) {
        name = Base64Utils.decodeToUtf8(parsed.params['remarks']!);
      }

      String protocolParam = '';
      if (parsed.params.containsKey('protoparam')) {
        protocolParam = Base64Utils.decodeToUtf8(parsed.params['protoparam']!);
      }

      String obfsParam = '';
      if (parsed.params.containsKey('obfsparam')) {
        obfsParam = Base64Utils.decodeToUtf8(parsed.params['obfsparam']!);
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

    String server = parts[0];
    int port = int.tryParse(parts[1]) ?? 0;
    String protocol = parts[2];
    String method = parts[3];
    String obfs = parts[4];
    String passwordBase64 = parts[5];
    String password = Base64Utils.decodeToUtf8(passwordBase64);

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
      name = Base64Utils.decodeToUtf8(params['remarks']!);
    }

    String protocolParam = '';
    if (params.containsKey('protoparam')) {
      protocolParam = Base64Utils.decodeToUtf8(params['protoparam']!);
    }

    String obfsParam = '';
    if (params.containsKey('obfsparam')) {
      obfsParam = Base64Utils.decodeToUtf8(params['obfsparam']!);
    }

    // Right now ClashX Meta doesn't support chacha20-ietf-poly1305 and rc4
    if (method == 'chacha20-ietf-poly1305') {
      method = 'chacha20-ietf';
    } else if (method == 'rc4') {
      method = 'rc4-md5';
      //return {'type': 'ssr', 'error': 'Unsupported cipher for SSR: $method'};
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

    // Convert URL-safe base64 to standard base64
    String ssrContent = urlContent.replaceAll('-', '+').replaceAll('_', '/');

    // Fix padding
    while (ssrContent.length % 4 != 0) {
      ssrContent += '=';
    }

    final decoded = utf8.decode(base64.decode(ssrContent));

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
        'Invalid SSR format: expected 6 parts, got ${parts.length}',
      );
    }

    String server = parts[0];
    int port = int.tryParse(parts[1]) ?? 0;
    if (port < 1 || port > 65535) {
      throw ArgumentError('Invalid SSR port: $port');
    }

    String ssrProtocol = parts[2];
    String method = parts[3];
    String obfs = parts[4];
    String passwordBase64 = parts[5];

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
