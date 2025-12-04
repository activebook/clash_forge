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
  final int? delay; // Delay in milliseconds (null if not tested yet)
  final bool testFailed; // Whether the delay test failed
  final VoidCallback? onRetry; // Callback for manual retry
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
    this.delay,
    this.testFailed = false,
    this.onRetry,
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

  /// Builds the delay badge with color coding based on latency
  Widget _buildDelayBadge(BuildContext context) {
    if (!isActive) {
      return const SizedBox.shrink();
    }

    // Error state - show retry badge
    if (testFailed && delay == null) {
      return GestureDetector(
        onTap: onRetry,
        child: Tooltip(
          message: 'Test failed - Tap to retry',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF9E9E9E), // Grey
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 14,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  'Retry',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (delay == null) {
      // Testing in progress
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Testing...',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Determine color based on delay
    Color badgeColor;
    Color textColor;
    if (delay! < 300) {
      badgeColor = const Color(0xFF66BB6A); // Green
      textColor = Colors.white;
    } else if (delay! < 1000) {
      badgeColor = const Color(0xFFFFA726); // Yellow/Orange
      textColor = Colors.white;
    } else {
      badgeColor = const Color(0xFFEF5350); // Red
      textColor = Colors.white;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${delay}ms',
            style: TextStyle(
              fontSize: 11,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.check_circle, size: 14, color: textColor),
        ],
      ),
    );
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

            // Delay Badge (shown when active)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: _buildDelayBadge(context),
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
