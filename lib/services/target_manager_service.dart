import 'dart:async';
import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';
import '../native/ttctk.dart';
import '../models/target.dart';
import '../models/ecu_profile.dart';

import 'log_service.dart';

class TargetManager {
  static final TargetManager _instance = TargetManager._internal();
  factory TargetManager() => _instance;
  TargetManager._internal();

  final List<Target> _targets = [];
  Target? _activeTarget;

  final _activeTargetController = StreamController<Target?>.broadcast();
  final _targetsController = StreamController<List<Target>>.broadcast();

  Stream<Target?> get activeTargetStream => _activeTargetController.stream;
  Stream<List<Target>> get targetsStream => _targetsController.stream;

  Target? get activeTarget => _activeTarget;
  List<Target> get targets => List.unmodifiable(_targets);

  Target createTarget(int sa, int ta, int canHandle) {
    final addr = TkTargetAddress();
    addr.type = TK_TARGET_CATEGORY_UDS_ON_CAN;
    addr.udsOnCan.mType = TK_TARGET_UDS_MTYPE_DIAGNOSTICS;
    addr.udsOnCan.sa = sa;
    addr.udsOnCan.ta = ta;
    addr.udsOnCan.taType = TK_TARGET_UDS_TATYPE_PHYSICAL;
    addr.udsOnCan.ae = 0;
    addr.udsOnCan.isotpFormat = TK_TARGET_ISOTP_FORMAT_NORMAL;
    addr.udsOnCan.canHandle = canHandle;
    addr.udsOnCan.canFormat = TK_CAN_FRAME_FORMAT_BASE;

    final (status, handle) = TTCTK.instance.addTarget(addr);
    if (status != 0) {
      LogService().error("Failed to add target to TTC toolkit: $status");
    }

    final target = Target(
      canHandle: canHandle,
      targetHandle: handle,
      sa: sa,
      ta: ta,
      profile: EcuProfile(
        name: "Unknown",
        txId: 0,
        rxId: 0,
        serialNumber: "Unknown",
        hardwareType: "Unknown",
        appVersion: "Unknown",
        bootloaderVersion: "Unknown",
        productionCode: "Unknown",
        appBuildDate: "Unknown",
      ),
    );

    // Use our internal add method
    return addTarget(target);
  }

  Target addTarget(Target target) {
    _targets.add(target);
    _notifyTargetsChanged();
    return target;
  }

  void removeTarget(Target target) {
    // Change active target if it's the one we're removing
    if (_activeTarget == target) {
      Target? newActiveTarget;
      if (_targets.length > 1) {
        newActiveTarget = _targets.firstWhere((t) => t != target, orElse: () => _targets.last);
        if (newActiveTarget == target) newActiveTarget = null;
      }
      setActiveTarget(newActiveTarget);
    }

    final status = TTCTK.instance.removeTarget(target.targetHandle);
    if (status != 0) {
      LogService().error("Failed to remove target from TTC toolkit: $status");
    }

    _targets.remove(target);
    _notifyTargetsChanged();
  }

  void setActiveTarget(Target? target) {
    if (_activeTarget != target) {
      _activeTarget = target;
      _activeTargetController.add(_activeTarget);
      if (target != null) {
        LogService().debug("Target switched to: ${target.profile?.name ?? 'Unknown'}");
      } else {
        LogService().debug("Target cleared");
      }
    }
  }

  void _notifyTargetsChanged() {
    _targetsController.add(List.unmodifiable(_targets));
  }

  void dispose() {
    _activeTargetController.close();
    _targetsController.close();
  }
}
