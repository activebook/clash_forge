import 'package:flutter_test/flutter_test.dart';
import 'package:clash_forge/managers/update_manager.dart';

void main() {
  group('UpdateManager SemVer Comparison Tests', () {
    test('Correctly identifies newer minor versions', () {
      expect(UpdateManager.isNewerVersion('2.1.0', '2.0.0'), isTrue);
      expect(UpdateManager.isNewerVersion('v2.1.0', '2.0.0'), isTrue);
      expect(UpdateManager.isNewerVersion('2.1.0', 'v2.0.0'), isTrue);
    });

    test('Correctly identifies newer patch versions', () {
      expect(UpdateManager.isNewerVersion('2.0.1', '2.0.0'), isTrue);
      expect(UpdateManager.isNewerVersion('2.0.10', '2.0.9'), isTrue);
    });

    test('Correctly identifies newer major versions', () {
      expect(UpdateManager.isNewerVersion('3.0.0', '2.9.9'), isTrue);
      expect(UpdateManager.isNewerVersion('10.0.0', '9.9.9'), isTrue);
    });

    test('Returns false for identical or older versions', () {
      expect(UpdateManager.isNewerVersion('2.0.0', '2.0.0'), isFalse);
      expect(UpdateManager.isNewerVersion('v2.0.0', '2.0.0'), isFalse);
      expect(UpdateManager.isNewerVersion('1.9.9', '2.0.0'), isFalse);
      expect(UpdateManager.isNewerVersion('2.0.0', '2.1.0'), isFalse);
    });

    test('Handles build number metadata gracefully', () {
      expect(UpdateManager.isNewerVersion('2.1.0+2', '2.0.0+1'), isTrue);
      expect(UpdateManager.isNewerVersion('2.0.0+2', '2.0.0+1'), isFalse);
    });
  });

  group('UpdateManager SHA256 Parser Tests', () {
    test('Parses SHA256 hash from standard shasum output', () {
      const shaContent = '''
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  Clash-Forge-v2.0.0-macOS-Universal.dmg
a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3  Clash-Forge-v2.0.0-macOS-Universal.zip
''';

      final zipHash = UpdateManager.parseSha256ForFile(
        shaContent,
        'Clash-Forge-v2.0.0-macOS-Universal.zip',
      );
      expect(
        zipHash,
        equals(
          'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3',
        ),
      );

      final dmgHash = UpdateManager.parseSha256ForFile(
        shaContent,
        'Clash-Forge-v2.0.0-macOS-Universal.dmg',
      );
      expect(
        dmgHash,
        equals(
          'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        ),
      );
    });

    test('Returns null if filename not present in checksum file', () {
      const shaContent = 'abc123def456  other-file.zip\n';
      final hash = UpdateManager.parseSha256ForFile(
        shaContent,
        'missing-file.zip',
      );
      expect(hash, isNull);
    });
  });
}
