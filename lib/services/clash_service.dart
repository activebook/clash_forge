import 'dart:io';

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
  /// Returns true if successful, false otherwise.
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

      // Give ClashX Meta a moment to reload the config
      await Future.delayed(const Duration(milliseconds: 500));

      // Trigger URL test for the Auto proxy group to select the fastest node
      final httpClient = HttpClient();
      try {
        final request = await httpClient
            .getUrl(
              Uri.parse(
                'http://127.0.0.1:9090/proxies/Auto/delay?timeout=3000&url=http://www.gstatic.com/generate_204',
              ),
            )
            .timeout(const Duration(seconds: 3));

        final response = await request.close();

        // The request itself triggers the test; we don't need to check the response
        // but we'll return true if it completes successfully
        final isSuccess =
            response.statusCode >= 200 && response.statusCode < 300;

        // Drain the response to prevent memory leaks
        await response.drain();

        return isSuccess;
      } catch (e) {
        // Even if the URL test fails, the profile was still switched successfully
        // So we return true here
        return true;
      } finally {
        httpClient.close();
      }
    } catch (e) {
      return false;
    }
  }
}
