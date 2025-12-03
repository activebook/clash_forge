import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import '../services/clash_service.dart';

class ProfileManager extends ChangeNotifier {
  final ClashService _clashService = ClashService();
  List<String> _profiles = [];
  bool _isLoading = false;
  String? _activeProfile;

  List<String> get profiles => List.unmodifiable(_profiles);
  bool get isLoading => _isLoading;
  String? get activeProfile => _activeProfile;

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
  }

  /// Switches to the specified profile.
  Future<bool> switchProfile(String profileName) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _clashService.setActiveProfile(profileName);

      if (success) {
        _activeProfile = profileName;
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
}
