import '../lib/services/protocols/proxy_url.dart';

void main() {
  print('Testing Hysteria2 URL with trailing slash...\n');

  final url =
      'hy2://395b673100014af8@178.128.6.120:37416/?insecure=1&sni=www.bing.com&obfs=salamander&obfs-password=395b673100014af8#HttpInjector-hysteria2';

  try {
    final parsed = ProxyUrl.parse(url);
    if (parsed != null) {
      print('✓ Successfully parsed!');
      print('  Protocol: ${parsed.protocol}');
      print('  Address: ${parsed.address}');
      print('  Port: ${parsed.port}');
      print('  ID: ${parsed.id}');
      print('  Params: ${parsed.params}');
      print('  Remark: ${parsed.remark}');
    } else {
      print('✗ Parsing returned null');
    }
  } catch (e) {
    print('✗ Error: $e');
  }
}
