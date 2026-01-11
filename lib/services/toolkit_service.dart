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

/// Exception thrown when an operation is attempted while another is in progress.
class OperationInProgressException implements Exception {
  final String operationName;
  OperationInProgressException(this.operationName);

  @override
  String toString() => 'Operation in progress: $operationName';
}

/// Unified service for toolkit operations.
///
/// Provides CAN interface management, target connection, target info reading,
/// and flash download functionality. All long-running operations execute in
/// isolates to keep the UI responsive.
class ToolkitService with ChangeNotifier {
  static final ToolkitService _instance = ToolkitService._internal();
  factory ToolkitService() => _instance;
  ToolkitService._internal();

  final LogService _log = LogService();

  // ============================================================
  // Operation Locking
  // ============================================================

  String? _activeOperation;

  /// Returns true if an operation is currently in progress.
  bool get isOperationPending => _activeOperation != null;

  /// Returns the name of the currently active operation, or null if none.
  String? get activeOperationName => _activeOperation;

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
    if (_activeOperation != null) {
      throw OperationInProgressException(_activeOperation!);
    }

    if (_canHandle == null) {
      throw Exception("CAN interface not registered");
    }

    _activeOperation = 'Connect';
    notifyListeners();

    try {
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
    } finally {
      _activeOperation = null;
      notifyListeners();
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
    if (_activeOperation != null) {
      throw OperationInProgressException(_activeOperation!);
    }

    _activeOperation = 'Read Target Info';
    notifyListeners();

    try {
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
    } finally {
      _activeOperation = null;
      notifyListeners();
    }
  }

  // ============================================================
  // Flash Download
  // ============================================================

  /// Downloads a HEX file to the target ECU.
  ///
  /// Uses memId=0. Runs in an isolate to avoid blocking the UI.
  /// Returns 0 on success, non-zero error code on failure.
  Future<int> downloadHexFile(int targetHandle, String filePath) async {
    if (_activeOperation != null) {
      throw OperationInProgressException(_activeOperation!);
    }

    _activeOperation = 'Download';
    notifyListeners();

    try {
      final result = await Isolate.run(() {
        // TODO: we could automatically determine the memid from the hex file and hardware model used
        return TTCTK.instance.writeFromFile(targetHandle, 0, filePath);
      });

      return result;
    } finally {
      _activeOperation = null;
      notifyListeners();
    }
  }

  // ============================================================
  // FDR (Flash Driver Routines) Management
  // ============================================================

  bool _fdrLoaded = false;

  /// Returns whether the FDR (Flash Driver Routines) has been loaded.
  bool get isFdrLoaded => _fdrLoaded;

  /// Loads the FDR (Flash Driver Routines) from the specified HEX file.
  ///
  /// Returns 0 on success, non-zero error code on failure.
  /// The FDR loaded state persists throughout the application lifetime.
  Future<int> loadFdr(int targetHandle, String filePath) async {
    _log.info('Loading FDR from: $filePath');

    final result = TTCTK.instance.setProgrammingRoutines(targetHandle, filePath);

    if (result == 0) {
      _fdrLoaded = true;
      _log.info('FDR loaded successfully');
    } else {
      _fdrLoaded = false;
      _log.error('Failed to load FDR. Error code: $result');
    }
    notifyListeners();

    return result;
  }

  /// Resets the FDR loaded state.
  void resetFdrState() {
    _fdrLoaded = false;
  }
  // ============================================================
  // Security Parameters Management
  // ============================================================

  bool _isSecuritySet = false;

  /// Returns whether security parameters have been successfully set.
  bool get isSecuritySet => _isSecuritySet;

  /// Sets security parameters for the target ECU.
  ///
  /// [level] is the security level (e.g., 1 or 2).
  /// [key] is the secret key as a list of integers.
  /// Returns 0 on success, non-zero error code on failure.
  Future<int> setSecurityParameters(int targetHandle, int level, List<int> key) async {
    _log.info('Applying security level $level key...');

    final params = calloc<TkTargetSecurityParametersType>();
    final secretPtr = calloc<ffi.Uint32>(key.length);

    try {
      params.ref.type = TK_TARGET_CATEGORY_UDS_ON_CAN;

      // Populate secret buffer (32-bit integers)
      for (var i = 0; i < key.length; i++) {
        secretPtr[i] = key[i];
      }

      final uds = params.uds;
      // Enable setSecurityLevel and set the level
      uds.ref.setSecurityLevel = 1; // true
      uds.ref.securityLevel = level;

      // Enable setSecret and assign the pointer
      uds.ref.setSecret = 1; // true
      uds.ref.secret = secretPtr.cast<ffi.Uint8>();
      uds.ref.secretLength = key.length * 4; // Length in bytes, 32-bit words

      // log length
      _log.debug('Secret length: ${uds.ref.secretLength} bytes');
      // log secret uint8 array contents
      _log.debug('Secret contents: \n ${secretPtr.cast<ffi.Uint8>().asTypedList(key.length * 4).map((e) => e.toRadixString(16)).join(", ")}');

      // Explicitly disable optional fields
      uds.ref.setAlgorithm = 0; // false
      uds.ref.setSubfunctions = 0; // false

      // Log params memory layout
      _log.debug(formatStructLayout(params, ffi.sizeOf<TkTargetSecurityParametersType>(), 'Params memory layout'));

      // This is a blocking call in the C library. Should be quick but safe to run in Isolate if needed.
      // For now, keeping it synchronous as it's passing pointers which is tricky with Isolate without proper serialization or native port.
      // However, since we are passing pointers allocated here, we MUST call it here in the main isolate if the C library allows it,
      // OR we need to move the allocation logic to the isolate.
      // Given the previous implementation was synchronous in the UI callback, this should be fine here.
      // BUT `ToolkitService` methods for `registerCanInterface` etc are sync calls to native.

      final result = TTCTK.instance.setSecurityParameters(targetHandle, params);

      if (result == 0) {
        _isSecuritySet = true;
        _log.info('Security level $level applied successfully.');
      } else {
        // Don't reset _isSecuritySet to false on failure if it was already true?
        // Probably safer to not change it, or perhaps we consider "Security Set" as "At least one successful application".
        _log.error('Failed to set security level $level. Error code: $result');
      }
      notifyListeners();
      return result;
    } catch (e) {
      _log.error('Exception setting security level $level: $e');
      return -1;
    } finally {
      calloc.free(params);
      calloc.free(secretPtr);
    }
  }

  /// Resets the security set state.
  void resetSecurityState() {
    _isSecuritySet = false;
    notifyListeners();
  }

  // ============================================================
  // Session Persistence (File Paths)
  // ============================================================

  String? _downloadFilePath;
  String? get downloadFilePath => _downloadFilePath;

  void setDownloadFilePath(String? path) {
    _downloadFilePath = path;
    notifyListeners();
  }

  String? _uploadSaveFilePath;
  String? get uploadSaveFilePath => _uploadSaveFilePath;

  void setUploadSaveFilePath(String? path) {
    _uploadSaveFilePath = path;
    notifyListeners();
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
