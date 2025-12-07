import 'package:flutter/material.dart';
import '../models/target.dart';

// --- FLASH PAGE ---
class FlashWizardPage extends StatelessWidget {
  final Target? target;
  const FlashWizardPage({super.key, this.target});

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
            const Icon(Icons.flash_on, size: 48, color: Colors.blue),
            const SizedBox(height: 16),
            const Text("Firmware Update Wizard", style: TextStyle(fontSize: 22)),
            const SizedBox(height: 8),
            Text("Target: ${target?.profile?.name ?? 'None'}", style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            _buildStepRow(1, "Select Firmware File", true),
            _buildStepRow(2, "Security Access (Seed/Key)", false),
            _buildStepRow(3, "Erase Memory", false),
            _buildStepRow(4, "Transfer Data", false),
            const SizedBox(height: 32),
            ElevatedButton(onPressed: () {}, child: const Text("LOAD FILE (.HEX)")),
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
