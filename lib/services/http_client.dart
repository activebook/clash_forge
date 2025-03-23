import 'dart:io';
import 'dart:convert'; // Added missing import for utf8
import 'package:flutter/services.dart';

Map<String, dynamic>? _proxySettings;

class ProxyService {
  static const platform = MethodChannel(
    'com.activebook.clash_forge/proxy_settings',
  );

  static Future<Map<String, dynamic>> getSystemProxySettings() async {
    try {
      final result = await platform.invokeMethod('getProxySettings');
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (_) {
      //print("Failed to get proxy settings: ${e.message}");
      return {};
    }
  }
}

Future<String> request(String url) async {
  // Create HttpClient with proxy
  final httpClient = HttpClient();

  // Get proxy settings
  if (_proxySettings == null) {
    // Get macOS system proxy settings
    _proxySettings = await ProxyService.getSystemProxySettings();
    if (_proxySettings!.isEmpty) {
      //print('No proxy settings found or proxy is disabled');
    }
  }

  if (_proxySettings != null && _proxySettings!.isNotEmpty) {
    // Configure proxy settings
    String? proxy =
        _proxySettings!['httpsProxy'] ?? _proxySettings!['httpProxy'];
    if (proxy != null) {
      httpClient.findProxy = (uri) => 'PROXY $proxy';
      //print('Using proxy: $proxy');
    }
  }

  // Make the request using HttpClient with proxy settings
  String responseBody = '';
  try {
    final request = await httpClient.getUrl(Uri.parse(url));
    final response = await request.close();
    if (response.statusCode != 200) {
      throw Exception('Failed to load URL: ${response.statusCode}');
    }
    responseBody = await response.transform(utf8.decoder).join();

    //print('Response status: ${response.statusCode}');
    //print('Response length: ${responseBody.length}');
  } catch (e) {
    rethrow;
  } finally {
    httpClient.close();
  }

  return responseBody;
}
