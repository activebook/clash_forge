import '../lib/services/protocols/wireguard.dart';

void main() {
  print('Running manual WireGuard verification...');

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

  // Test 1: Detection
  if (WireGuardParser.isWireGuardConfig(validConfig)) {
    print('✅ Test 1 Passed: Config detected correctly');
  } else {
    print('❌ Test 1 Failed: Config NOT detected');
  }

  // Test 2: Parsing
  try {
    final result = WireGuardParser.parse(validConfig);

    bool passed = true;
    if (result['type'] != 'wireguard') {
      print('❌ Type mismatch');
      passed = false;
    }
    if (result['server'] != 'usa2.vpnjantit.com') {
      print('❌ Server mismatch');
      passed = false;
    }
    if (result['port'] != 1024) {
      print('❌ Port mismatch');
      passed = false;
    }
    if (result['ip'] != '192.168.6.203/32') {
      print('❌ IP mismatch');
      passed = false;
    }
    if (result['private-key'] !=
        'eGxwn4aHprX28sYcAW3JjbEi+K+hvkkbCbNu/VlTWVo=') {
      print('❌ PrivateKey mismatch');
      passed = false;
    }
    if (result['public-key'] !=
        'h1Qr9B2JHc+S/c3l8rP8PbR01ZUOe4nCY7Smf4BHank=') {
      print('❌ PublicKey mismatch');
      passed = false;
    }
    if (!result.containsKey('dns')) {
      print('❌ DNS missing');
      passed = false;
    } else {
      final dnsList = result['dns'] as List;
      if (dnsList.length != 4) {
        print('❌ DNS list length mismatch: ${dnsList.length}');
        passed = false;
      } else {
        if (dnsList[0] != 'https://1.12.12.12/dns-query') {
          print('❌ Fixed DNS 1 mismatch');
          passed = false;
        }
        if (dnsList[1] != 'https://120.53.53.53/dns-query') {
          print('❌ Fixed DNS 2 mismatch');
          passed = false;
        }
        if (dnsList[2] != '1.1.1.1') {
          print('❌ Parsed DNS 1 mismatch');
          passed = false;
        }
        if (dnsList[3] != '8.8.8.8') {
          print('❌ Parsed DNS 2 mismatch');
          passed = false;
        }
      }
    }

    if (passed) {
      print('✅ Test 2 Passed: Parsing correct');
    }
  } catch (e) {
    print('❌ Test 2 Failed: Exception $e');
  }
}
