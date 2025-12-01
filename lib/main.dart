import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path/path.dart' as path;
import 'package:desktop_drop/desktop_drop.dart';
import 'services/url_converter.dart';
import 'services/loginfo.dart';
import 'services/file_utils.dart';
import 'services/http_client.dart';
import 'themes.dart';
import 'widgets/log_drawer.dart';
import 'widgets/batch_control_bar.dart';
import 'widgets/subscription_input_panel.dart';
import 'widgets/subscription_list_item.dart';
import 'models/app_info.dart';
import 'constants.dart';
import 'widgets/settings_drawer.dart';
import 'widgets/control_bottom_app_bar.dart';

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

  // List of log entries
  final List<LogInfo> _logEntries = List<LogInfo>.empty(
    growable: true,
  ); // This will store your log entries
  int? _hoveredLogIndex;

  List<String> _subscriptions = [];
  String? _configTemplate;

  final Map<int, bool> _processingItems =
      {}; // Track which items are processing

  // Batch processing Flag
  bool _isBatchProcessing = false;
  // Resolve DNS Flag
  bool _needResolveDNS = false;
  // Default DNS Provider
  String _dnsProvider = '';

  // Add new subscription Flag
  String _newSubscriptionUrl = '';
  bool _isAddingNew = false;

  // Edit subscription Flag
  int _editingIndex = -1;
  String _editSubscriptionUrl = '';

  bool _isValidUrl = false; // Track URL validity

  // Map to store validation status of URLs
  // Key: URL, Value: true (valid), false (invalid), null (checking/unknown)
  final Map<String, bool?> _urlValidationStatus = {};

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController =
      ScrollController(); // Add this line

  String _targetFolderPath = ''; // The real target folder path

  // Track current theme mode
  ThemeMode _themeMode = ThemeMode.light;

  // For snackbar
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  // For drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _appInfo = widget.appInfo;
    _loadSettings();
    _loadSubscriptions();
    _loadTargetFolder();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose(); // Add this line
    super.dispose();
  }

  // URL validation method
  void _validateUrl(String value) {
    setState(() {
      _newSubscriptionUrl = value;
      _editSubscriptionUrl = value;
      String trimmedValue = value.trim();
      String lowerValue = trimmedValue.toLowerCase();

      // Check for protocol URLs
      bool isProtocolUrl =
          lowerValue.startsWith('https://') ||
          lowerValue.startsWith('http://') ||
          lowerValue.startsWith('vmess://') ||
          lowerValue.startsWith('vless://') ||
          lowerValue.startsWith('trojan://') ||
          lowerValue.startsWith('ss://') ||
          lowerValue.startsWith('ssr://') ||
          lowerValue.startsWith('hysteria2://') ||
          lowerValue.startsWith('hy2://') ||
          lowerValue.startsWith('tuic://') ||
          lowerValue.startsWith('anytls://');

      // Check for local file paths - validate that file actually exists
      bool isLocalFile = FileUtils.isValidLocalFile(trimmedValue);

      _isValidUrl = isProtocolUrl || isLocalFile;
    });
  }

  // Async validation for remote URLs and local files
  Future<void> _validateSubscriptionUrl(String url) async {
    if (url.isEmpty) return;

    // Check if it's a local file
    if (FileUtils.isLocalFilePath(url)) {
      // For local files, check existence synchronously
      setState(() {
        _urlValidationStatus[url] = FileUtils.fileExists(url);
      });
      return;
    }

    // Set status to null (loading) for remote URLs
    setState(() {
      _urlValidationStatus[url] = null;
    });

    try {
      final uri = Uri.parse(url);

      // Only validate http/https URLs
      if (!uri.isScheme('http') && !uri.isScheme('https')) {
        // For other protocols, we assume they are valid or we can't easily check
        setState(() {
          _urlValidationStatus[url] = true;
        });
        return;
      }

      // Use ProxyService to validate URL with system proxy support
      final proxyService = ProxyService();
      final isValid = await proxyService.validateUrl(url);

      if (mounted) {
        setState(() {
          _urlValidationStatus[url] = isValid;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _urlValidationStatus[url] = false;
        });
      }
    }
  }

  String _formatUrlWithFilename(String url, {onlyFilename = false}) {
    try {
      // Check if this is a local file path
      if (FileUtils.isLocalFilePath(url)) {
        // For local files: show "local: parentDir_filename" (without .yaml extension)
        final filePath = url.trim();
        final parentDir = path.basename(path.dirname(filePath));
        final baseName = path.basenameWithoutExtension(filePath);
        final displayName = '${parentDir}_$baseName';
        return onlyFilename ? displayName : 'local: $displayName';
      }

      // For URLs
      final uri = Uri.parse(url);
      /*
      // For special protocol URLs (vless, vmess, ss, trojan)
      if (url.toLowerCase().startsWith('vless://') ||
          url.toLowerCase().startsWith('vmess://') ||
          url.toLowerCase().startsWith('ss://') ||
          url.toLowerCase().startsWith('trojan://')) {
        // Use the fragment identifier (part after #) if available as it often contains the name/label
        if (uri.fragment.isNotEmpty) {
          return onlyFilename ? uri.fragment : "${uri.host}: ${uri.fragment}";
        }

        // Fallback to host if no fragment
        return onlyFilename ? uri.host : uri.host;
      }

      // For standard URLs      
      if (uri.pathSegments.isNotEmpty) {
        String filename = uri.pathSegments.last;
        if (filename.isEmpty) {
          filename = uri.host;
        }
        return onlyFilename ? filename : "${uri.host}: $filename";
      } else {
        // If no path segments
        return onlyFilename ? uri.host : uri.host;
      }
      */

      final converter = UrlConverter();
      String filename = converter.extractFileNameFromUrlEx(
        url,
        defaultExtension: '',
      );
      return onlyFilename ? filename : "${uri.host}: $filename";
    } catch (e) {
      // Handle invalid URLs
      return url;
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _themeMode =
          prefs.getBool('darkMode') ?? false ? ThemeMode.dark : ThemeMode.light;
      _needResolveDNS = prefs.getBool('needResolveDNS') ?? false;
      _dnsProvider = prefs.getString('dnsProvider') ?? 'DNSPub';
    });
  }

  Future<void> _toggleDNS(bool needResolveDNS) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _needResolveDNS = needResolveDNS;
    });
    prefs.setBool('needResolveDNS', needResolveDNS);
  }

  // Toggle theme method
  Future<void> _toggleTheme(bool darkMode) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _themeMode = darkMode ? ThemeMode.dark : ThemeMode.light;
    });
    prefs.setBool('darkMode', darkMode);
  }

  Future<void> _toggleDnsProvider(String selectedDnsProvider) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dnsProvider = selectedDnsProvider;
    });
    prefs.setString('dnsProvider', _dnsProvider);
  }

  // Load subscriptions from SharedPreferences
  Future<void> _loadSubscriptions() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _subscriptions = prefs.getStringList('subscriptions') ?? [];
      // Validate all loaded subscriptions
      for (var url in _subscriptions) {
        _validateSubscriptionUrl(url);
      }
    });
  }

  // Save subscriptions to SharedPreferences
  Future<void> _saveSubscriptions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('subscriptions', _subscriptions);
  }

  void _addNewSubscription() {
    setState(() {
      _isAddingNew = true;
      _editingIndex = -1;
      _newSubscriptionUrl = '';
      _editSubscriptionUrl = '';
      _textController.text = '';
    });
  }

  void _confirmNewSubscription() {
    if (_newSubscriptionUrl.isNotEmpty && _isValidUrl) {
      setState(() {
        _subscriptions.add(_newSubscriptionUrl.trim());
        _validateSubscriptionUrl(
          _newSubscriptionUrl.trim(),
        ); // Validate new subscription
        _newSubscriptionUrl = '';
        _isAddingNew = false;
        _textController.clear();
      });
      _saveSubscriptions(); // Save after adding

      // Add this: scroll to bottom after adding new subscription
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
      _editSubscriptionUrl = _subscriptions[index];
      _textController.text = _editSubscriptionUrl;
    });
    // must force url validation
    // because the url is not validated when switch from add new subscription to edit existing subscription
    _validateUrl(_editSubscriptionUrl);
  }

  void _confirmEditSubscription() {
    if (_editSubscriptionUrl.isNotEmpty && _isValidUrl) {
      setState(() {
        _subscriptions[_editingIndex] = _editSubscriptionUrl.trim();
        _validateSubscriptionUrl(
          _editSubscriptionUrl.trim(),
        ); // Validate edited subscription
        _editSubscriptionUrl = '';
        _editingIndex = -1;
        _textController.clear();
      });
      _saveSubscriptions(); // Save after adding
    }
  }

  void _cancelEditSubscription() {
    setState(() {
      _editingIndex = -1;
      _textController.clear();
    });
  }

  Future<void> _selectFolder() async {
    final prefs = await SharedPreferences.getInstance();
    final targetFolder = prefs.getString('targetFolder');
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      initialDirectory: targetFolder,
    );

    if (selectedDirectory != null) {
      setState(() {
        _targetFolderPath = selectedDirectory;
      });

      // Save the selected path to SharedPreferences

      prefs.setString('targetFolder', _targetFolderPath);

      showNotification(
        'Save at: $_targetFolderPath',
        status: NotificationStatus.info,
      );
    }
  }

  Future<void> _loadTargetFolder() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _targetFolderPath = prefs.getString('targetFolder') ?? '';
    });
  }

  // Show confirmation dialog before deleting
  Future<void> _showDeleteAllConfirmation(BuildContext context) async {
    // Ensure we're in a mounted state
    if (!mounted) return;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm'),
          content: SingleChildScrollView(
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
                _deleteAllSubscriptions();
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
    // Get the position of the button that was clicked
    final RenderBox buttonBox = buttonContext.findRenderObject() as RenderBox;
    final Offset position = buttonBox.localToGlobal(Offset.zero);
    final Size buttonSize = buttonBox.size;

    // Position the popup menu just below and right-aligned with the button
    final result = await showMenu<bool>(
      context: buttonContext,
      position: RelativeRect.fromLTRB(
        position.dx - 100, // Adjust this to position horizontally
        position.dy + buttonSize.height, // Just below the button
        position.dx + buttonSize.width,
        position.dy,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      items: [
        PopupMenuItem<bool>(
          value: null,
          enabled: false,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Delete "${_formatUrlWithFilename(_subscriptions[index], onlyFilename: true)}"?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color:
                  Theme.of(buttonContext).extension<AppColors>()!.folderAction,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        PopupMenuItem<bool>(height: 40, value: false, child: Text('No')),
        PopupMenuItem<bool>(height: 40, value: true, child: Text('Yes')),
      ],
    );

    if (result == true) {
      _deleteSubscription(index);
    }
  }

  void _deleteSubscription(int index) {
    setState(() {
      _subscriptions.removeAt(index);
    });
    _saveSubscriptions(); // Save after deleting
  }

  void _deleteAllSubscriptions() async {
    // Delete all subscriptions
    setState(() {
      _subscriptions.clear();
    });
    _saveSubscriptions(); // Save after deleting
  }

  // Simulate processing with loading indicator
  Future<bool> _processUrl(String url, int index) async {
    if (_targetFolderPath.isEmpty) {
      showNotification(
        'Target folder does not exist. Please select a folder first.',
        status: NotificationStatus.warning,
      );
      return true;
    }

    // Refresh validation status
    _validateSubscriptionUrl(url);

    // Set the item to processing mode
    setState(() {
      _processingItems[index] = true;
    });

    // Simulate processing (replace with actual logic)
    //await Future.delayed(const Duration(seconds: 2));

    // Create instance
    final converter = UrlConverter();
    converter.needResolveDns = _needResolveDNS;
    converter.dnsProvider = _dnsProvider;
    try {
      _configTemplate ??= await rootBundle.loadString('config/template.yaml');
      List<LogInfo> logs = await converter.processSubscription(
        url,
        _targetFolderPath,
        _configTemplate!,
      );
      // Do something with result
      for (var log in logs) {
        addLogEntry(log);
      }
    } catch (e) {
      addLogEntryEx("$url: $e", LogLevel.error);
    } finally {
      // reset state
      setState(() {
        _processingItems[index] = false;
      });
    }

    // Update state when done
    if (mounted) {
      setState(() {
        _processingItems[index] = false;
      });
    }

    return true;
  }

  void _processAllUrls() async {
    // Process all URLs sequentially
    if (_subscriptions.isEmpty) {
      showNotification(
        'No subscriptions to process.',
        status: NotificationStatus.warning,
      );
      return;
    }
    if (_targetFolderPath.isEmpty) {
      showNotification(
        'Target folder does not exist. Please select a folder first.',
        status: NotificationStatus.warning,
      );
      return;
    }
    // Update state to show batch processing is in progress
    setState(() {
      _isBatchProcessing = true;
    });

    // Load template
    _configTemplate ??= await rootBundle.loadString('config/template.yaml');

    List<Future<bool>> futures = [];
    int totalUrls = 0;

    for (int i = 0; i < _subscriptions.length; i++) {
      // Skip if already processing
      if (_processingItems[i] == true) continue;

      totalUrls++;
      futures.add(_processUrl(_subscriptions[i], i));
      //await Future.delayed(const Duration(seconds: 2));
    }

    // Update UI to show processing has started
    showNotification(
      'Processing $totalUrls subscriptions...',
      status: NotificationStatus.info,
    );

    // Non-blocking completion monitoring
    Future.wait(futures)
        .then((_) {
          showNotification(
            'All subscriptions processed',
            status: NotificationStatus.success,
          );
        })
        .catchError((error) {
          showNotification(
            'Error processing subscriptions: $error',
            status: NotificationStatus.error,
          );
        })
        .whenComplete(() {
          // This always runs regardless of success or failure
          setState(() {
            _isBatchProcessing = false;
          });
        });
  }

  void importSubscriptions() async {
    final prefs = await SharedPreferences.getInstance();
    String? lastImportDirectory = prefs.getString('lastImportDirectory');

    // Let user select a file
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      initialDirectory: lastImportDirectory,
    );
    if (result == null) return; // User canceled

    final filePath = result.files.single.path!;
    final file = File(filePath);
    // Remember directory for next time
    final lastSeparator = filePath.lastIndexOf(Platform.pathSeparator);
    if (lastSeparator != -1) {
      lastImportDirectory = filePath.substring(0, lastSeparator);
      prefs.setString('lastImportDirectory', lastImportDirectory);
    }

    // Read file content
    final contents = await file.readAsString();

    // Split by lines and add to subscriptions
    final importedSubscriptions =
        contents.split('\n').where((line) => line.trim().isNotEmpty).toList();

    setState(() {
      _subscriptions.addAll(importedSubscriptions);
      for (var url in importedSubscriptions) {
        _validateSubscriptionUrl(url);
      }
    });

    _saveSubscriptions();

    // Add this: scroll to bottom after adding new subscription
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // Optional: show success message
    showNotification(
      'Imported ${importedSubscriptions.length} subscriptions',
      status: NotificationStatus.success,
    );
  }

  void exportSubscriptions() async {
    final prefs = await SharedPreferences.getInstance();
    String? lastImportDirectory = prefs.getString('lastImportDirectory');

    // Let user select a directory
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      initialDirectory: lastImportDirectory,
    );
    if (selectedDirectory == null) return; // User canceled

    // Remember directory for next time
    prefs.setString('lastImportDirectory', selectedDirectory);

    // Create file path
    final filePath = '$selectedDirectory/subscriptions.txt';
    // Write each subscription URL on a separate line
    final file = File(filePath);
    await file.writeAsString(_subscriptions.join('\n'));

    // Optional: show success message
    showNotification(
      'Exported to $filePath',
      status: NotificationStatus.success,
    );
  }

  void showNotification(
    String text, {
    NotificationStatus status = NotificationStatus.success,
  }) {
    Widget icon;
    switch (status) {
      case NotificationStatus.success:
        icon = Icon(Icons.check_circle, color: Color(0xFF66BB6A)); // Soft Green
        break;
      case NotificationStatus.error:
        icon = Icon(Icons.error, color: Color(0xFFEF5350)); // Soft Red
        break;
      case NotificationStatus.warning:
        icon = Icon(Icons.warning, color: Color(0xFFFFA726)); // Soft Orange
      case NotificationStatus.info:
        icon = Icon(Icons.info, color: Color(0xFF29B6F6)); // Soft Blue
        break;
    }
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            icon,
            SizedBox(width: 8),
            Expanded(child: Text(text)), // Use Expanded instead of Flexible
          ],
        ),
        // Choose one closing method:
        showCloseIcon: true,
        // Or use action but not both:
        // action: SnackBarAction(
        //   label: 'Close',
        //   onPressed: () {
        //     _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
        //   },
        // ),
      ),
    );
  }

  // Helper method to add log entries (call this whenever you want to log something)
  void addLogEntry(LogInfo log) {
    setState(() {
      // New log entry at the top
      _logEntries.insert(0, log);
    });
  }

  void addLogEntryEx(String msg, LogLevel level) {
    setState(() {
      // New log entry at the top
      _logEntries.insert(0, LogInfo(message: msg, level: level));
    });
  }

  void clearAllLogs() {
    setState(() {
      _logEntries.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    // the context parameter represents the location of MyApp widget in the tree, which is above the MaterialApp you're creating.
    // The MaterialApp widget is not the root of your application. the root is the MyApp widget.
    // If we directly use the context of the MyApp widget, we can't access the MaterialApp widget.
    // So we must use a builder to get the context of the MaterialApp widget.
    return MaterialApp(
      title: widget.appInfo.appName,
      //theme: macOSLightTheme(), // Your light theme
      theme: macOSLightThemeFollow(), // default light theme
      darkTheme: macOSDarkThemeFollow(), // Your dark theme
      themeMode: _themeMode, // Force dark mode
      // Add these localization delegates
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English
        // Add more locales as needed
      ],
      scaffoldMessengerKey: _scaffoldMessengerKey, // Add the key to MaterialApp
      home: Builder(
        builder: (context) {
          // ** Here is the key: The Builder widget creates a new context that's positioned inside the MaterialApp**
          return Scaffold(
            key: _scaffoldKey,
            appBar: _buildAppBar(context),
            drawer: _buildLogDrawer(context),
            endDrawer: SettingsDrawer(
              initialIsDarkMode: _themeMode == ThemeMode.dark,
              initialUseDns: _needResolveDNS,
              initialSelectedDnsProvider: _dnsProvider,
              onDnsChanged: (value) {
                // Update your main app state
                _toggleDNS(value);
              },
              onThemeModeChanged: (value) {
                // Handle theme changes
                _toggleTheme(value);
              },
              onDnsProviderChanged: (selectedDnsProvider) {
                _toggleDnsProvider(selectedDnsProvider);
              },
            ),
            body: DropTarget(
              onDragDone: (detail) {
                if (detail.files.isNotEmpty) {
                  final filePath = detail.files.first.path;
                  // If not adding or editing, switch to adding mode
                  if (!_isAddingNew && _editingIndex == -1) {
                    setState(() {
                      _isAddingNew = true;
                      _editingIndex = -1;
                    });
                  }
                  _textController.text = filePath;
                  _validateUrl(filePath);
                }
              },
              onDragEntered: (detail) {
                // Optional: add visual feedback
              },
              onDragExited: (detail) {
                // Optional: remove visual feedback
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
                    // Subscription List (takes most of the space)
                    Expanded(
                      flex:
                          1, // You can increase this value to give it more priority
                      child: _buildSubscriptionList(),
                    ),

                    // Spacing
                    //SizedBox(height: 8),

                    // Batch Process Bar
                    _buildBatchProcessBar(context),

                    // Spacing
                    //SizedBox(height: 8),

                    // Control Panel
                    _buildInputPanel(context),
                  ],
                ),
              ),
            ),

            // Floating Action Button
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                _addNewSubscription();
              },
              tooltip: 'Add new subscription',
              child: const Icon(Icons.add, size: 28),
            ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.miniCenterDocked,
            // Bottom Navigation Bar
            bottomNavigationBar: ControlBottomAppBar(
              fabLocation: FloatingActionButtonLocation.centerDocked,
              shape: null,
              onExport: exportSubscriptions,
              onImport: importSubscriptions,
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'images/logo.png',
            height: 24, // Control the logo size
          ),
          SizedBox(width: 8),
          Text(_appInfo.appName, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(width: 8), // Space between title and version
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
      leadingWidth: 40, // If you have a leading widget, make it narrower
      leading: Builder(
        builder:
            (context) => IconButton(
              icon: Badge.count(
                count: _logEntries.length,
                isLabelVisible: _logEntries.isNotEmpty,
                child: const Icon(Icons.notifications_outlined),
              ),
              onPressed:
                  () => {
                    // Handle add button press
                    // Open the drawer
                    _scaffoldKey.currentState?.openDrawer(),
                    //Scaffold.of(context).openDrawer(),
                  },
              tooltip: 'Log information',
            ),
      ),
      actions: [
        // Settings button
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
                  onPressed: () {
                    Scaffold.of(context).openEndDrawer();
                  },
                ),
              ),
        ),
      ],
    );
  }

  // Create the drawer
  Widget _buildLogDrawer(BuildContext context) {
    return LogDrawer(
      logEntries: _logEntries,
      hoveredLogIndex: _hoveredLogIndex,
      onClearLogs: () {
        HapticFeedback.mediumImpact();
        clearAllLogs();
      },
      onHoverChange: (index) {
        setState(() {
          _hoveredLogIndex = index;
        });
      },
      scaffoldKey: _scaffoldKey,
    );
  }

  Widget _buildSubscriptionList() {
    return Container(
      decoration: const BoxDecoration(),
      child:
          _subscriptions.isEmpty
              ? const Center(child: Text('No subscriptions yet'))
              : ListView.builder(
                controller: _scrollController,
                itemCount: _subscriptions.length,
                itemBuilder: (context, index) {
                  final bool isProcessing = _processingItems[index] ?? false;
                  return SubscriptionListItem(
                    subscription: _subscriptions[index],
                    index: index,
                    isProcessing: isProcessing,
                    validationStatus:
                        _urlValidationStatus[_subscriptions[index]],
                    displayName: _formatUrlWithFilename(_subscriptions[index]),
                    onTap: () => _editSubscription(index),
                    onProcess: () => _processUrl(_subscriptions[index], index),
                    onDelete: _showDeleteConfimMenu,
                  );
                },
              ),
    );
  }

  Widget _buildBatchProcessBar(BuildContext context) {
    return BatchControlBar(
      targetFolderPath: _targetFolderPath,
      isBatchProcessing: _isBatchProcessing,
      onSelectFolder: _selectFolder,
      onProcessAll: _processAllUrls,
      onDeleteAll: () => _showDeleteAllConfirmation(context),
    );
  }

  Widget _buildInputPanel(BuildContext context) {
    return SubscriptionInputPanel(
      isAddingNew: _isAddingNew,
      editingIndex: _editingIndex,
      textController: _textController,
      isValidUrl: _isValidUrl,
      urlValue: _isAddingNew ? _newSubscriptionUrl : _editSubscriptionUrl,
      onValidate: _validateUrl,
      onConfirm:
          _isAddingNew ? _confirmNewSubscription : _confirmEditSubscription,
      onCancel: _isAddingNew ? _cancelNewSubscription : _cancelEditSubscription,
    );
  }
}
