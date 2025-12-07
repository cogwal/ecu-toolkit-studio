import 'package:flutter/material.dart';
import 'dart:async';
import '../models/ecu_profile.dart';
import '../models/target_connection.dart';
import '../services/connection_service.dart';
import '../services/log_service.dart';

class ConnectionPage extends StatefulWidget {
  final Function(EcuProfile) onEcuConnected;

  const ConnectionPage({super.key, required this.onEcuConnected});

  @override
  State<ConnectionPage> createState() => _ConnectionPageState();
}

class _ConnectionPageState extends State<ConnectionPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isScanning = false;
  List<TargetConnection> _discoveredTargets = [];

  final TextEditingController _saController = TextEditingController(text: "F1");
  final TextEditingController _taController = TextEditingController(text: "08");
  double _connectionTimeout = 5000;

  // CAN interface handle
  int? _canHandle;
  String _canStatus = "Not registered";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _saController.dispose();
    _taController.dispose();
    // We might want to deregister CAN on dispose if that's desired, but usually connection persists.
    super.dispose();
  }

  void _startNetworkScan() async {
    if (_canHandle == null) {
      LogService().warning("Please register CAN interface first");
      return;
    }

    setState(() {
      _isScanning = true;
      _discoveredTargets.clear();
    });

    // Scan targets 0x01 to 0x08
    for (int ta = 0x01; ta <= 0x08; ta++) {
      await _connectTarget(0xF1, ta, isDiscovery: true);
    }

    setState(() {
      _isScanning = false;
    });
  }

  Future<void> _connectTarget(int sa, int ta, {bool isDiscovery = false}) async {
    if (!ConnectionService().isCanRegistered) {
      LogService().warning("Please register CAN interface first");
      return;
    }

    try {
      // For discovery, we might want a shorter timeout or different logic.
      // But adhering to the new service:
      final connection = await ConnectionService().connectTarget(sa, ta, durationMs: _connectionTimeout.toInt());

      setState(() {
        _discoveredTargets.add(connection);
      });

      if (!isDiscovery) {
        widget.onEcuConnected(connection.profile!);
      }
    } catch (e) {
      if (!isDiscovery) {
        LogService().error("Connection failed: $e");
      }
      debugPrint("Error connecting target: $e");
    }
  }

  void _connectMockTarget() {
    final connection = TargetConnection(
      canHandle: 0,
      targetHandle: 0,
      sa: 0xF1,
      ta: 0x99,
      profile: EcuProfile(
        name: "Mock ECU",
        txId: 0x7E0,
        rxId: 0x7E8,
        serialNumber: "MOCK-SN-12345",
        hardwareType: "Virtual ECU",
        appVersion: "1.0.0-mock",
        bootloaderVersion: "0.5.0-mock",
        productionCode: "P-MOCK-001",
        appBuildDate: "2023-10-27",
      ),
    );

    setState(() {
      _discoveredTargets.add(connection);
    });

    widget.onEcuConnected(connection.profile!);
  }

  void _registerCanInterface() async {
    try {
      await ConnectionService().registerCanInterface();
      setState(() {
        _canHandle = ConnectionService().canHandle;
        _canStatus = "Registered (Handle: $_canHandle)";
      });
      LogService().info("CAN interface registered successfully");
    } catch (e) {
      setState(() {
        _canStatus = "Error: $e";
      });
      LogService().error("$e");
    }
  }

  void _deregisterCanInterface() async {
    try {
      await ConnectionService().deregisterCanInterface();
      setState(() {
        _canHandle = null;
        _canStatus = "Not registered";
      });
      LogService().info("CAN interface deregistered");
    } catch (e) {
      LogService().error("$e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 900; // treat wide screens (desktop) differently

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Establish Connection", style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),

          // Wide layout: Left column (CAN + Direct Connect), Right column (Discovery full height)
          if (isWide)
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left side: CAN Interface + Direct Connect stacked
                  Expanded(
                    child: Column(
                      children: [
                        _buildCanInterfaceSection(),
                        const SizedBox(height: 16),
                        Expanded(
                          child: _panelCard(child: _buildDirectTab(), title: "Direct Connect"),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Right side: Discovery (full height)
                  Expanded(
                    child: _panelCard(child: _buildScannerTab(), title: "Network Discovery"),
                  ),
                ],
              ),
            )
          else
            // Narrow layout: keep original tab-based layout
            Column(
              children: [
                _buildCanInterfaceSection(),
                const SizedBox(height: 24),
                Container(
                  width: 400,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      TabBar(
                        controller: _tabController,
                        indicatorColor: Theme.of(context).primaryColor,
                        dividerColor: Colors.transparent,
                        tabs: const [
                          Tab(text: "Network Discovery"),
                          Tab(text: "Direct Connect"),
                        ],
                      ),
                      SizedBox(
                        height: 350,
                        child: TabBarView(controller: _tabController, children: [_buildScannerTab(), _buildDirectTab()]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCanInterfaceSection() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("CAN Interface", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              Text("Status: ", style: Theme.of(context).textTheme.bodyMedium),
              Text(
                _canStatus,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: _canHandle != null ? Colors.green : Colors.grey, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _canHandle == null ? _registerCanInterface : null,
                icon: const Icon(Icons.usb),
                label: const Text("Register PEAK USB 1 (500K)"),
              ),
              const SizedBox(width: 12),
              if (_canHandle != null)
                ElevatedButton.icon(
                  onPressed: _deregisterCanInterface,
                  icon: const Icon(Icons.close),
                  label: const Text("Deregister"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red.withOpacity(0.7)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _panelCard({required Widget child, String? title}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
              child: Text(title, style: Theme.of(context).textTheme.titleMedium),
            ),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildScannerTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isScanning ? null : _startNetworkScan,
              icon: _isScanning
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.search),
              label: Text(_isScanning ? "Scanning..." : "Discover ECUs"),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          Expanded(
            child: _discoveredTargets.isEmpty && !_isScanning
                ? const Center(
                    child: Text("No Targets found. Try again.", style: TextStyle(color: Colors.grey)),
                  )
                : ListView.builder(
                    itemCount: _discoveredTargets.length,
                    itemBuilder: (context, index) {
                      final target = _discoveredTargets[index];
                      final profile = target.profile;
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(profile?.name ?? "Target ${target.ta}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("SA: 0x${target.sa.toRadixString(16).toUpperCase()} | TA: 0x${target.ta.toRadixString(16).toUpperCase()}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.arrow_forward_ios, size: 14),
                          onPressed: () {
                            if (profile != null) widget.onEcuConnected(profile);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final sa = int.tryParse(_saController.text, radix: 16) ?? 0xF1;
                final ta = int.tryParse(_taController.text, radix: 16) ?? 0x08;
                _connectTarget(sa, ta);
              },
              child: const Text("Connect"),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(onPressed: _connectMockTarget, icon: const Icon(Icons.bug_report, size: 18), label: const Text("Connect Mock Target")),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _saController,
            decoration: const InputDecoration(
              labelText: "Source Address (SA) (Hex)",
              prefixText: "0x",
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _taController,
            decoration: const InputDecoration(
              labelText: "Target Address (TA) (Hex)",
              prefixText: "0x",
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Connection Timeout: " + ((_connectionTimeout.toInt() == 0) ? "Indefinite" : "${_connectionTimeout.toInt()} ms"),
                style: const TextStyle(fontSize: 13),
              ),
              Slider(
                value: _connectionTimeout,
                min: 0,
                max: 10000,
                divisions: 100,
                label: (_connectionTimeout.toInt() == 0) ? "Indefinite" : "${_connectionTimeout.toInt()} ms",
                onChanged: (value) {
                  setState(() {
                    _connectionTimeout = value;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
