import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import '../services/clash_service.dart';

class ProfileManager extends ChangeNotifier {
  final ClashService _clashService = ClashService();
  List<String> _profiles = [];
  bool _isLoading = false;
  String? _activeProfile;
  int? _activeProfileDelay; // Delay in milliseconds for the active profile
  bool _delayTestFailed = false; // Track if the delay test failed
  bool _hasRetriedOnce = false; // Track if we've already auto-retried

  List<String> get profiles => List.unmodifiable(_profiles);
  bool get isLoading => _isLoading;
  String? get activeProfile => _activeProfile;
  int? get activeProfileDelay => _activeProfileDelay;
  bool get delayTestFailed => _delayTestFailed;

  /// Loads profiles (YAML files) from the specified directory.
  Future<void> loadProfiles(String directoryPath) async {
    if (directoryPath.isEmpty) {
      _profiles = [];
      notifyListeners();
      return;
    }

    try {
      final dir = Directory(directoryPath);
      if (await dir.exists()) {
        final entities = await dir.list().toList();
        _profiles =
            entities
                .whereType<File>()
                .where(
                  (file) =>
                      path.extension(file.path).toLowerCase() == '.yaml' ||
                      path.extension(file.path).toLowerCase() == '.yml',
                )
                .map((file) => path.basenameWithoutExtension(file.path))
                .toList();
        _profiles.sort(); // Sort alphabetically
      } else {
        _profiles = [];
      }
    } catch (e) {
      debugPrint('Error loading profiles: $e');
      _profiles = [];
    }
    notifyListeners();
  }

  /// Checks the currently active profile in ClashX Meta.
  Future<void> checkActiveProfile() async {
    _activeProfile = await _clashService.getCurrentProfile();
    notifyListeners();

    // Test delay for the active profile in background
    _testActiveProfileDelay();
  }

  /// Switches to the specified profile.
  Future<bool> switchProfile(String profileName) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _clashService.setActiveProfile(profileName);

      if (success) {
        _activeProfile = profileName;
        _activeProfileDelay = null; // Reset delay while testing
        _delayTestFailed = false; // Reset error state
        _hasRetriedOnce = false; // Reset retry flag
        notifyListeners();

        // Test delay in background after successful switch
        _testActiveProfileDelay();
      }

      return success;
    } catch (e) {
      debugPrint('Error switching profile: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Manually retry the delay test (called when user taps the error badge)
  void retryDelayTest() {
    _delayTestFailed = false;
    _activeProfileDelay = null; // Show "Testing..." state
    notifyListeners();

    _testActiveProfileDelay(isManualRetry: true);
  }

  /// Tests the delay for the active profile in the background.
  void _testActiveProfileDelay({bool isManualRetry = false}) {
    // Run in background without waiting
    Future(() async {
      // Wait a moment for config to load
      await Future.delayed(const Duration(milliseconds: 800));

      final delay = await _clashService.testAutoGroupDelay();

      if (delay != null) {
        _activeProfileDelay = delay;
        _delayTestFailed = false;
        _hasRetriedOnce = false; // Reset on success
        notifyListeners();
      } else {
        // Test failed
        _delayTestFailed = true;
        _activeProfileDelay = null;
        notifyListeners();

        // Auto-retry once after 10 seconds if this wasn't a manual retry and we haven't retried yet
        if (!isManualRetry && !_hasRetriedOnce) {
          _hasRetriedOnce = true;

          Future.delayed(const Duration(seconds: 10), () {
            if (_delayTestFailed && _activeProfileDelay == null) {
              retryDelayTest();
            }
          });
        }
      }
    });
  }
}
