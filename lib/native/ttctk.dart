// Dart FFI bindings for selected TTC Toolkit functions and types.
// Generated for initial integration: covers common operations, memory handling,
// and typical structs (CAN frame, CAN id pair, target addressing).
//
// Notes:
// - This file does not attempt to exhaustively map every header type and
//   union. It includes safe helpers and the most commonly used functions.
// - Strings returned by toolkit functions are allocated in the toolkit and must
//   be freed by calling TK_FreeResource (wrapped as freeResource). Use the
//   helpers below to convert strings and free resources safely.

// ignore_for_file: constant_identifier_names
// ignore_for_file: camel_case_types

import 'dart:ffi' as ffi;
import 'dart:io' show Platform;
import 'dart:convert' show utf8;
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart' show debugPrint;

// ---------------------------------------------------------------------------
// C types and layout helpers
// ---------------------------------------------------------------------------

// Constants from headers: sizes
const int TK_CAN_FD_FRAME_MAX_LENGTH = 64;
const int TK_TARGET_ADDRESS_CONFIG_SIZE_MAX = 256;
const int TK_TARGET_PROPERTIES_CONFIG_SIZE_MAX = 256;
const int TK_CAN_INTERFACE_CONFIG_SIZE_MAX = 256;

// CAN Bitrates (from ttctk_can.h)
const int TK_CAN_BITRATE_5K = 5000;
const int TK_CAN_BITRATE_10K = 10000;
const int TK_CAN_BITRATE_20K = 20000;
const int TK_CAN_BITRATE_50K = 50000;
const int TK_CAN_BITRATE_100K = 100000;
const int TK_CAN_BITRATE_125K = 125000;
const int TK_CAN_BITRATE_250K = 250000;
const int TK_CAN_BITRATE_500K = 500000;
const int TK_CAN_BITRATE_1M = 1000000;

// CAN Interface Categories (from ttctk_can.h)
const int TK_CAN_INTERFACE_CATEGORY_CUSTOM = 0;
const int TK_CAN_INTERFACE_CATEGORY_PEAK = 1;
const int TK_CAN_INTERFACE_CATEGORY_SOCKETCAN = 2;

// CAN Frame Formats (from ttctk_can.h)
const int TK_CAN_FRAME_FORMAT_BASE = 0;
const int TK_CAN_FRAME_FORMAT_FD_BASE = 1;
const int TK_CAN_FRAME_FORMAT_EXTENDED = 2;
const int TK_CAN_FRAME_FORMAT_FD_EXTENDED = 3;

// Target Categories
const int TK_TARGET_CATEGORY_UDS_ON_CAN = 0;

// UDS Message Types
const int TK_TARGET_UDS_MTYPE_DIAGNOSTICS = 0;
const int TK_TARGET_UDS_MTYPE_REMOTE_DIAGNOSTICS = 1;

// UDS Target Address Types
const int TK_TARGET_UDS_TATYPE_PHYSICAL = 0;
const int TK_TARGET_UDS_TATYPE_FUNCTIONAL = 1;

// ISO-TP Formats
const int TK_TARGET_ISOTP_FORMAT_NORMAL = 0;
const int TK_TARGET_ISOTP_FORMAT_EXTENDED = 1;
const int TK_TARGET_ISOTP_FORMAT_MIXED = 2;
const int TK_TARGET_ISOTP_FORMAT_CUSTOM = 3;

// PCAN USB Channels (from PCANBasic.h)
const int PCAN_USBBUS1 = 0x51;
const int PCAN_USBBUS2 = 0x52;
const int PCAN_USBBUS3 = 0x53;
const int PCAN_USBBUS4 = 0x54;
const int PCAN_USBBUS5 = 0x55;
const int PCAN_USBBUS6 = 0x56;
const int PCAN_USBBUS7 = 0x57;
const int PCAN_USBBUS8 = 0x58;
const int PCAN_USBBUS9 = 0x59;
const int PCAN_USBBUS10 = 0x50A;
const int PCAN_USBBUS11 = 0x50B;
const int PCAN_USBBUS12 = 0x50C;
const int PCAN_USBBUS13 = 0x50D;
const int PCAN_USBBUS14 = 0x50E;
const int PCAN_USBBUS15 = 0x50F;
const int PCAN_USBBUS16 = 0x510;

// Typedefs
typedef TkStatusType = ffi.Uint32; // TkStatusType is uint32
typedef TkLogLevelType = ffi.Uint32;
typedef TkCanBitrateType = ffi.Uint32;
typedef TkCanInterfaceHandleType = ffi.Uint32;
typedef TkCanFrameFormatType = ffi.Uint32;
typedef TkTargetHandleType = ffi.Uint32;

// Additional types from ttctk_data.h
typedef TkDiagSessionType = ffi.Uint32;

final class TkVersionType extends ffi.Struct {
  @ffi.Uint32()
  external int major;
  @ffi.Uint32()
  external int minor;
  @ffi.Uint32()
  external int patch;
  @ffi.Uint8()
  external int patchSet; // bool -> Uint8
}

final class TmStruct extends ffi.Struct {
  @ffi.Int32()
  external int tm_sec;
  @ffi.Int32()
  external int tm_min;
  @ffi.Int32()
  external int tm_hour;
  @ffi.Int32()
  external int tm_mday;
  @ffi.Int32()
  external int tm_mon;
  @ffi.Int32()
  external int tm_year;
  @ffi.Int32()
  external int tm_wday;
  @ffi.Int32()
  external int tm_yday;
  @ffi.Int32()
  external int tm_isdst;
}

final class TkHwType extends ffi.Struct {
  @ffi.Array(20)
  external ffi.Array<ffi.Uint8> name;
  @ffi.Array(20)
  external ffi.Array<ffi.Uint8> type;
}

final class TkCybersecurityStatusType extends ffi.Struct {
  @ffi.Uint8()
  external int cybersecurityEnabled;
  @ffi.Uint8()
  external int dbgPortLocked;
  @ffi.Uint8()
  external int blSecureBoot;
  @ffi.Uint8()
  external int appSecureBoot;
  @ffi.Uint8()
  external int rootCertificateStored;
  @ffi.Uint8()
  external int blCertificateStored;
  @ffi.Uint8()
  external int appCertificateStored;
  @ffi.Uint8()
  external int blAuthFailed;
  @ffi.Uint8()
  external int appAuthFailed;
}

final class TkEccCheckType extends ffi.Struct {
  @ffi.Uint8()
  external int errorPresented;
  @ffi.Uint32()
  external int errorAddress;
}

// ---------------------------------------------------------------------------
// Structs / simple types needed for commonly used functions
// ---------------------------------------------------------------------------

final class TkCanFrameFlags extends ffi.Struct {
  // Bitfields in the original header; we represent as a single uint8 field.
  @ffi.Uint8()
  external int raw;
}

final class TkCanFrame extends ffi.Struct {
  @ffi.Uint32()
  external int id;

  external TkCanFrameFlags flags;

  @ffi.Uint8()
  external int dlc;

  @ffi.Array(TK_CAN_FD_FRAME_MAX_LENGTH)
  external ffi.Array<ffi.Uint8> data;
}

final class TkCanIdPair extends ffi.Struct {
  @ffi.Uint32()
  external int txId;

  @ffi.Uint32()
  external int rxId;
}

// Peak CAN interface configuration
final class TkCanInterfaceConfigPeakType extends ffi.Struct {
  @ffi.Uint16()
  external int channel;
}

// SocketCAN interface configuration
final class TkCanInterfaceConfigSocketCanType extends ffi.Struct {
  @ffi.Array(16) // Interface name, e.g., "can0"
  external ffi.Array<ffi.Int8> ifName;
}

// CAN interface union wrapper
// The C struct has a union of size TK_CAN_INTERFACE_CONFIG_SIZE_MAX (256 bytes).
// We represent this as a raw byte array to ensure correct memory layout.
final class TkCanInterfaceType extends ffi.Struct {
  @ffi.Uint32()
  external int type; // TkCanInterfaceCategoryType

  // Raw union storage - must match TK_CAN_INTERFACE_CONFIG_SIZE_MAX (256 bytes)
  // This ensures the struct has the correct memory layout for FFI calls.
  // Access specific config types by casting the pointer offset.
  @ffi.Array(TK_CAN_INTERFACE_CONFIG_SIZE_MAX)
  external ffi.Array<ffi.Uint8> raw;
}

/// Extension to provide convenient access to union members
extension TkCanInterfaceTypeExt on ffi.Pointer<TkCanInterfaceType> {
  /// Get pointer to Peak CAN configuration (valid when type == TK_CAN_INTERFACE_CATEGORY_PEAK)
  ffi.Pointer<TkCanInterfaceConfigPeakType> get peak {
    // Offset by size of 'type' field + alignment for a 64bit void pointer (8 bytes) to get to the union data
    final rawOffset = cast<ffi.Uint8>() + 8;
    return rawOffset.cast<TkCanInterfaceConfigPeakType>();
  }

  /// Get pointer to SocketCAN configuration (valid when type == TK_CAN_INTERFACE_CATEGORY_SOCKETCAN)
  ffi.Pointer<TkCanInterfaceConfigSocketCanType> get socketCan {
    final rawOffset = cast<ffi.Uint8>() + 8;
    return rawOffset.cast<TkCanInterfaceConfigSocketCanType>();
  }
}

// ---------------------------------------------------------------------------
// Dart POJOs (Plain Old Dart Objects) for higher-level API
// ---------------------------------------------------------------------------

class TkTargetCustomCanAddress {
  int txId = 0;
  int rxId = 0;
  int txFormat = 0;
  int rxFormat = 0;
}

class TkTargetAddressConfigUdsOnCan {
  int mType = 0;
  int sa = 0;
  int ta = 0;
  int taType = 0;
  int ae = 0;
  int isotpFormat = 0;
  int canHandle = 0;
  int canFormat = 0;
  TkTargetCustomCanAddress canCustom = TkTargetCustomCanAddress();
}

class TkTargetAddress {
  int type = 0;
  TkTargetAddressConfigUdsOnCan udsOnCan = TkTargetAddressConfigUdsOnCan();
}

// ---------------------------------------------------------------------------
// FFI Structs (Internal/Low-level)
// ---------------------------------------------------------------------------

// Custom CAN addressing parameters
final class TkTargetCustomCanAddressType extends ffi.Struct {
  @ffi.Uint32()
  external int txId;
  @ffi.Uint32()
  external int rxId;
  @ffi.Uint32()
  external int txFormat;
  @ffi.Uint32()
  external int rxFormat;
}

// UDS-on-CAN target addressing configuration
final class TkTargetAddressConfigUdsOnCanType extends ffi.Struct {
  @ffi.Uint32()
  external int mType;
  @ffi.Uint8()
  external int sa;
  @ffi.Uint8()
  external int ta;
  @ffi.Uint32()
  external int taType;
  @ffi.Uint8()
  external int ae;
  @ffi.Uint32()
  external int isotpFormat;
  @ffi.Uint32()
  external int canHandle;
  @ffi.Uint32()
  external int canFormat;
  external TkTargetCustomCanAddressType canCustom;
}

final class TkTargetAddressType extends ffi.Struct {
  @ffi.Uint32()
  external int type;

  external TkTargetAddressConfigUdsOnCanType udsOnCan;
}

final class TkTargetPropertiesType extends ffi.Struct {
  @ffi.Uint32()
  external int type;

  @ffi.Array(TK_TARGET_PROPERTIES_CONFIG_SIZE_MAX)
  external ffi.Array<ffi.Uint8> raw;
}

// ---------------------------------------------------------------------------
// Dynamic library loader & helper
// ---------------------------------------------------------------------------

String _ttctkLibraryName() {
  if (Platform.isWindows) return 'ttctk.dll';
  if (Platform.isLinux) return 'libttctk.so';
  if (Platform.isMacOS) return 'libttctk.dylib';
  throw UnsupportedError('TTCTK library not supported on this platform');
}

class TTCTK {
  late ffi.DynamicLibrary _lib;
  bool available = false;

  // Lib function pointers
  late _TK_GetVersion _tkGetVersion;
  late _TK_GetVersionString _tkGetVersionString;
  late _TK_GetBuildDate _tkGetBuildDate;
  late _TK_GetBuildTime _tkGetBuildTime;
  late _TK_Init _tkInit;
  late _TK_DeInit _tkDeInit;
  late _TK_FreeResource _tkFreeResource;

  // CAN API
  late _TK_RegisterCanInterface _tkRegisterCanInterface;
  late _TK_DeRegisterCanInterface _tkDeRegisterCanInterface;
  late _TK_NotifyCanFrameReceived _tkNotifyCanFrameReceived;
  late _TK_AddCanIdPair _tkAddCanIdPair;
  late _TK_RemoveCanIdPair _tkRemoveCanIdPair;
  late _TK_TransmitCanFrame _tkTransmitCanFrame;

  // Target API
  late _TK_AddTarget _tkAddTarget;
  late _TK_RemoveTarget _tkRemoveTarget;
  late _TK_SetProgrammingRoutines _tkSetProgrammingRoutines;
  late _TK_SetTargetProperties _tkSetTargetProperties;

  // Program API
  late _TK_AsyncDiscover _tkAsyncDiscover;
  late _TK_AwaitDiscover _tkAwaitDiscover;
  late _TK_AsyncConnect _tkAsyncConnect;
  late _TK_AwaitConnect _tkAwaitConnect;
  late _TK_WriteFromFile _tkWriteFromFile;
  late _TK_WriteFromFileSigned _tkWriteFromFileSigned;
  late _TK_EraseRange _tkEraseRange;
  late _TK_ReadToMemoryBuffer _tkReadToMemoryBuffer;
  late _TK_ResetTarget _tkResetTarget;
  // Data API
  late _TK_ReadDataByIdToMemoryBuffer _tkReadDataByIdToMemoryBuffer;
  late _TK_WriteDataByIdFromMemoryBuffer _tkWriteDataByIdFromMemoryBuffer;
  late _TK_GetBootloaderVersion _tkGetBootloaderVersion;
  late _TK_GetBootloaderBuildDate _tkGetBootloaderBuildDate;
  late _TK_GetApplicationVersion _tkGetApplicationVersion;
  late _TK_GetApplicationBuildDate _tkGetApplicationBuildDate;
  late _TK_GetHsmFirmwareVersion _tkGetHsmFirmwareVersion;
  late _TK_GetHsmFirmwareBuildDate _tkGetHsmFirmwareBuildDate;
  late _TK_GetActiveDiagnosticSessionType _tkGetActiveDiagnosticSessionType;
  late _TK_GetDeviceSerialNumber _tkGetDeviceSerialNumber;
  late _TK_GetBoardSerialNumber _tkGetBoardSerialNumber;
  late _TK_GetProductionCode _tkGetProductionCode;
  late _TK_GetMacAddress _tkGetMacAddress;
  late _TK_GetHardwareType _tkGetHardwareType;
  late _TK_GetCybersecurityStatus _tkGetCybersecurityStatus;
  late _TK_GetEccCheck _tkGetEccCheck;

  TTCTK._internal();

  static final TTCTK instance = TTCTK._internal();

  void loadLibrary() {
    if (available) return;
    final name = _ttctkLibraryName();
    try {
      _lib = ffi.DynamicLibrary.open(name);
      // Common
      _tkGetVersion = _lib.lookupFunction<_c_TK_GetVersion, _TK_GetVersion>('TK_GetVersion');
      _tkGetVersionString = _lib.lookupFunction<_c_TK_GetVersionString, _TK_GetVersionString>('TK_GetVersionString');
      _tkGetBuildDate = _lib.lookupFunction<_c_TK_GetBuildDate, _TK_GetBuildDate>('TK_GetBuildDate');
      _tkGetBuildTime = _lib.lookupFunction<_c_TK_GetBuildTime, _TK_GetBuildTime>('TK_GetBuildTime');
      _tkInit = _lib.lookupFunction<_c_TK_Init, _TK_Init>('TK_Init');
      _tkDeInit = _lib.lookupFunction<_c_TK_DeInit, _TK_DeInit>('TK_DeInit');
      _tkFreeResource = _lib.lookupFunction<_c_TK_FreeResource, _TK_FreeResource>('TK_FreeResource');

      // CAN
      _tkRegisterCanInterface = _lib.lookupFunction<_c_TK_RegisterCanInterface, _TK_RegisterCanInterface>('TK_RegisterCanInterface');
      _tkDeRegisterCanInterface = _lib.lookupFunction<_c_TK_DeRegisterCanInterface, _TK_DeRegisterCanInterface>('TK_DeRegisterCanInterface');
      _tkNotifyCanFrameReceived = _lib.lookupFunction<_c_TK_NotifyCanFrameReceived, _TK_NotifyCanFrameReceived>('TK_NotifyCanFrameReceived');
      _tkAddCanIdPair = _lib.lookupFunction<_c_TK_AddCanIdPair, _TK_AddCanIdPair>('TK_AddCanIdPair');
      _tkRemoveCanIdPair = _lib.lookupFunction<_c_TK_RemoveCanIdPair, _TK_RemoveCanIdPair>('TK_RemoveCanIdPair');
      _tkTransmitCanFrame = _lib.lookupFunction<_c_TK_TransmitCanFrame, _TK_TransmitCanFrame>('TK_TransmitCanFrame');

      // Targets
      _tkAddTarget = _lib.lookupFunction<_c_TK_AddTarget, _TK_AddTarget>('TK_AddTarget');
      _tkRemoveTarget = _lib.lookupFunction<_c_TK_RemoveTarget, _TK_RemoveTarget>('TK_RemoveTarget');
      _tkSetProgrammingRoutines = _lib.lookupFunction<_c_TK_SetProgrammingRoutines, _TK_SetProgrammingRoutines>('TK_SetProgrammingRoutines');
      _tkSetTargetProperties = _lib.lookupFunction<_c_TK_SetTargetProperties, _TK_SetTargetProperties>('TK_SetTargetProperties');

      // Program API
      _tkAsyncDiscover = _lib.lookupFunction<_c_TK_AsyncDiscover, _TK_AsyncDiscover>('TK_AsyncDiscover');
      _tkAwaitDiscover = _lib.lookupFunction<_c_TK_AwaitDiscover, _TK_AwaitDiscover>('TK_AwaitDiscover');
      _tkAsyncConnect = _lib.lookupFunction<_c_TK_AsyncConnect, _TK_AsyncConnect>('TK_AsyncConnect');
      _tkAwaitConnect = _lib.lookupFunction<_c_TK_AwaitConnect, _TK_AwaitConnect>('TK_AwaitConnect');
      _tkWriteFromFile = _lib.lookupFunction<_c_TK_WriteFromFile, _TK_WriteFromFile>('TK_WriteFromFile');
      _tkWriteFromFileSigned = _lib.lookupFunction<_c_TK_WriteFromFileSigned, _TK_WriteFromFileSigned>('TK_WriteFromFileSigned');
      _tkEraseRange = _lib.lookupFunction<_c_TK_EraseRange, _TK_EraseRange>('TK_EraseRange');
      _tkReadToMemoryBuffer = _lib.lookupFunction<_c_TK_ReadToMemoryBuffer, _TK_ReadToMemoryBuffer>('TK_ReadToMemoryBuffer');
      _tkResetTarget = _lib.lookupFunction<_c_TK_ResetTarget, _TK_ResetTarget>('TK_ResetTarget');
      // Data API
      _tkReadDataByIdToMemoryBuffer = _lib.lookupFunction<_c_TK_ReadDataByIdToMemoryBuffer, _TK_ReadDataByIdToMemoryBuffer>('TK_ReadDataByIdToMemoryBuffer');
      _tkWriteDataByIdFromMemoryBuffer = _lib.lookupFunction<_c_TK_WriteDataByIdFromMemoryBuffer, _TK_WriteDataByIdFromMemoryBuffer>(
        'TK_WriteDataByIdFromMemoryBuffer',
      );
      _tkGetBootloaderVersion = _lib.lookupFunction<_c_TK_GetBootloaderVersion, _TK_GetBootloaderVersion>('TK_GetBootloaderVersion');
      _tkGetBootloaderBuildDate = _lib.lookupFunction<_c_TK_GetBootloaderBuildDate, _TK_GetBootloaderBuildDate>('TK_GetBootloaderBuildDate');
      _tkGetApplicationVersion = _lib.lookupFunction<_c_TK_GetApplicationVersion, _TK_GetApplicationVersion>('TK_GetApplicationVersion');
      _tkGetApplicationBuildDate = _lib.lookupFunction<_c_TK_GetApplicationBuildDate, _TK_GetApplicationBuildDate>('TK_GetApplicationBuildDate');
      _tkGetHsmFirmwareVersion = _lib.lookupFunction<_c_TK_GetHsmFirmwareVersion, _TK_GetHsmFirmwareVersion>('TK_GetHsmFirmwareVersion');
      _tkGetHsmFirmwareBuildDate = _lib.lookupFunction<_c_TK_GetHsmFirmwareBuildDate, _TK_GetHsmFirmwareBuildDate>('TK_GetHsmFirmwareBuildDate');
      _tkGetActiveDiagnosticSessionType = _lib.lookupFunction<_c_TK_GetActiveDiagnosticSessionType, _TK_GetActiveDiagnosticSessionType>(
        'TK_GetActiveDiagnosticSessionType',
      );
      _tkGetDeviceSerialNumber = _lib.lookupFunction<_c_TK_GetDeviceSerialNumber, _TK_GetDeviceSerialNumber>('TK_GetDeviceSerialNumber');
      _tkGetBoardSerialNumber = _lib.lookupFunction<_c_TK_GetBoardSerialNumber, _TK_GetBoardSerialNumber>('TK_GetBoardSerialNumber');
      _tkGetProductionCode = _lib.lookupFunction<_c_TK_GetProductionCode, _TK_GetProductionCode>('TK_GetProductionCode');
      _tkGetMacAddress = _lib.lookupFunction<_c_TK_GetMacAddress, _TK_GetMacAddress>('TK_GetMacAddress');
      _tkGetHardwareType = _lib.lookupFunction<_c_TK_GetHardwareType, _TK_GetHardwareType>('TK_GetHardwareType');
      _tkGetCybersecurityStatus = _lib.lookupFunction<_c_TK_GetCybersecurityStatus, _TK_GetCybersecurityStatus>('TK_GetCybersecurityStatus');
      _tkGetEccCheck = _lib.lookupFunction<_c_TK_GetEccCheck, _TK_GetEccCheck>('TK_GetEccCheck');

      available = true;
    } catch (e, s) {
      debugPrint('TTCTK dynamic library ($name) failed to load; some functions will be unavailable: $e\n$s');
      available = false;
    }
  }

  // -------------------------------------------------------------------------
  // Safe helpers for getting string resources
  // -------------------------------------------------------------------------
  String? _callStringOut(ffi.Pointer<ffi.Pointer<ffi.Int8>> outPtr, int Function(ffi.Pointer<ffi.Pointer<ffi.Int8>>) fn) {
    if (!available) return null;
    final status = fn(outPtr);
    if (status != 0) return null; // not OK
    final raw = outPtr.value;
    if (raw == ffi.nullptr) return null;
    final dart = raw.cast<Utf8>().toDartString();
    _tkFreeResource(raw.cast<ffi.Void>());
    return dart;
  }

  /// Returns a tuple-like map for version
  Map<String, int>? getVersion() {
    loadLibrary();
    if (!available) return null;
    final major = calloc<ffi.Uint16>();
    final minor = calloc<ffi.Uint16>();
    final patch = calloc<ffi.Uint16>();
    try {
      final status = _tkGetVersion(major, minor, patch);
      if (status != 0) return null;
      return {'major': major.value, 'minor': minor.value, 'patch': patch.value};
    } finally {
      calloc.free(major);
      calloc.free(minor);
      calloc.free(patch);
    }
  }

  String? getVersionString() {
    loadLibrary();
    if (!available) return null;
    final out = calloc<ffi.Pointer<ffi.Int8>>();
    try {
      return _callStringOut(out, (p) => _tkGetVersionString(p));
    } finally {
      calloc.free(out);
    }
  }

  String? getBuildDate() {
    loadLibrary();
    if (!available) return null;
    final out = calloc<ffi.Pointer<ffi.Int8>>();
    try {
      return _callStringOut(out, (p) => _tkGetBuildDate(p));
    } finally {
      calloc.free(out);
    }
  }

  String? getBuildTime() {
    loadLibrary();
    if (!available) return null;
    final out = calloc<ffi.Pointer<ffi.Int8>>();
    try {
      return _callStringOut(out, (p) => _tkGetBuildTime(p));
    } finally {
      calloc.free(out);
    }
  }

  // -------------------------------------------------------------------------
  // Data helpers for reading/writing DIDs and retrieving target metadata
  // -------------------------------------------------------------------------
  int readDataByIdToMemoryBuffer(int handle, int id, ffi.Pointer<ffi.Pointer<ffi.Uint8>> outBuffer, ffi.Pointer<ffi.Uint32> outBufferSize) {
    loadLibrary();
    if (!available) return -1;
    return _tkReadDataByIdToMemoryBuffer(handle, id, outBuffer.cast(), outBufferSize.cast());
  }

  List<int>? readDataByIdAsList(int handle, int id) {
    loadLibrary();
    if (!available) return null;
    final outBuffer = calloc<ffi.Pointer<ffi.Uint8>>();
    final outSize = calloc<ffi.Uint32>();
    try {
      final status = _tkReadDataByIdToMemoryBuffer(handle, id, outBuffer.cast(), outSize.cast());
      if (status != 0) return null;
      final bufPtr = outBuffer.value;
      if (bufPtr == ffi.nullptr) return null;
      final len = outSize.value;
      final list = bufPtr.asTypedList(len);
      _tkFreeResource(bufPtr.cast());
      return List<int>.from(list);
    } finally {
      calloc.free(outBuffer);
      calloc.free(outSize);
    }
  }

  int writeDataByIdFromMemoryBuffer(int handle, int id, List<int> data) {
    loadLibrary();
    if (!available) return -1;
    final ptr = calloc<ffi.Uint8>(data.length);
    try {
      final typed = ptr.asTypedList(data.length);
      typed.setAll(0, data);
      return _tkWriteDataByIdFromMemoryBuffer(handle, id, ptr.cast(), data.length);
    } finally {
      calloc.free(ptr);
    }
  }

  Map<String, int>? getBootloaderVersion(int handle) {
    loadLibrary();
    if (!available) return null;
    final v = calloc<TkVersionType>();
    try {
      final status = _tkGetBootloaderVersion(handle, v.cast());
      if (status != 0) return null;
      return {'major': v.ref.major, 'minor': v.ref.minor, 'patch': v.ref.patch};
    } finally {
      calloc.free(v);
    }
  }

  Map<String, int>? getBootloaderBuildDate(int handle) {
    loadLibrary();
    if (!available) return null;
    final date = calloc<TmStruct>();
    try {
      final status = _tkGetBootloaderBuildDate(handle, date.cast());
      if (status != 0) return null;
      return {
        'tm_sec': date.ref.tm_sec,
        'tm_min': date.ref.tm_min,
        'tm_hour': date.ref.tm_hour,
        'tm_mday': date.ref.tm_mday,
        'tm_mon': date.ref.tm_mon,
        'tm_year': date.ref.tm_year,
      };
    } finally {
      calloc.free(date);
    }
  }

  Map<String, int>? getApplicationBuildDate(int handle) {
    loadLibrary();
    if (!available) return null;
    final date = calloc<TmStruct>();
    try {
      final status = _tkGetApplicationBuildDate(handle, date.cast());
      if (status != 0) return null;
      return {
        'tm_sec': date.ref.tm_sec,
        'tm_min': date.ref.tm_min,
        'tm_hour': date.ref.tm_hour,
        'tm_mday': date.ref.tm_mday,
        'tm_mon': date.ref.tm_mon,
        'tm_year': date.ref.tm_year,
      };
    } finally {
      calloc.free(date);
    }
  }

  Map<String, int>? getHsmFirmwareBuildDate(int handle) {
    loadLibrary();
    if (!available) return null;
    final date = calloc<TmStruct>();
    try {
      final status = _tkGetHsmFirmwareBuildDate(handle, date.cast());
      if (status != 0) return null;
      return {
        'tm_sec': date.ref.tm_sec,
        'tm_min': date.ref.tm_min,
        'tm_hour': date.ref.tm_hour,
        'tm_mday': date.ref.tm_mday,
        'tm_mon': date.ref.tm_mon,
        'tm_year': date.ref.tm_year,
      };
    } finally {
      calloc.free(date);
    }
  }

  int? getActiveDiagnosticSessionType(int handle) {
    loadLibrary();
    if (!available) return null;
    final out = calloc<ffi.Uint32>();
    try {
      final status = _tkGetActiveDiagnosticSessionType(handle, out.cast());
      if (status != 0) return null;
      return out.value;
    } finally {
      calloc.free(out);
    }
  }

  Map<String, int>? getApplicationVersion(int handle) {
    loadLibrary();
    if (!available) return null;
    final v = calloc<TkVersionType>();
    try {
      final status = _tkGetApplicationVersion(handle, v.cast());
      if (status != 0) return null;
      return {'major': v.ref.major, 'minor': v.ref.minor, 'patch': v.ref.patch};
    } finally {
      calloc.free(v);
    }
  }

  Map<String, int>? getHsmFirmwareVersion(int handle) {
    loadLibrary();
    if (!available) return null;
    final v = calloc<TkVersionType>();
    try {
      final status = _tkGetHsmFirmwareVersion(handle, v.cast());
      if (status != 0) return null;
      return {'major': v.ref.major, 'minor': v.ref.minor, 'patch': v.ref.patch};
    } finally {
      calloc.free(v);
    }
  }

  String? getDeviceSerialNumber(int handle) {
    loadLibrary();
    if (!available) return null;
    final out = calloc<ffi.Pointer<ffi.Int8>>();
    try {
      final status = _tkGetDeviceSerialNumber(handle, out.cast());
      if (status != 0) return null;
      final raw = out.value;
      if (raw == ffi.nullptr) return null;
      final dart = raw.cast<Utf8>().toDartString();
      _tkFreeResource(raw.cast());
      return dart;
    } finally {
      calloc.free(out);
    }
  }

  String? getBoardSerialNumber(int handle) {
    loadLibrary();
    if (!available) return null;
    final out = calloc<ffi.Pointer<ffi.Int8>>();
    try {
      final status = _tkGetBoardSerialNumber(handle, out.cast());
      if (status != 0) return null;
      final raw = out.value;
      if (raw == ffi.nullptr) return null;
      final dart = raw.cast<Utf8>().toDartString();
      _tkFreeResource(raw.cast());
      return dart;
    } finally {
      calloc.free(out);
    }
  }

  String? getProductionCode(int handle) {
    loadLibrary();
    if (!available) return null;
    final out = calloc<ffi.Pointer<ffi.Int8>>();
    try {
      final status = _tkGetProductionCode(handle, out.cast());
      if (status != 0) return null;
      final raw = out.value;
      if (raw == ffi.nullptr) return null;
      final dart = raw.cast<Utf8>().toDartString();
      _tkFreeResource(raw.cast());
      return dart;
    } finally {
      calloc.free(out);
    }
  }

  String? getMacAddress(int handle) {
    loadLibrary();
    if (!available) return null;
    final out = calloc<ffi.Pointer<ffi.Int8>>();
    try {
      final status = _tkGetMacAddress(handle, out.cast());
      if (status != 0) return null;
      final raw = out.value;
      if (raw == ffi.nullptr) return null;
      final dart = raw.cast<Utf8>().toDartString();
      _tkFreeResource(raw.cast());
      return dart;
    } finally {
      calloc.free(out);
    }
  }

  Map<String, String>? getHardwareType(int handle) {
    loadLibrary();
    if (!available) return null;
    final hw = calloc<TkHwType>();
    try {
      final status = _tkGetHardwareType(handle, hw.cast());
      if (status != 0) return null;
      // Convert char arrays to Dart String
      String arrToString(ffi.Array<ffi.Uint8> arr) {
        final list = <int>[];
        for (var i = 0; i < 20; i++) {
          final val = arr[i];
          if (val == 0) break;
          list.add(val);
        }
        return utf8.decode(list);
      }

      final name = arrToString(hw.ref.name);
      final type = arrToString(hw.ref.type);
      return {'name': name, 'type': type};
    } finally {
      calloc.free(hw);
    }
  }

  Map<String, bool>? getCybersecurityStatus(int handle) {
    loadLibrary();
    if (!available) return null;
    final statusPtr = calloc<TkCybersecurityStatusType>();
    try {
      final st = _tkGetCybersecurityStatus(handle, statusPtr.cast());
      if (st != 0) return null;
      final ref = statusPtr.ref;
      return {
        'cybersecurityEnabled': ref.cybersecurityEnabled != 0,
        'dbgPortLocked': ref.dbgPortLocked != 0,
        'blSecureBoot': ref.blSecureBoot != 0,
        'appSecureBoot': ref.appSecureBoot != 0,
        'rootCertificateStored': ref.rootCertificateStored != 0,
        'blCertificateStored': ref.blCertificateStored != 0,
        'appCertificateStored': ref.appCertificateStored != 0,
        'blAuthFailed': ref.blAuthFailed != 0,
        'appAuthFailed': ref.appAuthFailed != 0,
      };
    } finally {
      calloc.free(statusPtr);
    }
  }

  Map<String, Object>? getEccCheck(int handle) {
    loadLibrary();
    if (!available) return null;
    final ptr = calloc<TkEccCheckType>();
    try {
      final st = _tkGetEccCheck(handle, ptr.cast());
      if (st != 0) return null;
      return {'errorPresented': ptr.ref.errorPresented != 0, 'errorAddress': ptr.ref.errorAddress};
    } finally {
      calloc.free(ptr);
    }
  }

  // Wrap initialization functions
  int initLibrary(int logLevel, String? logFilePath) {
    loadLibrary();
    if (!available) return -1; // or some error
    final filePtr = logFilePath == null ? ffi.nullptr : logFilePath.toNativeUtf8();
    try {
      return _tkInit(logLevel, filePtr.cast());
    } finally {
      if (filePtr != ffi.nullptr) calloc.free(filePtr);
    }
  }

  int deinit() {
    loadLibrary();
    if (!available) return -1;
    return _tkDeInit();
  }

  // Free resource wrapper
  int freeResource(ffi.Pointer<ffi.Void> resource) {
    loadLibrary();
    if (!available) return -1;
    return _tkFreeResource(resource);
  }

  // -------------------------------------------------------------------------
  // CAN helpers
  // -------------------------------------------------------------------------
  int registerCanInterface(ffi.Pointer<ffi.Void> canInterface, int bitrate, ffi.Pointer<ffi.Uint32> handlePtr) {
    loadLibrary();
    if (!available) return -1;

    //

    return _tkRegisterCanInterface(canInterface.cast(), bitrate, handlePtr.cast());
  }

  int deRegisterCanInterface(int handle) {
    loadLibrary();
    if (!available) return -1;
    return _tkDeRegisterCanInterface(handle);
  }

  int notifyCanFrameReceived(int handle) {
    loadLibrary();
    if (!available) return -1;
    return _tkNotifyCanFrameReceived(handle);
  }

  int addCanIdPair(int handle, ffi.Pointer<TkCanIdPair> pair) {
    loadLibrary();
    if (!available) return -1;
    return _tkAddCanIdPair(handle, pair.cast());
  }

  int removeCanIdPair(int handle, ffi.Pointer<TkCanIdPair> pair) {
    loadLibrary();
    if (!available) return -1;
    return _tkRemoveCanIdPair(handle, pair.cast());
  }

  int transmitCanFrame(int handle, ffi.Pointer<TkCanFrame> frame) {
    loadLibrary();
    if (!available) return -1;
    return _tkTransmitCanFrame(handle, frame.cast());
  }

  /// Adds a target using a Dart POJO.
  /// Returns a record (status, handle).
  (int status, int handle) addTarget(TkTargetAddress addr) {
    loadLibrary();
    if (!available) return (-1, 0);

    final ffiAddr = calloc<TkTargetAddressType>();
    final outHandle = calloc<ffi.Uint32>();

    try {
      // Marshal data from POJO to FFI struct
      ffiAddr.ref.type = addr.type;

      ffiAddr.ref.udsOnCan.mType = addr.udsOnCan.mType;
      ffiAddr.ref.udsOnCan.sa = addr.udsOnCan.sa;
      ffiAddr.ref.udsOnCan.ta = addr.udsOnCan.ta;
      ffiAddr.ref.udsOnCan.taType = addr.udsOnCan.taType;
      ffiAddr.ref.udsOnCan.ae = addr.udsOnCan.ae;
      ffiAddr.ref.udsOnCan.isotpFormat = addr.udsOnCan.isotpFormat;
      ffiAddr.ref.udsOnCan.canHandle = addr.udsOnCan.canHandle;
      ffiAddr.ref.udsOnCan.canFormat = addr.udsOnCan.canFormat;

      ffiAddr.ref.udsOnCan.canCustom.txId = addr.udsOnCan.canCustom.txId;
      ffiAddr.ref.udsOnCan.canCustom.rxId = addr.udsOnCan.canCustom.rxId;
      ffiAddr.ref.udsOnCan.canCustom.txFormat = addr.udsOnCan.canCustom.txFormat;
      ffiAddr.ref.udsOnCan.canCustom.rxFormat = addr.udsOnCan.canCustom.rxFormat;

      final status = _tkAddTarget(ffiAddr.cast(), outHandle);
      final handle = outHandle.value;
      return (status, handle);
    } finally {
      calloc.free(ffiAddr);
      calloc.free(outHandle);
    }
  }

  int removeTarget(int handle) {
    loadLibrary();
    if (!available) return -1;
    return _tkRemoveTarget(handle);
  }

  int setProgrammingRoutines(int handle, String path) {
    loadLibrary();
    final p = path.toNativeUtf8();
    try {
      return _tkSetProgrammingRoutines(handle, p.cast());
    } finally {
      calloc.free(p);
    }
  }

  int setTargetProperties(int handle, ffi.Pointer<TkTargetPropertiesType> props) {
    loadLibrary();
    if (!available) return -1;
    return _tkSetTargetProperties(handle, props.cast());
  }

  int asyncDiscover(int durationMs) {
    loadLibrary();
    if (!available) return -1;
    return _tkAsyncDiscover(durationMs);
  }

  int awaitDiscover(ffi.Pointer<ffi.Pointer<ffi.Uint32>> outHandles, ffi.Pointer<ffi.Uint16> outCount) {
    loadLibrary();
    if (!available) return -1;
    return _tkAwaitDiscover(outHandles.cast(), outCount.cast());
  }

  int asyncConnect(int handle, int durationMs) {
    loadLibrary();
    if (!available) return -1;
    return _tkAsyncConnect(handle, durationMs);
  }

  int awaitConnect() {
    loadLibrary();
    if (!available) return -1;
    return _tkAwaitConnect();
  }

  int writeFromFile(int handle, int memId, String path) {
    loadLibrary();
    final p = path.toNativeUtf8();
    try {
      return _tkWriteFromFile(handle, memId, p.cast());
    } finally {
      calloc.free(p);
    }
  }

  int writeFromFileSigned(int handle, int memId, String path, String signaturePath) {
    loadLibrary();
    final p = path.toNativeUtf8();
    final q = signaturePath.toNativeUtf8();
    try {
      return _tkWriteFromFileSigned(handle, memId, p.cast(), q.cast());
    } finally {
      calloc.free(p);
      calloc.free(q);
    }
  }

  int eraseRange(int handle, int startAddr, int size, int memId) {
    loadLibrary();
    return _tkEraseRange(handle, startAddr, size, memId);
  }

  int readToMemoryBuffer(int handle, int startAddr, int size, int memId, ffi.Pointer<ffi.Pointer<ffi.Uint8>> outBuffer, ffi.Pointer<ffi.Uint32> outBufferSize) {
    loadLibrary();
    if (!available) return -1;
    return _tkReadToMemoryBuffer(handle, startAddr, size, memId, outBuffer.cast(), outBufferSize.cast());
  }

  /// Convenience helper that returns the data buffer as a Dart List<int> and
  /// ensures TTCTK memory is freed using TK_FreeResource.
  /// Returns null if unavailable or an error occurred.
  List<int>? readToMemoryBufferAsList(int handle, int startAddr, int size, int memId) {
    loadLibrary();
    if (!available) return null;
    final outBuffer = calloc<ffi.Pointer<ffi.Uint8>>();
    final outBufSize = calloc<ffi.Uint32>();
    try {
      final status = _tkReadToMemoryBuffer(handle, startAddr, size, memId, outBuffer.cast(), outBufSize.cast());
      if (status != 0) return null;
      final bufPtr = outBuffer.value;
      if (bufPtr == ffi.nullptr) return null;
      final len = outBufSize.value;
      final list = <int>[];
      final typed = bufPtr.asTypedList(len);
      list.addAll(typed);
      // free the underlying C buffer via TK_FreeResource
      _tkFreeResource(bufPtr.cast());
      return list;
    } finally {
      calloc.free(outBuffer);
      calloc.free(outBufSize);
    }
  }

  int resetTarget(int handle) {
    loadLibrary();
    if (!available) return -1;
    return _tkResetTarget(handle);
  }
}

// ---------------------------------------------------------------------------
// C function typedefs and Dart function types
// ---------------------------------------------------------------------------

// Common
typedef _c_TK_GetVersion = ffi.Uint32 Function(ffi.Pointer<ffi.Uint16>, ffi.Pointer<ffi.Uint16>, ffi.Pointer<ffi.Uint16>);
typedef _TK_GetVersion = int Function(ffi.Pointer<ffi.Uint16>, ffi.Pointer<ffi.Uint16>, ffi.Pointer<ffi.Uint16>);
typedef _c_TK_GetVersionString = ffi.Uint32 Function(ffi.Pointer<ffi.Pointer<ffi.Int8>>);
typedef _TK_GetVersionString = int Function(ffi.Pointer<ffi.Pointer<ffi.Int8>>);
typedef _c_TK_GetBuildDate = ffi.Uint32 Function(ffi.Pointer<ffi.Pointer<ffi.Int8>>);
typedef _TK_GetBuildDate = int Function(ffi.Pointer<ffi.Pointer<ffi.Int8>>);
typedef _c_TK_GetBuildTime = ffi.Uint32 Function(ffi.Pointer<ffi.Pointer<ffi.Int8>>);
typedef _TK_GetBuildTime = int Function(ffi.Pointer<ffi.Pointer<ffi.Int8>>);
typedef _c_TK_Init = ffi.Uint32 Function(ffi.Uint32, ffi.Pointer<ffi.Int8>);
typedef _TK_Init = int Function(int, ffi.Pointer<ffi.Int8>);
typedef _c_TK_DeInit = ffi.Uint32 Function();
typedef _TK_DeInit = int Function();
typedef _c_TK_FreeResource = ffi.Uint32 Function(ffi.Pointer<ffi.Void>);
typedef _TK_FreeResource = int Function(ffi.Pointer<ffi.Void>);

// CAN API
typedef _c_TK_RegisterCanInterface = ffi.Uint32 Function(ffi.Pointer<ffi.Void>, ffi.Uint32, ffi.Pointer<ffi.Uint32>);
typedef _TK_RegisterCanInterface = int Function(ffi.Pointer<ffi.Void>, int, ffi.Pointer<ffi.Uint32>);
typedef _c_TK_DeRegisterCanInterface = ffi.Uint32 Function(ffi.Uint32);
typedef _TK_DeRegisterCanInterface = int Function(int);
typedef _c_TK_NotifyCanFrameReceived = ffi.Uint32 Function(ffi.Uint32);
typedef _TK_NotifyCanFrameReceived = int Function(int);
typedef _c_TK_AddCanIdPair = ffi.Uint32 Function(ffi.Uint32, ffi.Pointer<ffi.Void>);
typedef _TK_AddCanIdPair = int Function(int, ffi.Pointer<ffi.Void>);
typedef _c_TK_RemoveCanIdPair = ffi.Uint32 Function(ffi.Uint32, ffi.Pointer<ffi.Void>);
typedef _TK_RemoveCanIdPair = int Function(int, ffi.Pointer<ffi.Void>);
typedef _c_TK_TransmitCanFrame = ffi.Uint32 Function(ffi.Uint32, ffi.Pointer<ffi.Void>);
typedef _TK_TransmitCanFrame = int Function(int, ffi.Pointer<ffi.Void>);

// Target API
typedef _c_TK_AddTarget = ffi.Uint32 Function(ffi.Pointer<ffi.Void>, ffi.Pointer<ffi.Uint32>);
typedef _TK_AddTarget = int Function(ffi.Pointer<ffi.Void>, ffi.Pointer<ffi.Uint32>);
typedef _c_TK_RemoveTarget = ffi.Uint32 Function(ffi.Uint32);
typedef _TK_RemoveTarget = int Function(int);
typedef _c_TK_SetProgrammingRoutines = ffi.Uint32 Function(ffi.Uint32, ffi.Pointer<ffi.Int8>);
typedef _TK_SetProgrammingRoutines = int Function(int, ffi.Pointer<ffi.Int8>);
typedef _c_TK_SetTargetProperties = ffi.Uint32 Function(ffi.Uint32, ffi.Pointer<ffi.Void>);
typedef _TK_SetTargetProperties = int Function(int, ffi.Pointer<ffi.Void>);

// Program API
typedef _c_TK_AsyncDiscover = ffi.Uint32 Function(ffi.Uint32);
typedef _TK_AsyncDiscover = int Function(int);
typedef _c_TK_AwaitDiscover = ffi.Uint32 Function(ffi.Pointer<ffi.Pointer<ffi.Uint32>>, ffi.Pointer<ffi.Uint16>);
typedef _TK_AwaitDiscover = int Function(ffi.Pointer<ffi.Pointer<ffi.Uint32>>, ffi.Pointer<ffi.Uint16>);
typedef _c_TK_AsyncConnect = ffi.Uint32 Function(ffi.Uint32, ffi.Uint32);
typedef _TK_AsyncConnect = int Function(int, int);
typedef _c_TK_AwaitConnect = ffi.Uint32 Function();
typedef _TK_AwaitConnect = int Function();
typedef _c_TK_WriteFromFile = ffi.Uint32 Function(ffi.Uint32, ffi.Uint8, ffi.Pointer<ffi.Int8>);
typedef _TK_WriteFromFile = int Function(int, int, ffi.Pointer<ffi.Int8>);
typedef _c_TK_WriteFromFileSigned = ffi.Uint32 Function(ffi.Uint32, ffi.Uint8, ffi.Pointer<ffi.Int8>, ffi.Pointer<ffi.Int8>);
typedef _TK_WriteFromFileSigned = int Function(int, int, ffi.Pointer<ffi.Int8>, ffi.Pointer<ffi.Int8>);
typedef _c_TK_EraseRange = ffi.Uint32 Function(ffi.Uint32, ffi.Uint32, ffi.Uint32, ffi.Uint8);
typedef _TK_EraseRange = int Function(int, int, int, int);
typedef _c_TK_ReadToMemoryBuffer =
    ffi.Uint32 Function(ffi.Uint32, ffi.Uint32, ffi.Uint32, ffi.Uint8, ffi.Pointer<ffi.Pointer<ffi.Uint8>>, ffi.Pointer<ffi.Uint32>);
typedef _TK_ReadToMemoryBuffer = int Function(int, int, int, int, ffi.Pointer<ffi.Pointer<ffi.Uint8>>, ffi.Pointer<ffi.Uint32>);
typedef _c_TK_ReadDataByIdToMemoryBuffer = ffi.Uint32 Function(ffi.Uint32, ffi.Uint32, ffi.Pointer<ffi.Pointer<ffi.Uint8>>, ffi.Pointer<ffi.Uint32>);
typedef _TK_ReadDataByIdToMemoryBuffer = int Function(int, int, ffi.Pointer<ffi.Pointer<ffi.Uint8>>, ffi.Pointer<ffi.Uint32>);
typedef _c_TK_WriteDataByIdFromMemoryBuffer = ffi.Uint32 Function(ffi.Uint32, ffi.Uint32, ffi.Pointer<ffi.Uint8>, ffi.Uint32);
typedef _TK_WriteDataByIdFromMemoryBuffer = int Function(int, int, ffi.Pointer<ffi.Uint8>, int);
typedef _c_TK_GetBootloaderVersion = ffi.Uint32 Function(ffi.Uint32, ffi.Pointer<TkVersionType>);
typedef _TK_GetBootloaderVersion = int Function(int, ffi.Pointer<TkVersionType>);
typedef _c_TK_GetBootloaderBuildDate = ffi.Uint32 Function(ffi.Uint32, ffi.Pointer<TmStruct>);
typedef _TK_GetBootloaderBuildDate = int Function(int, ffi.Pointer<TmStruct>);
typedef _c_TK_GetApplicationVersion = ffi.Uint32 Function(ffi.Uint32, ffi.Pointer<TkVersionType>);
typedef _TK_GetApplicationVersion = int Function(int, ffi.Pointer<TkVersionType>);
typedef _c_TK_GetApplicationBuildDate = ffi.Uint32 Function(ffi.Uint32, ffi.Pointer<TmStruct>);
typedef _TK_GetApplicationBuildDate = int Function(int, ffi.Pointer<TmStruct>);
typedef _c_TK_GetHsmFirmwareVersion = ffi.Uint32 Function(ffi.Uint32, ffi.Pointer<TkVersionType>);
typedef _TK_GetHsmFirmwareVersion = int Function(int, ffi.Pointer<TkVersionType>);
typedef _c_TK_GetHsmFirmwareBuildDate = ffi.Uint32 Function(ffi.Uint32, ffi.Pointer<TmStruct>);
typedef _TK_GetHsmFirmwareBuildDate = int Function(int, ffi.Pointer<TmStruct>);
typedef _c_TK_GetActiveDiagnosticSessionType = ffi.Uint32 Function(ffi.Uint32, ffi.Pointer<ffi.Uint32>);
typedef _TK_GetActiveDiagnosticSessionType = int Function(int, ffi.Pointer<ffi.Uint32>);
typedef _c_TK_GetDeviceSerialNumber = ffi.Uint32 Function(ffi.Uint32, ffi.Pointer<ffi.Pointer<ffi.Int8>>);
typedef _TK_GetDeviceSerialNumber = int Function(int, ffi.Pointer<ffi.Pointer<ffi.Int8>>);
typedef _c_TK_GetBoardSerialNumber = ffi.Uint32 Function(ffi.Uint32, ffi.Pointer<ffi.Pointer<ffi.Int8>>);
typedef _TK_GetBoardSerialNumber = int Function(int, ffi.Pointer<ffi.Pointer<ffi.Int8>>);
typedef _c_TK_GetProductionCode = ffi.Uint32 Function(ffi.Uint32, ffi.Pointer<ffi.Pointer<ffi.Int8>>);
typedef _TK_GetProductionCode = int Function(int, ffi.Pointer<ffi.Pointer<ffi.Int8>>);
typedef _c_TK_GetMacAddress = ffi.Uint32 Function(ffi.Uint32, ffi.Pointer<ffi.Pointer<ffi.Int8>>);
typedef _TK_GetMacAddress = int Function(int, ffi.Pointer<ffi.Pointer<ffi.Int8>>);
typedef _c_TK_GetHardwareType = ffi.Uint32 Function(ffi.Uint32, ffi.Pointer<TkHwType>);
typedef _TK_GetHardwareType = int Function(int, ffi.Pointer<TkHwType>);
typedef _c_TK_GetCybersecurityStatus = ffi.Uint32 Function(ffi.Uint32, ffi.Pointer<TkCybersecurityStatusType>);
typedef _TK_GetCybersecurityStatus = int Function(int, ffi.Pointer<TkCybersecurityStatusType>);
typedef _c_TK_GetEccCheck = ffi.Uint32 Function(ffi.Uint32, ffi.Pointer<TkEccCheckType>);
typedef _TK_GetEccCheck = int Function(int, ffi.Pointer<TkEccCheckType>);
typedef _c_TK_ResetTarget = ffi.Uint32 Function(ffi.Uint32);
typedef _TK_ResetTarget = int Function(int);

// ---------------------------------------------------------------------------
// End of bindings file
// ---------------------------------------------------------------------------

// Example usage:
// final tk = TTCTK.instance; tk.loadLibrary();
// final versionMap = tk.getVersion();
// final version = tk.getVersionString();
// if (version != null) debugPrint('TTCTK version: $version');
// final status = tk.init(4, null); // init with INFO level and default logfile
// tk.deinit();
