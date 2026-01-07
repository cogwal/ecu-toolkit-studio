import 'package:flutter/material.dart';
import 'dart:async';
import '../models/target.dart';
import '../models/ecu_profile.dart';
import '../services/toolkit_service.dart';
import '../services/target_manager_service.dart';
import '../services/log_service.dart';

// --- TARGET INFO PAGE ---
class TargetInfoPage extends StatefulWidget {
  const TargetInfoPage({super.key});

  @override
  State<TargetInfoPage> createState() => _TargetInfoPageState();
}

class _TargetInfoPageState extends State<TargetInfoPage> {
  Target? _activeTarget;
  EcuProfile? _profile;
  StreamSubscription<Target?>? _targetSubscription;
  bool _isReading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _targetSubscription = TargetManager().activeTargetStream.listen(_handleTargetChange);
    // Initialize with current target
    _handleTargetChange(TargetManager().activeTarget);
  }

  @override
  void dispose() {
    _targetSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleTargetChange(Target? target) {
    if (target == _activeTarget) return;

    setState(() {
      _activeTarget = target;
      _profile = target?.profile;

      if (target != null) {
        // Only read if we don't have basic info yet (e.g. name/hardware type is known)
        final p = target.profile;
        bool needsRead = p == null || p.hardwareType == 'Unknown';

        if (needsRead) {
          _startReading(target);
        }
      }
    });
  }

  Future<void> _startReading(Target target) async {
    if (_isReading) return;

    setState(() => _isReading = true);

    try {
      final updatedProfile = await ToolkitService().readTargetInfo(target);
      if (mounted && _activeTarget == target) {
        setState(() => _profile = updatedProfile);
      }
    } catch (e) {
      LogService().error("Failed to read target info: $e");
    } finally {
      if (mounted) {
        setState(() => _isReading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine target to use (local state)
    final target = _activeTarget;

    if (target == null) {
      return const Center(child: Text("No Active Connection"));
    }

    final profile = _profile;
    if (profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Target Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Connected to: ${profile.name}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                  ],
                ),
                const Spacer(),
                Container(width: 1, height: 32, color: Colors.white12),
                const SizedBox(width: 8),
                IconButton(
                  icon: _isReading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.refresh),
                  tooltip: 'Refresh Information',
                  onPressed: _isReading ? null : () => _startReading(target),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = 280.0;

                return Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader("Hardware"),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            _buildInfoCard("Device Serial", profile.serialNumber, Icons.qr_code, width: cardWidth),
                            _buildInfoCard("Hardware Type", "${profile.hardwareName} (${profile.hardwareType})", Icons.memory, width: cardWidth),
                            _buildInfoCard("Production Code", profile.productionCode, Icons.factory, width: cardWidth),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildSectionHeader("Software"),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            _buildInfoCard("Bootloader Version", profile.bootloaderVersion, Icons.system_update, width: cardWidth),
                            _buildInfoCard("Application Version", profile.appVersion, Icons.apps, width: cardWidth),
                            _buildInfoCard("HSM Version", profile.hsmVersion, Icons.security, width: cardWidth),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildSectionHeader("Build Dates"),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            _buildInfoCard("Bootloader Date", profile.bootloaderBuildDate, Icons.calendar_today, width: cardWidth),
                            _buildInfoCard("App Build Date", profile.appBuildDate, Icons.calendar_today, width: cardWidth),
                            _buildInfoCard("HSM Build Date", profile.hsmBuildDate, Icons.calendar_today, width: cardWidth),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, {required double width}) {
    final displayValue = value.isEmpty ? "Unknown" : value;
    return Container(
      width: width,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
            child: Icon(icon, size: 20, color: Colors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(
                  displayValue,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
