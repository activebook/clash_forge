import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/speedtest_service.dart';

/// Modal dialog that displays real-time speedtest output.
///
/// Executes the speedtest.sh script and streams its output with ANSI color support.
class SpeedTestDialog extends StatefulWidget {
  const SpeedTestDialog({super.key});

  @override
  State<SpeedTestDialog> createState() => _SpeedTestDialogState();
}

class _SpeedTestDialogState extends State<SpeedTestDialog> {
  final SpeedTestService _speedTestService = SpeedTestService();
  final List<String> _outputLines = [];
  final ScrollController _scrollController = ScrollController();
  bool _isRunning = true;
  bool _hasError = false;
  StreamSubscription<String>? _subscription;

  @override
  void initState() {
    super.initState();
    _runSpeedTest();
  }

  void _runSpeedTest() {
    setState(() {
      _isRunning = true;
      _hasError = false;
      _outputLines.clear();
    });

    _subscription = _speedTestService.runSpeedTest().listen(
      (line) {
        setState(() {
          _outputLines.add(line);
        });

        // Auto-scroll to bottom
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      },
      onDone: () {
        setState(() {
          _isRunning = false;
        });
      },
      onError: (error) {
        setState(() {
          _hasError = true;
          _isRunning = false;
          _outputLines.add('\n❌ Error: $error\n');
        });
      },
    );
  }

  @override
  void dispose() {
    _speedTestService.dispose();
    _subscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _copyToClipboard() {
    // Strip ANSI codes for clipboard
    final cleanText = _outputLines.join().replaceAll(
      RegExp(r'\x1B\[[0-9;]*[mGKHF]'),
      '',
    );
    Clipboard.setData(ClipboardData(text: cleanText));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Output copied to clipboard'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Parses ANSI color codes and returns styled text spans.
  List<TextSpan> _parseAnsiText(String text) {
    final spans = <TextSpan>[];
    final ansiPattern = RegExp(r'\x1B\[([0-9;]*)m');

    Color currentColor = Colors.white;
    FontWeight currentWeight = FontWeight.normal;
    int lastIndex = 0;

    for (final match in ansiPattern.allMatches(text)) {
      // Add text before this ANSI code
      if (match.start > lastIndex) {
        spans.add(
          TextSpan(
            text: text.substring(lastIndex, match.start),
            style: TextStyle(color: currentColor, fontWeight: currentWeight),
          ),
        );
      }

      // Parse ANSI code
      final code = match.group(1);
      if (code != null && code.isNotEmpty) {
        final codes = code.split(';').map((s) => int.tryParse(s) ?? 0).toList();

        for (final c in codes) {
          switch (c) {
            case 0: // Reset
              currentColor = Colors.white;
              currentWeight = FontWeight.normal;
              break;
            case 1: // Bold
              currentWeight = FontWeight.bold;
              break;
            case 31: // Red
              currentColor = const Color(0xFFEF5350);
              break;
            case 32: // Green
              currentColor = const Color(0xFF66BB6A);
              break;
            case 33: // Yellow
              currentColor = const Color(0xFFFFEE58);
              break;
            case 34: // Blue
              currentColor = const Color(0xFF42A5F5);
              break;
            case 35: // Magenta/Purple
              currentColor = const Color(0xFFAB47BC);
              break;
            case 36: // Cyan
              currentColor = const Color(0xFF26C6DA);
              break;
            case 37: // White
              currentColor = Colors.white;
              break;
          }
        }
      }

      lastIndex = match.end;
    }

    // Add remaining text
    if (lastIndex < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastIndex),
          style: TextStyle(color: currentColor, fontWeight: currentWeight),
        ),
      );
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor:
          isDark ? const Color(0xFF1E1E1E) : const Color(0xFF263238),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.75,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.speed, color: Color(0xFF42A5F5), size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Network Speed Test',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                if (_isRunning)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF42A5F5),
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.content_copy, color: Colors.white70),
                  onPressed: _outputLines.isEmpty ? null : _copyToClipboard,
                  tooltip: 'Copy to clipboard',
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close',
                ),
              ],
            ),
            const Divider(color: Colors.white24),
            const SizedBox(height: 8),

            // Output area
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child:
                    _outputLines.isEmpty
                        ? const Center(
                          child: Text(
                            'Initializing speed test...',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        )
                        : SingleChildScrollView(
                          controller: _scrollController,
                          child: SelectableText.rich(
                            TextSpan(
                              children: _parseAnsiText(_outputLines.join()),
                              style: const TextStyle(
                                fontFamily: 'Courier',
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
              ),
            ),

            // Status bar
            if (_isRunning || _hasError)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    if (_isRunning)
                      const Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF66BB6A),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Running speed test... (~30 seconds)',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    if (_hasError)
                      const Row(
                        children: [
                          Icon(Icons.error, color: Color(0xFFEF5350), size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Test failed. Check output for details.',
                            style: TextStyle(
                              color: Color(0xFFEF5350),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
