import 'protocol.dart';
import 'proxy_url.dart';
import 'protocol_parser.dart';
import 'utils.dart';

class Hysteria2Protocol implements Protocol {
  @override
  String get name => 'hysteria2';

  @override
  bool canHandle(String url, ProxyUrl? parsed) {
    if (parsed != null) {
      bool feature =
          (parsed.protocol == "hysteria2" || parsed.protocol == "hy2");
      return feature;
    }
    return url.toLowerCase().startsWith('hysteria2://') ||
        url.toLowerCase().startsWith('hy2://');
  }

  @override
  Map<String, dynamic> parse(String url, {ProxyUrl? parsed}) {
    try {
      final proxy = parsed ?? ProxyUrl.parse(url);
      if (proxy == null) throw FormatException('Failed to parse URL');

      Map<String, dynamic> serverInfo = {
        'type': 'hysteria2',
        'name': proxy.remark ?? proxy.address,
        'server': proxy.address,
        'port': proxy.port,
        'password': proxy.id,
      };

      final params = proxy.params;

      final serverName = ProtocolUtils.getFirstNonEmptyValue(params, [
        'sni',
        'servername',
        'peer',
      ]);
      if (serverName != null) {
        serverInfo['sni'] = serverName;
      }

      final insecure = ProtocolUtils.getFirstNonEmptyValue(params, [
        'insecure',
        'skip-cert-verify',
        'allowInsecure',
      ], defaultValue: '0');
      serverInfo['skip-cert-verify'] = ProtocolUtils.parseBooleanValue(
        insecure,
      );

      final fingerPrint = ProtocolUtils.getFirstNonEmptyValue(params, [
        'fp',
        'fingerprint',
        'client-fingerprint',
      ]);
      if (fingerPrint != null) {
        serverInfo['client-fingerprint'] = fingerPrint;
      }

      final obfs = ProtocolUtils.getFirstNonEmptyValue(params, [
        'obfs',
        'obfsParam',
      ]);
      if (obfs != null && obfs.isNotEmpty) {
        serverInfo['obfs'] = obfs;
        final obfsPassword = ProtocolUtils.getFirstNonEmptyValue(params, [
          'obfs-password',
          'obfsPassword',
        ]);
        if (obfsPassword != null) {
          serverInfo['obfs-password'] = obfsPassword;
        }
      }

      final mport = ProtocolUtils.getFirstNonEmptyValue(params, [
        'mport',
        'mports',
      ]);
      if (mport != null && mport.isNotEmpty) {
        serverInfo['ports'] = mport;
      }

      serverInfo['udp'] = true;

      final up = ProtocolUtils.getFirstNonEmptyValue(params, ['up', 'upmbps']);
      if (up != null) {
        serverInfo['up'] = up;
      }

      final down = ProtocolUtils.getFirstNonEmptyValue(params, [
        'down',
        'downmbps',
      ]);
      if (down != null) {
        serverInfo['down'] = down;
      }

      if (params.containsKey('alpn')) {
        final alpnString = params['alpn'] ?? '';
        if (alpnString.isNotEmpty) {
          final alpnList = alpnString.split(',').map((s) => s.trim()).toList();
          serverInfo['alpn'] = alpnList;
        }
      }

      final ca = ProtocolUtils.getFirstNonEmptyValue(params, ['ca', 'ca-str']);
      if (ca != null) {
        serverInfo['ca'] = ca;
      }

      final caStr = ProtocolUtils.getFirstNonEmptyValue(params, ['ca-path']);
      if (caStr != null) {
        serverInfo['ca-str'] = caStr;
      }

      return serverInfo;
    } catch (e) {
      return {'type': 'hysteria2', 'error': 'Error parsing Hysteria2 URL: $e'};
    }
  }
}

// ============================================================================
// Hysteria Parser (hysteria and hysteria2)
// ============================================================================
class HysteriaParser extends CommonProtocolParser {
  // Hysteria uses standard format, no special processing needed
}
