import 'package:flutter/material.dart';
import '../ecu_model.dart';

// --- DASHBOARD PAGE ---
class LiveDashboardPage extends StatelessWidget {
  final EcuProfile? profile;
  const LiveDashboardPage({super.key, this.profile});

  @override
  Widget build(BuildContext context) {
    if (profile == null) return const Center(child: Text("No Active Connection"));

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Context Header
          Row(
            children: [
              Text("Live Data Stream", style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              Chip(label: const Text("Sample Rate: 20ms"), backgroundColor: Colors.blue.withOpacity(0.2)),
            ],
          ),
          const SizedBox(height: 16),
          
          // Grid of Gauges
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              childAspectRatio: 1.6,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _buildMetricCard("Engine Speed", "850", "RPM", Colors.blue),
                _buildMetricCard("Coolant Temp", "92", "°C", Colors.green),
                _buildMetricCard("Intake Manifold", "0.34", "Bar", Colors.orange),
                _buildMetricCard("Mass Air Flow", "3.2", "g/s", Colors.purple),
                _buildMetricCard("Throttle Pos", "12.5", "%", Colors.teal),
                _buildMetricCard("Ignition Timing", "-4.0", "deg", Colors.red),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, String unit, Color color) {
    return Card(
      elevation: 2,
      child: Stack(
        children: [
          Positioned(
            right: -20, top: -20,
            child: Icon(Icons.speed, size: 100, color: color.withOpacity(0.05)),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label.toUpperCase(), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color, fontFamily: 'Courier')),
                    const SizedBox(width: 4),
                    Text(unit, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                LinearProgressIndicator(value: 0.4, color: color, backgroundColor: Colors.black26),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- DTC PAGE ---
class DtcPage extends StatelessWidget {
  final EcuProfile? profile;
  const DtcPage({super.key, this.profile});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text("Trouble Codes (${profile?.name ?? 'Unknown'})", style: Theme.of(context).textTheme.titleLarge),
               ElevatedButton.icon(
                 onPressed: (){}, 
                 icon: const Icon(Icons.delete), 
                 label: const Text("Clear All (0x14)"),
                 style: ElevatedButton.styleFrom(backgroundColor: Colors.red[900]),
               )
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                _buildDtcItem("P0300", "Random/Multiple Cylinder Misfire", "Active", Colors.red),
                _buildDtcItem("P0171", "System Too Lean (Bank 1)", "Pending", Colors.orange),
                _buildDtcItem("U0100", "Lost Comm with ECM/PCM A", "History", Colors.green),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDtcItem(String code, String desc, String status, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
          child: Text(code, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontFamily: 'Courier')),
        ),
        title: Text(desc),
        trailing: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 12)),
      ),
    );
  }
}

// --- FLASH PAGE ---
class FlashWizardPage extends StatelessWidget {
  final EcuProfile? profile;
  const FlashWizardPage({super.key, this.profile});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.memory, size: 48, color: Colors.blue),
            const SizedBox(height: 16),
            const Text("Firmware Update Wizard", style: TextStyle(fontSize: 22)),
            const SizedBox(height: 8),
            Text("Target: ${profile?.name ?? 'None'}", style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            _buildStepRow(1, "Select Firmware File", true),
            _buildStepRow(2, "Security Access (Seed/Key)", false),
            _buildStepRow(3, "Erase Memory", false),
            _buildStepRow(4, "Transfer Data", false),
            const SizedBox(height: 32),
            ElevatedButton(onPressed: () {}, child: const Text("LOAD FILE (.HEX)"))
          ],
        ),
      ),
    );
  }

  Widget _buildStepRow(int step, String title, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: isActive ? Colors.blue : Colors.grey[800],
            child: Text("$step", style: const TextStyle(fontSize: 12, color: Colors.white)),
          ),
          const SizedBox(width: 16),
          Text(title, style: TextStyle(color: isActive ? Colors.white : Colors.grey)),
        ],
      ),
    );
  }
}