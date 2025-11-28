import 'protocol.dart';
import 'proxy_url.dart';
import 'utils.dart';

class TrojanProtocol implements Protocol {
  @override
  String get name => 'trojan';

  @override
  bool canHandle(String url, ProxyUrl? parsed) {
    if (parsed != null) {
      if (parsed.protocol == 'hysteria2' || parsed.protocol == 'hy2') {
        return false;
      }

      if (!parsed.isBase64 &&
          (parsed.params.containsKey('allowInsecure') &&
              [
                '0',
                '1',
                'true',
                'false',
              ].contains(parsed.params['allowInsecure']?.toLowerCase()))) {
        return true;
      }
      if (!parsed.isBase64 && parsed.params.containsKey('sni')) {
        return true;
      }
      bool feature =
          !parsed.isBase64 &&
          parsed.params.containsKey('security') &&
          parsed.params['security'] == 'tls' &&
          !parsed.params.containsKey('encryption');
      return feature || parsed.protocol == 'trojan';
    }
    return url.toLowerCase().startsWith('trojan://');
  }

  @override
  Map<String, dynamic> parse(String url, {ProxyUrl? parsed}) {
    try {
      final proxy = parsed ?? ProxyUrl.parse(url);
      if (proxy == null) throw FormatException('Failed to parse URL');

      // Validate password exists - Trojan protocol requires authentication
      if (proxy.id.isEmpty) {
        return {
          'type': 'trojan',
          'error': 'Trojan protocol requires a password',
        };
      }

      Map<String, dynamic> serverInfo = {
        'type': 'trojan',
        'name': proxy.remark ?? proxy.address,
        'server': proxy.address,
        'port': proxy.port,
        'password': proxy.id, // In Trojan, userinfo is password
        'tls': true,
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

        if (!ProxyUrl.isValidPublicKey(publicKey)) {
          return {
            'type': 'trojan',
            'error': 'Trojan security Invalid public key: $publicKey',
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
      serverInfo['flow'] = params['flow'] ?? '';

      if (params.containsKey('alpn')) {
        final alpnString = params['alpn'] ?? '';
        if (alpnString.isNotEmpty) {
          final alpnList = alpnString.split(',').map((s) => s.trim()).toList();
          serverInfo['alpn'] = alpnList;
        }
      }

      serverInfo['tfo'] = ProtocolUtils.parseBooleanValue(
        ProtocolUtils.getFirstNonEmptyValue(params, ['tfo', 'fast-open']),
      );

      serverInfo['mptcp'] = ProtocolUtils.parseBooleanValue(
        ProtocolUtils.getFirstNonEmptyValue(params, ['mptcp']),
      );

      return serverInfo;
    } catch (e) {
      return {'type': 'trojan', 'error': 'Error parsing Trojan URL: $e'};
    }
  }
}
