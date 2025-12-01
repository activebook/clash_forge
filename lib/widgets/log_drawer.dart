import 'package:flutter/material.dart';
import '../services/loginfo.dart';

/// Widget that displays the log drawer with a list of log entries.
///
/// Supports hover-to-expand functionality for log messages and provides
/// a button to clear all logs.
class LogDrawer extends StatelessWidget {
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

  Icon _getLogLevelIcon(LogLevel level) {
    switch (level) {
      case LogLevel.error:
        return const Icon(
          Icons.error_outline,
          color: Color(0xFFEF5350),
        ); // Soft Red
      case LogLevel.warning:
        return const Icon(
          Icons.warning_amber,
          color: Color(0xFFFFA726),
        ); // Soft Orange
      case LogLevel.info:
        return const Icon(
          Icons.info_outline,
          color: Color(0xFF29B6F6),
        ); // Soft Blue
      case LogLevel.debug:
        return const Icon(
          Icons.bug_report,
          color: Color(0xFF78909C),
        ); // Soft Blue Grey
      case LogLevel.success:
        return const Icon(
          Icons.check_circle,
          color: Color(0xFF66BB6A),
        ); // Soft Green
      case LogLevel.start:
        return const Icon(
          Icons.play_circle_outline,
          color: Color(0xFF5C6BC0),
        ); // Soft Indigo
      case LogLevel.file:
        return const Icon(
          Icons.file_copy_outlined,
          color: Color(0xFF7E57C2),
        ); // Soft Purple
      default: // LogLevel.normal
        return const Icon(
          Icons.circle,
          size: 12,
          color: Color(0xFF9CCC65),
        ); // Soft Lime
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.70, // 70% of screen width
      child: Column(
        children: [
          AppBar(
            toolbarHeight: 48,
            leadingWidth: 40,
            titleSpacing: 0,
            automaticallyImplyLeading: false,
            title: Text('Logs', style: Theme.of(context).textTheme.titleSmall),
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => scaffoldKey.currentState?.closeDrawer(),
              ),
            ],
          ),

          // Log entries list
          Expanded(
            child:
                logEntries.isEmpty
                    ? const Center(child: Text('No log entries'))
                    : ListView.builder(
                      itemCount: logEntries.length,
                      itemBuilder: (context, index) {
                        return MouseRegion(
                          onEnter: (_) => onHoverChange(index),
                          onExit: (_) {
                            // Only clear if this item is currently hovered
                            if (hoveredLogIndex == index) {
                              onHoverChange(null);
                            }
                          },
                          child: ListTile(
                            title:
                                hoveredLogIndex == index
                                    // Expanded view when hovered
                                    ? Text(logEntries[index].message)
                                    // Single line with ellipsis when not hovered
                                    : Text(
                                      logEntries[index].message,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                            subtitle: Text(
                              logEntries[index].timestamp,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            leading: _getLogLevelIcon(logEntries[index].level),
                          ),
                        );
                      },
                    ),
          ),

          // Clear logs button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onClearLogs,
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(0, 50)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
