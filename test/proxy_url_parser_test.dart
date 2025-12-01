import 'package:clash_forge/services/protocols/proxy_url.dart';

void main() {
  print('=== ProxyUrl Parser Robustness Tests ===\n');

  int passed = 0;
  int failed = 0;

  void test(String name, bool Function() testFn) {
    try {
      final result = testFn();
      if (result) {
        print('✓ $name');
        passed++;
      } else {
        print('✗ $name - Assertion failed');
        failed++;
      }
    } catch (e) {
      print('✗ $name - Exception: $e');
      failed++;
    }
  }

  void testThrows(String name, void Function() testFn) {
    try {
      testFn();
      print('✗ $name - Expected exception but none thrown');
      failed++;
    } catch (e) {
      print('✓ $name - Correctly threw: ${e.runtimeType}');
      passed++;
    }
  }

  print('--- IPv6 Support Tests ---');
  test('IPv6 with brackets - VLESS', () {
    final parsed = ProxyUrl.parse('vless://uuid-1234@[2001:db8::1]:443#IPv6');
    return parsed != null &&
        parsed.address == '2001:db8::1' &&
        parsed.port == 443;
  });

  test('IPv6 loopback address', () {
    final parsed = ProxyUrl.parse('trojan://pass@[::1]:8080#Local');
    return parsed != null && parsed.address == '::1' && parsed.port == 8080;
  });

  test('IPv6 full address with Cloudflare DNS', () {
    final parsed = ProxyUrl.parse(
      'ss://method:pass@[2606:4700:4700::1111]:443',
    );
    return parsed != null && parsed.address == '2606:4700:4700::1111';
  });

  testThrows('IPv6 missing closing bracket', () {
    ProxyUrl.parse('vless://uuid@[2001:db8::1:443');
  });

  testThrows('IPv6 no colon after bracket', () {
    ProxyUrl.parse('vless://uuid@[2001:db8::1]443');
  });

  print('\n--- Port Validation Tests ---');
  test('Valid port - minimum (1)', () {
    final parsed = ProxyUrl.parse('vless://uuid@host:1');
    return parsed != null && parsed.port == 1;
  });

  test('Valid port - maximum (65535)', () {
    final parsed = ProxyUrl.parse('vless://uuid@host:65535');
    return parsed != null && parsed.port == 65535;
  });

  testThrows('Invalid port - zero', () {
    ProxyUrl.parse('vless://uuid@host:0');
  });

  testThrows('Invalid port - above range (655 36)', () {
    ProxyUrl.parse('vless://uuid@host:65536');
  });

  testThrows('Invalid port - non-numeric', () {
    ProxyUrl.parse('vless://uuid@host:abc');
  });

  print('\n--- URL Decoding Tests ---');
  test('Decode URL-encoded password - Trojan', () {
    final parsed = ProxyUrl.parse('trojan://my%40pass%23word@host:443');
    return parsed != null && parsed.id == 'my@pass#word';
  });

  test('Decode special characters in userinfo', () {
    final parsed = ProxyUrl.parse('trojan://test%2Fuser%3Apass@host:443');
    return parsed != null && parsed.id == 'test/user:pass';
  });

  test('Decode query parameters', () {
    final parsed = ProxyUrl.parse('vless://uuid@host:443?path=%2Ftest%2Fpath');
    return parsed != null && parsed.params['path'] == '/test/path';
  });

  test('Decode remark with emojis', () {
    final parsed = ProxyUrl.parse(
      'vless://uuid@host:443#%F0%9F%87%BA%F0%9F%87%B8%20US',
    );
    return parsed != null && parsed.remark == '🇺🇸 US';
  });

  print('\n--- Shadowsocks SIP022 Tests ---');
  test('SS percent-encoded format (SIP022)', () {
    final parsed = ProxyUrl.parse(
      'ss://2022-blake3-aes-256-gcm:password123@host:443',
    );
    return parsed != null &&
        parsed.params['method'] == '2022-blake3-aes-256-gcm' &&
        parsed.params['password'] == 'password123';
  });

  test('SS Base64-encoded format (legacy)', () {
    final parsed = ProxyUrl.parse(
      'ss://YWVzLTI1Ni1nY206cGFzc3dvcmQxMjM=@host:443',
    );
    return parsed != null &&
        parsed.params['method'] == 'aes-256-gcm' &&
        parsed.params['password'] == 'password123';
  });

  print('\n--- TUIC UUID:Password Tests ---');
  test('TUIC with UUID:password format', () {
    final parsed = ProxyUrl.parse(
      'tuic://de5d89a9-3f16-448e-8c40-9145852c8736:mypass@host:12907',
    );
    return parsed != null &&
        parsed.params['uuid'] == 'de5d89a9-3f16-448e-8c40-9145852c8736' &&
        parsed.params['password'] == 'mypass';
  });

  testThrows('TUIC with invalid UUID', () {
    ProxyUrl.parse('tuic://invalid-uuid:password@host:443');
  });

  test('TUIC with UUID only', () {
    final parsed = ProxyUrl.parse(
      'tuic://de5d89a9-3f16-448e-8c40-9145852c8736@host:443',
    );
    return parsed != null &&
        parsed.params['uuid'] == 'de5d89a9-3f16-448e-8c40-9145852c8736';
  });

  print('\n--- Input Sanitization Tests ---');
  test('Trim leading whitespace', () {
    final parsed = ProxyUrl.parse('   vless://uuid@host:443');
    return parsed != null && parsed.protocol == 'vless';
  });

  test('Trim trailing whitespace', () {
    final parsed = ProxyUrl.parse('vless://uuid@host:443   ');
    return parsed != null && parsed.protocol == 'vless';
  });

  print('\n--- Integration Tests ---');
  test('Complex VLESS with IPv6 and params', () {
    final parsed = ProxyUrl.parse(
      'vless://uuid@[2001:db8::1]:443?security=reality&pbk=key123#Test',
    );
    return parsed != null &&
        parsed.address == '2001:db8::1' &&
        parsed.params['security'] == 'reality' &&
        parsed.params['pbk'] == 'key123';
  });

  test('Backward compatibility - real SS URL', () {
    final parsed = ProxyUrl.parse(
      'ss://YWVzLTI1Ni1jZmI6YW1hem9uc2tyMDU@52.195.185.114:443#Test',
    );
    return parsed != null &&
        parsed.protocol == 'ss' &&
        parsed.address == '52.195.185.114' &&
        parsed.port == 443;
  });

  print('\n=== Test Summary ===');
  print('Passed: $passed');
  print('Failed: $failed');
  print('Total: ${passed + failed}');

  if (failed == 0) {
    print('\n🎉 All tests passed!');
  } else {
    print('\n⚠️  Some tests failed');
  }
}
