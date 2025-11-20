import 'dart:convert';

class ProxyUrl {
  final String protocol;
  final String id;
  final String address;
  final int port;
  final Map<String, String> params;
  final String? remark;
  final String? _url;
  bool? _base64Encoding = false;

  ProxyUrl({
    required this.protocol,
    required this.id,
    required this.address,
    required this.port,
    required this.params,
    this.remark,
    String? url,
    base64,
  }) : _url = url,
       _base64Encoding = base64;

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

  set base64Encoding(base64) {
    _base64Encoding = base64;
  }

  bool get isBase64 {
    return _base64Encoding!;
  }

  bool get isLikelyVless {
    // UUID format with dashes + VLESS-specific parameters
    bool encryption =
        params.containsKey('encryption') && params['encryption'] == 'none';
    bool security =
        params.containsKey('security') &&
        (params['security'] == 'reality' ||
            params['security'] == 'tls' ||
            params['security'] == 'none');
    // only in vless, type is a network factor
    bool type =
        params.containsKey('type') &&
        (params['type'] == 'ws' ||
            params['type'] == 'grpc' ||
            params['type'] == 'h2');
    bool feature =
        !isBase64 &&
        isUuid(id) &&
        (encryption || security || type || params.containsKey('pbk'));
    return feature;
  }

  bool get isLikelyVmess {
    // Check for VMESS-specific parameters or structure
    bool feature =
        isBase64 &&
        (isUuid(id) || params.containsKey("id")) &&
        (params.containsKey('aid') ||
            params.containsKey('net') ||
            params.containsKey('type') ||
            (params.containsKey('tls') && params.containsKey('network')));
    return feature;
  }

  bool get isLikelyTrojan {
    // Trojan typically has password + TLS security
    if (!isBase64 &&
        (params.containsKey('allowInsecure') &&
            [
              '0',
              '1',
              'true',
              'false',
            ].contains(params['allowInsecure']?.toLowerCase()))) {
      return true;
    }
    if (!isBase64 && params.containsKey('sni')) {
      return true;
    }
    bool feature =
        !isBase64 &&
        params.containsKey('security') &&
        params['security'] == 'tls' &&
        !params.containsKey('encryption'); // No encryption param unlike VLESS
    return feature;
  }

  bool get isLikelyShadowsocks {
    // Real Shadowsocks has method:password in base64
    // This is complex to check perfectly but we can look for non-UUID format
    // and typical SS parameters
    // Shadowsocks (SS) has two formats:
    // SIP002 (modern): ss://[base64(method:password)]@[server]:[port]#[remark]
    // Only the method:password part is base64-encoded
    // Legacy: ss://[base64(entire-configuration)]
    bool feature =
        !isUuid(id) &&
        (params.containsKey('method') ||
            params.containsKey('cipher') ||
            id.contains(':') || // might be method:password not in base64
            params.isEmpty) &&
        (protocol == "ss"); // SS often has minimal params
    return feature;
  }

  String getCorrectProtocol() {
    if (isLikelyVless) return 'vless';
    if (isLikelyVmess) return 'vmess';
    if (isLikelyTrojan) return 'trojan';
    if (isLikelyShadowsocks) return 'ss';
    return protocol; // Default to original if uncertain
  }

  String toRevisedUrl() {
    if (_url == null) {
      return toCorrectUrl();
    }
    final correctProtocol = getCorrectProtocol();
    String url = ProxyUrl.sanitizeUri(_url);
    final protocolSeparator = url.indexOf('://');
    if (protocolSeparator == -1) return toCorrectUrl();
    return correctProtocol + url.substring(protocolSeparator);
  }

  String toCorrectUrl() {
    final correctProtocol = getCorrectProtocol();

    if (correctProtocol != protocol) {
      final paramsStr = params.entries
          .map((e) => '${e.key}=${e.value}')
          .join('&');

      final paramsPart = params.isEmpty ? '' : '?$paramsStr';
      final remarkPart = remark != null ? '#$remark' : '';

      return '$correctProtocol://$id@$address:$port$paramsPart$remarkPart';
    }

    return ''; // Return empty if no correction needed
  }

  // Helper function to check if string is UUID format
  static bool isUuid(String str) {
    // Basic UUID validation - checking for format with dashes
    RegExp uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return uuidRegex.hasMatch(str);
  }

  // Method to remove protocol prefix from URL
  static String removeProtocolPrefix(String url) {
    final protocolSeparator = url.indexOf('://');
    if (protocolSeparator != -1) {
      return url.substring(protocolSeparator + 3);
    }
    return url; // Return original if no protocol prefix found
  }

  // Check if content is base64 encoded
  // Improved base64 detection
  static bool checkBase64(String content) {
    // Skip empty strings
    if (content.isEmpty) return false;

    // Quick check: if it contains hyphens and matches UUID format, it's not base64
    if (content.contains('-') &&
        RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
        ).hasMatch(content)) {
      return false;
    }

    // For proper base64 detection, don't remove characters before checking
    // Instead, validate the string only contains valid base64 characters
    if (!RegExp(r'^[A-Za-z0-9+/]*={0,2}$').hasMatch(content.trim())) {
      return false;
    }

    try {
      // Fix padding if needed
      String trimmed = fixBase64Padding(content.trim());

      // Try actual decode
      var decoded = base64.decode(trimmed);
      // If decoding succeeds, it's likely base64
      // If not, it's not base64
      utf8.decode(decoded);
      return true;
    } catch (_) {
      return false;
    }
  }

  static fixBase64Padding(String input) {
    // Strip any non-base64 characters (like backticks or extra quotes)
    input = input.replaceAll(RegExp(r'[^A-Za-z0-9+/=]'), '');

    // Add padding if needed
    switch (input.length % 4) {
      case 1:
        // Invalid - remove the last character
        input = input.substring(0, input.length - 1);
        break;
      case 2:
        // Add two padding characters
        input += '==';
        break;
      case 3:
        // Add one padding character
        input += '=';
        break;
    }

    return input;
  }

  static String sanitizeUri(String uri) {
    // Keep only valid URI characters
    // This includes alphanumeric, and special chars used in URIs
    return uri.replaceAll(
      RegExp(r"[^\w\-\.\~\:\/\?\#\[\]\@\!\$\&\'\(\)\*\+\,\;\=\%]"),
      '',
    );
  }

  static bool isValidCipher(String cipher) {
    const List<String> validCiphers = [
      // AEAD ciphers (recommended)
      'aes-128-gcm',
      'aes-192-gcm',
      'aes-256-gcm',

      // 2022 AEAD ciphers
      '2022-blake3-aes-128-gcm',
      '2022-blake3-aes-256-gcm',
      '2022-blake3-chacha20-poly1305',

      // AES stream ciphers
      'aes-128-cfb',
      'aes-192-cfb',
      'aes-256-cfb',
      'aes-128-ctr',
      'aes-192-ctr',
      'aes-256-ctr',

      // Camellia ciphers
      'camellia-128-cfb',
      'camellia-192-cfb',
      'camellia-256-cfb',

      // ChaCha family - removed chacha20-poly1305 as Clash doesn't support it
      'chacha20',
      'chacha20-ietf',
      'chacha20-ietf-poly1305',
      'xchacha20-ietf-poly1305',

      // Legacy or less common ciphers
      'rc4-md5',
      'bf-cfb',
      'salsa20',

      // Special values
      'auto',
      'none',
    ];
    // Then, add this validation before returning serverInfo:
    return (validCiphers.contains(cipher));
  }

  static int? getKeyLengthForCipher(String cipher) {
    switch (cipher) {
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
      case 'rc4-md5':
      case 'bf-cfb':
      case 'salsa20':
      case 'auto':
      case 'none':
        return null; // Variable or no key
      default:
        return null;
    }
  }

  static bool isValidPublicKey(String? key) {
    if (key == null) {
      return false;
    }
    try {
      // 1. Check if the key has reasonable length
      if (key.isEmpty || key.length < 43 || key.length > 44) {
        return false;
      }

      // 2. Try to decode the Base64 string
      // Add padding if needed (Base64 strings should have length multiple of 4)
      String paddedKey = key;
      while (paddedKey.length % 4 != 0) {
        paddedKey += '=';
      }

      // Use Base64Url decoder for keys that might use URL-safe encoding
      final bytes = base64Url.decode(paddedKey);

      // 3. Verify the decoded bytes have length of 32 (X25519 public key)
      return bytes.length == 32;
    } catch (e) {
      // If any exception occurs during decoding, the key is invalid
      return false;
    }
  }
}

/// vmess URLs use "@" to separate user information from server details and ":" to separate host from port
/// vless follows a format like: vless://userID@host:port
/// trojan follows: trojan://password@host:port
/// ss (ShadowSocks) URLs look like: ss://encoded-info@host:port
ProxyUrl? parseProxyUrl(String url) {
  try {
    url = ProxyUrl.sanitizeUri(url);
    final protocolSeparator = url.indexOf('://');
    if (protocolSeparator == -1) throw ArgumentError('Invalid URL');

    // Check if the URL is base64 encoded
    final protocol = url.substring(0, protocolSeparator).trim().toLowerCase();
    String urlContent = url.substring(
      protocolSeparator + 3,
    ); // skip protocol://
    if (ProxyUrl.checkBase64(urlContent)) {
      urlContent = ProxyUrl.fixBase64Padding(urlContent);
      final decoded = base64.decode(urlContent);
      final decodedUrl = utf8.decode(decoded);
      final jsonUrl = jsonDecode(decodedUrl);

      // Extract parameters that aren't already captured in other fields
      Map<String, String> params = {};
      jsonUrl.forEach((key, value) {
        // Convert all values to strings
        params[key] = value.toString();
      });
      int port =
          jsonUrl['port'] is int
              ? jsonUrl['port']
              : int.tryParse(jsonUrl['port']?.toString() ?? '') ?? 0;
      return ProxyUrl(
        protocol: protocol,
        id: jsonUrl['id'],
        address: jsonUrl['add'],
        port: port,
        params: params,
        url: url,
        base64: true,
      );
    }

    // Extract remark/tag if exists
    String urlWithoutRemark = url;
    String? remark;

    final remarkIndex = url.indexOf('#');
    if (remarkIndex != -1) {
      remark = url.substring(remarkIndex + 1);
      urlWithoutRemark = url.substring(0, remarkIndex);
    }

    if (protocol == 'ss') {
      // decode
      // for legacy ss format (ss://base64[method:pass@host:port]#remarks)
      urlWithoutRemark = urlWithoutRemark.replaceFirst("$protocol://", '');
      if (ProxyUrl.checkBase64(urlWithoutRemark)) {
        final content = ProxyUrl.fixBase64Padding(urlWithoutRemark);
        final decoded = base64.decode(content);
        final decodedUrl = utf8.decode(decoded);
        urlWithoutRemark = "$protocol://$decodedUrl}";
      } else {
        // SIP002 (modern): ss://[base64(method:password)]@[server]:[port]#[remark]
        final alphaIndex = urlWithoutRemark.indexOf('@');
        final coded = urlWithoutRemark.substring(0, alphaIndex);
        final others = urlWithoutRemark.substring(alphaIndex);
        if (ProxyUrl.isUuid(coded)) {
          // not a true ss url, it's more likely a vless disgused as ss
          urlWithoutRemark = "$protocol://$urlWithoutRemark";
        } else if (ProxyUrl.checkBase64(coded)) {
          final content = ProxyUrl.fixBase64Padding(coded);
          final decoded = base64.decode(content);
          final decodedUrl = utf8.decode(decoded);
          urlWithoutRemark = "$protocol://$decodedUrl$others";
        }
      }
    }

    // Extract connection details and parameters
    final urlParts = urlWithoutRemark.substring(protocolSeparator + 3);
    final paramsIndex = urlParts.indexOf('?');

    final connectionPart =
        paramsIndex != -1 ? urlParts.substring(0, paramsIndex) : urlParts;

    final atIndex = connectionPart.indexOf('@');
    if (atIndex == -1) throw ArgumentError('Invalid URL: No @ in URL: [$url]');

    final id = connectionPart.substring(0, atIndex);
    final serverPart = connectionPart.substring(atIndex + 1);

    final colonIndex = serverPart.lastIndexOf(':');
    if (colonIndex == -1)
      throw ArgumentError('Invalid URL: No : in URL: [$url]');

    final address = serverPart.substring(0, colonIndex);
    String portPart = serverPart.substring(colonIndex + 1);
    portPart = portPart.replaceAll(RegExp(r'[^0-9]'), '');
    final port = int.tryParse(portPart);
    if (port == null)
      throw ArgumentError('Invalid URL: No port in URL: [$url]');

    // Extract parameters
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
    // Check if ID is base64 (ss protocol)
    if (ProxyUrl.checkBase64(id)) {
      String idContent = ProxyUrl.fixBase64Padding(id);
      final decoded = base64.decode(idContent);
      final decodedId = utf8.decode(decoded);
      final colonIndex = decodedId.lastIndexOf(':');
      if (colonIndex != -1) {
        params['method'] = decodedId.substring(0, colonIndex);
        params['password'] = decodedId.substring(colonIndex + 1);
      }
    }

    return ProxyUrl(
      protocol: protocol,
      id: id,
      address: address,
      port: port,
      params: params,
      remark: remark,
      url: url,
      base64: false,
    );
  } catch (e) {
    rethrow;
  }
}
