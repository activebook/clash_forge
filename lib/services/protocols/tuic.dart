import 'protocol.dart';
import 'proxy_url.dart';
import 'utils.dart';

class TuicProtocol implements Protocol {
  @override
  String get name => 'tuic';

  @override
  bool canHandle(String url, ProxyUrl? parsed) {
    if (parsed != null) {
      return parsed.protocol == 'tuic';
    }
    return url.toLowerCase().startsWith('tuic://');
  }

  @override
  Map<String, dynamic> parse(String url, {ProxyUrl? parsed}) {
    try {
      final proxy = parsed ?? ProxyUrl.parse(url);
      if (proxy == null) throw FormatException('Failed to parse URL');

      String uuid = proxy.id;
      String password = proxy.id;
      if (proxy.id.contains(':')) {
        final parts = proxy.id.split(':');
        uuid = parts[0];
        password = parts.sublist(1).join(':');
      }

      Map<String, dynamic> serverInfo = {
        'type': 'tuic',
        'name': proxy.remark ?? proxy.address,
        'server': proxy.address,
        'port': proxy.port,
        'uuid': uuid,
        'password': password,
      };

      final params = proxy.params;

      // Map parameters
      if (params.containsKey('congestion_control')) {
        serverInfo['congestion-controller'] = params['congestion_control'];
      }

      serverInfo['udp'] = ProtocolUtils.parseBooleanValue(
        ProtocolUtils.getFirstNonEmptyValue(params, [
          'udp',
        ], defaultValue: 'true'),
      );

      final sni = ProtocolUtils.getFirstNonEmptyValue(params, ['sni']);
      if (sni != null) {
        serverInfo['sni'] = sni;
      }

      final alpn = ProtocolUtils.getFirstNonEmptyValue(params, ['alpn']);
      if (alpn != null) {
        serverInfo['alpn'] = alpn.split(',').map((e) => e.trim()).toList();
      }

      serverInfo['skip-cert-verify'] = ProtocolUtils.parseBooleanValue(
        ProtocolUtils.getFirstNonEmptyValue(params, [
          'allow_insecure',
          'allowInsecure',
        ], defaultValue: 'false'),
      );

      // If skip-cert-verify is false, we can omit it or set it to false.
      // The example shows it present when true.
      if (serverInfo['skip-cert-verify'] == false) {
        serverInfo.remove('skip-cert-verify');
      }

      return serverInfo;
    } catch (e) {
      return {'type': 'tuic', 'error': 'Error parsing TUIC URL: $e'};
    }
  }
}
