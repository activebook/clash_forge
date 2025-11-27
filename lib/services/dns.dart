import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

Future<List<String>> getDnsIpAddresses(
  String hostname, {
  String firstChoice = 'dohpub',
}) async {
  // Define the providers map
  Map<String, String> providers = {
    'dohpub': 'https://doh.pub/dns-query?name=$hostname&type=A',
    'dnspub': 'https://dns.pub/dns-query?name=$hostname&type=A',
    'cnnic': 'https://1.12.12.12/dns-query?name=$hostname&type=A',
    'tencent': 'https://120.53.53.53/dns-query?name=$hostname&type=A',
    'cloudflare': 'https://cloudflare-dns.com/dns-query?name=$hostname&type=A',
    'google': 'https://dns.google/resolve?name=$hostname&type=A',
    'alibaba': 'https://dns.alidns.com/resolve?name=$hostname&type=A',
    'quad9': 'https://dns.quad9.net/dns-query?name=$hostname&type=A',
    'adguard': 'https://dns.adguard.com/resolve?name=$hostname&type=A',
    'nextdns': 'https://dns.nextdns.io/dns-query?name=$hostname&type=A',
  };

  // China-friendly providers that work in China and return global IPs (uncensored)
  final chinaFriendlyProviders = ['dohpub', 'dnspub', 'tencent', 'cnnic'];

  // Global providers (may not work in China or be slow)
  final globalProviders = [
    'cloudflare',
    'google',
    'quad9',
    'adguard',
    'nextdns',
    'alibaba',
  ];

  try {
    // Try the preferred provider first
    firstChoice = firstChoice.trim().toLowerCase();
    if (providers.containsKey(firstChoice)) {
      try {
        return await _queryDnsProvider(providers[firstChoice]!);
      } catch (_) {
        // If preferred provider fails, try fallbacks
        //print('preferred provider fails, try fallbacks: $hostname');
      }
    }

    // Build fallback list: prioritize China-friendly providers first
    final fallbackProviders = <String>[];

    // Add China-friendly providers (excluding the first choice)
    for (var provider in chinaFriendlyProviders) {
      if (provider != firstChoice && !fallbackProviders.contains(provider)) {
        fallbackProviders.add(provider);
      }
    }

    // Add global providers (excluding the first choice)
    for (var provider in globalProviders) {
      if (provider != firstChoice && !fallbackProviders.contains(provider)) {
        fallbackProviders.add(provider);
      }
    }

    // Try fallbacks: first 2 China-friendly in parallel, then remaining if needed
    if (fallbackProviders.isNotEmpty) {
      // Try first 2 China-friendly providers in parallel
      final initialFallbacks = fallbackProviders.take(2).toList();
      final initialFutures =
          initialFallbacks
              .map((p) => _queryDnsProvider(providers[p]!))
              .toList();

      try {
        return await Future.any(initialFutures);
      } catch (_) {
        // If first 2 fail, try remaining providers
        if (fallbackProviders.length > 2) {
          final remainingFallbacks = fallbackProviders.skip(2).take(2).toList();
          final remainingFutures =
              remainingFallbacks
                  .map((p) => _queryDnsProvider(providers[p]!))
                  .toList();

          return await Future.any(remainingFutures);
        }
      }
    }

    // Last resort: use system DNS
    return await InternetAddress.lookup(
      hostname,
    ).then((addrs) => addrs.map((addr) => addr.address).toList());
  } catch (e) {
    //print('All dns lookup failed!: $hostname  -- $e');
    return <String>[];
  }
}

Future<List<String>> _queryDnsProvider(String provider) async {
  final response = await http
      .get(Uri.parse(provider), headers: {'Accept': 'application/dns-json'})
      .timeout(Duration(milliseconds: 1500));

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    List<String> ipAddresses = [];

    if (data['Answer'] != null) {
      for (var answer in data['Answer']) {
        if (answer['type'] == 1) {
          ipAddresses.add(answer['data']);
        }
      }
      if (ipAddresses.isNotEmpty) return ipAddresses;
    }
  }

  throw Exception('No results from provider');
}

bool isIPAddress(String hostname) {
  // IPv4 regex pattern
  final ipv4Pattern = RegExp(
    r'^(\d{1,3}\.){3}\d{1,3}$',
  ); // Matches "192.168.1.1"

  // IPv6 regex pattern (simplified)
  final ipv6Pattern = RegExp(
    r'^([a-fA-F0-9:]+)$',
  ); // Matches "2001:db8::ff00:42:8329"

  return ipv4Pattern.hasMatch(hostname) || ipv6Pattern.hasMatch(hostname);
}

bool isIpAddressFast(String hostname) {
  return InternetAddress.tryParse(hostname) != null;
}
