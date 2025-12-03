import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;
import '../services/url_converter.dart';
import '../services/loginfo.dart';
import '../services/file_utils.dart';
import '../services/http_client.dart';

class SubscriptionManager extends ChangeNotifier {
  // State
  List<String> _subscriptions = [];
  final Map<int, bool> _processingItems = {};
  final Map<String, bool?> _urlValidationStatus = {};
  final List<LogInfo> _logEntries = [];
  bool _isBatchProcessing = false;
  String? _configTemplate;

  // Getters
  List<String> get subscriptions => List.unmodifiable(_subscriptions);
  Map<int, bool> get processingItems => Map.unmodifiable(_processingItems);
  Map<String, bool?> get urlValidationStatus =>
      Map.unmodifiable(_urlValidationStatus);
  List<LogInfo> get logEntries => List.unmodifiable(_logEntries);
  bool get isBatchProcessing => _isBatchProcessing;

  // Constructor
  SubscriptionManager();

  // Initialize
  Future<void> init() async {
    await _loadSubscriptions();
  }

  // Load subscriptions
  Future<void> _loadSubscriptions() async {
    final prefs = await SharedPreferences.getInstance();
    _subscriptions = prefs.getStringList('subscriptions') ?? [];
    notifyListeners();
    // Validate all loaded subscriptions
    for (var url in _subscriptions) {
      validateSubscriptionUrl(url);
    }
  }

  // Save subscriptions
  Future<void> _saveSubscriptions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('subscriptions', _subscriptions);
  }

  // Add subscription
  Future<void> addSubscription(String url) async {
    final trimmedUrl = url.trim();
    if (trimmedUrl.isNotEmpty) {
      _subscriptions.add(trimmedUrl);
      await _saveSubscriptions();
      validateSubscriptionUrl(trimmedUrl);
      notifyListeners();
    }
  }

  // Edit subscription
  Future<void> editSubscription(int index, String newUrl) async {
    final trimmedUrl = newUrl.trim();
    if (trimmedUrl.isNotEmpty && index >= 0 && index < _subscriptions.length) {
      _subscriptions[index] = trimmedUrl;
      await _saveSubscriptions();
      validateSubscriptionUrl(trimmedUrl);
      notifyListeners();
    }
  }

  // Delete subscription
  Future<void> deleteSubscription(int index) async {
    if (index >= 0 && index < _subscriptions.length) {
      _subscriptions.removeAt(index);
      await _saveSubscriptions();
      notifyListeners();
    }
  }

  // Delete all subscriptions
  Future<void> deleteAllSubscriptions() async {
    _subscriptions.clear();
    await _saveSubscriptions();
    notifyListeners();
  }

  // Validate URL (Async)
  Future<void> validateSubscriptionUrl(String url) async {
    if (url.isEmpty) return;

    // Check if it's a local file
    if (FileUtils.isLocalFilePath(url)) {
      _urlValidationStatus[url] = FileUtils.fileExists(url);
      notifyListeners();
      return;
    }

    // Set status to null (loading) for remote URLs
    _urlValidationStatus[url] = null;
    notifyListeners();

    try {
      final uri = Uri.parse(url);

      // Only validate http/https URLs
      if (!uri.isScheme('http') && !uri.isScheme('https')) {
        _urlValidationStatus[url] = true;
        notifyListeners();
        return;
      }

      // Use ProxyService to validate URL with system proxy support
      final proxyService = ProxyService();
      final isValid = await proxyService.validateUrl(url);
      _urlValidationStatus[url] = isValid;
    } catch (e) {
      _urlValidationStatus[url] = false;
    }
    notifyListeners();
  }

  // Process single URL
  Future<bool> processUrl(
    String url,
    int index,
    String targetFolderPath, {
    bool needResolveDNS = false,
    String dnsProvider = '',
    bool tunEnable = false,
    int urlTestInterval = 300,
    int urlTestTolerance = 100,
    bool urlTestLazy = true,
  }) async {
    if (targetFolderPath.isEmpty) {
      addLogEntry(
        LogInfo(message: 'Target folder is empty', level: LogLevel.error),
      );
      return false;
    }

    // Refresh validation status
    validateSubscriptionUrl(url);

    _processingItems[index] = true;
    notifyListeners();

    try {
      final converter = UrlConverter();
      converter.needResolveDns = needResolveDNS;
      converter.dnsProvider = dnsProvider;
      converter.tunEnable = tunEnable;
      converter.urlTestInterval = urlTestInterval;
      converter.urlTestTolerance = urlTestTolerance;
      converter.urlTestLazy = urlTestLazy;

      _configTemplate ??= await rootBundle.loadString('config/template.yaml');

      List<LogInfo> logs = await converter.processSubscription(
        url,
        targetFolderPath,
        _configTemplate!,
      );

      for (var log in logs) {
        addLogEntry(log);
      }
      return true;
    } catch (e) {
      addLogEntry(LogInfo(message: "$url: $e", level: LogLevel.error));
      return false;
    } finally {
      _processingItems[index] = false;
      notifyListeners();
    }
  }

  // Process all URLs
  Future<void> processAllUrls(
    String targetFolderPath, {
    bool needResolveDNS = false,
    String dnsProvider = '',
    bool tunEnable = false,
    int urlTestInterval = 300,
    int urlTestTolerance = 100,
    bool urlTestLazy = true,
  }) async {
    if (_subscriptions.isEmpty) {
      addLogEntry(
        LogInfo(
          message: 'No subscriptions to process',
          level: LogLevel.warning,
        ),
      );
      return;
    }
    if (targetFolderPath.isEmpty) {
      addLogEntry(
        LogInfo(message: 'Target folder is empty', level: LogLevel.error),
      );
      return;
    }

    _isBatchProcessing = true;
    notifyListeners();

    _configTemplate ??= await rootBundle.loadString('config/template.yaml');

    List<Future<bool>> futures = [];

    for (int i = 0; i < _subscriptions.length; i++) {
      if (_processingItems[i] == true) continue;
      futures.add(
        processUrl(
          _subscriptions[i],
          i,
          targetFolderPath,
          needResolveDNS: needResolveDNS,
          dnsProvider: dnsProvider,
          tunEnable: tunEnable,
          urlTestInterval: urlTestInterval,
          urlTestTolerance: urlTestTolerance,
          urlTestLazy: urlTestLazy,
        ),
      );
    }

    addLogEntry(
      LogInfo(
        message: 'Processing ${_subscriptions.length} subscriptions...',
        level: LogLevel.info,
      ),
    );

    try {
      await Future.wait(futures);
      addLogEntry(
        LogInfo(
          message: 'All subscriptions processed',
          level: LogLevel.success,
        ),
      );
    } catch (error) {
      addLogEntry(
        LogInfo(
          message: 'Error processing subscriptions: $error',
          level: LogLevel.error,
        ),
      );
    } finally {
      _isBatchProcessing = false;
      notifyListeners();
    }
  }

  // Import subscriptions
  Future<int> importSubscriptions() async {
    final prefs = await SharedPreferences.getInstance();
    String? lastImportDirectory = prefs.getString('lastImportDirectory');

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      initialDirectory: lastImportDirectory,
    );

    if (result == null) return 0;

    final filePath = result.files.single.path!;
    final file = File(filePath);

    final lastSeparator = filePath.lastIndexOf(Platform.pathSeparator);
    if (lastSeparator != -1) {
      lastImportDirectory = filePath.substring(0, lastSeparator);
      prefs.setString('lastImportDirectory', lastImportDirectory);
    }

    final contents = await file.readAsString();
    final importedSubscriptions =
        contents.split('\n').where((line) => line.trim().isNotEmpty).toList();

    if (importedSubscriptions.isNotEmpty) {
      _subscriptions.addAll(importedSubscriptions);
      await _saveSubscriptions();
      for (var url in importedSubscriptions) {
        validateSubscriptionUrl(url);
      }
      notifyListeners();
    }

    return importedSubscriptions.length;
  }

  // Export subscriptions
  Future<String?> exportSubscriptions() async {
    final prefs = await SharedPreferences.getInstance();
    String? lastImportDirectory = prefs.getString('lastImportDirectory');

    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      initialDirectory: lastImportDirectory,
    );

    if (selectedDirectory == null) return null;

    prefs.setString('lastImportDirectory', selectedDirectory);

    final filePath = '$selectedDirectory/subscriptions.txt';
    final file = File(filePath);
    await file.writeAsString(_subscriptions.join('\n'));

    return filePath;
  }

  // Log management
  void addLogEntry(LogInfo log) {
    _logEntries.insert(0, log);
    notifyListeners();
  }

  void clearAllLogs() {
    _logEntries.clear();
    notifyListeners();
  }

  // Helper: Format URL for display
  String formatUrlWithFilename(String url, {bool onlyFilename = false}) {
    try {
      if (FileUtils.isLocalFilePath(url)) {
        final filePath = url.trim();
        final parentDir = path.basename(path.dirname(filePath));
        final baseName = path.basenameWithoutExtension(filePath);
        final displayName = '${parentDir}_$baseName';
        return onlyFilename ? displayName : 'local: $displayName';
      }

      final uri = Uri.parse(url);
      final converter = UrlConverter();
      String filename = converter.extractFileNameFromUrlEx(
        url,
        defaultExtension: '',
      );
      return onlyFilename ? filename : "${uri.host}: $filename";
    } catch (e) {
      return url;
    }
  }

  // Helper: Check if URL is valid (syntax check)
  bool isValidUrlSyntax(String value) {
    String trimmedValue = value.trim();
    String lowerValue = trimmedValue.toLowerCase();

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

    bool isLocalFile = FileUtils.isValidLocalFile(trimmedValue);

    return isProtocolUrl || isLocalFile;
  }
}
