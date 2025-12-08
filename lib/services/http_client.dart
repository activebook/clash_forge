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

  static const channelSettings = MethodChannel(
    'com.activebook.clash_forge/settings',
  );

  Future<Map<String, dynamic>> getSystemProxySettings() async {
    if (_proxySettings == null) {
      try {
        final result = await channelSettings.invokeMethod('getProxySettings');
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
      String? proxy =
          _proxySettings!['httpsProxy'] ?? _proxySettings!['httpProxy'];
      if (proxy != null) {
        httpClient.findProxy = (uri) => 'PROXY $proxy';
      }
    }

    return httpClient;
  }

  /// Validates a URL by making a HEAD or GET request through the system proxy
  /// Returns true if the URL is reachable and returns a successful status code (200-399)
  /// Returns false if the URL is unreachable, times out, or returns an error status code
  Future<bool> validateUrl(
    String url, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      // Ensure proxy settings are loaded
      await getSystemProxySettings();

      // Create proxy-aware client
      final httpClient = createProxyClient();

      try {
        // Wrap entire operation in timeout to prevent indefinite hangs
        return await Future(() async {
          final request = await httpClient.getUrl(Uri.parse(url));
          final response = await request.close();

          // Check if status code indicates success (2xx or 3xx)
          final isValid =
              response.statusCode >= 200 && response.statusCode < 400;

          // Drain the response to prevent memory leaks
          await response.drain();

          return isValid;
        }).timeout(timeout);
      } finally {
        // Always close the client to free resources
        httpClient.close();
      }
    } catch (e) {
      // Any error (network, timeout, etc.) means the URL is invalid/unreachable
      return false;
    }
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
