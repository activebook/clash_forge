import 'package:flutter/material.dart';
import '../themes.dart';
import 'custom_switch.dart';

/// Widget that displays a single subscription list item.
///
/// Shows the subscription URL, validation status, and action buttons
/// (switch toggle, process, and delete).
class SubscriptionListItem extends StatelessWidget {
  final String subscription;
  final int index;
  final bool isProcessing;
  final bool? validationStatus;
  final String displayName;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onProcess;
  final VoidCallback onSwitch;
  final Function(int, BuildContext) onDelete;

  const SubscriptionListItem({
    super.key,
    required this.subscription,
    required this.index,
    required this.isProcessing,
    required this.validationStatus,
    required this.displayName,
    required this.isActive,
    required this.onTap,
    required this.onProcess,
    required this.onSwitch,
    required this.onDelete,
  });

  Widget _buildValidationIcon(BuildContext context) {
    if (validationStatus == null) {
      return const SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else if (validationStatus == false) {
      return Tooltip(
        message: 'Cannot access this URL',
        child: Icon(
          Icons.warning_amber_rounded,
          size: 16,
          color: Theme.of(context).colorScheme.error,
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: ListTile(
        dense: true,
        onTap: onTap,
        title: Text(subscription, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          displayName,
          style: Theme.of(context).textTheme.bodySmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Validation Status Icon
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: _buildValidationIcon(context),
            ),

            // Process Button (Play)
            IconButton(
              icon:
                  isProcessing
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.0),
                      )
                      : Icon(
                        Icons.play_arrow,
                        color:
                            Theme.of(
                              context,
                            ).extension<AppColors>()!.saveAction,
                      ),
              tooltip: "Process this subscription",
              onPressed: isProcessing ? null : onProcess,
            ),

            // Switch Toggle
            Tooltip(
              message: "Activate this profile in Clash",
              child: CustomSwitch(
                value: isActive,
                onChanged: (value) {
                  if (value) {
                    onSwitch();
                  }
                  // If value is false, do nothing (can't "deselect" - radio behavior)
                },
              ),
            ),

            // Delete button
            Builder(
              builder:
                  (buttonContext) => IconButton(
                    icon: Icon(
                      Icons.close,
                      color:
                          Theme.of(
                            context,
                          ).extension<AppColors>()!.deleteAction,
                    ),
                    tooltip: "Delete this subscription",
                    onPressed: () => onDelete(index, buttonContext),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
