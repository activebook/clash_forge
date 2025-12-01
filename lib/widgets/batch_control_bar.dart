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
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.folder_open_outlined,
                color: Theme.of(context).extension<AppColors>()!.folderAction,
                size: 24,
              ),
              onPressed: onSelectFolder,
              tooltip: "Select Folder",
            ),
            Expanded(
              child: TextField(
                controller: TextEditingController(text: targetFolderPath),
                enabled: false,
                decoration: const InputDecoration(
                  hintText: "Select Clash Config Folder ...",
                ),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(width: 8),
            isBatchProcessing
                ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
                : IconButton(
                  icon: Icon(
                    Icons.fast_forward,
                    color:
                        Theme.of(context).extension<AppColors>()!.forwardAction,
                    size: 24,
                  ),
                  onPressed: onProcessAll,
                  tooltip: "Process all URLs",
                ),
            IconButton(
              icon: Icon(
                Icons.delete_forever_outlined,
                color: Theme.of(context).extension<AppColors>()!.deleteAction,
                size: 24,
              ),
              onPressed: () {
                HapticFeedback.mediumImpact();
                onDeleteAll();
              },
              tooltip: "Delete all URLs",
            ),
          ],
        ),
      ),
    );
  }
}
