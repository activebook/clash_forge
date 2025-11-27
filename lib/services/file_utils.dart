import 'dart:io';

/// Utility functions for file path validation and detection
class FileUtils {
  /// Check if a string is a local file path (Unix/Mac absolute path or Windows path)
  static bool isLocalFilePath(String input) {
    final trimmed = input.trim();

    // Unix/Mac absolute path
    if (trimmed.startsWith('/')) {
      return true;
    }

    // Windows path like C:\ or C:/
    if (trimmed.length >= 3 &&
        trimmed[1] == ':' &&
        (trimmed[2] == '\\' || trimmed[2] == '/')) {
      return true;
    }

    return false;
  }

  /// Check if a local file path actually exists
  static bool fileExists(String filePath) {
    try {
      final file = File(filePath.trim());
      return file.existsSync();
    } catch (_) {
      return false;
    }
  }

  /// Check if input is a valid file path and the file exists
  static bool isValidLocalFile(String input) {
    return isLocalFilePath(input) && fileExists(input);
  }
}
