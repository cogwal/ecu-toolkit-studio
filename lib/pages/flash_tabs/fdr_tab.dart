import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/target.dart';
import '../../services/log_service.dart';
import '../../services/target_manager_service.dart';
import '../../services/toolkit_service.dart';
import 'flash_tab_components.dart';

/// FDR Setup tab for loading flash driver routines
class FdrTab extends StatefulWidget {
  const FdrTab({super.key});

  @override
  State<FdrTab> createState() => FdrTabState();
}

class FdrTabState extends State<FdrTab> {
  final LogService _log = LogService();
  final ToolkitService _toolkit = ToolkitService();

  String? _fdrFilePath;

  Target? get _activeTarget => TargetManager().activeTarget;

  String get _hardwareType {
    return _activeTarget?.profile?.hardwareType ?? 'Unknown';
  }

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

  @override
  Widget build(BuildContext context) {
    return FlashTabContainer(
      icon: Icons.settings,
      title: 'Flash Driver (FDR)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FlashFileSelector(label: 'FDR File', value: _fdrFilePath, onBrowse: _pickHexFile),
          const SizedBox(height: 16),
          const FlashInfoBox(text: 'The flash driver must be loaded before any flash, erase, or upload operations.', icon: Icons.info_outline),
          const SizedBox(height: 16),
          Text('Recommended FDR files for $_hardwareType:', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text('• fdr_${_hardwareType.toLowerCase()}.hex', style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: FlashStatusIndicator(label: 'Status', value: _toolkit.isFdrLoaded ? 'Loaded' : 'Not loaded', isOk: _toolkit.isFdrLoaded),
              ),
            ],
          ),
          const Spacer(),
          FlashActionButton(label: 'Load Programming Routine', icon: Icons.upload_file, onPressed: _fdrFilePath != null ? _loadFdr : null),
        ],
      ),
    );
  }
}
