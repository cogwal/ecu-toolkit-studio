import 'dart:async';
import 'dart:isolate';
import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';
import '../native/ttctk.dart';
import '../models/target.dart';
import '../models/ecu_profile.dart';

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
      canInterface.ref.peak.channel = PCAN_USBBUS1;

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

  Future<Target> connectTarget(int sa, int ta, {int durationMs = 5000}) async {
    if (_canHandle == null) {
      throw Exception("CAN interface not registered");
    }

    final addr = TkTargetAddress();
    addr.type = TK_TARGET_CATEGORY_UDS_ON_CAN;
    addr.udsOnCan.mType = TK_TARGET_UDS_MTYPE_DIAGNOSTICS;
    addr.udsOnCan.sa = sa;
    addr.udsOnCan.ta = ta;
    addr.udsOnCan.taType = TK_TARGET_UDS_TATYPE_PHYSICAL;
    addr.udsOnCan.ae = 0;
    addr.udsOnCan.isotpFormat = TK_TARGET_ISOTP_FORMAT_NORMAL;
    addr.udsOnCan.canHandle = _canHandle!;
    addr.udsOnCan.canFormat = TK_CAN_FRAME_FORMAT_BASE;

    final (status, handle) = TTCTK.instance.addTarget(addr);

    if (status != 0) {
      throw Exception("Failed to add target. Status: $status");
    }

    try {
      // 3. asyncConnect
      final asyncStatus = TTCTK.instance.asyncConnect(handle, durationMs);
      if (asyncStatus != 0) {
        throw Exception("Async connect failed immediately. Status: $asyncStatus");
      }

      // 4. awaitConnect
      // This is a blocking call in the C library. We use Isolate.run to avoid freezing the UI.
      final connectStatus = await Isolate.run(() {
        return TTCTK.instance.awaitConnect();
      });

      if (connectStatus == 0) {
        // Calculate CAN IDs for display (Physical Addressing)
        final txId = 0x7DF + ta; // Simplified calculation as per previous logic
        final rxId = 0x7E7 + ta;

        return Target(
          canHandle: _canHandle!,
          targetHandle: handle,
          sa: sa,
          ta: ta,
          profile: EcuProfile(name: "Target 0x${ta.toRadixString(16).toUpperCase().padLeft(2, '0')}", txId: txId, rxId: rxId),
        );
      } else {
        throw Exception("Connection failed. Status: $connectStatus");
      }
    } catch (e) {
      TTCTK.instance.removeTarget(handle);
      rethrow;
    }
  }
}
