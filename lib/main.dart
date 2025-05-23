import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/url_converter.dart';
import 'services/loginfo.dart';
import 'themes.dart';

// Model class to hold app info
class AppInfo {
  final String appName;
  final String appVersion;

  AppInfo({required this.appName, required this.appVersion});
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final packageInfo = await PackageInfo.fromPlatform();

  final appInfo = AppInfo(
    appName: packageInfo.appName,
    appVersion: packageInfo.version,
  );

  runApp(MyApp(appInfo: appInfo));
}

enum NotificationStatus { success, error, warning, info }

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
      String trimmedValue = value.trim().toLowerCase();
      _isValidUrl =
          trimmedValue.startsWith('https://') ||
          trimmedValue.startsWith('vmess://') ||
          trimmedValue.startsWith('vless://') ||
          trimmedValue.startsWith('trojan://') ||
          trimmedValue.startsWith('ss://');
    });
  }

  String _formatUrlWithFilename(String url, {onlyFilename = false}) {
    try {
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
      _dnsProvider = prefs.getString('dnsProvider') ?? 'Google';
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
        _subscriptions.add(_newSubscriptionUrl);
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

  void _editSubscription(index) {
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
        _subscriptions[_editingIndex] = _editSubscriptionUrl;
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

  Future<void> _showInfo(String title, String desc) async {
    return showDialog(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
            title: Text(title),
            content: Text(desc),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, 'Cancel'),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'OK'),
                child: const Text('OK'),
              ),
            ],
          ),
    );
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
        icon = Icon(Icons.check_circle, color: Colors.green);
        break;
      case NotificationStatus.error:
        icon = Icon(Icons.error, color: Colors.red);
        break;
      case NotificationStatus.warning:
        icon = Icon(Icons.warning, color: Colors.orange);
      case NotificationStatus.info:
        icon = Icon(Icons.info, color: Colors.blue);
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

  Icon _getLogLevelIcon(LogLevel level) {
    switch (level) {
      case LogLevel.error:
        return const Icon(Icons.error_outline, color: Colors.red);
      case LogLevel.warning:
        return const Icon(Icons.warning_amber, color: Colors.orange);
      case LogLevel.info:
        return const Icon(Icons.info_outline, color: Colors.blue);
      case LogLevel.debug:
        return const Icon(Icons.bug_report, color: Colors.blueGrey);
      case LogLevel.success:
        return const Icon(Icons.check_circle, color: Colors.green);
      case LogLevel.start:
        return const Icon(
          Icons.play_circle_outline,
          color: Colors.indigoAccent,
        );
      case LogLevel.file:
        return const Icon(Icons.file_copy_outlined, color: Colors.purple);
      default: // LogLevel.normal
        return const Icon(Icons.circle, size: 12, color: Colors.lime);
    }
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
            body: Padding(
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

            // Floating Action Button
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                _addNewSubscription();
              },
              tooltip: 'Add new subscription',
              child: const Icon(Icons.add),
            ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.miniCenterDocked,
            // Bottom Navigation Bar
            bottomNavigationBar: _ControlBottomAppBar(
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
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade600,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              "v${_appInfo.appVersion}",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade200,
                fontWeight: FontWeight.w500,
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
              (context) => IconButton(
                icon: Icon(Icons.settings),
                tooltip: 'Settings',
                onPressed: () {
                  Scaffold.of(context).openEndDrawer();
                },
              ),
        ),
      ],
    );
  }

  // Create the drawer
  Widget _buildLogDrawer(BuildContext context) {
    // Track which log entry is being hovered
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.70, // 70% of screen width
      child: Column(
        children: [
          AppBar(
            toolbarHeight: 48,
            leadingWidth: 40,
            titleSpacing: 0,
            automaticallyImplyLeading: false,
            title: Text('Logs', style: Theme.of(context).textTheme.titleSmall),
            actions: [
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () => _scaffoldKey.currentState?.closeDrawer(),
                //onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          // Log entries list
          Expanded(
            child:
                _logEntries.isEmpty
                    ? const Center(child: Text('No log entries'))
                    : ListView.builder(
                      itemCount: _logEntries.length,
                      itemBuilder: (context, index) {
                        return MouseRegion(
                          onEnter:
                              (_) => setState(() => _hoveredLogIndex = index),
                          onExit: (_) {
                            // Only clear if this item is currently hovered
                            if (_hoveredLogIndex == index) {
                              setState(() => _hoveredLogIndex = null);
                            }
                          },
                          child: ListTile(
                            title:
                                _hoveredLogIndex == index
                                    // Expanded view when hovered
                                    ? Text(_logEntries[index].message)
                                    // Single line with ellipsis when not hovered
                                    : Text(
                                      _logEntries[index].message,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                            subtitle: Text(
                              _logEntries[index].timestamp,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            leading: _getLogLevelIcon(_logEntries[index].level),
                          ),
                        );
                      },
                    ),
          ),

          // Clear logs button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  clearAllLogs();
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear'),
                style: ElevatedButton.styleFrom(
                  iconColor: Colors.red,
                  minimumSize: const Size(0, 50),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionList() {
    return Container(
      decoration: BoxDecoration(
        //color: Colors.grey[200],
        //borderRadius: BorderRadius.circular(8.0),
      ),
      child:
          _subscriptions.isEmpty
              ? const Center(child: Text('No subscriptions yet'))
              : ListView.builder(
                controller: _scrollController,
                itemCount: _subscriptions.length,
                itemBuilder: (context, index) {
                  final bool isProcessing = _processingItems[index] ?? false;
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      vertical: 4.0,
                      horizontal: 8.0,
                    ),
                    child: ListTile(
                      dense: true,
                      onTap: () {
                        _editSubscription(index);
                      },
                      title: Text(
                        (_subscriptions[index]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        _formatUrlWithFilename(_subscriptions[index]),
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Play button
                          IconButton(
                            icon:
                                isProcessing
                                    ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.0,
                                      ),
                                    )
                                    : Icon(
                                      Icons.play_arrow,
                                      color:
                                          Theme.of(
                                            context,
                                          ).extension<AppColors>()!.saveAction,
                                    ),
                            tooltip: "Process this subscription",
                            onPressed:
                                isProcessing
                                    ? null
                                    : () => _processUrl(
                                      _subscriptions[index],
                                      index,
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
                                  onPressed:
                                      () => _showDeleteConfimMenu(
                                        index,
                                        buttonContext,
                                      ),
                                ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }

  Widget _buildBatchProcessBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
      decoration: BoxDecoration(
        //color: Colors.grey[200],
        //borderRadius: BorderRadius.circular(8.0),
      ),
      child: ListTile(
        leading: IconButton(
          icon: Icon(
            Icons.folder_open,
            color: Theme.of(context).extension<AppColors>()!.folderAction,
          ),
          onPressed: _selectFolder,
          tooltip: "Select Folder",
        ),
        title: TextField(
          controller: TextEditingController(text: _targetFolderPath),
          enabled: false,
          decoration: InputDecoration(
            hintText: "Select Clash Config Folder ...",
          ),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _isBatchProcessing
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.0),
                )
                : IconButton(
                  icon: Icon(
                    Icons.fast_forward,
                    color:
                        Theme.of(context).extension<AppColors>()!.forwardAction,
                  ),
                  onPressed: _processAllUrls,
                  tooltip: "Process all URLs",
                ),
            _isBatchProcessing ? SizedBox(width: 12) : SizedBox(width: 0.0),
            IconButton(
              icon: Icon(
                Icons.delete_forever,
                color: Theme.of(context).extension<AppColors>()!.deleteAction,
              ),
              onPressed: () {
                _showDeleteAllConfirmation(context);
              },
              tooltip: "Delete all URLs",
            ),
            SizedBox(width: 6.0),
          ],
        ),
      ),
    );
  }

  Widget _buildInputPanel(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 0.0),
      decoration: BoxDecoration(
        //color: Colors.grey[200],
        //borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          // URL Input or Add Button
          (_isAddingNew && _editingIndex == -1)
              ? Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          decoration: InputDecoration(
                            hintText: 'Enter URL',
                            errorText:
                                _newSubscriptionUrl.isNotEmpty && !_isValidUrl
                                    ? 'Only support https:// vmess:// vless:// trojan:// ss://'
                                    : null,
                          ),
                          onChanged: _validateUrl,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.check,
                          color:
                              Theme.of(
                                context,
                              ).extension<AppColors>()!.saveAction,
                        ),
                        onPressed: _confirmNewSubscription,
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color:
                              Theme.of(
                                context,
                              ).extension<AppColors>()!.deleteAction,
                        ),
                        onPressed: _cancelNewSubscription,
                      ),
                    ],
                  ),
                ),
              )
              : const SizedBox.shrink(), // Explicit zero-sized widget
          (_isAddingNew && _editingIndex == -1)
              ? const SizedBox(height: 8.0)
              : const SizedBox.shrink(),
          (!_isAddingNew && _editingIndex != -1)
              ? Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          decoration: InputDecoration(
                            hintText: 'Enter URL',
                            border: InputBorder.none,
                            errorText:
                                _editSubscriptionUrl.isNotEmpty && !_isValidUrl
                                    ? 'Only support https:// vmess:// vless:// trojan:// ss://'
                                    : null,
                          ),
                          onChanged: _validateUrl,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.check,
                          color:
                              Theme.of(
                                context,
                              ).extension<AppColors>()!.saveAction,
                        ),
                        onPressed: _confirmEditSubscription,
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color:
                              Theme.of(
                                context,
                              ).extension<AppColors>()!.deleteAction,
                        ),
                        onPressed: _cancelEditSubscription,
                      ),
                    ],
                  ),
                ),
              )
              : const SizedBox.shrink(),
          (!_isAddingNew && _editingIndex != -1)
              ? const SizedBox(height: 8.0)
              : const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class _ControlBottomAppBar extends StatelessWidget {
  const _ControlBottomAppBar({
    this.fabLocation = FloatingActionButtonLocation.endDocked,
    this.shape = const CircularNotchedRectangle(),
    this.onImport,
    this.onExport,
  });

  final FloatingActionButtonLocation fabLocation;
  final NotchedShape? shape;
  // Using separate callbacks instead of a list
  final VoidCallback? onImport;
  final VoidCallback? onExport;

  static final List<FloatingActionButtonLocation> centerLocations =
      <FloatingActionButtonLocation>[
        FloatingActionButtonLocation.centerDocked,
        FloatingActionButtonLocation.centerFloat,
      ];

  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled:
          true, //a maximum height limit of approximately 60% of the screen height. If you need a taller sheet, you can use the isScrollControlled: true parameter
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How to use',
                //style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.upload),
                title: const Text('Import Subscriptions'),
                subtitle: Text(
                  'Load subscription URLs from a file, where each line contains a single URL.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Export Subscriptions'),
                subtitle: Text(
                  'Save all added subscription URLs to a file, with each URL on a separate line.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.fast_forward),
                title: const Text('Process All Subscriptions'),
                subtitle: Text(
                  'Retrieve and format all protocols from all added subscription URLs.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: const Text('Subscriptions Target Path'),
                subtitle: Text(
                  'Process all subscription protocols in YAML format and save them in the specified folder.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: const Text('Logs of processing'),
                subtitle: Text(
                  'Logs record all subscription processing results, hover over each log to see the detail.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.format_align_center),
                title: const Text('Supported Formats'),
                subtitle: Text(
                  'Includes vmess, vless, trojan, and Shadowsocks (ss) protocols. Vmess provides secure, efficient data transmission; vless offers similar benefits with enhanced performance; trojan is optimized for stealth and reliability; and Shadowsocks is renowned for its simplicity and strong encryption.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showQuitConfimMenu(BuildContext buttonContext) async {
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
            'Want to quit ?',
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
      if (Platform.isMacOS) {
        exit(0); // Clean exit with code 0
      } else {
        SystemNavigator.pop(); // For mobile platforms
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: shape,
      child: Row(
        children: <Widget>[
          Builder(
            builder:
                (buttonContext) => IconButton(
                  onPressed: () {
                    // Quit the app
                    _showQuitConfimMenu(buttonContext);
                  },
                  icon: Icon(
                    Icons.power_settings_new_outlined,
                    color: Theme.of(context).extension<AppColors>()?.quitAction,
                  ),
                  tooltip: 'Quit',
                ),
          ),
          SizedBox(width: 4),
          ElevatedButton.icon(
            onPressed: onImport,
            icon: const Icon(Icons.upload),
            label: const Text('Import'),
            style: ElevatedButton.styleFrom(
              iconColor: Theme.of(context).extension<AppColors>()?.saveAction,
            ),
          ),

          if (centerLocations.contains(fabLocation)) const Spacer(),

          ElevatedButton.icon(
            onPressed: onExport,
            icon: const Icon(Icons.share),
            label: const Text('Export'),
            style: ElevatedButton.styleFrom(
              iconColor: Theme.of(context).extension<AppColors>()?.infoAction,
            ),
          ),
          SizedBox(width: 4),
          IconButton(
            onPressed: () {
              _showBottomSheet(context);
            },
            icon: Icon(
              Icons.question_mark_outlined,
              color: Theme.of(context).extension<AppColors>()?.folderAction,
            ),
            tooltip: 'How to use',
          ),
        ],
      ),
    );
  }
}

// Create this separate widget
class SettingsDrawer extends StatefulWidget {
  final bool initialUseDns;
  final bool initialIsDarkMode;
  final String initialSelectedDnsProvider;
  final Function(bool useDns) onDnsChanged;
  final Function(bool isDarkMode) onThemeModeChanged;
  final Function(String selectedDnsProvider) onDnsProviderChanged;

  const SettingsDrawer({
    super.key,
    required this.initialUseDns,
    required this.initialIsDarkMode,
    required this.initialSelectedDnsProvider,
    required this.onDnsChanged,
    required this.onThemeModeChanged,
    required this.onDnsProviderChanged,
  });

  @override
  SettingsDrawerState createState() => SettingsDrawerState();
}

class SettingsDrawerState extends State<SettingsDrawer> {
  bool _useDns = true;
  bool _isDarkMode = false;
  String _selectedDnsProvider = 'Google'; // Default selection

  // List of DNS providers
  final List<String> _dnsProviders = [
    'Google',
    'Cloudflare',
    'Alibaba',
    'CNNIC',
    'DNSPod',
    'NextDNS',
  ];

  @override
  void initState() {
    super.initState();
    _useDns = widget.initialUseDns;
    _isDarkMode = widget.initialIsDarkMode;
    _selectedDnsProvider = widget.initialSelectedDnsProvider;
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 300, // Slim width
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.settings,
                    color:
                        Theme.of(context).extension<AppColors>()!.folderAction,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Settings',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Close',
                  ),
                ],
              ),
              Divider(),
              SizedBox(height: 16),

              // DNS Setting with explanation
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Auto-resolve DNS',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                trailing: Switch(
                  value: _useDns,
                  onChanged: (value) {
                    setState(() {
                      _useDns = value;
                    });
                    // Add your DNS toggle logic here
                    widget.onDnsChanged(value); // Notify the parent
                  },
                ),
              ),

              // DNS Info Card
              Card(
                color: Theme.of(context).extension<AppColors>()?.cardInfoColor,
                elevation: 0,
                margin: EdgeInsets.only(bottom: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).cardTheme.surfaceTintColor,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Why this matters:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color:
                                  Theme.of(context).cardTheme.surfaceTintColor,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'When enabled, server domains will be automatically resolved to IP addresses. This improves reliability when DNS is blocked but may increase subscription processing time.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),

              // DNS Provider Selection Chips
              if (_useDns) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, bottom: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DNS Provider:',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            _dnsProviders.map((provider) {
                              return ChoiceChip(
                                label: Text(provider),
                                selected: _selectedDnsProvider == provider,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _selectedDnsProvider = provider;
                                    });
                                    // Handle provider change
                                    widget.onDnsProviderChanged(provider);
                                  }
                                },
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHigh
                                    .withValues(alpha: 0.5),
                                selectedColor:
                                    Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer,
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                ),
              ],

              Divider(),

              // Theme Setting
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Dark Theme',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                trailing: Switch(
                  value: _isDarkMode,
                  onChanged: (value) {
                    setState(() {
                      _isDarkMode = value;
                    });
                    // Add your theme toggle logic here
                    widget.onThemeModeChanged(value);
                  },
                ),
                leading: Icon(
                  _isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: _isDarkMode ? Colors.blueGrey : Colors.amber,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
