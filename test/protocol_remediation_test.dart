import 'package:flutter_test/flutter_test.dart';
import 'package:clash_forge/services/protocols/protocol_manager.dart';
import 'package:clash_forge/services/protocols/wireguard.dart';
import 'package:clash_forge/services/protocols/protocol_validator.dart';

void main() {
  group('Protocol Security & Remediation Tests', () {
    test('VLESS defaults skip-cert-verify to false', () {
      final url =
          'vless://df0680ca-e43c-498d-ed86-8e196eedd012@127.0.0.1:443?security=tls#Test';
      final result = ProtocolManager.parse(url);
      expect(result['skip-cert-verify'], isFalse);
      expect(result['tls'], isTrue);
    });

    test('VLESS respects explicit allowInsecure=1', () {
      final url =
          'vless://df0680ca-e43c-498d-ed86-8e196eedd012@127.0.0.1:443?security=tls&allowInsecure=1#Test';
      final result = ProtocolManager.parse(url);
      expect(result['skip-cert-verify'], isTrue);
    });

    test('VMess defaults skip-cert-verify to false and formats h2-opts as list', () {
      // JSON: {"add":"127.0.0.1","port":"443","id":"05641cf5-58d2-4ba4-a9f1-b3cda0b1fb1d","net":"h2","path":"/h2","host":"example.com","tls":"tls","ps":"VMessTest"}
      // Base64 encoded:
      const vmessUrl =
          'vmess://eyJhZGQiOiIxMjcuMC4wLjEiLCJwb3J0IjoiNDQzIiwiaWQiOiIwNTY0MWNmNS01OGQyLTRiYTQtYTlmMS1iM2NkYTBiMWZiMWQiLCJuZXQiOiJoMiIsInBhdGgiOiIvaDIiLCJob3N0IjoiZXhhbXBsZS5jb20iLCJ0bHMiOiJ0bHMiLCJwcyI6IlZNZXNzVGVzdCJ9';
      final result = ProtocolManager.parse(vmessUrl);
      expect(result['type'], equals('vmess'));
      expect(result['skip-cert-verify'], isFalse);
      expect(result['tls'], isTrue);
      expect(result['h2-opts']['host'], equals(['example.com']));
      expect(result['h2-opts']['path'], equals('/h2'));
    });

    test('Trojan defaults skip-cert-verify to false', () {
      final url = 'trojan://pass123@127.0.0.1:443?sni=example.com#TrojanTest';
      final result = ProtocolManager.parse(url);
      expect(result['type'], equals('trojan'));
      expect(result['skip-cert-verify'], isFalse);
      expect(result['tls'], isTrue);
    });

    test('Hysteria2 correctly maps ca-path to ca and ca-str to ca-str', () {
      final url =
          'hy2://pass123@127.0.0.1:443?ca-path=/etc/ssl/cert.pem&ca-str=MIIB...#Hy2Test';
      final result = ProtocolManager.parse(url);
      expect(result['type'], equals('hysteria2'));
      expect(result['ca'], equals('/etc/ssl/cert.pem'));
      expect(result['ca-str'], equals('MIIB...'));
    });

    test('WireGuard correctly extracts IPv6 endpoints and cleanses DNS', () {
      const config = '''
[Interface]
Address = 10.0.0.2/32, fd00::2/128
PrivateKey = eGxwn4aHprX28sYcAW3JjbEi+K+hvkkbCbNu/VlTWVo=
DNS = 1.1.1.1, 8.8.8.8
MTU = 1420

[Peer]
Endpoint = [2606:4700:d0::a29f:c001]:51820
PublicKey = h1Qr9B2JHc+S/c3l8rP8PbR01ZUOe4nCY7Smf4BHank=
''';
      final result = WireGuardParser.parse(config);
      expect(result['type'], equals('wireguard'));
      expect(result['server'], equals('2606:4700:d0::a29f:c001'));
      expect(result['port'], equals(51820));
      expect(result['dns'], equals(['1.1.1.1', '8.8.8.8']));
      expect(result['mtu'], equals(1420));
    });

    test('Shadowsocks preserves passwords with colons', () {
      // SIP002 base64 of 'aes-256-gcm:pass:word123'
      // base64('aes-256-gcm:pass:word123') = 'YWVzLTI1Ni1nY206cGFzczp3b3JkMTIz'
      final url =
          'ss://YWVzLTI1Ni1nY206cGFzczp3b3JkMTIz@1.2.3.4:8388#ColonPassTest';
      final result = ProtocolManager.parse(url);
      expect(result['type'], equals('ss'));
      expect(result['cipher'], equals('aes-256-gcm'));
      expect(result['password'], equals('pass:word123'));
      expect(result['server'], equals('1.2.3.4'));
      expect(result['port'], equals(8388));
    });

    test('Shadowsocks handles legacy full-base64 URL with plugin query params', () {
      // base64('aes-256-gcm:password@1.2.3.4:8388') = 'YWVzLTI1Ni1nY206cGFzc3dvcmRAMS4yLjMuNDo4Mzg4'
      final url =
          'ss://YWVzLTI1Ni1nY206cGFzc3dvcmRAMS4yLjMuNDo4Mzg4/?plugin=obfs-local%3Bobfs%3Dhttp#LegacyPlugin';
      final result = ProtocolManager.parse(url);
      expect(result['type'], equals('ss'));
      expect(result['server'], equals('1.2.3.4'));
      expect(result['port'], equals(8388));
      expect(result['cipher'], equals('aes-256-gcm'));
      expect(result['password'], equals('password'));
      expect(result['plugin'], equals('obfs-local'));
      expect(result['plugin-opts']['obfs'], equals('http'));
    });

    test('ShadowsocksR safely handles non-base64 remarks without crashing', () {
      // Construct SSR string: server:port:protocol:method:obfs:password_base64/?remarks=plain_text_remarks
      // base64('pass') = 'cGFzcw=='
      // ssr string = '1.2.3.4:8080:origin:aes-256-cfb:plain:cGFzcw==/?remarks=RawRemark'
      // base64 url-safe:
      // base64('1.2.3.4:8080:origin:aes-256-cfb:plain:cGFzcw==/?remarks=RawRemark')
      // = 'MS4yLjMuNDo4MDgwOm9yaWdpbjphZXMtMjU2LWNmYjpwbGFpbjpjR0Z6Y3c9PS8_cmVtYXJrcz1SYXdSZW1hcms='
      final url =
          'ssr://MS4yLjMuNDo4MDgwOm9yaWdpbjphZXMtMjU2LWNmYjpwbGFpbjpjR0Z6Y3c9PS8_cmVtYXJrcz1SYXdSZW1hcms=';
      final result = ProtocolManager.parse(url);
      expect(result['type'], equals('ssr'));
      expect(result['server'], equals('1.2.3.4'));
      expect(result['port'], equals(8080));
      expect(result['name'], equals('RawRemark'));
      expect(result['password'], equals('pass'));
    });

    test('ProtocolValidator accepts 32-byte keys with +, /, -, and _', () {
      // Standard Base64 key with + and /
      const keyWithSlashPlus = 'eGxwn4aHprX28sYcAW3JjbEi+K+hvkkbCbNu/VlTWVo=';
      expect(ProtocolValidator.isValidPublicKey(keyWithSlashPlus), isTrue);

      // URL-safe Base64 key with - and _
      const keyUrlSafe = 'eGxwn4aHprX28sYcAW3JjbEi-K-hvkkbCbNu_VlTWVo=';
      expect(ProtocolValidator.isValidPublicKey(keyUrlSafe), isTrue);

      // Invalid length key
      expect(ProtocolValidator.isValidPublicKey('invalidShortKey'), isFalse);
    });

    test('AnyTLS handles separated uuid:password userinfo', () {
      final url =
          'anytls://c1854182-5014-4cd5-b024-022302480ba1:custompass@1.2.3.4:443?sni=example.com#AnyTlsTest';
      final result = ProtocolManager.parse(url);
      expect(result['type'], equals('anytls'));
      expect(result['uuid'], equals('c1854182-5014-4cd5-b024-022302480ba1'));
      expect(result['password'], equals('custompass'));
      expect(result['server'], equals('1.2.3.4'));
      expect(result['sni'], equals('example.com'));
      expect(result['tls'], isTrue);
    });
  });
}
