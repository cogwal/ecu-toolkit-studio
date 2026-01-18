import 'package:flutter/material.dart';
import 'dart:async';
import '../models/target.dart';
import '../services/target_manager_service.dart';
import '../services/toolkit_service.dart';
import 'flash_tabs/download_tab.dart';
import 'flash_tabs/erase_tab.dart';
import 'flash_tabs/upload_tab.dart';
import 'flash_tabs/setup_tab.dart';

/// Flash operations page with tabbed interface
class FlashWizardPage extends StatefulWidget {
  const FlashWizardPage({super.key});

  @override
  State<FlashWizardPage> createState() => _FlashWizardPageState();
}

class _FlashWizardPageState extends State<FlashWizardPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  Target? _activeTarget;
  StreamSubscription<Target?>? _targetSubscription;
  final ToolkitService _toolkit = ToolkitService();

  String get _hardwareType {
    return _activeTarget?.profile?.name ?? 'Unknown';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _targetSubscription = TargetManager().activeTargetStream.listen((target) {
      setState(() => _activeTarget = target);
    });
    // Set initial value
    _activeTarget = TargetManager().activeTarget;
    _toolkit.addListener(_onToolkitChanged);
  }

  @override
  void dispose() {
    _targetSubscription?.cancel();
    _tabController.dispose();
    _toolkit.removeListener(_onToolkitChanged);
    super.dispose();
  }

  void _onToolkitChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_activeTarget == null) {
      return const Center(child: Text('No target connected'));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact Header + Tab Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                // Title Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Flash Operations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Connected to: $_hardwareType', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                  ],
                ),
                const SizedBox(width: 16),
                Container(width: 1, height: 32, color: Colors.white12),
                const SizedBox(width: 8),

                // Tabs
                Expanded(
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicatorSize: TabBarIndicatorSize.label,
                    dividerColor: Colors.transparent,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                    tabs: const [
                      Tab(child: Row(children: [Icon(Icons.download, size: 16), SizedBox(width: 8), Text('Download')])),
                      Tab(child: Row(children: [Icon(Icons.delete_forever, size: 16), SizedBox(width: 8), Text('Erase')])),
                      Tab(child: Row(children: [Icon(Icons.upload, size: 16), SizedBox(width: 8), Text('Upload')])),
                      Tab(child: Row(children: [Icon(Icons.settings, size: 16), SizedBox(width: 8), Text('Setup')])),
                    ],
                  ),
                ),

                // Status
                // Status
                const SizedBox(width: 16),
                ToolkitStatusChip(
                  isOk: _toolkit.isFdrLoaded,
                  labelOk: 'FDR Loaded',
                  labelError: 'FDR Not Loaded',
                  iconOk: Icons.check_circle,
                  iconError: Icons.error_outline,
                  colorOk: Colors.green,
                  colorError: Colors.red,
                ),
                const SizedBox(width: 8),
                ToolkitStatusChip(
                  isOk: _toolkit.isSecuritySet,
                  labelOk: 'Security Set',
                  labelError: 'Security Not Set',
                  iconOk: Icons.shield,
                  iconError: Icons.shield_outlined,
                  colorOk: Colors.blue,
                  colorError: Colors.red,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tab content
          Expanded(
            child: TabBarView(controller: _tabController, children: [DownloadTab(), EraseTab(), UploadTab(), SetupTab()]),
          ),
        ],
      ),
    );
  }
}

class ToolkitStatusChip extends StatelessWidget {
  final bool isOk;
  final String labelOk;
  final String labelError;
  final IconData iconOk;
  final IconData iconError;
  final MaterialColor colorOk;
  final MaterialColor colorError;

  const ToolkitStatusChip({
    super.key,
    required this.isOk,
    required this.labelOk,
    required this.labelError,
    required this.iconOk,
    required this.iconError,
    required this.colorOk,
    required this.colorError,
  });

  @override
  Widget build(BuildContext context) {
    final color = isOk ? colorOk : colorError;
    return Chip(
      avatar: Icon(isOk ? iconOk : iconError, color: color, size: 16),
      label: Text(isOk ? labelOk : labelError, style: const TextStyle(fontSize: 11)),
      visualDensity: VisualDensity.compact,
      backgroundColor: color.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      side: BorderSide(color: color.withOpacity(0.3)),
    );
  }
}
