import 'dart:async';
import 'dart:isolate';
import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';
import '../native/ttctk.dart';

class ConnectionService {
  static final ConnectionService _instance = ConnectionService._internal();
  factory ConnectionService() => _instance;
  ConnectionService._internal();

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

  Future<bool> connectTarget(int handle, {int durationMs = 5000}) async {
    if (_canHandle == null) {
      throw Exception("CAN interface not registered");
    }

    final asyncStatus = TTCTK.instance.asyncConnect(handle, durationMs);
    if (asyncStatus != 0) {
      throw Exception("Async connect failed immediately. Status: $asyncStatus");
    }

    // This is a blocking call in the C library. We use Isolate.run to avoid freezing the UI.
    final connectStatus = await Isolate.run(() {
      return TTCTK.instance.awaitConnect();
    });

    if (connectStatus == 0) {
      return true;
    } else {
      throw Exception("Await connect returned with error: $connectStatus");
    }
  }
}
