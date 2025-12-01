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
      'Supported: https, vmess, vless, trojan, ss, ssr, hysteria2, tuic, anytls, local file.'
      '\nHttps url can be a subscription url. You can also drag the local config file to import it.';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 0.0),
      child: Column(
        children: [
          // Add new subscription panel
          if (isAddingNew && editingIndex == -1)
            Card(
              elevation: 3,
              shadowColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.2),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.link,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: textController,
                        decoration: InputDecoration(
                          hintText: 'Enter subscription URL or drag file here',
                          errorText:
                              urlValue.isNotEmpty && !isValidUrl
                                  ? kSupportedUrlMessage
                                  : null,
                          errorMaxLines: 3,
                        ),
                        onChanged: onValidate,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        Icons.check_circle,
                        color:
                            Theme.of(
                              context,
                            ).extension<AppColors>()!.saveAction,
                      ),
                      onPressed: onConfirm,
                      tooltip: 'Confirm',
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.cancel,
                        color:
                            Theme.of(
                              context,
                            ).extension<AppColors>()!.deleteAction,
                      ),
                      onPressed: onCancel,
                      tooltip: 'Cancel',
                    ),
                  ],
                ),
              ),
            ),
          if (isAddingNew && editingIndex == -1) const SizedBox(height: 8.0),

          // Edit subscription panel
          if (!isAddingNew && editingIndex != -1)
            Card(
              elevation: 3,
              shadowColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.2),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.edit,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: textController,
                        decoration: InputDecoration(
                          hintText: 'Enter subscription URL or drag file here',
                          border: InputBorder.none,
                          errorText:
                              urlValue.isNotEmpty && !isValidUrl
                                  ? kSupportedUrlMessage
                                  : null,
                          errorMaxLines: 3,
                        ),
                        onChanged: onValidate,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        Icons.check_circle,
                        color:
                            Theme.of(
                              context,
                            ).extension<AppColors>()!.saveAction,
                      ),
                      onPressed: onConfirm,
                      tooltip: 'Confirm',
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.cancel,
                        color:
                            Theme.of(
                              context,
                            ).extension<AppColors>()!.deleteAction,
                      ),
                      onPressed: onCancel,
                      tooltip: 'Cancel',
                    ),
                  ],
                ),
              ),
            ),
          if (!isAddingNew && editingIndex != -1) const SizedBox(height: 8.0),
        ],
      ),
    );
  }
}
