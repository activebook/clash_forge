import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:desktop_drop/desktop_drop.dart';

import 'themes.dart';
import 'constants.dart';
import 'models/app_info.dart';

import 'widgets/log_drawer.dart';
import 'widgets/batch_control_bar.dart';
import 'widgets/subscription_input_panel.dart';
import 'widgets/subscription_list_item.dart';
import 'widgets/settings_drawer.dart';
import 'widgets/control_bottom_app_bar.dart';

import 'managers/subscription_manager.dart';
import 'managers/settings_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final packageInfo = await PackageInfo.fromPlatform();

  final appInfo = AppInfo(
    appName: packageInfo.appName,
    appVersion: packageInfo.version,
  );

  runApp(MyApp(appInfo: appInfo));
}

class MyApp extends StatefulWidget {
  final AppInfo appInfo;
  const MyApp({super.key, required this.appInfo});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  late final AppInfo _appInfo;
  final SubscriptionManager _subscriptionManager = SubscriptionManager();
  final SettingsManager _settingsManager = SettingsManager();

  // UI State
  int? _hoveredLogIndex;

  // Input Panel State
  String _newSubscriptionUrl = '';
  bool _isAddingNew = false;
  int _editingIndex = -1;
  String _editSubscriptionUrl = '';
  bool _isValidUrl = false;

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _appInfo = widget.appInfo;
    _subscriptionManager.init();
    _settingsManager.init();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _subscriptionManager.dispose();
    _settingsManager.dispose();
    super.dispose();
  }

  // URL validation for Input Panel
  void _validateInputUrl(String value) {
    setState(() {
      _newSubscriptionUrl = value;
      _editSubscriptionUrl = value;
      _isValidUrl = _subscriptionManager.isValidUrlSyntax(value);
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
      _subscriptionManager.addSubscription(_newSubscriptionUrl);

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
      _editSubscriptionUrl = _subscriptionManager.subscriptions[index];
      _textController.text = _editSubscriptionUrl;
    });
    _validateInputUrl(_editSubscriptionUrl);
  }

  void _confirmEditSubscription() {
    if (_editSubscriptionUrl.isNotEmpty && _isValidUrl) {
      _subscriptionManager.editSubscription(
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
          title: const Text('Confirm'),
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
                _subscriptionManager.deleteAllSubscriptions();
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
    final RenderBox buttonBox = buttonContext.findRenderObject() as RenderBox;
    final Offset position = buttonBox.localToGlobal(Offset.zero);
    final Size buttonSize = buttonBox.size;

    final result = await showMenu<bool>(
      context: buttonContext,
      position: RelativeRect.fromLTRB(
        position.dx - 100,
        position.dy + buttonSize.height,
        position.dx + buttonSize.width,
        position.dy,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      items: [
        PopupMenuItem<bool>(
          value: null,
          enabled: false,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Delete "${_subscriptionManager.formatUrlWithFilename(_subscriptionManager.subscriptions[index], onlyFilename: true)}"?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color:
                  Theme.of(buttonContext).extension<AppColors>()!.folderAction,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const PopupMenuItem<bool>(height: 40, value: false, child: Text('No')),
        const PopupMenuItem<bool>(height: 40, value: true, child: Text('Yes')),
      ],
    );

    if (result == true) {
      _subscriptionManager.deleteSubscription(index);
    }
  }

  void showNotification(
    String text, {
    NotificationStatus status = NotificationStatus.success,
  }) {
    Widget icon;
    switch (status) {
      case NotificationStatus.success:
        icon = const Icon(Icons.check_circle, color: Color(0xFF66BB6A));
        break;
      case NotificationStatus.error:
        icon = const Icon(Icons.error, color: Color(0xFFEF5350));
        break;
      case NotificationStatus.warning:
        icon = const Icon(Icons.warning, color: Color(0xFFFFA726));
        break;
      case NotificationStatus.info:
        icon = const Icon(Icons.info, color: Color(0xFF29B6F6));
        break;
    }
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            icon,
            const SizedBox(width: 8),
            Expanded(child: Text(text)),
          ],
        ),
        showCloseIcon: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _settingsManager,
      builder: (context, _) {
        return MaterialApp(
          title: widget.appInfo.appName,
          theme: macOSLightThemeFollow(),
          darkTheme: macOSDarkThemeFollow(),
          themeMode: _settingsManager.themeMode,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en', '')],
          scaffoldMessengerKey: _scaffoldMessengerKey,
          home: Builder(
            builder: (context) {
              return Scaffold(
                key: _scaffoldKey,
                appBar: _buildAppBar(context),
                drawer: _buildLogDrawer(context),
                endDrawer: _buildSettingsDrawer(context),
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
                    final path =
                        await _subscriptionManager.exportSubscriptions();
                    if (path != null) {
                      showNotification('Exported to $path');
                    }
                  },
                  onImport: () async {
                    final count =
                        await _subscriptionManager.importSubscriptions();
                    if (count > 0) {
                      showNotification('Imported $count subscriptions');
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
            },
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('images/logo.png', height: 24),
          const SizedBox(width: 8),
          Text(_appInfo.appName, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                  Theme.of(context).colorScheme.primary,
                ],
              ),
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              "v${_appInfo.appVersion}",
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
      leadingWidth: 40,
      leading: Builder(
        builder:
            (context) => ListenableBuilder(
              listenable: _subscriptionManager,
              builder: (context, _) {
                return IconButton(
                  icon: Badge.count(
                    count: _subscriptionManager.logEntries.length,
                    isLabelVisible: _subscriptionManager.logEntries.isNotEmpty,
                    child: const Icon(Icons.notifications_outlined),
                  ),
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  tooltip: 'Log information',
                );
              },
            ),
      ),
      actions: [
        Builder(
          builder:
              (context) => Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  tooltip: 'Settings',
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                ),
              ),
        ),
      ],
    );
  }

  Widget _buildLogDrawer(BuildContext context) {
    return ListenableBuilder(
      listenable: _subscriptionManager,
      builder: (context, _) {
        return LogDrawer(
          logEntries: _subscriptionManager.logEntries,
          hoveredLogIndex: _hoveredLogIndex,
          onClearLogs: () {
            HapticFeedback.mediumImpact();
            _subscriptionManager.clearAllLogs();
          },
          onHoverChange: (index) {
            setState(() {
              _hoveredLogIndex = index;
            });
          },
          scaffoldKey: _scaffoldKey,
        );
      },
    );
  }

  Widget _buildSettingsDrawer(BuildContext context) {
    return ListenableBuilder(
      listenable: _settingsManager,
      builder: (context, _) {
        return SettingsDrawer(
          initialIsDarkMode: _settingsManager.themeMode == ThemeMode.dark,
          initialUseDns: _settingsManager.needResolveDNS,
          initialSelectedDnsProvider: _settingsManager.dnsProvider,
          onDnsChanged: _settingsManager.toggleDNS,
          onThemeModeChanged: _settingsManager.toggleTheme,
          onDnsProviderChanged: _settingsManager.toggleDnsProvider,
        );
      },
    );
  }

  Widget _buildSubscriptionList() {
    return ListenableBuilder(
      listenable: _subscriptionManager,
      builder: (context, _) {
        final subscriptions = _subscriptionManager.subscriptions;
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
                          _subscriptionManager.processingItems[index] ?? false;
                      return SubscriptionListItem(
                        subscription: subscriptions[index],
                        index: index,
                        isProcessing: isProcessing,
                        validationStatus:
                            _subscriptionManager
                                .urlValidationStatus[subscriptions[index]],
                        displayName: _subscriptionManager.formatUrlWithFilename(
                          subscriptions[index],
                        ),
                        onTap: () => _editSubscription(index),
                        onProcess: () async {
                          if (_settingsManager.targetFolderPath.isEmpty) {
                            showNotification(
                              'Target folder does not exist. Please select a folder first.',
                              status: NotificationStatus.warning,
                            );
                            return;
                          }
                          await _subscriptionManager.processUrl(
                            subscriptions[index],
                            index,
                            _settingsManager.targetFolderPath,
                            needResolveDNS: _settingsManager.needResolveDNS,
                            dnsProvider: _settingsManager.dnsProvider,
                          );
                        },
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
      listenable: Listenable.merge([_settingsManager, _subscriptionManager]),
      builder: (context, _) {
        return BatchControlBar(
          targetFolderPath: _settingsManager.targetFolderPath,
          isBatchProcessing: _subscriptionManager.isBatchProcessing,
          onSelectFolder: () async {
            final path = await _settingsManager.selectFolder();
            if (path != null) {
              showNotification(
                'Save at: $path',
                status: NotificationStatus.info,
              );
            }
          },
          onProcessAll: () async {
            if (_settingsManager.targetFolderPath.isEmpty) {
              showNotification(
                'Target folder does not exist. Please select a folder first.',
                status: NotificationStatus.warning,
              );
              return;
            }
            if (_subscriptionManager.subscriptions.isEmpty) {
              showNotification(
                'No subscriptions to process.',
                status: NotificationStatus.warning,
              );
              return;
            }

            showNotification(
              'Processing ${_subscriptionManager.subscriptions.length} subscriptions...',
              status: NotificationStatus.info,
            );

            await _subscriptionManager.processAllUrls(
              _settingsManager.targetFolderPath,
              needResolveDNS: _settingsManager.needResolveDNS,
              dnsProvider: _settingsManager.dnsProvider,
            );

            showNotification(
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
