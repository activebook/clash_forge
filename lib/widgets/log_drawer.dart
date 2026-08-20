import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/loginfo.dart';

/// Widget that displays the log drawer with filtered logs and copy capability.
class LogDrawer extends StatefulWidget {
  final List<LogInfo> logEntries;
  final int? hoveredLogIndex;
  final VoidCallback onClearLogs;
  final Function(int?) onHoverChange;
  final GlobalKey<ScaffoldState> scaffoldKey;

  const LogDrawer({
    super.key,
    required this.logEntries,
    required this.hoveredLogIndex,
    required this.onClearLogs,
    required this.onHoverChange,
    required this.scaffoldKey,
  });

  @override
  State<LogDrawer> createState() => _LogDrawerState();
}

class _LogDrawerState extends State<LogDrawer> {
  String _selectedFilter = 'All';

  List<LogInfo> get _filteredEntries {
    if (_selectedFilter == 'Errors') {
      return widget.logEntries.where((l) => l.level == LogLevel.error).toList();
    } else if (_selectedFilter == 'Warnings') {
      return widget.logEntries
          .where((l) => l.level == LogLevel.warning)
          .toList();
    } else if (_selectedFilter == 'Success') {
      return widget.logEntries
          .where((l) => l.level == LogLevel.success)
          .toList();
    } else if (_selectedFilter == 'Info') {
      return widget.logEntries
          .where(
            (l) =>
                l.level == LogLevel.info ||
                l.level == LogLevel.start ||
                l.level == LogLevel.file,
          )
          .toList();
    }
    return widget.logEntries;
  }

  void _copyAllLogs(BuildContext context) {
    if (widget.logEntries.isEmpty) return;
    final buffer = StringBuffer();
    for (final log in widget.logEntries) {
      buffer.writeln(
        '[${log.timestamp}] [${log.level.name.toUpperCase()}] ${log.message}',
      );
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
            SizedBox(width: 8),
            Text('All logs copied to clipboard'),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildLevelIcon(LogLevel level) {
    switch (level) {
      case LogLevel.error:
        return const Icon(
          Icons.error_rounded,
          color: Color(0xFFF87171),
          size: 18,
        );
      case LogLevel.warning:
        return const Icon(
          Icons.warning_amber_rounded,
          color: Color(0xFFFBBF24),
          size: 18,
        );
      case LogLevel.info:
        return const Icon(
          Icons.info_rounded,
          color: Color(0xFF38BDF8),
          size: 18,
        );
      case LogLevel.debug:
        return const Icon(
          Icons.bug_report_rounded,
          color: Color(0xFF94A3B8),
          size: 18,
        );
      case LogLevel.success:
        return const Icon(
          Icons.check_circle_rounded,
          color: Color(0xFF34D399),
          size: 18,
        );
      case LogLevel.start:
        return const Icon(
          Icons.play_circle_rounded,
          color: Color(0xFF818CF8),
          size: 18,
        );
      case LogLevel.file:
        return const Icon(
          Icons.file_copy_rounded,
          color: Color(0xFFA78BFA),
          size: 18,
        );
      default:
        return const Icon(Icons.circle, size: 8, color: Color(0xFF94A3B8));
    }
  }

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _selectedFilter == label;
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => setState(() => _selectedFilter = label),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.15)
                  : theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? theme.colorScheme.primary : null,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? theme.colorScheme.primary
                          : const Color(0xFF64748B),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = (screenWidth * 0.50).clamp(420.0, 620.0);
    final filtered = _filteredEntries;

    final errorCount =
        widget.logEntries.where((l) => l.level == LogLevel.error).length;
    final warningCount =
        widget.logEntries.where((l) => l.level == LogLevel.warning).length;

    return Drawer(
      width: drawerWidth,
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      child: Column(
        children: [
          // Drawer Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color:
                      isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.terminal_rounded,
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Event Log Console',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                IconButton(
                  iconSize: 18,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.copy_rounded),
                  tooltip: 'Copy all logs',
                  onPressed: () => _copyAllLogs(context),
                ),
                const SizedBox(width: 6),
                IconButton(
                  iconSize: 20,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close_rounded),
                  onPressed:
                      () => widget.scaffoldKey.currentState?.closeDrawer(),
                  tooltip: 'Close logs',
                ),
              ],
            ),
          ),

          // Filter bar
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14.0,
              vertical: 8.0,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161F30) : const Color(0xFFF1F5F9),
              border: Border(
                bottom: BorderSide(
                  color:
                      isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', widget.logEntries.length),
                  const SizedBox(width: 6),
                  _buildFilterChip('Errors', errorCount),
                  const SizedBox(width: 6),
                  _buildFilterChip('Warnings', warningCount),
                  const SizedBox(width: 6),
                  _buildFilterChip('Success', 0),
                  const SizedBox(width: 6),
                  _buildFilterChip('Info', 0),
                ],
              ),
            ),
          ),

          // Log entries list
          Expanded(
            child:
                filtered.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.terminal_rounded,
                            size: 40,
                            color: const Color(
                              0xFF94A3B8,
                            ).withValues(alpha: 0.6),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'No logs found',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 10,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final isHovered = widget.hoveredLogIndex == index;

                        return MouseRegion(
                          onEnter: (_) => widget.onHoverChange(index),
                          onExit: (_) {
                            if (widget.hoveredLogIndex == index) {
                              widget.onHoverChange(null);
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 3),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isHovered
                                      ? (isDark
                                          ? const Color(0xFF1E293B)
                                          : Colors.white)
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color:
                                    isHovered
                                        ? (isDark
                                            ? const Color(0xFF334155)
                                            : const Color(0xFFCBD5E1))
                                        : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 2.0),
                                  child: _buildLevelIcon(item.level),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.message,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w500,
                                          color:
                                              isDark
                                                  ? const Color(0xFFF1F5F9)
                                                  : const Color(0xFF0F172A),
                                          height: 1.35,
                                        ),
                                        maxLines: isHovered ? null : 2,
                                        overflow:
                                            isHovered
                                                ? null
                                                : TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.timestamp,
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontFamily: 'monospace',
                                          color: Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),

          // Clear logs button
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: Border(
                top: BorderSide(
                  color:
                      isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: widget.onClearLogs,
                icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                label: const Text('Clear All Logs'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(
                    color:
                        isDark
                            ? const Color(0xFF475569)
                            : const Color(0xFFCBD5E1),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
