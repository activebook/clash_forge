import 'dart:convert';

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
    } else {
      return '$protocol://$id@$address:$port';
    }
  }

  // Helper function to check if string is UUID format
  static bool isUuid(String str) {
    RegExp uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return uuidRegex.hasMatch(str);
  }

  static String sanitizeUri(String uri) {
    return uri.replaceAll(
      RegExp(r"[^\w\-\.\~\:\/\?\#\[\]\@\!\$\&\'\(\)\*\+\,\;\=\%]"),
      '',
    );
  }

  static String fixBase64Padding(String input) {
    input = input.replaceAll(RegExp(r'[^A-Za-z0-9+/=]'), '');
    switch (input.length % 4) {
      case 1:
        input = input.substring(0, input.length - 1);
        break;
      case 2:
        input += '==';
        break;
      case 3:
        input += '=';
        break;
    }
    return input;
  }

  static bool checkBase64(String content) {
    if (content.isEmpty) return false;
    if (content.contains('-') &&
        RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
        ).hasMatch(content)) {
      return false;
    }
    if (!RegExp(r'^[A-Za-z0-9+/]*={0,2}$').hasMatch(content.trim())) {
      return false;
    }
    try {
      String trimmed = fixBase64Padding(content.trim());
      var decoded = base64.decode(trimmed);
      utf8.decode(decoded);
      return true;
    } catch (_) {
      return false;
    }
  }

  static ProxyUrl? parse(String url) {
    try {
      url = sanitizeUri(url);
      final protocolSeparator = url.indexOf('://');
      if (protocolSeparator == -1) throw ArgumentError('Invalid URL');

      final protocol = url.substring(0, protocolSeparator).trim().toLowerCase();
      String urlContent = url.substring(protocolSeparator + 3);

      if (checkBase64(urlContent)) {
        urlContent = fixBase64Padding(urlContent);
        final decoded = base64.decode(urlContent);
        final decodedUrl = utf8.decode(decoded);

        // Try to parse as JSON (VMess style)
        try {
          final jsonUrl = jsonDecode(decodedUrl);
          if (jsonUrl is Map<String, dynamic>) {
            Map<String, String> params = {};
            jsonUrl.forEach((key, value) {
              params[key] = value.toString();
            });
            int port = int.tryParse(jsonUrl['port']?.toString() ?? '') ?? 0;
            return ProxyUrl(
              protocol: protocol,
              id: jsonUrl['id']?.toString() ?? '',
              address: jsonUrl['add']?.toString() ?? '',
              port: port,
              params: params,
              rawUrl: url,
              base64: true,
            );
          }
        } catch (_) {
          // Not JSON, treat as string
        }
      }

      String urlWithoutRemark = url;
      String? remark;
      final remarkIndex = url.indexOf('#');
      if (remarkIndex != -1) {
        final encodedRemark = url.substring(remarkIndex + 1);
        // Decode URL-encoded characters (emojis, special chars, spaces, etc.)
        try {
          remark = Uri.decodeComponent(encodedRemark);
        } catch (_) {
          // Fallback if decoding fails (e.g., invalid encoding)
          remark = encodedRemark;
        }
        urlWithoutRemark = url.substring(0, remarkIndex);
      }

      // Special handling for SS legacy format
      if (protocol == 'ss') {
        String content = urlWithoutRemark.substring(protocolSeparator + 3);
        // Check if it's the legacy format: ss://base64(method:pass@host:port)
        if (!content.contains('@') && checkBase64(content)) {
          // It's likely the legacy format or SIP002 without userinfo separator (which is rare but possible if full base64)
          // But wait, the original logic had specific handling.
          // Let's try to decode it.
          try {
            final decoded = utf8.decode(
              base64.decode(fixBase64Padding(content)),
            );
            if (decoded.contains('@') && decoded.contains(':')) {
              // It was indeed base64 encoded config
              urlWithoutRemark = "$protocol://$decoded";
            }
          } catch (_) {}
        }
      }

      final urlParts = urlWithoutRemark.substring(protocolSeparator + 3);
      final paramsIndex = urlParts.indexOf('?');
      final connectionPart =
          paramsIndex != -1 ? urlParts.substring(0, paramsIndex) : urlParts;

      final atIndex = connectionPart.indexOf('@');
      if (atIndex == -1) {
        // If no @, it might be that the ID is missing or it's a different format.
        // For now, we throw, but we might want to handle it gracefully.
        throw ArgumentError('Invalid URL: No @ in URL: [$url]');
      }

      final id = connectionPart.substring(0, atIndex);
      final serverPart = connectionPart.substring(atIndex + 1);

      final colonIndex = serverPart.lastIndexOf(':');
      if (colonIndex == -1) {
        throw ArgumentError('Invalid URL: No : in URL: [$url]');
      }

      final address = serverPart.substring(0, colonIndex);
      String portPart = serverPart.substring(colonIndex + 1);
      portPart = portPart.replaceAll(RegExp(r'[^0-9]'), '');
      final port = int.tryParse(portPart);
      if (port == null) {
        throw ArgumentError('Invalid URL: No port in URL: [$url]');
      }

      Map<String, String> params = {};
      if (paramsIndex != -1) {
        final paramsString = urlParts.substring(paramsIndex + 1);
        final paramPairs = paramsString.split('&');
        for (final pair in paramPairs) {
          final keyValue = pair.split('=');
          if (keyValue.length == 2) {
            params[keyValue[0]] = keyValue[1];
          }
        }
      }

      // SS specific: decode ID if it is base64 and contains method:password
      if (protocol == 'ss' && checkBase64(id)) {
        try {
          final decodedId = utf8.decode(base64.decode(fixBase64Padding(id)));
          final colonIndex = decodedId.lastIndexOf(':');
          if (colonIndex != -1) {
            params['method'] = decodedId.substring(0, colonIndex);
            params['password'] = decodedId.substring(colonIndex + 1);
          }
        } catch (_) {}
      }

      return ProxyUrl(
        protocol: protocol,
        id: id,
        address: address,
        port: port,
        params: params,
        remark: remark,
        rawUrl: url,
        base64: false,
      );
    } catch (e) {
      rethrow;
    }
  }

  static bool isValidCipher(String cipher) {
    const List<String> validCiphers = [
      'aes-128-gcm',
      'aes-192-gcm',
      'aes-256-gcm',
      '2022-blake3-aes-128-gcm',
      '2022-blake3-aes-256-gcm',
      '2022-blake3-chacha20-poly1305',
      'aes-128-cfb',
      'aes-192-cfb',
      'aes-256-cfb',
      'aes-128-ctr',
      'aes-192-ctr',
      'aes-256-ctr',
      'camellia-128-cfb',
      'camellia-192-cfb',
      'camellia-256-cfb',
      'chacha20',
      'chacha20-ietf',
      'chacha20-ietf-poly1305',
      'xchacha20-ietf-poly1305',
      'rc4-md5',
      'bf-cfb',
      'salsa20',
      'auto',
      'none',
    ];
    return validCiphers.contains(cipher);
  }

  static int? getKeyLengthForCipher(String cipher) {
    switch (cipher.toLowerCase()) {
      case 'aes-128-gcm':
      case 'aes-128-cfb':
      case 'aes-128-ctr':
      case 'camellia-128-cfb':
      case '2022-blake3-aes-128-gcm':
        return 16;
      case 'aes-256-gcm':
      case 'aes-256-cfb':
      case 'aes-256-ctr':
      case 'camellia-256-cfb':
      case 'chacha20':
      case 'chacha20-ietf':
      case 'chacha20-ietf-poly1305':
      case 'xchacha20-ietf-poly1305':
      case '2022-blake3-aes-256-gcm':
      case '2022-blake3-chacha20-poly1305':
        return 32;
      case 'aes-192-gcm':
      case 'aes-192-cfb':
      case 'aes-192-ctr':
      case 'camellia-192-cfb':
        return 24;
      default:
        return null;
    }
  }

  static bool isValidPublicKey(String? key) {
    if (key == null) return false;
    try {
      if (key.isEmpty || key.length < 43 || key.length > 44) return false;
      String paddedKey = key;
      while (paddedKey.length % 4 != 0) {
        paddedKey += '=';
      }
      final bytes = base64Url.decode(paddedKey);
      return bytes.length == 32;
    } catch (e) {
      return false;
    }
  }
}
