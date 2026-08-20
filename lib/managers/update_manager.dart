import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class UpdateInfo {
  final String version;
  final String downloadUrl;
  final String? shaUrl;
  final String fileName;
  final int? size;

  UpdateInfo({
    required this.version,
    required this.downloadUrl,
    this.shaUrl,
    required this.fileName,
    this.size,
  });
}

class UpdateManager extends ChangeNotifier {
  static const String _githubRepo = 'activebook/clash_forge';
  static const String _releasesApiUrl =
      'https://api.github.com/repos/$_githubRepo/releases/latest';

  String _currentVersion = '';
  UpdateInfo? _availableUpdate;
  bool _isChecking = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _downloadStatus = '';
  String? _errorMessage;

  String get currentVersion => _currentVersion;
  UpdateInfo? get availableUpdate => _availableUpdate;
  bool get hasUpdate => _availableUpdate != null;
  bool get isChecking => _isChecking;
  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;
  String get downloadStatus => _downloadStatus;
  String? get errorMessage => _errorMessage;

  void init(String version) {
    _currentVersion = version.replaceAll(RegExp(r'^v'), '').split('+').first;
    // Perform a silent background update check upon startup
    checkForUpdates(silent: true);
  }

  /// Compares two Semantic Versioning strings (e.g. "2.1.0" > "2.0.0").
  static bool isNewerVersion(String remote, String current) {
    try {
      final cleanRemote =
          remote.replaceAll(RegExp(r'^v'), '').split('+').first.trim();
      final cleanCurrent =
          current.replaceAll(RegExp(r'^v'), '').split('+').first.trim();

      if (cleanRemote == cleanCurrent) return false;

      final rParts =
          cleanRemote.split('.').map((p) => int.tryParse(p) ?? 0).toList();
      final cParts =
          cleanCurrent.split('.').map((p) => int.tryParse(p) ?? 0).toList();

      while (rParts.length < 3) {
        rParts.add(0);
      }
      while (cParts.length < 3) {
        cParts.add(0);
      }

      for (var i = 0; i < 3; i++) {
        if (rParts[i] > cParts[i]) return true;
        if (rParts[i] < cParts[i]) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Checks GitHub Releases API for latest version.
  Future<bool> checkForUpdates({bool silent = false}) async {
    if (_isChecking || _isDownloading) return false;

    _isChecking = true;
    _errorMessage = null;
    if (!silent) notifyListeners();

    try {
      final client = http.Client();
      final response = await client
          .get(
            Uri.parse(_releasesApiUrl),
            headers: {'Accept': 'application/vnd.github.v3+json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String tagName = data['tag_name'] as String? ?? '';
        final String remoteVer = tagName.replaceAll(RegExp(r'^v'), '');

        if (isNewerVersion(remoteVer, _currentVersion)) {
          final List<dynamic> assets = data['assets'] as List<dynamic>? ?? [];

          // Find universal zip asset
          String? downloadUrl;
          String? fileName;
          int? assetSize;

          for (final asset in assets) {
            final name = asset['name'] as String? ?? '';
            if (name.endsWith('-macOS-Universal.zip') ||
                (name.endsWith('.zip') && name.contains('macos'))) {
              downloadUrl = asset['browser_download_url'] as String?;
              fileName = name;
              assetSize = asset['size'] as int?;
              break;
            }
          }

          // Fallback to any zip if universal not found
          if (downloadUrl == null) {
            for (final asset in assets) {
              final name = asset['name'] as String? ?? '';
              if (name.endsWith('.zip')) {
                downloadUrl = asset['browser_download_url'] as String?;
                fileName = name;
                assetSize = asset['size'] as int?;
                break;
              }
            }
          }

          // Find SHA256SUMS.txt
          String? shaUrl;
          for (final asset in assets) {
            final name = asset['name'] as String? ?? '';
            if (name == 'SHA256SUMS.txt') {
              shaUrl = asset['browser_download_url'] as String?;
              break;
            }
          }

          if (downloadUrl != null && fileName != null) {
            _availableUpdate = UpdateInfo(
              version: tagName.startsWith('v') ? tagName : 'v$tagName',
              downloadUrl: downloadUrl,
              shaUrl: shaUrl,
              fileName: fileName,
              size: assetSize,
            );
            _isChecking = false;
            notifyListeners();
            return true;
          }
        }
      }
      _availableUpdate = null;
    } catch (e) {
      if (!silent) {
        _errorMessage = 'Failed to check for updates: $e';
      }
    } finally {
      _isChecking = false;
      notifyListeners();
    }
    return false;
  }

  /// Parses SHA256 checksum string for a specific file name.
  static String? parseSha256ForFile(String shaContent, String targetFileName) {
    final lines = shaContent.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final parts = trimmed.split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        final hash = parts[0].trim();
        final name = parts[1].trim();
        if (name == targetFileName || name.endsWith('/$targetFileName')) {
          return hash.toLowerCase();
        }
      }
    }
    return null;
  }

  /// Downloads, verifies, extracts, and initiates the hot-swap relaunch.
  Future<void> downloadAndInstallUpdate() async {
    final update = _availableUpdate;
    if (update == null || _isDownloading) return;

    _isDownloading = true;
    _downloadProgress = 0.0;
    _downloadStatus = 'Initializing download...';
    _errorMessage = null;
    notifyListeners();

    final client = http.Client();
    try {
      // 1. Prepare temporary update directory
      final tempDir = await Directory.systemTemp.createTemp(
        'clash_forge_update_',
      );
      final zipFilePath = path.join(tempDir.path, update.fileName);
      final zipFile = File(zipFilePath);

      // 2. Fetch expected SHA256 if available
      String? expectedSha;
      if (update.shaUrl != null) {
        _downloadStatus = 'Fetching security checksums...';
        notifyListeners();
        try {
          final shaResponse = await client
              .get(Uri.parse(update.shaUrl!))
              .timeout(const Duration(seconds: 10));
          if (shaResponse.statusCode == 200) {
            expectedSha = parseSha256ForFile(shaResponse.body, update.fileName);
          }
        } catch (_) {}
      }

      // 3. Stream download the zip file
      _downloadStatus = 'Downloading update package...';
      notifyListeners();

      final request = http.Request('GET', Uri.parse(update.downloadUrl));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception('Server returned HTTP status ${response.statusCode}');
      }

      final totalBytes = response.contentLength ?? update.size ?? 0;
      int receivedBytes = 0;

      final sink = zipFile.openWrite();
      await response.stream.listen((chunk) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          _downloadProgress = (receivedBytes / totalBytes).clamp(0.0, 1.0);
          final mbReceived = (receivedBytes / (1024 * 1024)).toStringAsFixed(1);
          final mbTotal = (totalBytes / (1024 * 1024)).toStringAsFixed(1);
          _downloadStatus =
              'Downloading: $mbReceived MB / $mbTotal MB (${(_downloadProgress * 100).toInt()}%)';
        } else {
          final mbReceived = (receivedBytes / (1024 * 1024)).toStringAsFixed(1);
          _downloadStatus = 'Downloading: $mbReceived MB';
        }
        notifyListeners();
      }).asFuture();

      await sink.flush();
      await sink.close();

      // 4. Verify cryptographic hash
      if (expectedSha != null) {
        _downloadStatus = 'Verifying cryptographic checksum...';
        notifyListeners();

        final result = await Process.run('shasum', ['-a', '256', zipFilePath]);
        if (result.exitCode == 0) {
          final computedHash =
              (result.stdout as String)
                  .split(RegExp(r'\s+'))
                  .first
                  .toLowerCase()
                  .trim();
          if (computedHash != expectedSha) {
            throw Exception(
              'Checksum verification failed. Expected $expectedSha but got $computedHash',
            );
          }
        }
      }

      // 5. Extract using native macOS ditto
      _downloadStatus = 'Extracting application bundle...';
      notifyListeners();

      final stagingDir = Directory(path.join(tempDir.path, 'staged'));
      await stagingDir.create(recursive: true);

      final extractResult = await Process.run('ditto', [
        '-x',
        '-k',
        zipFilePath,
        stagingDir.path,
      ]);
      if (extractResult.exitCode != 0) {
        throw Exception('Failed to extract archive: ${extractResult.stderr}');
      }

      // Locate the .app directory inside staging
      String? stagedAppPath;
      final entities = stagingDir.listSync(recursive: false);
      for (final entity in entities) {
        if (entity is Directory && entity.path.endsWith('.app')) {
          stagedAppPath = entity.path;
          break;
        }
      }

      if (stagedAppPath == null) {
        throw Exception(
          'Application bundle (.app) not found inside update package.',
        );
      }

      // Determine current running app bundle path
      final currentAppPath = _resolveCurrentAppBundlePath();

      // 6. Launch detached hot-swap helper script and terminate
      _downloadStatus = 'Applying update and restarting...';
      notifyListeners();

      await _executeHotSwapAndRelaunch(
        currentAppPath: currentAppPath,
        stagedAppPath: stagedAppPath,
        cleanupDir: tempDir.path,
      );
    } catch (e) {
      _isDownloading = false;
      _errorMessage = 'Update installation failed: $e';
      notifyListeners();
    }
  }

  /// Resolves the file system path of the currently executing macOS .app bundle.
  String _resolveCurrentAppBundlePath() {
    final execPath = Platform.resolvedExecutable;
    // On macOS, executable is at: /Applications/Clash Forge.app/Contents/MacOS/Clash Forge
    if (execPath.contains('.app/Contents/MacOS/')) {
      final parts = execPath.split('.app/Contents/MacOS/');
      return '${parts[0]}.app';
    }
    return '/Applications/Clash Forge.app';
  }

  /// Writes and invokes a detached bash script that waits for current PID to exit,
  /// swaps the .app bundle, strips quarantine, and relaunches the new binary.
  Future<void> _executeHotSwapAndRelaunch({
    required String currentAppPath,
    required String stagedAppPath,
    required String cleanupDir,
  }) async {
    final currentPid = pid;
    final scriptContent = '''
#!/bin/bash
TARGET_PID=$currentPid
TARGET_APP="$currentAppPath"
STAGED_APP="$stagedAppPath"
CLEANUP_DIR="$cleanupDir"

# Wait for current process to terminate
while kill -0 \$TARGET_PID 2>/dev/null; do
    sleep 0.1
done

# Perform atomic replacement
rm -rf "\$TARGET_APP"
mv "\$STAGED_APP" "\$TARGET_APP"

# Strip quarantine flag
xattr -dr com.apple.quarantine "\$TARGET_APP" 2>/dev/null || true

# Relaunch the new application
open "\$TARGET_APP"

# Cleanup temporary files
rm -rf "\$CLEANUP_DIR"
rm -- "\$0"
''';

    final scriptFile = File(
      path.join(Directory.systemTemp.path, 'clash_forge_updater.sh'),
    );
    await scriptFile.writeAsString(scriptContent);
    await Process.run('chmod', ['+x', scriptFile.path]);

    // Launch detached process
    await Process.start('/bin/bash', [
      scriptFile.path,
    ], mode: ProcessStartMode.detached);

    // Gracefully exit current process
    exit(0);
  }
}
