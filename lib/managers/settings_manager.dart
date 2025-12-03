import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';

class SettingsManager extends ChangeNotifier {
  // State
  ThemeMode _themeMode = ThemeMode.light;
  bool _needResolveDNS = false;
  String _dnsProvider = 'DNSPub';
  String _targetFolderPath = '';

  // New Settings
  bool _tunEnable = false;
  int _urlTestInterval = 300;
  int _urlTestTolerance = 100;
  bool _urlTestLazy = true;

  // Getters
  ThemeMode get themeMode => _themeMode;
  bool get needResolveDNS => _needResolveDNS;
  String get dnsProvider => _dnsProvider;
  String get targetFolderPath => _targetFolderPath;

  bool get tunEnable => _tunEnable;
  int get urlTestInterval => _urlTestInterval;
  int get urlTestTolerance => _urlTestTolerance;
  bool get urlTestLazy => _urlTestLazy;

  // Constructor
  SettingsManager();

  // Initialize
  Future<void> init() async {
    await _loadSettings();
  }

  // Load settings
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode =
        prefs.getBool('darkMode') ?? false ? ThemeMode.dark : ThemeMode.light;
    _needResolveDNS = prefs.getBool('needResolveDNS') ?? false;
    _dnsProvider = prefs.getString('dnsProvider') ?? 'DNSPub';
    _targetFolderPath = prefs.getString('targetFolder') ?? '';

    _tunEnable = prefs.getBool('tunEnable') ?? false;
    _urlTestInterval = prefs.getInt('urlTestInterval') ?? 300;
    _urlTestTolerance = prefs.getInt('urlTestTolerance') ?? 100;
    _urlTestLazy = prefs.getBool('urlTestLazy') ?? true;

    notifyListeners();
  }

  // Toggle theme
  Future<void> toggleTheme(bool darkMode) async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = darkMode ? ThemeMode.dark : ThemeMode.light;
    await prefs.setBool('darkMode', darkMode);
    notifyListeners();
  }

  // Toggle DNS resolution
  Future<void> toggleDNS(bool needResolveDNS) async {
    final prefs = await SharedPreferences.getInstance();
    _needResolveDNS = needResolveDNS;
    await prefs.setBool('needResolveDNS', needResolveDNS);
    notifyListeners();
  }

  // Toggle DNS provider
  Future<void> toggleDnsProvider(String selectedDnsProvider) async {
    final prefs = await SharedPreferences.getInstance();
    _dnsProvider = selectedDnsProvider;
    await prefs.setString('dnsProvider', _dnsProvider);
    notifyListeners();
  }

  // Update Tun Enable
  Future<void> setTunEnable(bool enable) async {
    final prefs = await SharedPreferences.getInstance();
    _tunEnable = enable;
    await prefs.setBool('tunEnable', enable);
    notifyListeners();
  }

  // Update URL Test Interval
  Future<void> setUrlTestInterval(int interval) async {
    final prefs = await SharedPreferences.getInstance();
    _urlTestInterval = interval;
    await prefs.setInt('urlTestInterval', interval);
    notifyListeners();
  }

  // Update URL Test Tolerance
  Future<void> setUrlTestTolerance(int tolerance) async {
    final prefs = await SharedPreferences.getInstance();
    _urlTestTolerance = tolerance;
    await prefs.setInt('urlTestTolerance', tolerance);
    notifyListeners();
  }

  // Update URL Test Lazy
  Future<void> setUrlTestLazy(bool lazy) async {
    final prefs = await SharedPreferences.getInstance();
    _urlTestLazy = lazy;
    await prefs.setBool('urlTestLazy', lazy);
    notifyListeners();
  }

  // Select target folder
  Future<String?> selectFolder() async {
    final prefs = await SharedPreferences.getInstance();
    final targetFolder = prefs.getString('targetFolder');

    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      initialDirectory: targetFolder,
    );

    if (selectedDirectory != null) {
      _targetFolderPath = selectedDirectory;
      await prefs.setString('targetFolder', _targetFolderPath);
      notifyListeners();
      return _targetFolderPath;
    }
    return null;
  }
}
