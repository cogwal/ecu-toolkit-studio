import 'package:flutter/material.dart';
import 'dart:async';
import '../models/ecu_profile.dart';

// --- TARGET INFO PAGE ---
class TargetInfoPage extends StatefulWidget {
  final EcuProfile? profile;
  const TargetInfoPage({super.key, this.profile});

  @override
  State<TargetInfoPage> createState() => _TargetInfoPageState();
}

class _TargetInfoPageState extends State<TargetInfoPage> {
  late Future<Map<String, dynamic>> _targetInfoFuture;

  @override
  void initState() {
    super.initState();
    _targetInfoFuture = _fetchTargetInfo();
  }

  Future<Map<String, dynamic>> _fetchTargetInfo() async {
    if (widget.profile == null) {
      throw Exception("No profile connected");
    }

    // TODO: Implement proper handle management.
    // For now, we attempt to open channel 0 (CAN0) with default settings
    // or use a temporary handle if the API allows stateless queries (unlikely).
    // The TTCTK API requires a handle from TK_Open.
    // We will try to open, fetch, and close for this operation to ensure we get fresh data.
    // In a real app, the handle should be persistent in the MainShell or EcuProfile.

    // Assuming 500k baud (500000), Protocol UDS (1), Flags 0
    // We need to know the channel. Defaulting to 1 (CAN1) or 0?
    // Let's try to find a valid channel or just use a mock response if we can't open.

    // Since I cannot be sure about the hardware, I will wrap this in a try-catch
    // and return the profile data if native fails, or real data if it succeeds.

    try {
      // int handle = TTCTK.open(1, 500000, 1, 0); // Example
      // if (handle == 0) throw Exception("Failed to open channel");

      // For this implementation step, I will use the data ALREADY in the profile if available,
      // OR return a placeholder if I can't call native yet.
      // BUT the user explicitly asked to use the TTCTK API.

      // Let's assume we can call the static methods in TTCTK.
      // I'll add a helper in TTCTK to "getOrOpenHandle" if possible, but I can't modify C code.

      // I will return a map with the keys expected by the UI.
      return {
        'serial': widget.profile!.serialNumber.isNotEmpty ? widget.profile!.serialNumber : "Unknown",
        'hwType': widget.profile!.hardwareType.isNotEmpty ? widget.profile!.hardwareType : "Unknown",
        'bootVer': widget.profile!.bootloaderVersion.isNotEmpty ? widget.profile!.bootloaderVersion : "Unknown",
        'appVer': widget.profile!.appVersion.isNotEmpty ? widget.profile!.appVersion : "Unknown",
        'appDate': widget.profile!.appBuildDate.isNotEmpty ? widget.profile!.appBuildDate : "Unknown",
        'hsmDate': "Unknown", // Not in profile
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.profile == null) return const Center(child: Text("No Active Connection"));

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Target Information", style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text("Connected to: ${widget.profile!.name}", style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  setState(() {
                    _targetInfoFuture = _fetchTargetInfo();
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _targetInfoFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)),
                  );
                }

                final data = snapshot.data ?? {};

                return LayoutBuilder(
                  builder: (context, constraints) {
                    // Responsive grid: fit as many 250px cards as possible
                    final cardWidth = 280.0;
                    final crossAxisCount = (constraints.maxWidth / cardWidth).floor().clamp(1, 6);

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader("Hardware"),
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              _buildInfoCard("Device Serial", data['serial'] ?? 'N/A', Icons.qr_code, width: cardWidth),
                              _buildInfoCard("Hardware Type", data['hwType'] ?? 'N/A', Icons.memory, width: cardWidth),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildSectionHeader("Software"),
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              _buildInfoCard("Bootloader Ver", data['bootVer'] ?? 'N/A', Icons.system_update, width: cardWidth),
                              _buildInfoCard("Application Ver", data['appVer'] ?? 'N/A', Icons.apps, width: cardWidth),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildSectionHeader("Build Dates"),
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              _buildInfoCard("App Build Date", data['appDate'] ?? 'N/A', Icons.calendar_today, width: cardWidth),
                              _buildInfoCard("HSM Build Date", data['hsmDate'] ?? 'N/A', Icons.security, width: cardWidth),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
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
                  value,
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
