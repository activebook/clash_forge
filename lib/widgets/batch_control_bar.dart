import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../themes.dart';

/// Widget that displays the batch processing control bar.
///
/// Provides folder selection, process all URLs, and delete all subscriptions
/// buttons with appropriate loading indicators.
class BatchControlBar extends StatelessWidget {
  final String targetFolderPath;
  final bool isBatchProcessing;
  final VoidCallback onSelectFolder;
  final VoidCallback onProcessAll;
  final VoidCallback onDeleteAll;

  const BatchControlBar({
    super.key,
    required this.targetFolderPath,
    required this.isBatchProcessing,
    required this.onSelectFolder,
    required this.onProcessAll,
    required this.onDeleteAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            onTap: onSelectFolder,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: appColors.folderAction.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.folder_open_rounded,
                    color: appColors.folderAction,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Folder',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: appColors.folderAction,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: onSelectFolder,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Text(
                  targetFolderPath.isEmpty
                      ? "Select Clash Config Output Folder..."
                      : targetFolderPath,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: targetFolderPath.isEmpty
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.45)
                        : theme.colorScheme.onSurface.withValues(alpha: 0.85),
                    fontSize: 12.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          isBatchProcessing
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  iconSize: 22,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    Icons.fast_forward_rounded,
                    color: appColors.forwardAction,
                  ),
                  onPressed: onProcessAll,
                  tooltip: "Process all subscriptions",
                ),
          const SizedBox(width: 6),
          IconButton(
            iconSize: 20,
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
            icon: Icon(
              Icons.delete_sweep_rounded,
              color: appColors.deleteAction.withValues(alpha: 0.8),
            ),
            onPressed: () {
              HapticFeedback.mediumImpact();
              onDeleteAll();
            },
            tooltip: "Delete all subscriptions",
          ),
        ],
      ),
    );
  }
}
