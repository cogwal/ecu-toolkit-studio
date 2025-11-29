import 'package:flutter/material.dart';
import 'dart:async';
import '../ecu_model.dart';
import '../native/ecu_models.dart';

class ConnectionPage extends StatefulWidget {
  final Function(EcuProfile) onEcuConnected;

  const ConnectionPage({super.key, required this.onEcuConnected});

  @override
  State<ConnectionPage> createState() => _ConnectionPageState();
}

class _ConnectionPageState extends State<ConnectionPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isScanning = false;
  List<EcuProfile> _discoveredEcus = [];
  
  final TextEditingController _txIdController = TextEditingController(text: "7E0");
  final TextEditingController _rxIdController = TextEditingController(text: "7E8");

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _txIdController.dispose();
    _rxIdController.dispose();
    super.dispose();
  }

  void _startNetworkScan() {
    setState(() {
      _isScanning = true;
      _discoveredEcus.clear();
    });
    // Delegate mock data retrieval to native models (FFI) when available.
    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      try {
        final nativeList = getMockEcusFromNative();
        setState(() {
          _isScanning = false;
          _discoveredEcus = nativeList;
        });
      } catch (e) {
        // Fallback to existing inline mock if anything goes wrong
        setState(() {
          _isScanning = false;
          _discoveredEcus = [
            EcuProfile(name: "Engine Control Module", txId: 0x7E0, rxId: 0x7E8),
            EcuProfile(name: "Transmission Control", txId: 0x7E1, rxId: 0x7E9),
            EcuProfile(name: "ABS Control Module", txId: 0x7E2, rxId: 0x7EA),
          ];
        });
      }
    });
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

          // Wide layout: show two panels side-by-side. Narrow layout: keep tabs.
          if (isWide)
            SizedBox(
              height: 460,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _panelCard(child: _buildScannerTab(), title: "Network Discovery")),
                  const SizedBox(width: 16),
                  Expanded(child: _panelCard(child: _buildDirectTab(), title: "Direct Connect")),
                ],
              ),
            )
          else
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
                    height: 350, // Fixed height for the tab content area
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildScannerTab(),
                        _buildDirectTab(),
                      ],
                    ),
                  ),
                ],
              ),
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
          if (title != null) Padding(
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
            child: _discoveredEcus.isEmpty && !_isScanning
              ? const Center(child: Text("No ECUs found. Try again.", style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  itemCount: _discoveredEcus.length,
                  itemBuilder: (context, index) {
                    final ecu = _discoveredEcus[index];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(ecu.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("Tx: 0x${ecu.txId.toRadixString(16)} | Rx: 0x${ecu.rxId.toRadixString(16)}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, size: 14),
                        onPressed: () => widget.onEcuConnected(ecu),
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
            controller: _txIdController,
            decoration: const InputDecoration(labelText: "Request ID (Hex)", prefixText: "0x", border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _rxIdController,
            decoration: const InputDecoration(labelText: "Response ID (Hex)", prefixText: "0x", border: OutlineInputBorder()),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              onPressed: () {
                final tx = int.tryParse(_txIdController.text, radix: 16) ?? 0x7E0;
                final rx = int.tryParse(_rxIdController.text, radix: 16) ?? 0x7E8;
                widget.onEcuConnected(EcuProfile(name: "Manual ECU", txId: tx, rxId: rx));
              },
              child: const Text("Connect"),
            ),
          ),
        ],
      ),
    );
  }
}