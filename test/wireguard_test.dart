import 'package:flutter_test/flutter_test.dart';
import 'package:clash_forge/services/protocols/wireguard.dart';

void main() {
  group('WireGuardParser', () {
    const validConfig = '''
[Interface]
Address = 192.168.6.203/32
DNS = 1.1.1.1,8.8.8.8
PrivateKey = eGxwn4aHprX28sYcAW3JjbEi+K+hvkkbCbNu/VlTWVo=
MTU = 1280

[Peer]
PublicKey = h1Qr9B2JHc+S/c3l8rP8PbR01ZUOe4nCY7Smf4BHank=
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = usa2.vpnjantit.com:1024
''';

    test('isWireGuardConfig detects valid config', () {
      expect(WireGuardParser.isWireGuardConfig(validConfig), isTrue);
    });

    test('isWireGuardConfig rejects invalid config', () {
      expect(
        WireGuardParser.isWireGuardConfig('Just some random text'),
        isFalse,
      );
      expect(WireGuardParser.isWireGuardConfig('[Interface] only'), isFalse);
    });

    test('parse correctly extracts fields and ignores others', () {
      final result = WireGuardParser.parse(validConfig);

      expect(result['type'], equals('wireguard'));
      expect(result['server'], equals('usa2.vpnjantit.com'));
      expect(result['port'], equals(1024));
      expect(result['ip'], equals('192.168.6.203/32'));
      expect(
        result['private-key'],
        equals('eGxwn4aHprX28sYcAW3JjbEi+K+hvkkbCbNu/VlTWVo='),
      );
      expect(
        result['public-key'],
        equals('h1Qr9B2JHc+S/c3l8rP8PbR01ZUOe4nCY7Smf4BHank='),
      );
      expect(result['udp'], isTrue);

      // Verify ignored fields are NOT present
      expect(result.containsKey('dns'), isFalse);
      expect(result.containsKey('mtu'), isFalse);
      expect(result.containsKey('allowed-ips'), isFalse);
    });

    test('parse handles case insensitivity', () {
      const mixedCaseConfig = '''
[interface]
address = 10.0.0.1/32
privatekey = key1

[PEER]
endpoint = server.com:51820
publickey = key2
''';
      final result = WireGuardParser.parse(mixedCaseConfig);
      expect(result['server'], equals('server.com'));
      expect(result['port'], equals(51820));
    });

    test('parse returns error for missing required fields', () {
      const invalidConfig = '''
[Interface]
Address = 10.0.0.1/32
''';
      final result = WireGuardParser.parse(invalidConfig);
      expect(result.containsKey('error'), isTrue);
    });
  });
}
