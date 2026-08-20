import 'package:flutter/material.dart';
import '../themes.dart';

/// Widget that displays the subscription input panel for adding or editing subscriptions.
///
/// Shows an input field with validation, confirm/cancel buttons, and error messages.
class SubscriptionInputPanel extends StatelessWidget {
  final bool isAddingNew;
  final int editingIndex;
  final TextEditingController textController;
  final bool isValidUrl;
  final String urlValue;
  final Function(String) onValidate;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const SubscriptionInputPanel({
    super.key,
    required this.isAddingNew,
    required this.editingIndex,
    required this.textController,
    required this.isValidUrl,
    required this.urlValue,
    required this.onValidate,
    required this.onConfirm,
    required this.onCancel,
  });

  static const String kSupportedUrlMessage =
      'Supported: HTTPS Subscription, VLESS, VMess, Trojan, SS, SSR, Hysteria2, TUIC, AnyTLS, WireGuard, Local YAML/Config.';

  Widget _buildProtocolChip(String label, BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
          width: 0.8,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isVisible = (isAddingNew && editingIndex == -1) || (!isAddingNew && editingIndex != -1);
    if (!isVisible) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    final isDark = theme.brightness == Brightness.dark;
    final isEditing = !isAddingNew && editingIndex != -1;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isEditing ? Icons.edit_rounded : Icons.add_link_rounded,
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: textController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: isEditing
                          ? 'Edit subscription link or path...'
                          : 'Enter subscription URL, proxy link, or drop a file here...',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    onChanged: onValidate,
                    onSubmitted: (_) => onConfirm(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  iconSize: 22,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    Icons.check_circle_rounded,
                    color: appColors.saveAction,
                  ),
                  onPressed: onConfirm,
                  tooltip: 'Save',
                ),
                const SizedBox(width: 4),
                IconButton(
                  iconSize: 22,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    Icons.cancel_rounded,
                    color: appColors.deleteAction.withValues(alpha: 0.8),
                  ),
                  onPressed: onCancel,
                  tooltip: 'Cancel',
                ),
              ],
            ),
            if (urlValue.isNotEmpty && !isValidUrl)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        kSupportedUrlMessage,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.error,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    _buildProtocolChip('HTTPS Sub', context),
                    _buildProtocolChip('VLESS', context),
                    _buildProtocolChip('VMess', context),
                    _buildProtocolChip('Trojan', context),
                    _buildProtocolChip('Shadowsocks', context),
                    _buildProtocolChip('Hysteria2', context),
                    _buildProtocolChip('WireGuard', context),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
