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

      return reloadResult.exitCode == 0;
    } catch (e) {
      return false;
    }
  }
}
