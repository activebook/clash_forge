import 'dart:convert';
import 'protocol.dart';
import 'proxy_url.dart';
import 'protocol_parser.dart';
import 'protocol_validator.dart';
import 'utils.dart';

class VmessProtocol implements Protocol {
  @override
  String get name => 'vmess';

  @override
  bool canHandle(String url, ProxyUrl? parsed) {
    if (parsed != null) {
      return parsed.protocol == 'vmess';
    }
    return url.toLowerCase().startsWith('vmess://');
  }

  @override
  Map<String, dynamic> parse(String url, {ProxyUrl? parsed}) {
    if (!url.toLowerCase().startsWith('vmess://')) {
      // If it doesn't start with vmess://, but canHandle said yes, it might be a disguised URL.
      // But typically we expect the prefix.
      // However, if we rely on ProxyUrl to have parsed it, we might use that.
    }

    // VMess format: vmess://BASE64(JSON)
    try {
      // Remove the "vmess://" prefix
      // If parsed is provided and it is base64, we can use it directly?
      // Actually, the ProxyUrl parsing logic for base64 JSON already extracts params.

      Map<String, dynamic> params;

      if (parsed != null && parsed.isBase64 && parsed.protocol == 'vmess') {
        // Reconstruct params from parsed data if it was parsed as JSON
        // But ProxyUrl stores params as Map<String, String>.
        // We might need the original JSON if we want types, but strings are usually fine.
        // However, ProxyUrl.parse logic for base64 JSON puts everything in params.
        params = Map<String, dynamic>.from(parsed.params);
        // Add other fields that might be outside params in ProxyUrl
        params['id'] = parsed.id;
        params['add'] = parsed.address;
        params['port'] = parsed.port;
      } else {
        String content = url;
        final protocolSeparator = url.indexOf('://');
        if (protocolSeparator != -1) {
          content = url.substring(protocolSeparator + 3);
        }

        content = Base64Utils.fixPadding(content);
        String decodedContent = utf8.decode(base64.decode(content));
        params = jsonDecode(decodedContent);
      }

      String cipher =
          ProtocolUtils.getFirstNonEmptyValue(params, [
            'security',
            'scy',
          ], defaultValue: 'auto')!;

      if (!ProtocolValidator.isValidCipher(cipher)) {
        return {
          'type': 'vmess',
          'error': 'Invalid VMess cipher method: $cipher',
        };
      }

      if (!UUIDUtils.isValid(params['id'])) {
        throw ArgumentError('Vmess requires valid UUID, got: ${params['id']}');
      }

      Map<String, dynamic> serverInfo = {
        'type': 'vmess',
        'name': params['ps'] ?? params['name'],
        'server': params['add'],
        'port': int.tryParse(params['port']?.toString() ?? '0') ?? 0,
        'uuid': params['id'],
        'alterId': int.tryParse(params['aid']?.toString() ?? '0') ?? 0,
        'cipher': cipher,
      };

      final security = params['security'];
      if (security == 'reality') {
        final publicKey = ProtocolUtils.getFirstNonEmptyValue(params, [
          'pbk',
          'public-key',
        ], defaultValue: '');
        final shortId = ProtocolUtils.getFirstNonEmptyValue(params, [
          'sid',
          'short-id',
        ], defaultValue: '');

        if (!ProtocolValidator.isValidPublicKey(publicKey)) {
          return {
            'type': 'vmess',
            'error': 'Vmess security Invalid public key: $publicKey',
          };
        }
        serverInfo['reality-opts'] = {
          'public-key': publicKey,
          'short-id': shortId,
        };
      }

      final serverName = ProtocolUtils.getFirstNonEmptyValue(params, [
        'sni',
        'servername',
        'server-name',
        'spx',
      ]);
      if (serverName != null) {
        serverInfo['servername'] = serverName;
        serverInfo['sni'] = serverName;
      }

      final fingerPrint = ProtocolUtils.getFirstNonEmptyValue(params, [
        'fp',
        'fingerprint',
        'client-fingerprint',
      ]);
      if (fingerPrint != null) {
        serverInfo['client-fingerprint'] = fingerPrint;
      }

      serverInfo['skip-cert-verify'] = ProtocolUtils.parseBooleanValue(
        ProtocolUtils.getFirstNonEmptyValue(params, [
          'skip-cert-verify',
          'allowInsecure',
        ], defaultValue: 'true'),
      );

      bool tlsEnabled = false;
      if (params.containsKey('security') && params['security'] != null) {
        String sec = params['security'].toString().toLowerCase();
        tlsEnabled = (sec == 'tls' || sec == 'reality');
      } else if (params.containsKey('tls')) {
        tlsEnabled = ProtocolUtils.parseBooleanValue(params['tls']);
      } else if (serverInfo['port'] == 443) {
        tlsEnabled = true;
      }
      serverInfo['tls'] = tlsEnabled;

      final network = ProtocolUtils.getFirstNonEmptyValue(params, [
        'network',
        'net',
      ], defaultValue: 'tcp');

      if (network == 'ws' || network == 'h2') {
        final path = ProtocolUtils.getFirstNonEmptyValue(params, [
          'path',
          'pathname',
          'path-name',
        ], defaultValue: '');
        final host = ProtocolUtils.getFirstNonEmptyValue(params, [
          'host',
          'hostname',
        ], defaultValue: '');

        if (network == 'ws') {
          serverInfo['ws-opts'] = {
            'path': path,
            'headers': {'host': host},
          };
        } else {
          if (path != null && path.isNotEmpty) {
            serverInfo['h2-opts'] = {'path': path, 'host': host};
          }
        }
      } else if (network == 'http') {
        final httpPath = ProtocolUtils.getFirstNonEmptyValue(params, [
          'path',
          'pathname',
          'path-name',
        ], defaultValue: '/');
        final httpHost = ProtocolUtils.getFirstNonEmptyValue(params, [
          'host',
          'hostname',
        ], defaultValue: '');
        final httpMethod = ProtocolUtils.getFirstNonEmptyValue(params, [
          'method',
        ], defaultValue: 'GET');
        serverInfo['http-opts'] = {
          'method': httpMethod,
          'path': [httpPath],
          'headers': {
            'Host': [httpHost],
          },
        };
      } else if (network == 'grpc') {
        final serviceName = ProtocolUtils.getFirstNonEmptyValue(params, [
          'serviceName',
          'service-name',
          'grpc-service-name',
        ], defaultValue: '');
        serverInfo['grpc-opts'] = {'grpc-service-name': serviceName};
      } else if (network == 'tcp') {
        final headerType = ProtocolUtils.getFirstNonEmptyValue(params, [
          'type',
          'headerType',
        ], defaultValue: 'none');
        serverInfo['tcp-opts'] = {'type': headerType};
      }

      serverInfo['network'] = network ?? 'tcp';
      serverInfo['udp'] = ProtocolUtils.parseBooleanValue(params['udp']);
      serverInfo['ip-version'] = params['ip-version'] ?? '';
      serverInfo['flow'] = params['flow'] ?? '';

      if (params.containsKey('alpn')) {
        final alpnString = params['alpn']?.toString() ?? '';
        if (alpnString.isNotEmpty) {
          final alpnList = alpnString.split(',').map((s) => s.trim()).toList();
          serverInfo['alpn'] = alpnList;
        }
      }

      final packetEncoding = ProtocolUtils.getFirstNonEmptyValue(params, [
        'packetEncoding',
        'packet-encoding',
      ]);
      if (packetEncoding != null) {
        serverInfo['packet-encoding'] = packetEncoding;
      }

      final globalPadding = ProtocolUtils.getFirstNonEmptyValue(params, [
        'global-padding',
      ]);
      if (globalPadding != null) {
        serverInfo['global-padding'] = ProtocolUtils.parseBooleanValue(
          globalPadding,
        );
      }

      final authenticatedLength = ProtocolUtils.getFirstNonEmptyValue(params, [
        'authenticated-length',
      ]);
      if (authenticatedLength != null) {
        serverInfo['authenticated-length'] = ProtocolUtils.parseBooleanValue(
          authenticatedLength,
        );
      }

      final tfo = ProtocolUtils.getFirstNonEmptyValue(params, [
        'tfo',
        'fast-open',
      ]);
      if (tfo != null) {
        serverInfo['tfo'] = ProtocolUtils.parseBooleanValue(tfo);
      }

      final mptcp = ProtocolUtils.getFirstNonEmptyValue(params, ['mptcp']);
      if (mptcp != null) {
        serverInfo['mptcp'] = ProtocolUtils.parseBooleanValue(mptcp);
      }

      return serverInfo;
    } catch (e) {
      return {'type': 'vmess', 'error': 'Error parsing VMess URL: $e'};
    }
  }
}

// ============================================================================
// VMess Parser - handles base64 encoded JSON
// ============================================================================
class VmessParser implements ProtocolParser {
  @override
  ProxyUrl parse(String url, String protocol) {
    final protocolSeparator = url.indexOf('://');
    String urlContent = url.substring(protocolSeparator + 3);

    if (!Base64Utils.isValid(urlContent)) {
      throw ArgumentError('VMess URL must be base64 encoded JSON');
    }

    urlContent = Base64Utils.fixPadding(urlContent);
    final decoded = base64.decode(urlContent);
    final decodedUrl = utf8.decode(decoded);

    final jsonUrl = jsonDecode(decodedUrl);
    if (jsonUrl is! Map<String, dynamic>) {
      throw FormatException('VMess JSON must be an object');
    }

    // Validate required fields
    if (!jsonUrl.containsKey('add') || !jsonUrl.containsKey('port')) {
      throw FormatException('VMess JSON missing required fields (add, port)');
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
      id: jsonUrl['id']?.toString() ?? jsonUrl['uuid']?.toString() ?? '',
      address: jsonUrl['add']?.toString() ?? '',
      port: port,
      params: params,
      remark: jsonUrl['ps']?.toString(),
      rawUrl: url,
      base64: true,
    );
  }
}
