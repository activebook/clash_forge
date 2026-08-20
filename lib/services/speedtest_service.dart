import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as path;

/// Service that executes the speedtest.sh script and streams its output.
class SpeedTestService {
  Process? _currentProcess;
  File? _tempScriptFile;
  File? _tempWebrtcFile;

  /// Runs the speedtest script and returns a stream of output lines.
  Stream<String> runSpeedTest() async* {
    // Cancel any existing process
    cancel();

    try {
      // Load the bundled script assets
      final scriptContent = await rootBundle.loadString(
        'assets/scripts/speedtest.sh',
      );
      String? webrtcContent;
      try {
        webrtcContent = await rootBundle.loadString(
          'assets/scripts/webrtc_check.py',
        );
      } catch (_) {}

      // Create a temporary file to execute the script
      final tempDir = Directory.systemTemp;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _tempScriptFile = File(
        path.join(tempDir.path, 'speedtest_$timestamp.sh'),
      );

      // Write script content to temp file
      await _tempScriptFile!.writeAsString(scriptContent);
      await Process.run('chmod', ['+x', _tempScriptFile!.path]);

      // Write webrtc_check.py to temp dir if available
      if (webrtcContent != null && webrtcContent.isNotEmpty) {
        _tempWebrtcFile = File(path.join(tempDir.path, 'webrtc_check.py'));
        await _tempWebrtcFile!.writeAsString(webrtcContent);
        await Process.run('chmod', ['+x', _tempWebrtcFile!.path]);
      }

      // Start the bash process
      _currentProcess = await Process.start('bash', [
        _tempScriptFile!.path,
      ], workingDirectory: tempDir.path);

      // Stream stderr (where the script outputs everything)
      await for (final output in _currentProcess!.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        yield '$output\n';
      }

      // Also capture stdout just in case
      await for (final output in _currentProcess!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        yield '$output\n';
      }

      // Wait for process to complete
      final exitCode = await _currentProcess!.exitCode;
      if (exitCode != 0 && exitCode != 143) {
        // 143 is SIGTERM
        yield '\n⚠️ Process exited with code $exitCode\n';
      }
    } catch (e) {
      yield '\n❌ Error running speedtest: $e\n';
    } finally {
      _cleanup();
    }
  }

  /// Cancels the running speedtest process.
  void cancel() {
    _currentProcess?.kill(ProcessSignal.sigterm);
    _currentProcess = null;
  }

  void _cleanup() {
    if (_tempScriptFile != null) {
      _tempScriptFile!.exists().then((exists) async {
        if (exists) {
          try {
            await _tempScriptFile!.delete();
          } catch (_) {}
        }
      });
      _tempScriptFile = null;
    }
    if (_tempWebrtcFile != null) {
      _tempWebrtcFile!.exists().then((exists) async {
        if (exists) {
          try {
            await _tempWebrtcFile!.delete();
          } catch (_) {}
        }
      });
      _tempWebrtcFile = null;
    }
  }

  /// Dispose method for proper cleanup
  void dispose() {
    cancel();
    _cleanup();
  }
}
