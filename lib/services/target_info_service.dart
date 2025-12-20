import 'dart:async';
import 'package:flutter/foundation.dart';

import '../native/ttctk.dart';
import '../models/target.dart';
import '../models/ecu_profile.dart';
import 'log_service.dart';

/// Service for reading target information from an ECU.
///
/// The stream stays open for the lifetime of the service, allowing multiple
/// reads via [startReading]. Call [dispose] when the service is no longer needed.
class TargetInfoService {
  final Target target;
  final _controller = StreamController<EcuProfile>.broadcast();

  bool _isReading = false;
  bool _isDisposed = false;

  TargetInfoService(this.target);

  /// Stream of profile updates. Stays open until [dispose] is called.
  Stream<EcuProfile> get stream => _controller.stream;

  /// Whether a read operation is currently in progress.
  bool get isReading => _isReading;

  /// Start reading target info from the ECU.
  ///
  /// Emits the current profile immediately, then fetches fresh data
  /// and emits an updated profile when complete.
  Future<void> startReading() async {
    if (_isDisposed) {
      LogService().warning("Cannot read - service is disposed");
      return;
    }

    if (_isReading) {
      LogService().debug("Read already in progress, skipping");
      return;
    }

    _isReading = true;

    // Start with current profile
    EcuProfile currentProfile = target.profile ?? EcuProfile(name: "Unknown", txId: target.ta, rxId: target.sa);

    _controller.add(currentProfile);
    LogService().debug("Reading target info...");

    try {
      // Use compute() which properly handles isolate message passing
      final handle = target.targetHandle;
      final updates = await compute(_readTargetInfo, handle);

      if (_isDisposed) return;

      _isReading = false;

      if (updates.isEmpty) {
        LogService().error("Failed to read target info - no data received");
        return;
      }

      // Apply updates
      currentProfile = currentProfile.copyWith(
        serialNumber: updates['serial'],
        hardwareName: updates['hwName'],
        hardwareType: updates['hwType'],
        bootloaderVersion: updates['bootVer'],
        bootloaderBuildDate: updates['bootDate'],
        appVersion: updates['appVer'],
        appBuildDate: updates['appDate'],
        hsmVersion: updates['hsmVer'],
        hsmBuildDate: updates['hsmDate'],
        productionCode: updates['productionCode'],
      );
      _controller.add(currentProfile);

      // Update the target's profile reference as well
      target.profile = currentProfile;

      LogService().info("Target info read successfully");
    } catch (e) {
      if (_isDisposed) return;

      _isReading = false;
      LogService().error("Failed to read target info: $e");
      _controller.addError(e);
    }
  }

  /// Dispose of the service and close the stream.
  ///
  /// After calling dispose, no more reads can be started.
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _controller.close();
  }
}

// Top-level function for isolate
Map<String, String> _readTargetInfo(int handle) {
  // This runs in a separate isolate.
  // We can use TTCTK calls here because they are thread-safe (assuming handle is valid).
  // Note: FFI bindings must be loaded in this isolate too.
  // The TTCTK calls usually load the lib on first use.

  final result = <String, String>{};

  void safeRead(String key, String? Function(int) fn) {
    try {
      final val = fn(handle);
      if (val != null && val.isNotEmpty) {
        result[key] = val;
      }
    } catch (_) {}
  }

  void safeReadVer(String key, Map<String, int>? Function(int) fn) {
    try {
      final val = fn(handle);
      if (val != null) {
        result[key] = "${val['major']}.${val['minor']}.${val['patch']}";
      }
    } catch (_) {}
  }

  void safeReadDate(String key, Map<String, int>? Function(int) fn) {
    try {
      final val = fn(handle);
      if (val != null) {
        // tm_year is years since 1900, tm_mon is 0-11
        final year = 1900 + (val['tm_year'] ?? 0);
        final month = 1 + (val['tm_mon'] ?? 0);
        final day = val['tm_mday'] ?? 1;
        result[key] = "$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
      }
    } catch (_) {}
  }

  // Identify calls
  safeRead('serial', TTCTK.instance.getDeviceSerialNumber);
  safeRead('productionCode', TTCTK.instance.getProductionCode);
  // hardware type returns map
  try {
    final hw = TTCTK.instance.getHardwareType(handle);
    if (hw != null) {
      result['hwType'] = "(${hw['type']})";
      result['hwName'] = "${hw['name']}";
    }
  } catch (_) {}

  safeReadVer('bootVer', TTCTK.instance.getBootloaderVersion);
  safeReadDate('bootDate', TTCTK.instance.getBootloaderBuildDate);
  safeReadVer('appVer', TTCTK.instance.getApplicationVersion);
  safeReadDate('appDate', TTCTK.instance.getApplicationBuildDate);
  safeReadVer('hsmVer', TTCTK.instance.getHsmFirmwareVersion);
  safeReadDate('hsmDate', TTCTK.instance.getHsmFirmwareBuildDate);

  return result;
}
