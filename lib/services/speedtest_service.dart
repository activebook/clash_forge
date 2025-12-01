import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as path;

/// Service that executes the speedtest.sh script and streams its output.
class SpeedTestService {
  /// Runs the speedtest script and returns a stream of output lines.
  ///
  /// The script outputs to stderr, so we capture both stderr and stdout.
  /// Returns a stream that emits each line of output as it becomes available.
  Stream<String> runSpeedTest() async* {
    File? tempScriptFile;

    try {
      // Load the bundled script asset
      final scriptContent = await rootBundle.loadString(
        'assets/scripts/speedtest.sh',
      );

      // Create a temporary file to execute the script
      final tempDir = Directory.systemTemp;
      tempScriptFile = File(
        path.join(
          tempDir.path,
          'speedtest_${DateTime.now().millisecondsSinceEpoch}.sh',
        ),
      );

      // Write script content to temp file
      await tempScriptFile.writeAsString(scriptContent);

      // Make the script executable
      await Process.run('chmod', ['+x', tempScriptFile.path]);

      // Start the bash process
      final process = await Process.start('bash', [
        tempScriptFile.path,
      ], workingDirectory: tempDir.path);

      // The script outputs to stderr (using '>&2' redirects)
      // We need to capture both stderr and stdout

      // Stream stderr (where the script outputs everything)
      await for (final output in process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        yield '$output\n';
      }

      // Also capture stdout just in case
      await for (final output in process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        yield '$output\n';
      }

      // Wait for process to complete
      final exitCode = await process.exitCode;
      if (exitCode != 0) {
        yield '\n⚠️ Process exited with code $exitCode\n';
      }
    } catch (e) {
      yield '\n❌ Error running speedtest: $e\n';
    } finally {
      // Clean up temporary script file
      if (tempScriptFile != null && await tempScriptFile.exists()) {
        try {
          await tempScriptFile.delete();
        } catch (e) {
          // Ignore cleanup errors
        }
      }
    }
  }

  /// Cancels the running speedtest process.
  /// Note: This is a simple implementation. For production, you'd want to
  /// track the Process object and kill it explicitly.
  void cancel() {
    // Implementation note: To properly support cancellation, we'd need to
    // refactor this to return a Process object or use a StreamController
    // with proper cleanup.
  }
}
