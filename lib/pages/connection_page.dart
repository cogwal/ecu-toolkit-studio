import 'package:flutter/material.dart';
import 'dart:async';
import '../models/ecu_profile.dart';
import '../models/target.dart';
import '../services/connection_service.dart';
import '../services/log_service.dart';

class ConnectionPage extends StatefulWidget {
  final Function(Target) onEcuConnected;

  const ConnectionPage({super.key, required this.onEcuConnected});

  @override
  State<ConnectionPage> createState() => _ConnectionPageState();
}

class _ConnectionPageState extends State<ConnectionPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isScanning = false;
  List<Target> _discoveredTargets = [];

  final TextEditingController _saController = TextEditingController(text: "F1");
  final TextEditingController _taController = TextEditingController(text: "08");
  double _connectionTimeout = 5000;

  // CAN interface handle
  int? _canHandle;
  String _canStatus = "Not registered";

  @override
  void initState() {
    if (ConnectionService().isCanRegistered) {
      _canHandle = ConnectionService().canHandle;
      _canStatus = "Registered (Handle: $_canHandle)";
    }
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

    LogService().info("Starting network scan for ECU targets...");
    setState(() {
      _isScanning = true;
      _discoveredTargets.clear();
    });

    // Scan targets 0x01 to 0x08
    // TODO Broken, add targets first then do a discovery using the correct APIs
    // for (int ta = 0x01; ta <= 0x08; ta++) {
    //   await _connectTarget(0xF1, ta, isDiscovery: true);
    // }

    LogService().info("Network scan completed. Found ${_discoveredTargets.length} target(s)");
    setState(() {
      _isScanning = false;
    });
  }

  Future<void> _connectTarget(int sa, int ta, {bool isDiscovery = false}) async {
    if (!ConnectionService().isCanRegistered) {
      LogService().warning("Please register CAN interface first");
      return;
    }

    final saHex = "0x${sa.toRadixString(16).toUpperCase()}";
    final taHex = "0x${ta.toRadixString(16).toUpperCase()}";
    LogService().info("Attempting connection to target SA=$saHex, TA=$taHex (timeout: ${_connectionTimeout.toInt()}ms)");

    try {
      final target = await ConnectionService().connectTarget(sa, ta, durationMs: _connectionTimeout.toInt());

      LogService().info("Successfully connected to target SA=$saHex, TA=$taHex (handle: ${target.targetHandle})");

      LogService().debug("Invoking onEcuConnected callback for target TA=$taHex");
      widget.onEcuConnected(target);
    } catch (e) {
      LogService().error("Connection to target SA=$saHex, TA=$taHex failed: $e");
    }
  }

  void _connectMockTarget() {
    LogService().info("Creating mock target connection...");
    final target = Target(
      canHandle: 0,
      targetHandle: 0,
      sa: 0xF1,
      ta: 0x01,
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

    LogService().info("Mock target created: ${target.profile?.name} (SA=0xF1, TA=0x01)");

    LogService().debug("Invoking onEcuConnected callback for mock target");
    widget.onEcuConnected(target);
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
    final isWide = width >= 900;

    return Padding(
      padding: const EdgeInsets.all(32.0),
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
                    const Text('Connection', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(isWide ? 'Dashboard' : 'Setup', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                  ],
                ),
                if (!isWide) ...[
                  const SizedBox(width: 16),
                  Container(width: 1, height: 32, color: Colors.white12),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TabBar(
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.label,
                      dividerColor: Colors.transparent,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                      isScrollable: true,
                      tabs: const [
                        Tab(child: Row(children: [Icon(Icons.search, size: 16), SizedBox(width: 8), Text('Discovery')])),
                        Tab(child: Row(children: [Icon(Icons.link, size: 16), SizedBox(width: 8), Text('Direct')])),
                      ],
                    ),
                  ),
                ] else ...[
                  const Spacer(), // Push content to left in wide mode or add actions here
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Content
          if (isWide)
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  Expanded(
                    child: _panelCard(child: _buildDiscoveryTab(), title: "Network Discovery"),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: Column(
                children: [
                  _buildCanInterfaceSection(),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: TabBarView(controller: _tabController, children: [_buildDiscoveryTab(), _buildDirectTab()]),
                    ),
                  ),
                ],
              ),
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

  Widget _buildDiscoveryTab() {
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
                            widget.onEcuConnected(target);
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
