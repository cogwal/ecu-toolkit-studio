import 'package:flutter/material.dart';
import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';
import '../../models/target.dart';
import '../../services/log_service.dart';
import '../../services/target_manager_service.dart';
import '../../native/ttctk.dart';
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

  @override
  void dispose() {
    _secretKey1Controller.dispose();
    _secretKey2Controller.dispose();
    super.dispose();
  }

  void _applySecuritySettings() {
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

    if (key1 != null) {
      if (!_setSecurityLevel(TK_TARGET_UDS_SECURITY_LEVEL_1, key1)) {
        success = false;
      }
    }

    if (key2 != null) {
      if (!_setSecurityLevel(TK_TARGET_UDS_SECURITY_LEVEL_2, key2)) {
        success = false;
      }
    }

    if (success) {
      _log.info('Security settings application completed.');
    } else {
      _log.warning('Security settings application completed with errors.');
    }
  }

  bool _setSecurityLevel(int level, List<int> key) {
    _log.info('Applying security level $level key...');

    final params = calloc<TkTargetSecurityParametersType>();
    final secretPtr = calloc<ffi.Uint32>(key.length);

    try {
      params.ref.type = TK_TARGET_CATEGORY_UDS_ON_CAN;

      // Populate secret buffer (32-bit integers)
      for (var i = 0; i < key.length; i++) {
        secretPtr[i] = key[i];
      }

      final uds = params.uds;
      // Enable setSecurityLevel and set the level
      uds.ref.setSecurityLevel = 1; // true
      uds.ref.securityLevel = level;

      // Enable setSecret and assign the pointer
      uds.ref.setSecret = 1; // true
      uds.ref.secret = secretPtr.cast<ffi.Uint8>();
      uds.ref.secretLength = key.length * 4; // Length in bytes, 32-bit words

      // log length
      _log.debug('Secret length: ${uds.ref.secretLength} bytes');
      // log secret uint8 array contents
      _log.debug('Secret contents: \n ${secretPtr.cast<ffi.Uint8>().asTypedList(key.length * 4).map((e) => e.toRadixString(16)).join(", ")}');

      // Explicitly disable optional fields
      uds.ref.setAlgorithm = 0; // false
      uds.ref.setSubfunctions = 0; // false

      // Log params memory layout
      _log.debug(formatStructLayout(params, ffi.sizeOf<TkTargetSecurityParametersType>(), 'Params memory layout'));

      final result = TTCTK.instance.setSecurityParameters(_activeTarget!.targetHandle, params);

      if (result != 0) {
        _log.error('Failed to set security level $level. Error code: $result');
        return false;
      } else {
        _log.info('Security level $level applied successfully.');
        return true;
      }
    } catch (e) {
      _log.error('Exception setting security level $level: $e');
      return false;
    } finally {
      calloc.free(params);
      calloc.free(secretPtr);
    }
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
