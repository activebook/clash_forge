import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';

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
  /// Returns true if the config was successfully switched, false otherwise.
  /// Note: This does NOT wait for URL testing - it only verifies config reload.
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
        return false;
      }

      // Trigger ClashX Meta to reload the config
      final reloadResult = await Process.run('open', ['clash://update-config']);

      if (reloadResult.exitCode != 0) {
        return false;
      }

      // Note: URL test will be triggered by ProfileManager calling testAutoGroupDelay()
      // in the background. We don't do it here to keep profile switching fast.

      // Return success based on config switch only
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Tests the Auto proxy group and returns the delay in milliseconds.
  /// Returns null if the test fails or times out.
  /// Use this to show delay information in the UI.
  ///
  /// Note: This endpoint both TRIGGERS the test AND returns the result!
  Future<int?> testAutoGroupDelay() async {
    // Wait a bit for ClashX Meta to complete the test
    await Future.delayed(const Duration(seconds: 2));

    final httpClient = HttpClient();
    try {
      final request = await httpClient
          .getUrl(
            Uri.parse(
              'http://127.0.0.1:9090/proxies/Auto/delay?timeout=3000&url=http://www.gstatic.com/generate_204',
            ),
          )
          .timeout(const Duration(seconds: 10));

      final response = await request.close();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseBody = await response.transform(utf8.decoder).join();
        debugPrint('Delay test response: $responseBody');

        final jsonData = json.decode(responseBody) as Map<String, dynamic>;
        final delay = jsonData['delay'] as int?;

        debugPrint('Parsed delay: $delay ms');
        return delay;
      } else {
        debugPrint('Delay test failed with status: ${response.statusCode}');
      }

      return null;
    } catch (e) {
      debugPrint('Error getting delay: $e');
      return null;
    } finally {
      httpClient.close();
    }
  }
}
