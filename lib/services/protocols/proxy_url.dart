import 'protocol_parser.dart';

// ============================================================================
// Core ProxyUrl class - only shared data and utilities
// ============================================================================
class ProxyUrl {
  final String protocol;
  final String id;
  final String address;
  final int port;
  final Map<String, String> params;
  final String? remark;
  final String? rawUrl;
  final bool isBase64;

  const ProxyUrl({
    required this.protocol,
    required this.id,
    required this.address,
    required this.port,
    required this.params,
    this.remark,
    this.rawUrl,
    bool base64 = false,
  }) : isBase64 = base64;

  @override
  String toString() {
    if (params.isNotEmpty) {
      final paramsStr = params.entries
          .map((e) => '${e.key}=${e.value}')
          .join('&');
      return '$protocol://$id@$address:$port?$paramsStr';
    }
    return '$protocol://$id@$address:$port';
  }

  // Main entry point - delegates to protocol-specific parsers
  static ProxyUrl? parse(String url) {
    try {
      // 1. Sanitize the URL (shared logic)
      url = UrlSanitizer.sanitize(url);

      // 2. Extract protocol
      final protocolSeparator = url.indexOf('://');
      if (protocolSeparator == -1) {
        throw ArgumentError('Invalid URL: missing ://');
      }

      final protocol = url.substring(0, protocolSeparator).trim().toLowerCase();

      // 3. Get the appropriate parser and delegate
      final parser = ProtocolParserFactory.getParser(protocol);
      if (parser == null) {
        throw ArgumentError('Unsupported protocol: $protocol');
      }

      return parser.parse(url, protocol);
    } catch (e) {
      rethrow;
    }
  }
}

// ============================================================================
// URL Sanitizer - handles all cleaning logic
// ============================================================================
class UrlSanitizer {
  static String sanitize(String uri) {
    // Trim whitespace
    uri = uri.trim();

    // Remove zero-width spaces and invisible Unicode characters
    uri = uri.replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '');

    // Remove HTML tags and entities
    uri = uri.replaceAll(RegExp(r'<[^>]*>'), '');
    uri = uri.replaceAll(RegExp(r'&[a-zA-Z]+;'), '');
    uri = uri.replaceAll(RegExp(r'&#\d+;'), '');

    // Find protocol and extract from there
    final protocolMatch = RegExp(
      r'(vless|vmess|trojan|ss|ssr|hy2|hysteria2?|tuic|anytls)://',
      caseSensitive: false,
    ).firstMatch(uri);

    if (protocolMatch != null) {
      uri = uri.substring(protocolMatch.start);
    }

    return uri;
  }
}

// ============================================================================
// URL parsing utilities - shared extraction logic
// ============================================================================
class UrlParser {
  static String? extractRemark(String url) {
    final remarkIndex = url.indexOf('#');
    if (remarkIndex == -1) return null;

    final encodedRemark = url.substring(remarkIndex + 1);
    try {
      return Uri.decodeComponent(encodedRemark);
    } catch (_) {
      return encodedRemark;
    }
  }

  static String removeRemark(String url) {
    final remarkIndex = url.indexOf('#');
    return remarkIndex != -1 ? url.substring(0, remarkIndex) : url;
  }

  static Map<String, String> parseQueryParams(String paramsString) {
    final params = <String, String>{};
    final paramPairs = paramsString.split('&');

    for (final pair in paramPairs) {
      final keyValue = pair.split('=');
      if (keyValue.length == 2) {
        try {
          params[keyValue[0]] = Uri.decodeComponent(keyValue[1]);
        } catch (_) {
          params[keyValue[0]] = keyValue[1];
        }
      }
    }

    return params;
  }

  static ({String address, int port}) parseServerAndPort(
    String serverPart,
    String fullUrl,
  ) {
    String address;
    String portString;

    if (serverPart.startsWith('[')) {
      // IPv6 with brackets: [2001:db8::1]:443
      final closeBracket = serverPart.indexOf(']');
      if (closeBracket == -1) {
        throw ArgumentError(
          'Invalid IPv6 address: missing closing bracket in [$serverPart]',
        );
      }
      address = serverPart.substring(1, closeBracket);

      if (closeBracket + 1 < serverPart.length) {
        if (serverPart[closeBracket + 1] != ':') {
          throw ArgumentError(
            'Invalid IPv6 URL: expected : after ] in [$serverPart]',
          );
        }
        portString = serverPart.substring(closeBracket + 2);
      } else {
        throw ArgumentError(
          'Invalid URL: No port specified after IPv6 address in [$serverPart]',
        );
      }
    } else {
      // IPv4 or hostname
      final colonIndex = serverPart.lastIndexOf(':');
      if (colonIndex == -1) {
        throw ArgumentError('Invalid URL: No : in URL: [$fullUrl]');
      }
      address = serverPart.substring(0, colonIndex);
      portString = serverPart.substring(colonIndex + 1);
    }

    // Validate port
    final originalPortString = portString;
    portString = portString.replaceAll(RegExp(r'[^0-9]'), '');

    final port = int.tryParse(portString);
    if (port == null || portString.isEmpty) {
      throw ArgumentError(
        'Invalid URL: Port is not a valid number: [$originalPortString]',
      );
    }
    if (port < 1 || port > 65535) {
      throw ArgumentError(
        'Invalid URL: Port must be between 1-65535, got: $port',
      );
    }

    return (address: address, port: port);
  }
}
