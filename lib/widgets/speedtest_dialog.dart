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

  String? _peakSpeed;
  String? _avgSpeed;
  String? _latency;
  String? _webrtcStatus;

  @override
  void initState() {
    super.initState();
    _runSpeedTest();
  }

  void _extractMetrics(String line) {
    // Parse speedtest.sh / webrtc output patterns
    final clean = line.replaceAll(RegExp(r'\x1B\[[0-9;]*[mGKHF]'), '');
    if (clean.contains('Max Speed:') || clean.contains('Peak:')) {
      final match = RegExp(
        r'(?:Max Speed|Peak):\s*([0-9.]+\s*[MGK]?B/s)',
        caseSensitive: false,
      ).firstMatch(clean);
      if (match != null) _peakSpeed = match.group(1);
    }
    if (clean.contains('Avg Speed:') || clean.contains('Average:')) {
      final match = RegExp(
        r'(?:Avg Speed|Average):\s*([0-9.]+\s*[MGK]?B/s)',
        caseSensitive: false,
      ).firstMatch(clean);
      if (match != null) _avgSpeed = match.group(1);
    }
    if (clean.contains('Latency:') || clean.contains('Ping:')) {
      final match = RegExp(
        r'(?:Latency|Ping):\s*([0-9.]+\s*ms)',
        caseSensitive: false,
      ).firstMatch(clean);
      if (match != null) _latency = match.group(1);
    }
    if (clean.contains('WebRTC')) {
      if (clean.toLowerCase().contains('leak') ||
          clean.toLowerCase().contains('warning')) {
        _webrtcStatus = 'Leak Detected';
      } else if (clean.toLowerCase().contains('safe') ||
          clean.toLowerCase().contains('protected') ||
          clean.toLowerCase().contains('ok')) {
        _webrtcStatus = 'Secure';
      }
    }
  }

  void _runSpeedTest() {
    setState(() {
      _isRunning = true;
      _hasError = false;
      _outputLines.clear();
      _peakSpeed = null;
      _avgSpeed = null;
      _latency = null;
      _webrtcStatus = null;
    });

    _subscription = _speedTestService.runSpeedTest().listen(
      (line) {
        setState(() {
          _outputLines.add(line);
          _extractMetrics(line);
        });

        // Auto-scroll to bottom
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 150),
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
    final cleanText = _outputLines.join().replaceAll(
      RegExp(r'\x1B\[[0-9;]*[mGKHF]'),
      '',
    );
    Clipboard.setData(ClipboardData(text: cleanText));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
            SizedBox(width: 8),
            Text('Terminal output copied to clipboard'),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Parses ANSI color codes and returns styled text spans.
  List<TextSpan> _parseAnsiText(String text) {
    final spans = <TextSpan>[];
    final ansiPattern = RegExp(r'\x1B\[([0-9;]*)m');

    Color currentColor = const Color(0xFFE2E8F0);
    FontWeight currentWeight = FontWeight.normal;
    int lastIndex = 0;

    for (final match in ansiPattern.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(
          TextSpan(
            text: text.substring(lastIndex, match.start),
            style: TextStyle(color: currentColor, fontWeight: currentWeight),
          ),
        );
      }

      final code = match.group(1);
      if (code != null && code.isNotEmpty) {
        final codes = code.split(';').map((s) => int.tryParse(s) ?? 0).toList();

        for (final c in codes) {
          switch (c) {
            case 0:
              currentColor = const Color(0xFFE2E8F0);
              currentWeight = FontWeight.normal;
              break;
            case 1:
              currentWeight = FontWeight.bold;
              break;
            case 31:
              currentColor = const Color(0xFFF87171); // Rose 400
              break;
            case 32:
              currentColor = const Color(0xFF34D399); // Emerald 400
              break;
            case 33:
              currentColor = const Color(0xFFFBBF24); // Amber 400
              break;
            case 34:
              currentColor = const Color(0xFF60A5FA); // Blue 400
              break;
            case 35:
              currentColor = const Color(0xFFC084FC); // Purple 400
              break;
            case 36:
              currentColor = const Color(0xFF38BDF8); // Sky 400
              break;
            case 37:
              currentColor = Colors.white;
              break;
          }
        }
      }

      lastIndex = match.end;
    }

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

  Widget _buildMetricPill(
    String title,
    String? value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 9.5,
                  color: color.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value ?? '--',
                style: TextStyle(
                  fontSize: 11.5,
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0F172A), // Deep Slate OLED
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF334155)),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.82,
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            // macOS Window Header
            Row(
              children: [
                // Traffic Lights
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF5F56),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFBD2E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Color(0xFF27C93F),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                const Icon(
                  Icons.speed_rounded,
                  color: Color(0xFF6366F1),
                  size: 22,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Network Speed & Security Test',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
                const Spacer(),
                if (_isRunning)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF6366F1),
                      ),
                    ),
                  )
                else
                  IconButton(
                    iconSize: 20,
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: Color(0xFF94A3B8),
                    ),
                    onPressed: _runSpeedTest,
                    tooltip: 'Retest',
                  ),
                const SizedBox(width: 8),
                IconButton(
                  iconSize: 20,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.copy_rounded,
                    color: Color(0xFF94A3B8),
                  ),
                  onPressed: _outputLines.isEmpty ? null : _copyToClipboard,
                  tooltip: 'Copy output',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Live Telemetry Bar
            if (_peakSpeed != null ||
                _avgSpeed != null ||
                _latency != null ||
                _webrtcStatus != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    if (_peakSpeed != null)
                      _buildMetricPill(
                        'PEAK SPEED',
                        _peakSpeed,
                        Icons.bolt_rounded,
                        const Color(0xFF10B981),
                      ),
                    if (_avgSpeed != null)
                      _buildMetricPill(
                        'AVG SPEED',
                        _avgSpeed,
                        Icons.trending_up_rounded,
                        const Color(0xFF0EA5E9),
                      ),
                    if (_latency != null)
                      _buildMetricPill(
                        'LATENCY',
                        _latency,
                        Icons.timer_outlined,
                        const Color(0xFF8B5CF6),
                      ),
                    if (_webrtcStatus != null)
                      _buildMetricPill(
                        'WEBRTC',
                        _webrtcStatus,
                        Icons.shield_outlined,
                        _webrtcStatus == 'Secure'
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                      ),
                  ],
                ),
              ),

            // Terminal Console
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF020617), // Black OLED Slate
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child:
                    _outputLines.isEmpty
                        ? const Center(
                          child: Text(
                            'Initializing speed test engine...',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 13,
                              fontFamily: 'monospace',
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
                                fontSize: 12.5,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ),
              ),
            ),

            // Status bar
            if (_isRunning || _hasError)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    if (_isRunning) ...[
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.8,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF34D399),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Running speed test and WebRTC leak audit... (~30 seconds)',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                    if (_hasError) ...[
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Color(0xFFF87171),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Test encountered an issue. See output for diagnostics.',
                        style: TextStyle(
                          color: Color(0xFFF87171),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
