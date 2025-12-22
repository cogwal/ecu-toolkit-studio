import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/target.dart';
import '../../services/log_service.dart';
import '../../services/target_manager_service.dart';
import '../../native/ttctk.dart';
import 'flash_tab_components.dart';

/// FDR Setup tab for loading flash driver routines
class FdrTab extends StatefulWidget {
  const FdrTab({super.key});

  @override
  State<FdrTab> createState() => _FdrTabState();
}

class _FdrTabState extends State<FdrTab> {
  final LogService _log = LogService();

  String? _fdrFilePath;
  bool _fdrLoaded = false;

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

  void _loadFdr() {
    if (_activeTarget == null) {
      _log.error('No active target');
      return;
    }
    if (_fdrFilePath == null) {
      _log.error('No FDR file selected');
      return;
    }

    _log.info('Loading FDR from: $_fdrFilePath');

    final result = TTCTK.instance.setProgrammingRoutines(_activeTarget!.targetHandle, _fdrFilePath!);

    if (result == 0) {
      _log.info('FDR loaded successfully');
      setState(() => _fdrLoaded = true);
    } else {
      _log.error('Failed to load FDR. Error code: $result');
      setState(() => _fdrLoaded = false);
    }
  }

  /// Returns whether FDR is loaded (for parent widget status display)
  bool get isFdrLoaded => _fdrLoaded;

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
                child: FlashStatusIndicator(label: 'Status', value: _fdrLoaded ? 'Loaded' : 'Not loaded', isOk: _fdrLoaded),
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
