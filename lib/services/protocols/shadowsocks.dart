import 'dart:convert';
import 'protocol.dart';
import 'proxy_url.dart';

class ShadowsocksProtocol implements Protocol {
  @override
  String get name => 'ss';

  @override
  bool canHandle(String url, ProxyUrl? parsed) {
    if (parsed != null) {
      return parsed.protocol == 'ss';
    }
    return url.toLowerCase().startsWith('ss://');
  }

  @override
  Map<String, dynamic> parse(String url, {ProxyUrl? parsed}) {
    try {
      if (!url.startsWith('ss://')) {
        // If parsed is available and protocol is ss, maybe we can reconstruct or use parsed data?
        // But SS parsing logic is quite specific about base64 parts.
        // Let's rely on the raw URL for SS as it has unique encoding rules.
        if (parsed != null &&
            parsed.protocol == 'ss' &&
            parsed.rawUrl != null) {
          url = parsed.rawUrl!;
        } else {
          throw FormatException('Not a Shadowsocks URL');
        }
      }

      String ssUrl = url;
      String remark = '';

      if (ssUrl.contains('#')) {
        final parts = ssUrl.split('#');
        ssUrl = parts[0];
        try {
          remark = Uri.decodeComponent(parts[1]);
        } catch (e) {
          remark = parts[1];
        }
      }

      Uri uri;
      String method = '';
      String password = '';

      // --- 1. Parse UserInfo (3 formats) ---
      if (!ssUrl.contains('@')) {
        // Format: ss://BASE64(...)
        final base64Part = ssUrl.substring(5);
        try {
          final decoded = utf8.decode(
            base64.decode(ProxyUrl.fixBase64Padding(base64Part)),
          );
          // If decoded string contains another ss://, it's recursive? No.
          // It should be method:password@server:port
          uri = Uri.parse('ss://$decoded');
          final userInfoParts = uri.userInfo.split(':');
          if (userInfoParts.length >= 2) {
            method = userInfoParts[0];
            password = userInfoParts.sublist(1).join(':');
          }
        } catch (e) {
          return {'type': 'ss', 'error': 'Invalid Base64 in SS URL'};
        }
      } else {
        uri = Uri.parse(ssUrl);
        final userInfoParts = uri.userInfo.split(':');
        if (userInfoParts.length >= 2) {
          // Format: ss://method:pass@server:port
          method = userInfoParts[0];
          password = userInfoParts.sublist(1).join(':');
        } else {
          // Format: ss://BASE64(method:pass)@server:port
          final userInfo = uri.userInfo;
          if (ProxyUrl.checkBase64(userInfo)) {
            try {
              final decoded = utf8.decode(
                base64.decode(ProxyUrl.fixBase64Padding(userInfo)),
              );
              final parts = decoded.split(':');
              if (parts.length >= 2) {
                method = parts[0];
                password = parts.sublist(1).join(':');
              }
            } catch (e) {
              // Ignore decode errors, treat as raw
            }
          }
        }
      }

      method = method.toLowerCase();

      if (!ProxyUrl.isValidCipher(method)) {
        return {
          'type': 'ss',
          'error': 'Unsupported or Legacy cipher detected: $method',
        };
      }

      int? expectedKeyLength = ProxyUrl.getKeyLengthForCipher(method);

      if (method.startsWith('2022-blake3') && expectedKeyLength != null) {
        List<String> keysToCheck =
            password.contains(':') ? password.split(':') : [password];

        for (String keyStr in keysToCheck) {
          try {
            List<int> keyBytes = base64.decode(keyStr);
            if (keyBytes.length != expectedKeyLength) {
              return {
                'type': 'ss',
                'error':
                    'Key length mismatch for $method. Expected $expectedKeyLength bytes, but got ${keyBytes.length}.',
              };
            }
          } catch (e) {
            return {
              'type': 'ss',
              'error': 'Invalid Base64 key in SS-2022 config.',
            };
          }
        }
      }

      String plugin = '';
      Map<String, dynamic> pluginOpts = {};

      if (uri.queryParameters.containsKey('plugin')) {
        String pluginInfo = Uri.decodeComponent(uri.queryParameters['plugin']!);

        if (pluginInfo.contains(';')) {
          final pluginParts = pluginInfo.split(';');
          plugin = pluginParts[0];

          for (var opt in pluginParts.sublist(1)) {
            opt = opt.trim();
            if (opt.isEmpty) continue;

            if (opt.contains('=') || opt.contains(':')) {
              final separator = opt.contains('=') ? '=' : ':';
              final keyValue = opt.split(separator);
              if (keyValue.length >= 2) {
                String key = keyValue[0].trim().toLowerCase();
                String val = keyValue.sublist(1).join(separator).trim();

                // Handle v2ray-plugin specific mappings
                if (plugin == 'v2ray-plugin') {
                  if (key == 'obfs') key = 'mode';
                  if (key == 'obfs-host') key = 'host';
                }

                if (key == 'tls' || key == 'skip-cert-verify') {
                  pluginOpts[key] = val == 'true' || val == '1';
                } else if (key == 'mux') {
                  pluginOpts[key] =
                      (val != '0' && val != 'false' && val.isNotEmpty);
                } else if (key == 'port') {
                  pluginOpts[key] = int.tryParse(val) ?? val;
                } else {
                  pluginOpts[key] = val;
                }
              }
            } else {
              // Heuristic for malformed v2ray-plugin options where separator is missing
              if (plugin == 'v2ray-plugin' && opt.startsWith('obfs-host')) {
                String val = opt.substring('obfs-host'.length).trim();
                if (val.isNotEmpty) {
                  pluginOpts['host'] = val;
                  continue;
                }
              }
              pluginOpts[opt] = true;
            }
          }
        } else {
          plugin = pluginInfo;
        }
      }

      Map<String, dynamic> serverInfo = {
        'type': 'ss',
        'name': remark.isNotEmpty ? remark : uri.host,
        'server': uri.host,
        'port': uri.port,
        'password': password,
        'cipher': method,
        'udp': true,
        'tls': false,
      };

      if (plugin.isNotEmpty) {
        serverInfo['plugin'] = plugin;
        serverInfo['plugin-opts'] = pluginOpts;
      }

      return serverInfo;
    } catch (e) {
      return {'type': 'ss', 'error': 'Parse error: $e'};
    }
  }
}
