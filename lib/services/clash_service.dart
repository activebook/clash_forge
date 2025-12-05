import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'http_client.dart';

/// Service that handles ClashX Meta profile switching.
class ClashService {
  /// Gets the name of the currently selected profile in ClashX Meta.
  Future<String?> getCurrentProfile() async {
    try {
      final result = await Process.run('defaults', [
        'read',
        'com.metacubex.ClashX.meta',
        'selectConfigName',
      ]);

      if (result.exitCode == 0) {
        return result.stdout.toString().trim();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Sets the active profile in ClashX Meta.
  /// Returns true if the config name was successfully written, false otherwise.
  ///
  /// Note: This ONLY writes the config name to defaults.
  /// You MUST call restartClashXMeta() afterwards for the change to take effect.
  Future<bool> setActiveProfile(String profileName) async {
    try {
      // Write the new profile name to defaults
      final writeResult = await Process.run('defaults', [
        'write',
        'com.metacubex.ClashX.meta',
        'selectConfigName',
        profileName,
      ]);

      if (writeResult.exitCode != 0) {
        debugPrint('Failed to write config: ${writeResult.stderr}');
        return false;
      }

      debugPrint('Config name written: $profileName');

      // the core issue: open clash://update-config doesn't apply the new profile; a full app restart is required.
      // so we need to restart the app
      return true;
    } catch (e) {
      debugPrint('Error writing config: $e');
      return false;
    }
  }

  /// Restarts ClashX Meta app and waits for it to be ready.
  /// Call this after setActiveProfile for the change to take effect.
  ///
  /// Returns true if restart was successful and API is responding.
  Future<bool> restartClashXMeta() async {
    try {
      debugPrint('Restarting ClashX Meta...');

      // 1. Kill existing process
      final killResult = await Process.run('pkill', ['ClashX Meta']);
      debugPrint('Kill result: ${killResult.exitCode}');

      // 2. Wait a moment for clean shutdown
      await Future.delayed(const Duration(milliseconds: 800));

      // 3. Reopen the app
      final openResult = await Process.run('open', ['-a', 'ClashX Meta']);
      if (openResult.exitCode != 0) {
        debugPrint('Failed to open ClashX Meta: ${openResult.stderr}');
        return false;
      }

      // 4. Wait for API to become available
      final ready = await _waitForApiReady(
        timeout: const Duration(seconds: 15),
      );
      if (ready) {
        debugPrint('ClashX Meta API is ready');
      } else {
        debugPrint('ClashX Meta API did not become ready in time');
      }
      return ready;
    } catch (e) {
      debugPrint('Error restarting ClashX Meta: $e');
      return false;
    }
  }

  /// Polls the ClashX API until it responds or times out.
  Future<bool> _waitForApiReady({required Duration timeout}) async {
    final stopwatch = Stopwatch()..start();

    while (stopwatch.elapsed < timeout) {
      try {
        final client = HttpClient();
        try {
          final request = await client
              .getUrl(Uri.parse('http://127.0.0.1:9090/version'))
              .timeout(const Duration(seconds: 2));
          final response = await request.close();

          if (response.statusCode == 200) {
            return true; // API is ready
          }
        } finally {
          client.close();
        }
      } catch (_) {
        // Not ready yet, keep polling
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }

    return false;
  }

  /// Tests the Auto proxy group and returns the delay in milliseconds.
  /// Returns null if the test fails or times out.
  ///
  /// Strategy:
  /// 1. First, try ClashX Meta's built-in delay API (fast path)
  /// 2. If API returns error, fallback to manual delay measurement via proxy
  Future<int?> testAutoGroupDelay() async {
    // Wait a bit for ClashX Meta to stabilize after config reload
    await Future.delayed(const Duration(seconds: 2));

    // Try ClashX Meta API first
    final apiResult = await _testDelayViaClashApi();
    if (apiResult != null) {
      debugPrint('Delay obtained via ClashX API: $apiResult ms');
      return apiResult;
    }

    // Fallback: Manual delay measurement through proxy
    debugPrint('ClashX API failed, falling back to manual delay test...');
    final manualResult = await _testDelayManually();
    if (manualResult != null) {
      debugPrint('Delay obtained via manual test: $manualResult ms');
    }
    return manualResult;
  }

  /// Attempts to get delay from ClashX Meta's built-in API.
  /// Returns null if the API returns an error or fails.
  Future<int?> _testDelayViaClashApi() async {
    final httpClient = HttpClient();
    try {
      final request = await httpClient
          .getUrl(
            Uri.parse(
              'http://127.0.0.1:9090/proxies/Auto/delay?timeout=3000&url=http://www.gstatic.com/generate_204',
            ),
          )
          .timeout(const Duration(seconds: 5));

      final response = await request.close();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseBody = await response.transform(utf8.decoder).join();
        debugPrint('ClashX API response: $responseBody');

        final jsonData = json.decode(responseBody) as Map<String, dynamic>;

        // Check for error message - ClashX sometimes returns this instead of delay
        if (jsonData.containsKey('message')) {
          debugPrint('ClashX API returned error: ${jsonData['message']}');
          return null;
        }

        return jsonData['delay'] as int?;
      }
      return null;
    } catch (e) {
      debugPrint('ClashX API error: $e');
      return null;
    } finally {
      httpClient.close();
    }
  }

  /// Manually measures delay by making a request through the proxy.
  /// This is the fallback when ClashX API fails.
  ///
  /// IMPORTANT: This uses ProxyService to route through the system proxy.
  /// The test URL must be an HTTP URL to ensure it goes through httpProxy.
  Future<int?> _testDelayManually() async {
    const testUrl = 'http://www.google.com/generate_204';
    const timeout = Duration(seconds: 3);

    try {
      final proxyService = ProxyService();
      final settings = await proxyService.getSystemProxySettings();

      // Debug: Log proxy settings to verify configuration
      debugPrint('Manual delay test - Proxy settings: $settings');

      // Check if proxy is actually configured
      final httpProxy = settings['httpProxy'];
      if (httpProxy == null || httpProxy.toString().isEmpty) {
        debugPrint('Manual delay test - No HTTP proxy configured, skipping');
        return null;
      }

      debugPrint('Manual delay test - Using proxy: $httpProxy');

      // Create HTTP client with explicit HTTP proxy
      final httpClient = HttpClient();
      httpClient.findProxy = (uri) => 'PROXY $httpProxy';

      try {
        final stopwatch = Stopwatch()..start();

        final statusCode = await Future(() async {
          final request = await httpClient.getUrl(Uri.parse(testUrl));
          final response = await request.close();

          // Drain response body
          await response.drain();

          debugPrint(
            'Manual delay test - Response status: ${response.statusCode}',
          );
          return response.statusCode;
        }).timeout(timeout);

        stopwatch.stop();

        // Only 204 No Content indicates success for generate_204 endpoint
        // 502 Bad Gateway, 503 Service Unavailable, etc. indicate proxy failure
        if (statusCode == 204) {
          debugPrint(
            'Manual delay test - Success: ${stopwatch.elapsedMilliseconds} ms',
          );
          return stopwatch.elapsedMilliseconds;
        }

        debugPrint('Manual delay test - Failed with status: $statusCode');
        return null;
      } finally {
        httpClient.close();
      }
    } catch (e) {
      debugPrint('Manual delay test error: $e');
      return null;
    }
  }
}
