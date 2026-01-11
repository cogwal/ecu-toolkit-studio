import 'package:flutter/material.dart';
import '../../models/target.dart';
import '../../services/log_service.dart';
import '../../services/target_manager_service.dart';
import '../../native/ttctk.dart';
import '../../services/toolkit_service.dart';
import 'flash_tab_components.dart';

/// Security Access tab for configuring security keys
class SecurityTab extends StatefulWidget {
  const SecurityTab({super.key});

  @override
  State<SecurityTab> createState() => _SecurityTabState();
}

class _SecurityTabState extends State<SecurityTab> {
  final LogService _log = LogService();

  final TextEditingController _secretKey1Controller = TextEditingController(text: '0x84EE5D28, 0xE75DE7CF, 0x118D5080, 0x28D3CAE2');
  final TextEditingController _secretKey2Controller = TextEditingController(text: '0xF94C35E9, 0x03BA9691, 0x3D4DF7DA, 0x63213EAA');

  Target? get _activeTarget => TargetManager().activeTarget;

  final ToolkitService _toolkit = ToolkitService();

  @override
  void dispose() {
    _secretKey1Controller.dispose();
    _secretKey2Controller.dispose();
    super.dispose();
  }

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
      _showErrorSnackBar('Cannot set security: ${e.operationName} is in progress.');
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

  void _showErrorSnackBar(String message) {
    _log.warning(message);
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FlashTabContainer(
      icon: Icons.lock,
      title: 'Security Access',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FlashInfoBox(
            text: 'Security keys are required for privileged flash operations. Enter keys in format:\n0x84EE5D28, 0xE75DE7CF, 0x118D5080, 0x28D3CAE2',
            icon: Icons.info_outline,
          ),
          const SizedBox(height: 24),
          _buildSecretKeyField(label: 'Security Level 1', controller: _secretKey1Controller, hint: '0x84EE5D28, 0xE75DE7CF, ...'),
          const SizedBox(height: 16),
          _buildSecretKeyField(label: 'Security Level 2', controller: _secretKey2Controller, hint: '0x84EE5D28, 0xE75DE7CF, ...'),
          const Spacer(),
          FlashActionButton(label: 'Apply Security Settings', icon: Icons.lock_open, onPressed: _applySecuritySettings),
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

/// Security configuration for a security level
class SecurityConfig {
  final int level;
  final List<int> secretKey;

  SecurityConfig({required this.level, required this.secretKey});

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
