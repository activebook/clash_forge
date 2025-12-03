import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';

import '../constants.dart';
import '../managers/subscription_manager.dart';
import '../managers/settings_manager.dart';
import '../managers/profile_manager.dart';
import 'subscription_list_item.dart';
import 'batch_control_bar.dart';
import 'subscription_input_panel.dart';
import 'control_bottom_app_bar.dart';

class ForgeView extends StatefulWidget {
  final SubscriptionManager subscriptionManager;
  final SettingsManager settingsManager;
  final ProfileManager profileManager;
  final Function(String, {NotificationStatus status}) onShowNotification;

  const ForgeView({
    super.key,
    required this.subscriptionManager,
    required this.settingsManager,
    required this.profileManager,
    required this.onShowNotification,
  });

  @override
  State<ForgeView> createState() => _ForgeViewState();
}

class _ForgeViewState extends State<ForgeView> {
  // Input Panel State
  String _newSubscriptionUrl = '';
  bool _isAddingNew = false;
  int _editingIndex = -1;
  String _editSubscriptionUrl = '';
  bool _isValidUrl = false;

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Check the active profile on load
    widget.profileManager.checkActiveProfile();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // URL validation for Input Panel
  void _validateInputUrl(String value) {
    setState(() {
      _newSubscriptionUrl = value;
      _editSubscriptionUrl = value;
      _isValidUrl = widget.subscriptionManager.isValidUrlSyntax(value);
    });
  }

  void _addNewSubscription() {
    setState(() {
      _isAddingNew = true;
      _editingIndex = -1;
      _newSubscriptionUrl = '';
      _editSubscriptionUrl = '';
      _textController.text = '';
      _isValidUrl = false;
    });
  }

  void _confirmNewSubscription() {
    if (_newSubscriptionUrl.isNotEmpty && _isValidUrl) {
      widget.subscriptionManager.addSubscription(_newSubscriptionUrl);

      setState(() {
        _newSubscriptionUrl = '';
        _isAddingNew = false;
        _textController.clear();
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _cancelNewSubscription() {
    setState(() {
      _newSubscriptionUrl = '';
      _isAddingNew = false;
      _textController.clear();
    });
  }

  void _editSubscription(int index) {
    setState(() {
      _isAddingNew = false;
      _editingIndex = index;
      _newSubscriptionUrl = '';
      _editSubscriptionUrl = widget.subscriptionManager.subscriptions[index];
      _textController.text = _editSubscriptionUrl;
    });
    _validateInputUrl(_editSubscriptionUrl);
  }

  void _confirmEditSubscription() {
    if (_editSubscriptionUrl.isNotEmpty && _isValidUrl) {
      widget.subscriptionManager.editSubscription(
        _editingIndex,
        _editSubscriptionUrl,
      );

      setState(() {
        _editSubscriptionUrl = '';
        _editingIndex = -1;
        _textController.clear();
      });
    }
  }

  void _cancelEditSubscription() {
    setState(() {
      _editingIndex = -1;
      _textController.clear();
    });
  }

  Future<void> _showDeleteAllConfirmation(BuildContext context) async {
    if (!mounted) return;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Confirm',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Do you want to delete All Subscriptions?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                Navigator.of(context).pop();
                widget.subscriptionManager.deleteAllSubscriptions();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteConfimMenu(
    int index,
    BuildContext buttonContext,
  ) async {
    // The new UI uses a popup menu which handles the "Delete" action directly.
    // However, we still want to show a confirmation dialog or use the existing logic.
    // Since the PopupMenuButton in SubscriptionListItem calls this, we can just show the dialog.

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Confirm Delete',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          content: Text(
            'Delete "${widget.subscriptionManager.formatUrlWithFilename(widget.subscriptionManager.subscriptions[index], onlyFilename: true)}"?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (result == true) {
      widget.subscriptionManager.deleteSubscription(index);
    }
  }

  Future<void> _handleSwitchProfile(String url) async {
    // 1. Determine the profile name from the URL
    final profileName = widget.subscriptionManager.formatUrlWithFilename(
      url,
      onlyFilename: true,
    );

    // 2. Switch
    final success = await widget.profileManager.switchProfile(profileName);

    // 3. Show notification
    if (success) {
      widget.onShowNotification(
        'Switched to $profileName',
        status: NotificationStatus.success,
      );
    } else {
      widget.onShowNotification(
        'Failed to switch to $profileName',
        status: NotificationStatus.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DropTarget(
        onDragDone: (detail) {
          if (detail.files.isNotEmpty) {
            final filePath = detail.files.first.path;
            if (!_isAddingNew && _editingIndex == -1) {
              setState(() {
                _isAddingNew = true;
                _editingIndex = -1;
              });
            }
            _textController.text = filePath;
            _validateInputUrl(filePath);
          }
        },
        child: Padding(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: 8,
          ),
          child: Column(
            children: [
              Expanded(flex: 1, child: _buildSubscriptionList()),
              _buildBatchProcessBar(context),
              _buildInputPanel(context),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewSubscription,
        tooltip: 'Add new subscription',
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.miniCenterDocked,
      bottomNavigationBar: ControlBottomAppBar(
        fabLocation: FloatingActionButtonLocation.centerDocked,
        shape: null,
        onExport: () async {
          final path = await widget.subscriptionManager.exportSubscriptions();
          if (path != null) {
            widget.onShowNotification('Exported to $path');
          }
        },
        onImport: () async {
          final count = await widget.subscriptionManager.importSubscriptions();
          if (count > 0) {
            widget.onShowNotification('Imported $count subscriptions');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients) {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            });
          }
        },
      ),
    );
  }

  Widget _buildSubscriptionList() {
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.subscriptionManager,
        widget.profileManager,
      ]),
      builder: (context, _) {
        final subscriptions = widget.subscriptionManager.subscriptions;
        return Container(
          decoration: const BoxDecoration(),
          child:
              subscriptions.isEmpty
                  ? const Center(child: Text('No subscriptions yet'))
                  : ListView.builder(
                    controller: _scrollController,
                    itemCount: subscriptions.length,
                    itemBuilder: (context, index) {
                      final bool isProcessing =
                          widget.subscriptionManager.processingItems[index] ??
                          false;

                      // Determine if this subscription is the active profile
                      final profileName = widget.subscriptionManager
                          .formatUrlWithFilename(
                            subscriptions[index],
                            onlyFilename: true,
                          );
                      final bool isActive =
                          widget.profileManager.activeProfile == profileName;

                      return SubscriptionListItem(
                        subscription: subscriptions[index],
                        index: index,
                        isProcessing: isProcessing,
                        isActive: isActive,
                        validationStatus:
                            widget
                                .subscriptionManager
                                .urlValidationStatus[subscriptions[index]],
                        displayName: widget.subscriptionManager
                            .formatUrlWithFilename(subscriptions[index]),
                        onTap: () => _editSubscription(index),
                        onProcess: () async {
                          if (widget.settingsManager.targetFolderPath.isEmpty) {
                            widget.onShowNotification(
                              'Target folder does not exist. Please select a folder first.',
                              status: NotificationStatus.warning,
                            );
                            return;
                          }
                          await widget.subscriptionManager.processUrl(
                            subscriptions[index],
                            index,
                            widget.settingsManager.targetFolderPath,
                            needResolveDNS:
                                widget.settingsManager.needResolveDNS,
                            dnsProvider: widget.settingsManager.dnsProvider,
                            tunEnable: widget.settingsManager.tunEnable,
                            urlTestInterval:
                                widget.settingsManager.urlTestInterval,
                            urlTestTolerance:
                                widget.settingsManager.urlTestTolerance,
                            urlTestLazy: widget.settingsManager.urlTestLazy,
                          );
                        },
                        onSwitch:
                            () => _handleSwitchProfile(subscriptions[index]),
                        onDelete: _showDeleteConfimMenu,
                      );
                    },
                  ),
        );
      },
    );
  }

  Widget _buildBatchProcessBar(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.settingsManager,
        widget.subscriptionManager,
      ]),
      builder: (context, _) {
        return BatchControlBar(
          targetFolderPath: widget.settingsManager.targetFolderPath,
          isBatchProcessing: widget.subscriptionManager.isBatchProcessing,
          onSelectFolder: () async {
            final path = await widget.settingsManager.selectFolder();
            if (path != null) {
              widget.onShowNotification(
                'Save at: $path',
                status: NotificationStatus.info,
              );
            }
          },
          onProcessAll: () async {
            if (widget.settingsManager.targetFolderPath.isEmpty) {
              widget.onShowNotification(
                'Target folder does not exist. Please select a folder first.',
                status: NotificationStatus.warning,
              );
              return;
            }
            if (widget.subscriptionManager.subscriptions.isEmpty) {
              widget.onShowNotification(
                'No subscriptions to process.',
                status: NotificationStatus.warning,
              );
              return;
            }

            widget.onShowNotification(
              'Processing ${widget.subscriptionManager.subscriptions.length} subscriptions...',
              status: NotificationStatus.info,
            );

            await widget.subscriptionManager.processAllUrls(
              widget.settingsManager.targetFolderPath,
              needResolveDNS: widget.settingsManager.needResolveDNS,
              dnsProvider: widget.settingsManager.dnsProvider,
              tunEnable: widget.settingsManager.tunEnable,
              urlTestInterval: widget.settingsManager.urlTestInterval,
              urlTestTolerance: widget.settingsManager.urlTestTolerance,
              urlTestLazy: widget.settingsManager.urlTestLazy,
            );

            widget.onShowNotification(
              'All subscriptions processed',
              status: NotificationStatus.success,
            );
          },
          onDeleteAll: () => _showDeleteAllConfirmation(context),
        );
      },
    );
  }

  Widget _buildInputPanel(BuildContext context) {
    return SubscriptionInputPanel(
      isAddingNew: _isAddingNew,
      editingIndex: _editingIndex,
      textController: _textController,
      isValidUrl: _isValidUrl,
      urlValue: _isAddingNew ? _newSubscriptionUrl : _editSubscriptionUrl,
      onValidate: _validateInputUrl,
      onConfirm:
          _isAddingNew ? _confirmNewSubscription : _confirmEditSubscription,
      onCancel: _isAddingNew ? _cancelNewSubscription : _cancelEditSubscription,
    );
  }
}
