import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/target.dart';
import '../../services/log_service.dart';
import '../../services/target_manager_service.dart';
import '../../native/ttctk.dart';
import '../../services/toolkit_service.dart';
import 'flash_tab_components.dart';

/// Combined Setup tab for FDR loading and Security configuration
class SetupTab extends StatefulWidget {
  const SetupTab({super.key});

  @override
  State<SetupTab> createState() => _SetupTabState();
}

class _SetupTabState extends State<SetupTab> {
  final LogService _log = LogService();
  final ToolkitService _toolkit = ToolkitService();

  // FDR State
  String? _fdrFilePath;

  // Security State
  final TextEditingController _secretKey1Controller = TextEditingController(text: '0x84EE5D28, 0xE75DE7CF, 0x118D5080, 0x28D3CAE2');
  final TextEditingController _secretKey2Controller = TextEditingController(text: '0xF94C35E9, 0x03BA9691, 0x3D4DF7DA, 0x63213EAA');

  Target? get _activeTarget => TargetManager().activeTarget;

  String get _hardwareType {
    return _activeTarget?.profile?.hardwareType ?? 'Unknown';
  }

  @override
  void dispose() {
    _secretKey1Controller.dispose();
    _secretKey2Controller.dispose();
    super.dispose();
  }

  // --- FDR Methods ---

  Future<void> _pickHexFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['hex', 'HEX'], dialogTitle: 'Select HEX File');
    if (result != null && result.files.single.path != null) {
      setState(() => _fdrFilePath = result.files.single.path!);
    }
  }

  Future<void> _loadFdr() async {
    if (_activeTarget == null) {
      _log.error('No active target');
      return;
    }
    if (_fdrFilePath == null) {
      _log.error('No FDR file selected');
      return;
    }

    try {
      await _toolkit.loadFdr(_activeTarget!.targetHandle, _fdrFilePath!);
    } on OperationInProgressException catch (e) {
      if (mounted) showFlashErrorSnackBar(context, 'Cannot load FDR: ${e.operationName} is in progress.');
    } catch (e) {
      _log.error('Failed to load FDR: $e');
    }
    // Trigger rebuild to update status indicator
    if (mounted) setState(() {});
  }

  // --- Security Methods ---

  Future<void> _applySecuritySettings() async {
    final key1 = SecurityConfig.parseSecretKey(_secretKey1Controller.text);
    final key2 = SecurityConfig.parseSecretKey(_secretKey2Controller.text);

    if (_secretKey1Controller.text.isNotEmpty && key1 == null) {
      _log.error('Invalid format for Security Level 1 key');
      return;
    }
    if (_secretKey2Controller.text.isNotEmpty && key2 == null) {
      _log.error('Invalid format for Security Level 2 key');
      return;
    }

    if (_activeTarget == null) {
      _log.error('No active target connected');
      return;
    }

    bool success = true;

    try {
      if (key1 != null) {
        final res = await _toolkit.setSecurityParameters(_activeTarget!.targetHandle, TK_TARGET_UDS_SECURITY_LEVEL_1, key1);
        if (res != 0) success = false;
      }

      if (key2 != null) {
        final res = await _toolkit.setSecurityParameters(_activeTarget!.targetHandle, TK_TARGET_UDS_SECURITY_LEVEL_2, key2);
        if (res != 0) success = false;
      }
    } on OperationInProgressException catch (e) {
      if (mounted) showFlashErrorSnackBar(context, 'Cannot set security: ${e.operationName} is in progress.');
      return;
    } catch (e) {
      _log.error('Failed to set security: $e');
      return;
    }

    if (success) {
      _log.info('Security settings application completed.');
    } else {
      _log.warning('Security settings application completed with errors.');
    }

    // Trigger rebuild to update any UI states if necessary
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FlashTabContainer(
      icon: Icons.settings,
      title: 'Setup & Configuration',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- FDR Section ---
          const _SectionHeader(title: 'Flash Driver (FDR)', icon: Icons.memory),
          const SizedBox(height: 16),
          FlashFileSelector(label: 'FDR File', value: _fdrFilePath, onBrowse: _pickHexFile),
          const SizedBox(height: 12),
          const FlashInfoBox(text: 'The flash driver must be loaded before any download, erase, or upload operations.', icon: Icons.info_outline),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FlashStatusIndicator(label: 'Status', value: _toolkit.isFdrLoaded ? 'Loaded' : 'Not loaded', isOk: _toolkit.isFdrLoaded),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _fdrFilePath != null ? _loadFdr : null,
                icon: const Icon(Icons.upload_file, size: 16),
                label: const Text('Load FDR'),
                style: ElevatedButton.styleFrom(visualDensity: VisualDensity.compact, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
              ),
            ],
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 24),

          // --- Security Section ---
          const _SectionHeader(title: 'Security Access', icon: Icons.lock),
          const SizedBox(height: 16),
          _buildSecretKeyField(label: 'Security Level 1', controller: _secretKey1Controller, hint: '0x84EE5D28, 0xE75DE7CF, ...'),
          const SizedBox(height: 12),
          _buildSecretKeyField(label: 'Security Level 2', controller: _secretKey2Controller, hint: '0x84EE5D28, 0xE75DE7CF, ...'),
          const SizedBox(height: 12),
          const FlashInfoBox(text: 'Security keys are required for privileged flash operations.', icon: Icons.shield),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FlashStatusIndicator(label: 'Security Status', value: _toolkit.isSecuritySet ? 'Keys Set' : 'Not Set', isOk: _toolkit.isSecuritySet),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _applySecuritySettings,
                icon: const Icon(Icons.lock_open, size: 16),
                label: const Text('Apply Keys'),
                style: ElevatedButton.styleFrom(visualDensity: VisualDensity.compact, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
              ),
            ],
          ),

          const SizedBox(height: 32), // Bottom padding
        ],
      ),
    );
  }

  Widget _buildSecretKeyField({required String label, required TextEditingController controller, required String hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            prefixIcon: const Icon(Icons.key, size: 18),
          ),
          style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

/// Helper class reused from SecurityTab logic
class SecurityConfig {
  /// Parse secret key from format like: { 0x84EE5D28, 0xE75DE7CF, 0x118D5080, 0x28D3CAE2 }
  /// or comma-separated hex values: 0x84EE5D28, 0xE75DE7CF, 0x118D5080, 0x28D3CAE2
  static List<int>? parseSecretKey(String input) {
    try {
      // Remove curly braces and whitespace
      String cleaned = input.replaceAll(RegExp(r'[{}\s]'), '');
      if (cleaned.isEmpty) return null;

      // Split by comma and parse each value
      final parts = cleaned.split(',').where((s) => s.isNotEmpty).toList();
      final result = <int>[];

      for (final part in parts) {
        final trimmed = part.trim();
        if (trimmed.startsWith('0x') || trimmed.startsWith('0X')) {
          result.add(int.parse(trimmed.substring(2), radix: 16));
        } else {
          result.add(int.parse(trimmed, radix: 16));
        }
      }

      return result.isEmpty ? null : result;
    } catch (e) {
      return null;
    }
  }
}
