import 'package:flutter/material.dart';
import '../themes.dart';
import 'custom_switch.dart';

/// Widget that displays a single subscription list item.
///
/// Shows the subscription URL, validation status, and action buttons
/// (switch toggle, process, and delete).
class SubscriptionListItem extends StatefulWidget {
  final String subscription;
  final int index;
  final bool isProcessing;
  final bool? validationStatus;
  final String displayName;
  final bool isActive;
  final int? delay;
  final bool testFailed;
  final VoidCallback? onRetry;
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

  @override
  State<SubscriptionListItem> createState() => _SubscriptionListItemState();
}

class _SubscriptionListItemState extends State<SubscriptionListItem> {
  bool _isHovered = false;

  Widget _buildLeadingIcon(BuildContext context) {
    final isLocal = widget.subscription.startsWith('/') ||
        (widget.subscription.length > 2 && widget.subscription[1] == ':');
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: (widget.isActive ? primary : Theme.of(context).colorScheme.surfaceContainerHighest)
            .withValues(alpha: widget.isActive ? 0.15 : 0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Icon(
          isLocal ? Icons.description_outlined : Icons.link_rounded,
          size: 18,
          color: widget.isActive ? primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  Widget _buildValidationIcon(BuildContext context) {
    if (widget.validationStatus == null) {
      return const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(strokeWidth: 1.5),
      );
    } else if (widget.validationStatus == false) {
      return Tooltip(
        message: 'Cannot reach this URL or file',
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.warning_amber_rounded,
            size: 14,
            color: Color(0xFFEF4444),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildDelayBadge(BuildContext context) {
    if (!widget.isActive) return const SizedBox.shrink();

    if (widget.testFailed && widget.delay == null) {
      return GestureDetector(
        onTap: widget.onRetry,
        child: Tooltip(
          message: 'Latency test failed - Click to retry',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
            decoration: BoxDecoration(
              color: const Color(0xFF64748B).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF64748B).withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh_rounded, size: 12, color: Color(0xFF64748B)),
                SizedBox(width: 4),
                Text(
                  'Retry',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (widget.delay == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              'Testing...',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final delay = widget.delay!;
    final Color badgeColor;
    if (delay < 200) {
      badgeColor = const Color(0xFF10B981); // Emerald
    } else if (delay < 500) {
      badgeColor = const Color(0xFFF59E0B); // Amber
    } else {
      badgeColor = const Color(0xFFEF4444); // Red
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '${delay}ms',
            style: TextStyle(
              fontSize: 11,
              color: badgeColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    final isDark = theme.brightness == Brightness.dark;

    final borderColor = widget.isActive
        ? theme.colorScheme.primary.withValues(alpha: 0.6)
        : (_isHovered
            ? (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1))
            : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)));

    final cardBg = widget.isActive
        ? theme.colorScheme.primary.withValues(alpha: isDark ? 0.08 : 0.04)
        : (_isHovered
            ? (isDark ? const Color(0xFF26334D).withValues(alpha: 0.5) : const Color(0xFFF1F5F9))
            : theme.cardTheme.color);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(color: borderColor, width: widget.isActive ? 1.5 : 1),
          boxShadow: widget.isActive
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : (_isHovered
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null),
        ),
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
          onTap: widget.onTap,
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ReorderableDragStartListener(
                index: widget.index,
                child: MouseRegion(
                  cursor: SystemMouseCursors.grab,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: Icon(
                      Icons.drag_indicator_rounded,
                      size: 18,
                      color: (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))
                          .withValues(alpha: _isHovered ? 0.9 : 0.4),
                    ),
                  ),
                ),
              ),
              _buildLeadingIcon(context),
            ],
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  widget.subscription,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 13.5,
                  ),
                ),
              ),
              if (widget.isActive) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'ACTIVE',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Text(
              widget.displayName,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 11.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Validation Status Icon
              Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: _buildValidationIcon(context),
              ),

              // Delay Badge
              Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: _buildDelayBadge(context),
              ),

              // Process Button
              IconButton(
                iconSize: 20,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
                icon: widget.isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.0),
                      )
                    : Icon(
                        Icons.play_arrow_rounded,
                        color: appColors.saveAction,
                      ),
                tooltip: "Process this subscription",
                onPressed: widget.isProcessing ? null : widget.onProcess,
              ),
              const SizedBox(width: 4),

              // Switch Toggle
              Tooltip(
                message: "Activate this profile in Clash",
                child: CustomSwitch(
                  value: widget.isActive,
                  onChanged: (value) {
                    if (value) {
                      widget.onSwitch();
                    }
                  },
                ),
              ),
              const SizedBox(width: 4),

              // Delete button
              Builder(
                builder: (buttonContext) => IconButton(
                  iconSize: 18,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    Icons.close_rounded,
                    color: appColors.deleteAction.withValues(alpha: 0.8),
                  ),
                  tooltip: "Delete this subscription",
                  onPressed: () => widget.onDelete(widget.index, buttonContext),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
