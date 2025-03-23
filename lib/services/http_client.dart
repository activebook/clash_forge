import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';

class ProxyService {
  // Singleton instance
  static final ProxyService _instance = ProxyService._internal();
  
  // Factory constructor returns singleton instance
  factory ProxyService() {
    return _instance;
  }
  
  // Private constructor
  ProxyService._internal();
  
  // Cached proxy settings
  Map<String, dynamic>? _proxySettings;
  
  static const platform = MethodChannel(
    'com.activebook.clash_forge/proxy_settings',
  );

  Future<Map<String, dynamic>> getSystemProxySettings() async {
    if (_proxySettings == null) {
      try {
        final result = await platform.invokeMethod('getProxySettings');
        _proxySettings = Map<String, dynamic>.from(result);
      } on PlatformException catch (_) {
        _proxySettings = {};
      }
    }
    return _proxySettings!;
  }
  
  HttpClient createProxyClient() {
    final httpClient = HttpClient();
    
    if (_proxySettings != null && _proxySettings!.isNotEmpty) {
      String? proxy = _proxySettings!['httpsProxy'] ?? _proxySettings!['httpProxy'];
      if (proxy != null) {
        httpClient.findProxy = (uri) => 'PROXY $proxy';
      }
    }
    
    return httpClient;
  }
}

Future<String> request(String url) async {
  final proxyService = ProxyService();
  
  // Initialize proxy settings if needed
  await proxyService.getSystemProxySettings();
  
  // Get configured HttpClient
  final httpClient = proxyService.createProxyClient();
  
  // Make the request
  String responseBody = '';
  try {
    final request = await httpClient.getUrl(Uri.parse(url));
    final response = await request.close();
    if (response.statusCode != 200) {
      throw Exception('Failed to load URL: ${response.statusCode}');
    }
    responseBody = await response.transform(utf8.decoder).join();
  } catch (e) {
    rethrow;
  } finally {
    httpClient.close();
  }

  return responseBody;
}