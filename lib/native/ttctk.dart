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

import 'dart:ffi' as ffi;
import 'dart:io' show Platform;
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart' show debugPrint;

// ---------------------------------------------------------------------------
// C types and layout helpers
// ---------------------------------------------------------------------------

// Constants from headers: sizes
const int TK_CAN_FD_FRAME_MAX_LENGTH = 64;
const int TK_TARGET_ADDRESS_CONFIG_SIZE_MAX = 256;
const int TK_TARGET_PROPERTIES_CONFIG_SIZE_MAX = 256;

// Typedefs
typedef TkStatusType = ffi.Uint32; // TkStatusType is uint32
typedef TkLogLevelType = ffi.Uint32;
typedef TkCanBitrateType = ffi.Uint32;
typedef TkCanInterfaceHandleType = ffi.Uint32;
typedef TkCanFrameFormatType = ffi.Uint32;
typedef TkTargetHandleType = ffi.Uint32;

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

// Representing simple fixed-length unions as raw bytes
final class TkTargetAddressType extends ffi.Struct {
  @ffi.Uint32()
  external int type;

  @ffi.Array(TK_TARGET_ADDRESS_CONFIG_SIZE_MAX)
  external ffi.Array<ffi.Uint8> raw;
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

  TTCTK._internal();

  static final TTCTK instance = TTCTK._internal();

  void initialize() {
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
    initialize();
    if (!available) return null;
    final major = calloc<ffi.Uint16>();
    final minor = calloc<ffi.Uint16>();
    final patch = calloc<ffi.Uint16>();
    try {
      final status = _tkGetVersion(major, minor, patch);
      if (status != 0) return null;
      return {
        'major': major.value,
        'minor': minor.value,
        'patch': patch.value,
      };
    } finally {
      calloc.free(major);
      calloc.free(minor);
      calloc.free(patch);
    }
  }

  String? getVersionString() {
    initialize();
    if (!available) return null;
    final out = calloc<ffi.Pointer<ffi.Int8>>();
    try {
      return _callStringOut(out, (p) => _tkGetVersionString(p));
    } finally {
      calloc.free(out);
    }
  }

  String? getBuildDate() {
    initialize();
    if (!available) return null;
    final out = calloc<ffi.Pointer<ffi.Int8>>();
    try {
      return _callStringOut(out, (p) => _tkGetBuildDate(p));
    } finally {
      calloc.free(out);
    }
  }

  String? getBuildTime() {
    initialize();
    if (!available) return null;
    final out = calloc<ffi.Pointer<ffi.Int8>>();
    try {
      return _callStringOut(out, (p) => _tkGetBuildTime(p));
    } finally {
      calloc.free(out);
    }
  }

  // Wrap initialization functions
  int initLog(int logLevel, String? logFilePath) {
    initialize();
    if (!available) return -1; // or some error
    final filePtr = logFilePath == null ? ffi.nullptr : logFilePath.toNativeUtf8();
    try {
      return _tkInit(logLevel, filePtr.cast());
    } finally {
      if (filePtr != ffi.nullptr) calloc.free(filePtr);
    }
  }

  int deinit() {
    initialize();
    if (!available) return -1;
    return _tkDeInit();
  }

  // Free resource wrapper
  int freeResource(ffi.Pointer<ffi.Void> resource) {
    initialize();
    if (!available) return -1;
    return _tkFreeResource(resource);
  }

  // -------------------------------------------------------------------------
  // CAN helpers
  // -------------------------------------------------------------------------
  int registerCanInterface(ffi.Pointer<ffi.Void> canInterface, int bitrate, ffi.Pointer<ffi.Uint32> handlePtr) {
    initialize();
    if (!available) return -1;
    return _tkRegisterCanInterface(canInterface.cast(), bitrate, handlePtr.cast());
  }

  int deRegisterCanInterface(int handle) {
    initialize();
    if (!available) return -1;
    return _tkDeRegisterCanInterface(handle);
  }

  int notifyCanFrameReceived(int handle) {
    initialize();
    if (!available) return -1;
    return _tkNotifyCanFrameReceived(handle);
  }

  int addCanIdPair(int handle, ffi.Pointer<TkCanIdPair> pair) {
    initialize();
    if (!available) return -1;
    return _tkAddCanIdPair(handle, pair.cast());
  }

  int removeCanIdPair(int handle, ffi.Pointer<TkCanIdPair> pair) {
    initialize();
    if (!available) return -1;
    return _tkRemoveCanIdPair(handle, pair.cast());
  }

  int transmitCanFrame(int handle, ffi.Pointer<TkCanFrame> frame) {
    initialize();
    if (!available) return -1;
    return _tkTransmitCanFrame(handle, frame.cast());
  }

  // -------------------------------------------------------------------------
  // Target and programming API minimal wrappers
  // -------------------------------------------------------------------------

  int addTarget(ffi.Pointer<TkTargetAddressType> addr, ffi.Pointer<ffi.Uint32> outHandle) {
    initialize();
    if (!available) return -1;
    return _tkAddTarget(addr.cast(), outHandle.cast());
  }

  int removeTarget(int handle) {
    initialize();
    if (!available) return -1;
    return _tkRemoveTarget(handle);
  }

  int setProgrammingRoutines(int handle, String path) {
    initialize();
    final p = path.toNativeUtf8();
    try {
      return _tkSetProgrammingRoutines(handle, p.cast());
    } finally {
      calloc.free(p);
    }
  }

  int setTargetProperties(int handle, ffi.Pointer<TkTargetPropertiesType> props) {
    initialize();
    if (!available) return -1;
    return _tkSetTargetProperties(handle, props.cast());
  }

  int asyncDiscover(int durationMs) {
    initialize();
    if (!available) return -1;
    return _tkAsyncDiscover(durationMs);
  }

  int awaitDiscover(ffi.Pointer<ffi.Pointer<ffi.Uint32>> outHandles, ffi.Pointer<ffi.Uint16> outCount) {
    initialize();
    if (!available) return -1;
    return _tkAwaitDiscover(outHandles.cast(), outCount.cast());
  }

  int asyncConnect(int handle, int durationMs) {
    initialize();
    if (!available) return -1;
    return _tkAsyncConnect(handle, durationMs);
  }

  int awaitConnect() {
    initialize();
    if (!available) return -1;
    return _tkAwaitConnect();
  }

  int writeFromFile(int handle, int memId, String path) {
    initialize();
    final p = path.toNativeUtf8();
    try {
      return _tkWriteFromFile(handle, memId, p.cast());
    } finally {
      calloc.free(p);
    }
  }

  int writeFromFileSigned(int handle, int memId, String path, String signaturePath) {
    initialize();
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
    initialize();
    return _tkEraseRange(handle, startAddr, size, memId);
  }

  int readToMemoryBuffer(int handle, int startAddr, int size, int memId, ffi.Pointer<ffi.Pointer<ffi.Uint8>> outBuffer, ffi.Pointer<ffi.Uint32> outBufferSize) {
    initialize();
    if (!available) return -1;
    return _tkReadToMemoryBuffer(handle, startAddr, size, memId, outBuffer.cast(), outBufferSize.cast());
  }

  /// Convenience helper that returns the data buffer as a Dart List<int> and
  /// ensures TTCTK memory is freed using TK_FreeResource.
  /// Returns null if unavailable or an error occurred.
  List<int>? readToMemoryBufferAsList(int handle, int startAddr, int size, int memId) {
    initialize();
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
    initialize();
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
typedef _c_TK_ReadToMemoryBuffer = ffi.Uint32 Function(ffi.Uint32, ffi.Uint32, ffi.Uint32, ffi.Uint8, ffi.Pointer<ffi.Pointer<ffi.Uint8>>, ffi.Pointer<ffi.Uint32>);
typedef _TK_ReadToMemoryBuffer = int Function(int, int, int, int, ffi.Pointer<ffi.Pointer<ffi.Uint8>>, ffi.Pointer<ffi.Uint32>);
typedef _c_TK_ResetTarget = ffi.Uint32 Function(ffi.Uint32);
typedef _TK_ResetTarget = int Function(int);

// ---------------------------------------------------------------------------
// End of bindings file
// ---------------------------------------------------------------------------

// Example usage:
// final tk = TTCTK.instance; tk.initialize();
// final versionMap = tk.getVersion();
// final version = tk.getVersionString();
// if (version != null) debugPrint('TTCTK version: $version');
// final status = tk.initLog(4, null); // init with INFO level and default logfile
// tk.deinit();
