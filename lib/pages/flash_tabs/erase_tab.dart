import 'package:flutter/material.dart';
import '../../models/target.dart';
import '../../models/hardware_models.dart';
import '../../services/log_service.dart';
import '../../services/target_manager_service.dart';
import 'flash_tab_components.dart';

/// Erase tab for erasing memory regions
class EraseTab extends StatefulWidget {
  const EraseTab({super.key});

  @override
  State<EraseTab> createState() => _EraseTabState();
}

class _EraseTabState extends State<EraseTab> {
  final LogService _log = LogService();

  int? _eraseSelectedRegion;
  bool _eraseUseCustomRange = false;
  final TextEditingController _eraseStartController = TextEditingController(text: '0x00000000');
  final TextEditingController _eraseSizeController = TextEditingController(text: '0x1000');

  Target? get _activeTarget => TargetManager().activeTarget;

  List<MemoryRegion> get _memoryRegions {
    final hwType = _activeTarget?.profile?.hardwareType ?? '';
    return MemoryConfigurations.getByHardwareType(hwType)?.regions ?? [];
  }

  @override
  void dispose() {
    _eraseStartController.dispose();
    _eraseSizeController.dispose();
    super.dispose();
  }

  void _performErase() {
    if (_eraseUseCustomRange) {
      final start = CustomMemoryRange.parseHex(_eraseStartController.text);
      final size = CustomMemoryRange.parseHex(_eraseSizeController.text);
      if (start == null || size == null) {
        _log.error('Invalid custom range values');
        return;
      }
      _log.info('Erasing custom range: 0x${start.toRadixString(16)} size 0x${size.toRadixString(16)} (not implemented)');
    } else {
      _log.info('Erasing (not implemented)');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlashTabContainer(
      icon: Icons.delete_forever,
      title: 'Erase Memory',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select region to erase:', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: FlashRegionSelector(
                memoryRegions: _memoryRegions,
                selectedId: _eraseUseCustomRange ? -1 : _eraseSelectedRegion,
                onChanged: (id) => setState(() {
                  _eraseSelectedRegion = id;
                  _eraseUseCustomRange = false;
                }),
                showCustom: true,
                customSelected: _eraseUseCustomRange,
                onCustomSelected: () => setState(() {
                  _eraseUseCustomRange = true;
                  _eraseSelectedRegion = null;
                }),
                customStartController: _eraseStartController,
                customSizeController: _eraseSizeController,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const FlashWarningBox(text: 'Erasing is irreversible. Double-check your selection.'),
          const SizedBox(height: 16),
          FlashActionButton(
            label: 'Erase',
            icon: Icons.delete_forever,
            isDestructive: true,
            onPressed: (_eraseSelectedRegion != null || _eraseUseCustomRange) ? _performErase : null,
          ),
        ],
      ),
    );
  }
}

/// Custom memory range for erase/upload operations
class CustomMemoryRange {
  int startAddress;
  int size;

  CustomMemoryRange({this.startAddress = 0, this.size = 0x1000});

  /// Parse hex string to int, returns null if invalid
  static int? parseHex(String input) {
    try {
      String cleaned = input.trim();
      if (cleaned.startsWith('0x') || cleaned.startsWith('0X')) {
        return int.parse(cleaned.substring(2), radix: 16);
      }
      return int.parse(cleaned, radix: 16);
    } catch (e) {
      return null;
    }
  }
}
