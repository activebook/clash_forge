import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import '../services/clash_service.dart';

/// States for the profile switching process
enum SwitchingState {
  idle, // Not switching
  writingConfig, // Writing config to defaults
  restarting, // Restarting ClashX Meta
  waitingForApi, // Waiting for API to respond
  testingDelay, // Running delay test
  completed, // Switch completed successfully
  completedWithWarning, // Switch completed but delay failed
  failed, // Switch failed
}

class ProfileManager extends ChangeNotifier {
  final ClashService _clashService = ClashService();
  List<String> _profiles = [];
  bool _isLoading = false;
  String? _activeProfile;
  int? _activeProfileDelay; // Delay in milliseconds for the active profile
  bool _delayTestFailed = false; // Track if the delay test failed
  bool _hasRetriedOnce = false; // Track if we've already auto-retried

  // Switching overlay state
  SwitchingState _switchingState = SwitchingState.idle;
  String _switchingMessage = '';

  List<String> get profiles => List.unmodifiable(_profiles);
  bool get isLoading => _isLoading;
  String? get activeProfile => _activeProfile;
  int? get activeProfileDelay => _activeProfileDelay;
  bool get delayTestFailed => _delayTestFailed;
  SwitchingState get switchingState => _switchingState;
  String get switchingMessage => _switchingMessage;
  bool get isSwitching =>
      _switchingState != SwitchingState.idle &&
      _switchingState != SwitchingState.completed &&
      _switchingState != SwitchingState.completedWithWarning &&
      _switchingState != SwitchingState.failed;

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

  /// Updates the switching state and notifies listeners
  void _updateSwitchingState(SwitchingState state, String message) {
    _switchingState = state;
    _switchingMessage = message;
    notifyListeners();
  }

  /// Clears the switching overlay after a delay
  void _clearSwitchingStateAfterDelay() {
    Future.delayed(const Duration(seconds: 2), () {
      if (_switchingState == SwitchingState.completed ||
          _switchingState == SwitchingState.completedWithWarning ||
          _switchingState == SwitchingState.failed) {
        _switchingState = SwitchingState.idle;
        _switchingMessage = '';
        notifyListeners();
      }
    });
  }

  /// Switches to the specified profile.
  /// This now includes full app restart for the change to take effect.
  Future<bool> switchProfile(String profileName) async {
    _isLoading = true;
    _activeProfileDelay = null; // Reset delay
    _delayTestFailed = false;
    _hasRetriedOnce = false;
    notifyListeners();

    try {
      // Step 1: Write config
      _updateSwitchingState(
        SwitchingState.writingConfig,
        'Writing configuration...',
      );
      final writeSuccess = await _clashService.setActiveProfile(profileName);

      if (!writeSuccess) {
        _updateSwitchingState(SwitchingState.failed, 'Failed to write config');
        _clearSwitchingStateAfterDelay();
        return false;
      }

      // Optimistic UI update - switch appears active immediately
      _activeProfile = profileName;
      notifyListeners();

      // Brief pause for UI
      await Future.delayed(const Duration(milliseconds: 500));

      // Step 2: Restart ClashX Meta
      _updateSwitchingState(
        SwitchingState.restarting,
        'Restarting ClashX Meta...',
      );
      await Future.delayed(
        const Duration(milliseconds: 300),
      ); // Brief pause for UI

      final restartSuccess = await _clashService.restartClashXMeta();

      if (!restartSuccess) {
        _updateSwitchingState(
          SwitchingState.failed,
          'Failed to restart ClashX Meta',
        );
        _clearSwitchingStateAfterDelay();
        return false;
      }

      // Step 3: Test delay
      _updateSwitchingState(
        SwitchingState.testingDelay,
        'Testing connection...',
      );
      final delay = await _clashService.testAutoGroupDelay();

      if (delay != null) {
        _activeProfileDelay = delay;
        _delayTestFailed = false;
        _updateSwitchingState(
          SwitchingState.completed,
          'Switched successfully!\n(${delay}ms)',
        );
      } else {
        _delayTestFailed = true;
        _updateSwitchingState(
          SwitchingState.completedWithWarning,
          'Switched successfully!\n(but delay test failed)',
        );
      }

      _clearSwitchingStateAfterDelay();
      return true;
    } catch (e) {
      debugPrint('Error switching profile: $e');
      _updateSwitchingState(SwitchingState.failed, 'Error: $e');
      _clearSwitchingStateAfterDelay();
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
