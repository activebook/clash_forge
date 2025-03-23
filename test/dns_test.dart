import 'package:clash_forge/services/dns.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> testDoHEndpoint(String endpointUrl, String hostname) async {
  // Replace $hostname with an actual hostname (e.g., 'example.com')
  final url = endpointUrl.replaceAll(r'$hostname', hostname);
  try {
    final response = await http
      .get(Uri.parse(url), headers: {'Accept': 'application/dns-json'})
      .timeout(Duration(milliseconds: 1500));
    if (response.statusCode == 200) {
      print('Success: $url is working.');
      // Optionally, decode and inspect the response:
      final data = jsonDecode(response.body);
      print(data);
    } else {
      print('Error: $url returned status code ${response.statusCode}');
    }
  } catch (e) {
    print('Exception while testing $url: $e');
  }
}

void test_service() async {
  // List of endpoints with descriptive keys.
  final endpoints = {
    'alibaba': 'https://dns.alidns.com/resolve?name=\$hostname&type=A',
    'cloudflare': 'https://cloudflare-dns.com/dns-query?name=\$hostname&type=A',
    'cnnic': 'https://1.12.12.12/dns-query?name=\$hostname&type=A',
    'dnspod': 'https://doh.pub/dns-query?name=\$hostname&type=A',
    'google': 'https://dns.google/resolve?name=\$hostname&type=A',
    'nextdns': 'https://dns.nextdns.io/dns-query?name=\$hostname&type=A',
  };

  // Test with a sample hostname (e.g., 'example.com')
  for (final entry in endpoints.entries) {
    print('Testing ${entry.key} endpoint:');
    await testDoHEndpoint(entry.value, 'www.baidu.com');
    print('-----------------------------');
  }
}


void main() async {
  final startTime = DateTime.now();
  final ipAddresses = await getDnsIpAddresses('hajlab.ucdavis.edu');
  final endTime = DateTime.now();
  print('DNS lookup took ${endTime.difference(startTime).inMilliseconds} ms.');
  print('IP addresses: $ipAddresses');

  List<String> testCases = [
    '192.168.1.1', // IPv4
    '8.8.8.8', // IPv4
    '2001:db8::ff00:42:8329', // IPv6
    'example.com', // Domain name
    'sub.domain.net', // Domain name
    'localhost', // Domain name
  ];

  for (var host in testCases) {
    print('$host is ${isIpAddressFast(host) ? "an IP address" : "a domain name"}');
  }

  //test_service();
}