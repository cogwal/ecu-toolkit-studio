import 'ecu_profile.dart';

class TargetConnection {
  final int canHandle;
  final int targetHandle;
  final int sa;
  final int ta;
  EcuProfile? profile;

  TargetConnection({required this.canHandle, required this.targetHandle, required this.sa, required this.ta, this.profile});
}
