import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io' show Platform;
import 'package:ffi/ffi.dart';
import '../models/ecu_profile.dart';
import 'package:flutter/foundation.dart' show debugPrint;

typedef _get_mock_ecus_native = ffi.Pointer<ffi.Int8> Function();
typedef _get_mock_ecus_dart = ffi.Pointer<ffi.Int8> Function();

typedef _free_cstr_native = ffi.Void Function(ffi.Pointer<ffi.Int8>);
typedef _free_cstr_dart = void Function(ffi.Pointer<ffi.Int8>);

typedef _get_ttctk_version_native = ffi.Pointer<ffi.Int8> Function();
typedef _get_ttctk_version_dart = ffi.Pointer<ffi.Int8> Function();

class NativeEcuModels {
  late ffi.DynamicLibrary _lib;
  late _get_ttctk_version_dart _getTtctkVersion;
  late _get_mock_ecus_dart _getMockEcus;
  late _free_cstr_dart _freeCstr;
  bool available = false;

  NativeEcuModels._internal();

  static final NativeEcuModels instance = NativeEcuModels._internal();

  void initialize() {
    if (available) return;
    String name = '';
    try {
      name = _libraryNameForPlatform();
      _lib = ffi.DynamicLibrary.open(name);
      _getTtctkVersion = _lib.lookupFunction<_get_ttctk_version_native, _get_ttctk_version_dart>('get_ttctk_version');
      _getMockEcus = _lib.lookupFunction<_get_mock_ecus_native, _get_mock_ecus_dart>('get_mock_ecus');
      _freeCstr = _lib.lookupFunction<_free_cstr_native, _free_cstr_dart>('free_cstring');
      available = true;
    } catch (e, s) {
      debugPrint('Native ECU library ($name) failed to load: $e\n$s');
      available = false;
    }
  }

  String _libraryNameForPlatform() {
    if (Platform.isWindows) return 'ecu_models.dll';
    if (Platform.isLinux) return 'libecu_models.so';
    if (Platform.isMacOS) return 'libecu_models.dylib';
    throw UnsupportedError('Native ECU models not supported on this platform');
  }

  // Fallback for ttctk version retrieval
  //TODO

  List<EcuProfile> getMockEcusFallback() {
    // Pure Dart fallback (kept in sync with native mocked data)
    final data = '''[
      {"name":"Engine Control Module","txId":2016,"rxId":2024},
      {"name":"Transmission Control","txId":2017,"rxId":2025},
      {"name":"Fallback Module","txId":2018,"rxId":2026}
    ]''';
    final list = jsonDecode(data) as List<dynamic>;
    return list.map((e) => EcuProfile.fromJson(e)).toList();
  }

  List<EcuProfile> getMockEcus() {
    initialize();
    if (!available) return getMockEcusFallback();

    final ptr = _getMockEcus();
    if (ptr == ffi.nullptr) return [];
    final cstr = ptr.cast<Utf8>();
    final dartStr = cstr.toDartString();
    _freeCstr(ptr);
    final list = jsonDecode(dartStr) as List<dynamic>;
    return list.map((e) => EcuProfile.fromJson(e)).toList();
  }
}

// Convenience
List<EcuProfile> getMockEcusFromNative() => NativeEcuModels.instance.getMockEcus();

String getTtctkVersionFromNative() {
  NativeEcuModels.instance.initialize();
  if (!NativeEcuModels.instance.available) return 'Unknown';

  final ptr = NativeEcuModels.instance._getTtctkVersion();
  if (ptr == ffi.nullptr) return 'Unknown';
  final cstr = ptr.cast<Utf8>();
  final dartStr = cstr.toDartString();
  // NativeEcuModels.instance._freeCstr(ptr);
  return dartStr;
}
