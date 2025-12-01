import 'protocol.dart';
import 'proxy_url.dart';
import 'protocol_parser.dart';
import 'utils.dart';

class AnyTlsProtocol implements Protocol {
  @override
  String get name => 'anytls';

  @override
  bool canHandle(String url, ProxyUrl? parsed) {
    if (parsed != null) {
      return parsed.protocol == 'anytls';
    }
    return url.toLowerCase().startsWith('anytls://');
  }

  @override
  Map<String, dynamic> parse(String url, {ProxyUrl? parsed}) {
    try {
      final proxy = parsed ?? ProxyUrl.parse(url);
      if (proxy == null) throw FormatException('Failed to parse URL');

      if (!UUIDUtils.isValid(proxy.id)) {
        throw ArgumentError('AnyTLS requires valid UUID, got: ${proxy.id}');
      }

      Map<String, dynamic> serverInfo = {
        'type':
            'anytls', // Clash Meta might treat this as a specific type or custom
        // Wait, "anytls" is likely a custom protocol name used by some providers,
        // but in Clash Meta it might map to something else or be a plugin.
        // However, the user provided example output shows `type: anytls`.
        // So we will stick to that.
        'name': proxy.remark ?? proxy.address,
        'server': proxy.address,
        'port': proxy.port,
        'uuid': proxy.id,
        'password': proxy.id,
      };

      final params = proxy.params;

      // Map parameters
      serverInfo['network'] = ProtocolUtils.getFirstNonEmptyValue(params, [
        'type',
        'network',
      ], defaultValue: 'tcp');

      serverInfo['tls'] = true; // anytls implies tls
      if (params.containsKey('security')) {
        // If security is explicitly set, we can check it, but usually it's tls
      }

      final sni = ProtocolUtils.getFirstNonEmptyValue(params, ['sni']);
      if (sni != null) {
        serverInfo['sni'] = sni;
      }

      final alpn = ProtocolUtils.getFirstNonEmptyValue(params, ['alpn']);
      if (alpn != null) {
        serverInfo['alpn'] = alpn.split(',').map((e) => e.trim()).toList();
      }

      final fp = ProtocolUtils.getFirstNonEmptyValue(params, [
        'fp',
        'fingerprint',
      ]);
      if (fp != null) {
        serverInfo['client-fingerprint'] = fp;
      }

      serverInfo['skip-cert-verify'] = ProtocolUtils.parseBooleanValue(
        ProtocolUtils.getFirstNonEmptyValue(params, [
          'allowInsecure',
          'insecure',
        ], defaultValue: 'false'),
      );

      // If skip-cert-verify is false, we can omit it.
      if (serverInfo['skip-cert-verify'] == false) {
        serverInfo.remove('skip-cert-verify');
      }

      serverInfo['udp'] = ProtocolUtils.parseBooleanValue(
        ProtocolUtils.getFirstNonEmptyValue(params, [
          'udp',
        ], defaultValue: 'true'),
      );

      return serverInfo;
    } catch (e) {
      return {'type': 'anytls', 'error': 'Error parsing AnyTLS URL: $e'};
    }
  }
}

// ============================================================================
// AnyTLS Parser
// ============================================================================
class AnyTlsParser extends CommonProtocolParser {
  // AnyTLS uses standard format, no special processing needed
}
