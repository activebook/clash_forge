import 'package:clash_forge/services/protocols/vless.dart';
import 'package:clash_forge/services/protocols/vmess.dart';
import 'package:clash_forge/services/protocols/trojan.dart';
import 'package:clash_forge/services/protocols/shadowsocks.dart';
import 'package:clash_forge/services/protocols/shadowsocksr.dart';
import 'package:clash_forge/services/protocols/proxy_url.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Protocol Strictness', () {
    final vless = VlessProtocol();
    final vmess = VmessProtocol();
    final trojan = TrojanProtocol();
    final ss = ShadowsocksProtocol();
    final ssr = ShadowsocksRProtocol();

    test('VLESS should not handle VMess URL', () {
      final url =
          'vmess://eyJhZGQiOiIxMjcuMC4wLjEiLCJwb3J0IjoiODA4MCIsImlkIjoiYWFhYSIsIm5ldCI6InRjcCJ9';
      final parsed = ProxyUrl.parse(url);
      expect(vless.canHandle(url, parsed), isFalse);
    });

    test('VMess should not handle VLESS URL', () {
      final url = 'vless://uuid@127.0.0.1:8080?security=none';
      final parsed = ProxyUrl.parse(url);
      expect(vmess.canHandle(url, parsed), isFalse);
    });

    test('Trojan should not handle VLESS URL with TLS', () {
      final url = 'vless://uuid@127.0.0.1:443?security=tls';
      final parsed = ProxyUrl.parse(url);
      expect(trojan.canHandle(url, parsed), isFalse);
    });

    test('Shadowsocks should not handle VLESS URL', () {
      final url = 'vless://uuid@127.0.0.1:8080?security=none';
      final parsed = ProxyUrl.parse(url);
      expect(ss.canHandle(url, parsed), isFalse);
    });

    test('VLESS should handle VLESS URL', () {
      final url =
          'vless://df0680ca-e43c-498d-ed86-8e196eedd012@127.0.0.1:8080?security=none';
      final parsed = ProxyUrl.parse(url);
      expect(vless.canHandle(url, parsed), isTrue);
    });

    test('VMess should handle VMess URL', () {
      final url =
          'vmess://eyJhZGQiOiIxMjcuMC4wLjEiLCJwb3J0IjoiODA4MCIsImlkIjoiYWFhYSIsIm5ldCI6InRjcCJ9';
      final parsed = ProxyUrl.parse(url);
      expect(vmess.canHandle(url, parsed), isTrue);
    });

    test('VLESS should handle VLESS URL format and route properly', () {
      final url = 'vless://not-a-uuid@127.0.0.1:8080?security=none';
      final parsed = ProxyUrl.parse(url);
      expect(vless.canHandle(url, parsed), isTrue);
    });

    test(
      'VMess should route VMess scheme and return error for invalid body',
      () {
        final url = 'vmess://not-base64-json';
        expect(vmess.canHandle(url, null), isTrue);
        final result = vmess.parse(url);
        expect(result.containsKey('error'), isTrue);
      },
    );

    test(
      'SSR should handle valid SSR URL (even if ProxyUrl fails to parse it fully)',
      () {
        final url =
            'ssr://MTAzLjE3Mi4xMTYuNzk6OTA1NzpvcmlnaW46YWVzLTI1Ni1jZmI6cGxhaW46ZDJwVWRXZFlNMXAwU0UxQ09XTXpXZy8_Z3JvdXA9VTFOU1VISnZkbWxrWlhJJnJlbWFya3M9NXBhdzVZcWc1WjJoTFRVd055NDJTMEl2Y3cmb2Jmc3BhcmFtPSZwcm90b3BhcmFtPQ';
        // ProxyUrl.parse likely throws for this format because it lacks '@'
        ProxyUrl? parsed;
        try {
          parsed = ProxyUrl.parse(url);
        } catch (_) {}

        // Even if parsed is null, canHandle should return true based on scheme
        expect(ssr.canHandle(url, parsed), isTrue);
      },
    );

    test(
      'Trojan should handle Trojan URL without password (to return error later)',
      () {
        // Trojan usually treats userinfo as password.
        // We allow it in canHandle so parse() can return a specific error.
        final url = 'trojan://@127.0.0.1:443';
        final parsed = ProxyUrl.parse(url);
        expect(trojan.canHandle(url, parsed), isTrue);
      },
    );
  });
}
