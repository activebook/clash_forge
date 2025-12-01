import '../lib/services/protocols/proxy_url.dart';

void main() {
  print('Testing URL with garbage prefix...\n');

  final url =
      '%40tunder_vpn<br/><br/>hysteria2://7daa4a7f-f76e-4941-84bd-c6004cdbb859@94.249.197.95:30000?security=tls&insecure=1&sni=bing.com';

  try {
    final parsed = ProxyUrl.parse(url);
    if (parsed != null) {
      print('✓ Successfully parsed!');
      print('  Protocol: ${parsed.protocol}');
      print('  Address: ${parsed.address}');
      print('  Port: ${parsed.port}');
    } else {
      print('✗ Parsing returned null');
    }
  } catch (e) {
    print('✗ Error: $e');
  }
}
