import 'dart:async';
import 'dart:isolate';
import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

import '../native/ttctk.dart';
import '../models/target.dart';
import '../models/ecu_profile.dart';
import '../models/hardware_models.dart';
import 'log_service.dart';

/// Unified service for toolkit operations.
///
/// Provides CAN interface management, target connection, target info reading,
/// and flash download functionality. All long-running operations execute in
/// isolates to keep the UI responsive.
class ToolkitService {
  static final ToolkitService _instance = ToolkitService._internal();
  factory ToolkitService() => _instance;
  ToolkitService._internal();

  final LogService _log = LogService();

  // ============================================================
  // CAN Interface Management
  // ============================================================

  int? _canHandle;
  int? get canHandle => _canHandle;
  bool get isCanRegistered => _canHandle != null;

  /// Registers the CAN interface with default settings (PEAK USB 1, 500k).
  /// Returns the handle on success. Throws exception on failure.
  Future<int> registerCanInterface() async {
    final canInterface = calloc<TkCanInterfaceType>();
    final handlePtr = calloc<ffi.Uint32>();

    try {
      canInterface.ref.type = TK_CAN_INTERFACE_CATEGORY_PEAK;
      canInterface.peak.ref.channel = PCAN_USBBUS1;

      final status = TTCTK.instance.registerCanInterface(canInterface.cast(), TK_CAN_BITRATE_500K, handlePtr.cast());

      if (status == 0) {
        _canHandle = handlePtr.value;
        return _canHandle!;
      } else {
        throw Exception("Failed to register CAN interface. Status: $status");
      }
    } finally {
      calloc.free(canInterface);
      calloc.free(handlePtr);
    }
  }

  /// Deregisters the current CAN interface.
  Future<void> deregisterCanInterface() async {
    if (_canHandle == null) return;

    final status = TTCTK.instance.deRegisterCanInterface(_canHandle!);
    if (status == 0) {
      _canHandle = null;
    } else {
      throw Exception("Failed to deregister CAN interface. Status: $status");
    }
  }

  /// Connects to a target ECU.
  /// Returns true on success. Throws exception on failure.
  Future<bool> connectTarget(int handle, {int durationMs = 5000}) async {
    if (_canHandle == null) {
      throw Exception("CAN interface not registered");
    }

    final asyncStatus = TTCTK.instance.asyncConnect(handle, durationMs);
    if (asyncStatus != 0) {
      throw Exception("Async connect failed immediately. Status: $asyncStatus");
    }

    // This is a blocking call in the C library. Use Isolate.run to avoid freezing the UI.
    final connectStatus = await Isolate.run(() {
      return TTCTK.instance.awaitConnect();
    });

    if (connectStatus == 0) {
      return true;
    } else {
      throw Exception("Await connect returned with error: $connectStatus");
    }
  }

  // ============================================================
  // Target Info Reading
  // ============================================================

  /// Reads target information from the ECU.
  ///
  /// Returns an updated [EcuProfile] with hardware info, versions, etc.
  /// Runs in an isolate to avoid blocking the UI.
  Future<EcuProfile> readTargetInfo(Target target) async {
    _log.debug("Reading target info...");

    final handle = target.targetHandle;
    final updates = await compute(_readTargetInfoIsolate, handle);

    if (updates.isEmpty) {
      _log.error("Failed to read target info - no data received");
      return target.profile ?? EcuProfile(name: "Unknown", txId: target.ta, rxId: target.sa);
    }

    final hwType = updates['hwType'] ?? '';
    final mappedName = EcuHardwareMap.getEcuName(hwType);

    final currentProfile = target.profile ?? EcuProfile(name: "Unknown", txId: target.ta, rxId: target.sa);

    final updatedProfile = currentProfile.copyWith(
      name: mappedName ?? currentProfile.name,
      serialNumber: updates['serial'],
      hardwareName: updates['hwName'],
      hardwareType: hwType,
      bootloaderVersion: updates['bootVer'],
      bootloaderBuildDate: updates['bootDate'],
      appVersion: updates['appVer'],
      appBuildDate: updates['appDate'],
      hsmVersion: updates['hsmVer'],
      hsmBuildDate: updates['hsmDate'],
      productionCode: updates['productionCode'],
    );

    // Update the target's profile reference
    target.profile = updatedProfile;

    _log.info("Target info read successfully");
    return updatedProfile;
  }

  // ============================================================
  // Flash Download
  // ============================================================

  /// Downloads a HEX file to the target ECU.
  ///
  /// Uses memId=0. Runs in an isolate to avoid blocking the UI.
  /// Returns 0 on success, non-zero error code on failure.
  Future<int> downloadHexFile(int targetHandle, String filePath) async {
    _log.info("Starting download: $filePath");

    final result = await Isolate.run(() {
      return TTCTK.instance.writeFromFile(targetHandle, 0, filePath);
    });

    if (result == 0) {
      _log.info("Download completed successfully");
    } else {
      _log.error("Download failed with error code: $result");
    }

    return result;
  }
}

// ============================================================
// Isolate Functions (Top-level)
// ============================================================

/// Top-level function for target info reading isolate.
Map<String, String> _readTargetInfoIsolate(int handle) {
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

  // Hardware type returns map
  try {
    final hw = TTCTK.instance.getHardwareType(handle);
    if (hw != null) {
      result['hwType'] = "${hw['type']}";
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
