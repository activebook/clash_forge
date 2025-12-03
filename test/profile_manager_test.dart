import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:clash_forge/managers/profile_manager.dart';
import 'package:path/path.dart' as path;

void main() {
  group('ProfileManager Tests', () {
    late ProfileManager profileManager;
    late Directory tempDir;

    setUp(() async {
      profileManager = ProfileManager();
      tempDir = await Directory.systemTemp.createTemp('profile_test_');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('loadProfiles should list yaml files', () async {
      // Create dummy yaml files
      await File(path.join(tempDir.path, 'config1.yaml')).create();
      await File(path.join(tempDir.path, 'config2.yml')).create();
      await File(path.join(tempDir.path, 'other.txt')).create();

      await profileManager.loadProfiles(tempDir.path);

      expect(profileManager.profiles.length, 2);
      expect(profileManager.profiles, contains('config1'));
      expect(profileManager.profiles, contains('config2'));
    });

    test('loadProfiles should handle empty directory', () async {
      await profileManager.loadProfiles(tempDir.path);
      expect(profileManager.profiles, isEmpty);
    });

    test('loadProfiles should handle non-existent directory', () async {
      await profileManager.loadProfiles('/non/existent/path');
      expect(profileManager.profiles, isEmpty);
    });
  });
}
