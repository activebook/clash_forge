import 'protocol.dart';
import 'proxy_url.dart';
import 'protocol_parser.dart';
import 'protocol_validator.dart';
import 'utils.dart';

class VlessProtocol implements Protocol {
  @override
  String get name => 'vless';

  @override
  bool canHandle(String url, ProxyUrl? parsed) {
    if (parsed != null) {
      return parsed.protocol == 'vless';
    }
    return url.toLowerCase().startsWith('vless://');
  }

  @override
  Map<String, dynamic> parse(String url, {ProxyUrl? parsed}) {
    try {
      // Use the parsed object if available, otherwise parse it
      final proxy = parsed ?? ProxyUrl.parse(url);
      if (proxy == null) throw FormatException('Failed to parse URL');

      // UUID validation
      // Popular implementations like Xray (a core often used for VLESS) allow you to use a custom string (e.g., a simple password or username) for the id field in the configuration file.
      if (!UUIDUtils.isValid(proxy.id)) {
        // throw ArgumentError('Vless requires valid UUID, got: ${proxy.id}');
      }

      // Initialize serverInfo with default values
      Map<String, dynamic> serverInfo = {
        'type': 'vless',
        'name': proxy.remark ?? proxy.address,
        'server': proxy.address,
        'port': proxy.port,
        'uuid': proxy.id,
      };

      final params = proxy.params;

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
            'type': 'vless',
            'error': 'Vless security Invalid public key: $publicKey',
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
      if (params.containsKey('security')) {
        String sec = params['security']?.toLowerCase() ?? '';
        tlsEnabled = (sec == 'tls' || sec == 'reality');
      } else if (params.containsKey('tls')) {
        tlsEnabled = ProtocolUtils.parseBooleanValue(params['tls']);
      } else if (proxy.port == 443) {
        tlsEnabled = true;
      }
      serverInfo['tls'] = tlsEnabled;

      final network = ProtocolUtils.getFirstNonEmptyValue(params, [
        'network',
        'type',
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
      }

      serverInfo['network'] = network ?? 'tcp';
      serverInfo['udp'] = ProtocolUtils.parseBooleanValue(params['udp']);
      serverInfo['ip-version'] = params['ip-version'] ?? '';

      if (params['flow'] != null && params['flow']!.isNotEmpty) {
        final flow = params['flow']!;
        if (flow.startsWith("xtls-rprx-")) {
          serverInfo['flow'] = flow;
        }
      }

      if (params.containsKey('alpn')) {
        final alpnString = params['alpn'] ?? '';
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
      return {'type': 'vless', 'error': 'Error parsing VLESS URL: $e'};
    }
  }
}

// ============================================================================
// VLESS Parser
// ============================================================================
class VlessParser extends CommonProtocolParser {
  // VLESS uses standard format, no special processing needed
}
