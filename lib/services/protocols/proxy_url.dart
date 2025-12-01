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
    // Trim whitespace (common user error)
    uri = uri.trim();

    // Remove zero-width spaces and other invisible Unicode characters
    uri = uri.replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '');

    // Remove HTML tags and entities (e.g., <br/>, &nbsp;, etc.)
    uri = uri.replaceAll(RegExp(r'<[^>]*>'), '');
    uri = uri.replaceAll(RegExp(r'&[a-zA-Z]+;'), '');
    uri = uri.replaceAll(RegExp(r'&#\d+;'), '');

    // Find the protocol position and extract from there
    final protocolMatch = RegExp(
      r'(vless|vmess|trojan|ss|ssr|hy2|hysteria2?|tuic|anytls)://',
      caseSensitive: false,
    ).firstMatch(uri);

    if (protocolMatch != null) {
      // Extract everything from the protocol onwards
      uri = uri.substring(protocolMatch.start);
    }

    // Don't be too aggressive - let Uri.parse or protocol handlers validate
    return uri;
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

  /// ProxyUrl.parse handles:
  /// Protocol	Format	Works?
  /// VLESS	vless://UUID@host:port?params	✓ Standard URL
  /// VMess	vmess://BASE64(JSON)	✓ Special handling
  /// Trojan	trojan://password@host:port?params	✓ Standard URL
  /// Shadowsocks	ss://BASE64(method:password)@host:port	✓ Special handling
  /// ShadowsocksR	ssr://BASE64(server:port:proto:method:obfs:pass/?)	✓ Special handling (URL-safe Base64)
  /// Hysteria2	hysteria2://password@host:port?params	✓ Standard URL
  /// TUIC	tuic://uuid:password@host:port?params	✓ Standard URL
  /// AnyTLS	anytls://uuid@host:port?params	✓ Standard URL
  /// ProxyUrl.parse CANNOT handle:
  /// Protocol	Format	Why?
  /// WireGuard	INI file ([Interface], [Peer])	Not a URL at all
  /// Remember: this function only handles the URL part of the proxy.
  /// It doesn't verify the URL or the proxy.
  /// Don't trust this function; you must verify the URL and the proxy for each protocol itself.
  /// Protocol.parse is the function that handles the URL part of the proxy.
  static ProxyUrl? parse(String url) {
    try {
      url = sanitizeUri(url);
      final protocolSeparator = url.indexOf('://');
      if (protocolSeparator == -1) throw ArgumentError('Invalid URL');

      final protocol = url.substring(0, protocolSeparator).trim().toLowerCase();
      String urlContent = url.substring(protocolSeparator + 3);

      // Special handling for SSR (uses URL-safe Base64)
      if (protocol == 'ssr') {
        String ssrContent = urlContent
            .replaceAll('-', '+')
            .replaceAll('_', '/');
        // Fix padding
        while (ssrContent.length % 4 != 0) {
          ssrContent += '=';
        }

        try {
          final decoded = utf8.decode(base64.decode(ssrContent));

          // SSR format: server:port:protocol:method:obfs:password_base64/?params
          int queryIndex = decoded.indexOf('/?');
          String mainPart;
          Map<String, String> params = {};

          if (queryIndex != -1) {
            mainPart = decoded.substring(0, queryIndex);
            String queryPart = decoded.substring(queryIndex + 2);

            // Parse query parameters
            List<String> queryParams = queryPart.split('&');
            for (var param in queryParams) {
              int eqIndex = param.indexOf('=');
              if (eqIndex != -1) {
                String key = param.substring(0, eqIndex);
                String value = param.substring(eqIndex + 1);
                params[key] = value;
              }
            }
          } else {
            mainPart = decoded;
          }

          // Parse main parts: server:port:protocol:method:obfs:password_base64
          List<String> parts = mainPart.split(':');
          if (parts.length >= 6) {
            String server = parts[0];
            int port = int.tryParse(parts[1]) ?? 0;
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
              id: passwordBase64, // Use password as ID
              address: server,
              port: port,
              params: params,
              remark: params['remarks'], // Will be decoded later if needed
              rawUrl: url,
              base64: true,
            );
          }
        } catch (_) {
          // SSR parsing failed, will fall through to error
        }
      }

      if (checkBase64(urlContent)) {
        urlContent = fixBase64Padding(urlContent);
        final decoded = base64.decode(urlContent);
        final decodedUrl = utf8.decode(decoded);

        // Try to parse as JSON (VMess style)
        try {
          final jsonUrl = jsonDecode(decodedUrl);
          if (jsonUrl is Map<String, dynamic>) {
            // Validate required fields for VMess
            if (!jsonUrl.containsKey('add') || !jsonUrl.containsKey('port')) {
              throw FormatException(
                'VMess JSON missing required fields (add, port)',
              );
            }

            Map<String, String> params = {};
            jsonUrl.forEach((key, value) {
              params[key] = value.toString();
            });

            // Parse and validate port
            int port = int.tryParse(jsonUrl['port']?.toString() ?? '') ?? 0;
            if (port < 1 || port > 65535) {
              throw FormatException('VMess JSON invalid port: $port');
            }

            return ProxyUrl(
              protocol: protocol,
              id:
                  jsonUrl['id']?.toString() ??
                  jsonUrl['uuid']?.toString() ??
                  '',
              address: jsonUrl['add']?.toString() ?? '',
              port: port,
              params: params,
              remark: jsonUrl['ps']?.toString(), // VMess uses 'ps' for remarks
              rawUrl: url,
              base64: true,
            );
          }
        } catch (e) {
          // Not JSON - check if it's SSR format
          if (protocol == 'ssr') {
            // SSR format: server:port:protocol:method:obfs:password_base64/?params
            int queryIndex = decodedUrl.indexOf('/?');
            String mainPart;
            Map<String, String> params = {};

            if (queryIndex != -1) {
              mainPart = decodedUrl.substring(0, queryIndex);
              String queryPart = decodedUrl.substring(queryIndex + 2);

              // Parse query parameters
              List<String> queryParams = queryPart.split('&');
              for (var param in queryParams) {
                int eqIndex = param.indexOf('=');
                if (eqIndex != -1) {
                  String key = param.substring(0, eqIndex);
                  String value = param.substring(eqIndex + 1);
                  params[key] = value;
                }
              }
            } else {
              mainPart = decodedUrl;
            }

            // Parse main parts: server:port:protocol:method:obfs:password_base64
            List<String> parts = mainPart.split(':');
            if (parts.length >= 6) {
              String server = parts[0];
              int port = int.tryParse(parts[1]) ?? 0;
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
                id: passwordBase64, // Use password as ID
                address: server,
                port: port,
                params: params,
                remark: params['remarks'], // Will be decoded later if needed
                rawUrl: url,
                base64: true,
              );
            }
          }
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

      String id = connectionPart.substring(0, atIndex);

      // Decode URL-encoded characters in userinfo (e.g., Trojan passwords)
      try {
        id = Uri.decodeComponent(id);
      } catch (_) {
        // If decoding fails, use as-is (backward compatibility)
      }

      final serverPart = connectionPart.substring(atIndex + 1);

      // Parse server address and port, supporting IPv6 bracket notation
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
        address = serverPart.substring(1, closeBracket); // Remove brackets

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
          throw ArgumentError('Invalid URL: No : in URL: [$url]');
        }
        address = serverPart.substring(0, colonIndex);
        portString = serverPart.substring(colonIndex + 1);
      }

      // Validate port number and range
      // Strip any trailing non-numeric characters (e.g., "/" from "37416/?...")
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

      Map<String, String> params = {};
      if (paramsIndex != -1) {
        final paramsString = urlParts.substring(paramsIndex + 1);
        final paramPairs = paramsString.split('&');
        for (final pair in paramPairs) {
          final keyValue = pair.split('=');
          if (keyValue.length == 2) {
            try {
              params[keyValue[0]] = Uri.decodeComponent(keyValue[1]);
            } catch (e) {
              params[keyValue[0]] = keyValue[1];
            }
          }
        }
      }

      // SS specific: decode ID if it is base64 and contains method:password
      if (protocol == 'ss') {
        if (!checkBase64(id) && id.contains(':')) {
          // Percent-encoded format (SIP022 for AEAD-2022 ciphers)
          // ID has already been decoded by Uri.decodeComponent earlier
          final colonIndex = id.indexOf(':');
          if (colonIndex != -1) {
            params['method'] = id.substring(0, colonIndex);
            params['password'] = id.substring(colonIndex + 1);
          }
        } else if (checkBase64(id)) {
          // Base64 format (legacy SIP002 for Stream/AEAD ciphers)
          try {
            final decodedId = utf8.decode(base64.decode(fixBase64Padding(id)));
            final colonIndex = decodedId.lastIndexOf(':');
            if (colonIndex != -1) {
              params['method'] = decodedId.substring(0, colonIndex);
              params['password'] = decodedId.substring(colonIndex + 1);
            }
          } catch (_) {}
        }
      }

      // TUIC specific: split UUID:password format
      if (protocol == 'tuic') {
        final colonIndex = id.indexOf(':');
        if (colonIndex != -1) {
          final uuid = id.substring(0, colonIndex);
          final password = id.substring(colonIndex + 1);

          if (!isUuid(uuid)) {
            throw ArgumentError('TUIC requires valid UUID, got: $uuid');
          }

          params['uuid'] = uuid;
          params['password'] = password;
        } else if (isUuid(id)) {
          // UUID only, password might be in query params
          params['uuid'] = id;
        } else {
          throw ArgumentError('TUIC requires valid UUID format');
        }
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
