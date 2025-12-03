import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';
import '../models/ecu_profile.dart';
import '../models/target_connection.dart';

import '../native/ttctk.dart';

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
    super.dispose();
  }

  void _startNetworkScan() async {
    if (_canHandle == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please register CAN interface first")));
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
    if (_canHandle == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please register CAN interface first")));
      return;
    }

    try {
      final addr = TkTargetAddress();
      addr.type = TK_TARGET_CATEGORY_UDS_ON_CAN;
      addr.udsOnCan.mType = TK_TARGET_UDS_MTYPE_DIAGNOSTICS;
      addr.udsOnCan.sa = sa;
      addr.udsOnCan.ta = ta;
      addr.udsOnCan.taType = TK_TARGET_UDS_TATYPE_PHYSICAL;
      addr.udsOnCan.ae = 0;
      addr.udsOnCan.isotpFormat = TK_TARGET_ISOTP_FORMAT_NORMAL;
      addr.udsOnCan.canHandle = _canHandle!;
      addr.udsOnCan.canFormat = TK_CAN_FRAME_FORMAT_BASE; // Assuming base frame format for now

      final (status, handle) = TTCTK.instance.addTarget(addr);

      if (status == 0) {
        // Connection successful (or at least target added)
        // In a real scenario, we might want to "ping" the target or read a DID to confirm it's actually there.
        // For discovery, we assume if addTarget succeeds, we keep it?
        // Actually addTarget just adds the configuration. It doesn't verify presence.
        // But for this task, "A target is added to the ttctk when ... all possible targets are added when doing a discover operation"
        // So we add them all.

        // Create a basic profile for display
        // Calculate CAN IDs for display (Physical Addressing)
        // txId = 0x7E0 + (ta - 1) ? No, see table.
        // ta=0x01 -> tx=0x7E0. ta=0x08 -> tx=0x7E7.
        // So txId = 0x7DF + ta? No. 0x7DF + 1 = 0x7E0. Correct.
        // rxId = 0x7E7 + ta? 0x7E7 + 1 = 0x7E8. Correct.

        final txId = 0x7DF + ta;
        final rxId = 0x7E7 + ta;

        final connection = TargetConnection(
          canHandle: _canHandle!,
          targetHandle: handle,
          sa: sa,
          ta: ta,
          profile: EcuProfile(name: "Target 0x${ta.toRadixString(16).toUpperCase().padLeft(2, '0')}", txId: txId, rxId: rxId),
        );

        setState(() {
          _discoveredTargets.add(connection);
        });

        if (!isDiscovery) {
          widget.onEcuConnected(connection.profile!);
        }
      } else {
        if (!isDiscovery) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to add target: $status")));
        }
      }
    } catch (e) {
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
      final canInterface = calloc<TkCanInterfaceType>();
      final handlePtr = calloc<ffi.Uint32>();

      try {
        // Configure PEAK interface with default values
        canInterface.ref.type = TK_CAN_INTERFACE_CATEGORY_PEAK;
        canInterface.ref.peak.channel = PCAN_USBBUS1;

        // Register the interface
        final status = TTCTK.instance.registerCanInterface(canInterface.cast(), TK_CAN_BITRATE_500K, handlePtr.cast());

        if (status == 0) {
          setState(() {
            _canHandle = handlePtr.value;
            _canStatus = "Registered (Handle: $_canHandle)";
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("CAN interface registered successfully"), backgroundColor: Colors.green));
          }
        } else {
          setState(() {
            _canStatus = "Registration failed (Status: $status)";
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to register CAN interface: $status")));
          }
        }
      } finally {
        calloc.free(canInterface);
        calloc.free(handlePtr);
      }
    } catch (e) {
      setState(() {
        _canStatus = "Error: $e";
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Exception: $e")));
      }
    }
  }

  void _deregisterCanInterface() {
    if (_canHandle == null) return;

    try {
      final status = TTCTK.instance.deRegisterCanInterface(_canHandle!);
      if (status == 0) {
        setState(() {
          _canHandle = null;
          _canStatus = "Not registered";
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("CAN interface deregistered"), backgroundColor: Colors.green));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to deregister: $status")));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Exception: $e")));
      }
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
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          TextField(
            controller: _saController,
            decoration: const InputDecoration(labelText: "Source Address (SA) (Hex)", prefixText: "0x", border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _taController,
            decoration: const InputDecoration(labelText: "Target Address (TA) (Hex)", prefixText: "0x", border: OutlineInputBorder()),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              onPressed: () {
                final sa = int.tryParse(_saController.text, radix: 16) ?? 0xF1;
                final ta = int.tryParse(_taController.text, radix: 16) ?? 0x08;
                _connectTarget(sa, ta);
              },
              child: const Text("Connect"),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: OutlinedButton.icon(onPressed: _connectMockTarget, icon: const Icon(Icons.bug_report), label: const Text("Connect Mock Target")),
          ),
        ],
      ),
    );
  }
}
