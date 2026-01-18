import 'package:flutter/material.dart';
import '../../models/target.dart';
import '../../models/hardware_models.dart';
import '../../services/log_service.dart';
import '../../services/toolkit_service.dart';
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

  int? _eraseSelectedIndex;
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

  Future<void> _performErase() async {
    final target = _activeTarget;
    if (target == null) {
      _log.error('No active target connected');
      return;
    }

    // Validation: FDR must be loaded
    if (!ToolkitService().isFdrLoaded) {
      if (mounted) showFlashErrorSnackBar(context, 'FDR must be loaded before erasing.');
      return;
    }

    // Validation: Security must be set
    if (!ToolkitService().isSecuritySet) {
      if (mounted) showFlashErrorSnackBar(context, 'Security keys must be set before erasing.');
      return;
    }

    int startAddress;
    int size;
    int memId;

    if (_eraseUseCustomRange) {
      final start = CustomMemoryRange.parseHex(_eraseStartController.text);
      final sz = CustomMemoryRange.parseHex(_eraseSizeController.text);
      if (start == null || sz == null) {
        _log.error('Invalid custom range values');
        return;
      }
      startAddress = start;
      size = sz;
      memId = 0; // Default memId for custom range
    } else if (_eraseSelectedIndex != null) {
      final region = _memoryRegions[_eraseSelectedIndex!];
      startAddress = region.startAddress;
      size = region.size;
      memId = region.id;
    } else {
      return;
    }

    try {
      _log.info('Erasing memory: 0x${startAddress.toRadixString(16)} size 0x${size.toRadixString(16)} memId=$memId');
      final result = await ToolkitService().eraseMemoryRange(target.targetHandle, startAddress, size, memId);

      if (result == 0) {
        _log.info('Erase completed successfully');
      } else {
        _log.error('Erase failed with error code: $result');
      }

      ToolkitService().disconnectAfterOperation(target);
    } on OperationInProgressException catch (e) {
      if (mounted) showFlashErrorSnackBar(context, 'Cannot start erase: ${e.operationName} is in progress.');
    } catch (e) {
      _log.error('Erase failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlashTabContainer(
      icon: Icons.delete_forever,
      title: 'Erase Memory',
      child: ListenableBuilder(
        listenable: ToolkitService(),
        builder: (context, _) {
          final isOperationPending = ToolkitService().isOperationPending;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select region to erase:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: FlashRegionSelector(
                    memoryRegions: _memoryRegions,
                    selectedIndex: _eraseUseCustomRange ? -1 : _eraseSelectedIndex,
                    onChanged: (index) => setState(() {
                      _eraseSelectedIndex = index;
                      _eraseUseCustomRange = false;
                    }),
                    showCustom: true,
                    customSelected: _eraseUseCustomRange,
                    onCustomSelected: () => setState(() {
                      _eraseUseCustomRange = true;
                      _eraseSelectedIndex = null;
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
                label: isOperationPending ? '${ToolkitService().activeOperationName}...' : 'Erase',
                icon: Icons.delete_forever,
                isDestructive: true,
                onPressed: (!isOperationPending && (_eraseSelectedIndex != null || _eraseUseCustomRange)) ? _performErase : null,
              ),
            ],
          );
        },
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
