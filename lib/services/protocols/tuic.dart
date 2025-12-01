import 'protocol.dart';
import 'proxy_url.dart';
import 'protocol_parser.dart';
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

      final disableSni = ProtocolUtils.getFirstNonEmptyValue(params, [
        'disable-sni',
      ]);
      if (disableSni != null) {
        serverInfo['disable-sni'] = ProtocolUtils.parseBooleanValue(disableSni);
      }

      final reduceRtt = ProtocolUtils.getFirstNonEmptyValue(params, [
        'reduce-rtt',
      ]);
      if (reduceRtt != null) {
        serverInfo['reduce-rtt'] = ProtocolUtils.parseBooleanValue(reduceRtt);
      }

      final fastOpen = ProtocolUtils.getFirstNonEmptyValue(params, [
        'fast-open',
      ]);
      if (fastOpen != null) {
        serverInfo['fast-open'] = ProtocolUtils.parseBooleanValue(fastOpen);
      }

      final udpRelayMode = ProtocolUtils.getFirstNonEmptyValue(params, [
        'udp-relay-mode',
      ]);
      if (udpRelayMode != null) {
        serverInfo['udp-relay-mode'] = udpRelayMode;
      }

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

// ============================================================================
// TUIC Parser - handles UUID:password format
// ============================================================================
class TuicParser extends CommonProtocolParser {
  @override
  ({String id, Map<String, String> params}) processIdAndParams(
    String id,
    Map<String, String> params,
    String protocol,
  ) {
    final colonIndex = id.indexOf(':');

    if (colonIndex != -1) {
      final uuid = id.substring(0, colonIndex);
      final password = id.substring(colonIndex + 1);

      if (!UUIDUtils.isValid(uuid)) {
        throw ArgumentError('TUIC requires valid UUID, got: $uuid');
      }

      params['uuid'] = uuid;
      params['password'] = password;
    } else if (UUIDUtils.isValid(id)) {
      params['uuid'] = id;
    } else {
      throw ArgumentError('TUIC requires valid UUID format');
    }

    return (id: id, params: params);
  }
}
