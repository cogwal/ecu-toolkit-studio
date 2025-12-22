import 'package:flutter/material.dart';
import 'dart:async';
import '../models/target.dart';
import '../services/target_manager_service.dart';
import '../services/toolkit_service.dart';
import 'flash_tabs/fdr_tab.dart';
import 'flash_tabs/security_tab.dart';
import 'flash_tabs/download_tab.dart';
import 'flash_tabs/erase_tab.dart';
import 'flash_tabs/upload_tab.dart';

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
    return _activeTarget?.profile?.hardwareType ?? 'Unknown';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
                    Text('HW: $_hardwareType', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
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
                      Tab(child: Row(children: [Icon(Icons.settings, size: 16), SizedBox(width: 8), Text('FDR Setup')])),
                      Tab(child: Row(children: [Icon(Icons.lock, size: 16), SizedBox(width: 8), Text('Security')])),
                      Tab(child: Row(children: [Icon(Icons.download, size: 16), SizedBox(width: 8), Text('Download')])),
                      Tab(child: Row(children: [Icon(Icons.delete_forever, size: 16), SizedBox(width: 8), Text('Erase')])),
                      Tab(child: Row(children: [Icon(Icons.upload, size: 16), SizedBox(width: 8), Text('Upload')])),
                    ],
                  ),
                ),

                // Status
                if (_toolkit.isFdrLoaded) ...[
                  const SizedBox(width: 16),
                  Chip(
                    avatar: const Icon(Icons.check_circle, color: Colors.green, size: 16),
                    label: const Text('FDR Loaded', style: TextStyle(fontSize: 11)),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: Colors.green.withOpacity(0.1),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ],
                if (_toolkit.isSecuritySet) ...[
                  const SizedBox(width: 8),
                  Chip(
                    avatar: const Icon(Icons.shield, color: Colors.blue, size: 16),
                    label: const Text('Security Keys Set', style: TextStyle(fontSize: 11)),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tab content
          Expanded(
            child: TabBarView(controller: _tabController, children: [const FdrTab(), SecurityTab(), DownloadTab(), EraseTab(), UploadTab()]),
          ),
        ],
      ),
    );
  }
}
