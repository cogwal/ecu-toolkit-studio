import 'dart:async';
import 'dart:isolate';

import '../native/ttctk.dart';
import '../models/target.dart';
import '../models/ecu_profile.dart';

class TargetInfoService {
  final Target target;
  final _controller = StreamController<EcuProfile>.broadcast();

  TargetInfoService(this.target);

  Stream<EcuProfile> get stream => _controller.stream;

  void startReading() {
    // Start with current profile
    EcuProfile currentProfile =
        target.profile ??
        EcuProfile(
          name: "Unknown",
          txId: target.ta, // Fallback if needed, though profile should exist
          rxId: target.sa,
        );

    _controller.add(currentProfile);

    // Spawn Isolate
    Isolate.run(() async {
          return _readTargetInfo(target.targetHandle);
        })
        .then((updates) {
          if (updates.isEmpty) return;

          // Apply updates
          currentProfile = currentProfile.copyWith(
            serialNumber: updates['serial'],
            hardwareType: updates['hwType'],
            bootloaderVersion: updates['bootVer'],
            bootloaderBuildDate: updates['bootDate'],
            appVersion: updates['appVer'],
            appBuildDate: updates['appDate'],
            hsmVersion: updates['hsmVer'],
            hsmBuildDate: updates['hsmDate'],
          );
          _controller.add(currentProfile);

          // Update the target's profile reference as well (mutable update for consistency)
          target.profile = currentProfile;

          _controller.close();
        })
        .catchError((e) {
          // Log error but don't crash stream?
          // For now just close
          _controller.addError(e);
          _controller.close();
        });
  }

  // Static function to run in Isolate
  static Map<String, String> _readTargetInfo(int handle) {
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
    // hardware type returns map
    try {
      final hw = TTCTK.instance.getHardwareType(handle);
      if (hw != null) {
        result['hwType'] = "${hw['name']} (${hw['type']})";
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
}
