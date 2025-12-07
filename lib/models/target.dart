import 'ecu_profile.dart';

class Target {
  final int canHandle;
  final int targetHandle;
  final int sa;
  final int ta;
  EcuProfile? profile;

  Target({required this.canHandle, required this.targetHandle, required this.sa, required this.ta, this.profile});
}
