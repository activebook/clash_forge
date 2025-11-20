import 'package:clash_forge/services/protocols.dart';
import 'package:logger/logger.dart';

// Configure logger for command-line use
var logger = Logger(
  // Use ConsoleOutput that works with dart command-line
  output: ConsoleOutput(),
  // SimpleLogPrinter is better for command-line
  printer: SimplePrinter(colors: true),
  // Ensure all log levels are shown
  level: Level.all,
  // Filter to show all logs
  filter: DevelopmentFilter(),
);

// Usage example
void detectAndCorrectUrl(String url) {
  try {
    final parsedUrl = parseProxyUrl(url)!;

    final correctUrl = parsedUrl.toCorrectUrl();
    if (correctUrl.isNotEmpty) {
      print('Detected incorrect protocol. Corrected URL: $correctUrl');
    } else {
      print('URL appears to use the correct protocol: ${parsedUrl.protocol}');
    }

    // Print detection results
    print('Protocol detection results:');
    print('- Is VLESS? ${parsedUrl.isLikelyVless}');
    print('- Is VMESS? ${parsedUrl.isLikelyVmess}');
    print('- Is Trojan? ${parsedUrl.isLikelyTrojan}');
    print('- Is Shadowsocks? ${parsedUrl.isLikelyShadowsocks}');

    print("Revised url: ${parsedUrl.toRevisedUrl()}");
    print(parsedUrl.toString());
  } catch (e) {
    print('Failed to parse URL: $e');
  }
}

void main() {
  // Test URLs
  final testUrls = [
    'ss://beb8afcb-4c95-46ea-8b05-d890ba1d3215@85.208.139.222:1633?security=reality&encryption=none&pbk=ANlgAsYC8HmKfJnc5SFvru822urkxG1PzW1Zw4Vbm0Q&host=jokerrvpnTelegram#[]t.me/ConfigsHub',
    'vmess://eyJhZGQiOiJzaS4xODA4LnNpdGUiLCJhaWQiOiIwIiwiaG9zdCI6Im9iZGlpLmNmZCIsImlkIjoiMDU2NDFjZjUtNThkMi00YmE0LWE5ZjEtYjNjZGEwYjFmYjFkIiwibmV0Ijoid3MiLCJwYXRoIjoiL2xpbmt3cyIsInBvcnQiOiIzMDAwMiIsInBzIjoiW/Cfj4FddC5tZS9Db25maWdzSHViIiwic2N5IjoiYXV0byIsInNuaSI6Im9iZGlpLmNmZCIsInRscyI6InRscyIsInR5cGUiOiIiLCJ2IjoiMiJ9`',
    'ss://eyJhZGQiOiJodHRwczovL2dpdGh1Yi5jb20vQUxJSUxBUFJPL3YycmF5TkctQ29uZmlnIiwiYWlkIjoiMCIsImFscG4iOiIiLCJmcCI6IiIsImhvc3QiOiIiLCJpZCI6IkZyZWUiLCJuZXQiOiJ0Y3AiLCJwYXRoIjoiIiwicG9ydCI6IjQzMyIsInBzIjoi8J+SgPCfmI4gUHJvamVjdCBCeSBBTElJTEFQUk8iLCJzY3kiOiJjaGFjaGEyMC1wb2x5MTMwNSIsInNuaSI6IiIsInRscyI6IiIsInR5cGUiOiJub25lIiwidiI6IjIifQ==',
    'ss://YWVzLTI1Ni1jZmI6YW1hem9uc2tyMDU@52.195.185.114:443#2%7C%F0%9F%87%BA%F0%9F%87%B83%20%7C%20%206.0MB%2Fs',
    'vless://df0680ca-e43c-498d-ed86-8e196eedd012@138.199.175.222:8880?security=&encryption=none&type=grpc#[]t.me/ConfigsHub',
    'trojan://74260712244661900@gorgeous-bull.shiner427.skin:443?allowInsecure=0&sni=gorgeous-bull.shiner427.skin#%F0%9F%87%AC%F0%9F%87%A7%20%E8%8B%B1%E5%9B%BD%20V2CROSS.COM',
    'trojan://telegram-id-directvpn@52.49.75.121:22222?allowInsecure=0&sni=trojan.burgerip.co.uk#%F0%9F%87%AE%F0%9F%87%AA%20%E7%88%B1%E5%B0%94%E5%85%B0%20%E9%83%BD%E6%9F%8F%E6%9E%97Amazon%E6%95%B0%E6%8D%AE%E4%B8%AD%E5%BF%83',
    'ss://c3M6Ly9ZV1Z6TFRJMU5pMWpabUk2WVcxaGVtOXVjMnR5TURV@13.215.250.172:443#13%7Ctg%E9%A2%91%E9%81%93%3A%40ripaojiedian%20%231',
    'http://kjafl18@a:11',
    'vless://5d245df1-c570-4b84-9642-faa4d0e3d3b7@5.75.193.144:8081?security=none&type=tcp&headerType=http#VL-TCP-NONEDE-5.75.193.144:8081',
    'ss://Y2hhY2hhMjAtaWV0Zi1wb2x5MTMwNTpvWEdwMStpaGxmS2c4MjZIQDE3Mi4yMzIuMTcxLjE5MjoxODY2#SS-%E7%BE%8E%E5%9B%BD-NF%E8%A7%A3%E9%94%81%E8%87%AA%E5%88%B6%E5%89%A7-ChatGPT-TikTok-YouTube-172.232.171.192%3A1866',
    'ss://cmM0LW1kNTplZmFuY2N5dW4@cn01.efan8867801.xyz:8773/?plugin=obfs-local%3Bobfs%3Dhttp%3Bobfs-host%3D202503170996717-MVQjjXvt4R.download.microsoft.com#%F0%9F%87%BA%F0%9F%87%B8%20%E7%BE%8E%E5%9B%BD2%7C%40ripaojiedian',
    'ss://df0680ca-e43c-498d-ed86-8e196eedd012@157.180.22.144:8880?mode=gun&security=none&encryption=none&type=grpc#',
    'ss://c72db571-2c94-4bfa-e546-c6eca9e43b91@151.101.66.219:80?type=ws&host=foffmelo.com&path=%2Folem%2Fws%3Fed%3D1024#@Hope_Net-join-us-on-Telegram',
    'hy2://2c833c5d-cbcc-4afb-89ba-d17dc39db6f0@75.127.13.83:47974?insecure=1&sni=www.bing.com#Test_HY2',
  ];
  /*
  for (final url in testUrls) {
    detectAndCorrectUrl(url);
  }
  */

  logger.d("Debug message");
  logger.i("Info message");
  logger.w("Warning message");
  logger.e("Error message");
  logger.wtf("WTF message");

  // Test the hy2 URL
  detectAndCorrectUrl(testUrls.last);
}
