import 'package:flutter/foundation.dart';

/// Service for managing application settings.
/// Uses the singleton pattern to ensure settings are accessible globally.
class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  /// Simulation mode enables developer/testing features like mock targets.
  bool _simulationMode = false;

  bool get simulationMode => _simulationMode;

  set simulationMode(bool value) {
    if (_simulationMode != value) {
      _simulationMode = value;
      notifyListeners();
    }
  }
}
