import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';

class SettingsManager extends ChangeNotifier {
  // State
  ThemeMode _themeMode = ThemeMode.light;
  bool _needResolveDNS = false;
  String _dnsProvider = 'DNSPub';
  String _targetFolderPath = '';

  // Getters
  ThemeMode get themeMode => _themeMode;
  bool get needResolveDNS => _needResolveDNS;
  String get dnsProvider => _dnsProvider;
  String get targetFolderPath => _targetFolderPath;

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
