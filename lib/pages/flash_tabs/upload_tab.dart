import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/target.dart';
import '../../models/hardware_models.dart';
import '../../services/log_service.dart';
import '../../services/target_manager_service.dart';
import 'flash_tab_components.dart';
import 'erase_tab.dart' show CustomMemoryRange;

/// Upload tab for reading memory to HEX files
class UploadTab extends StatefulWidget {
  const UploadTab({super.key});

  @override
  State<UploadTab> createState() => _UploadTabState();
}

class _UploadTabState extends State<UploadTab> {
  final LogService _log = LogService();

  int? _uploadSelectedRegion;
  bool _uploadUseCustomRange = false;
  final TextEditingController _uploadStartController = TextEditingController(text: '0x00000000');
  final TextEditingController _uploadSizeController = TextEditingController(text: '0x1000');
  String? _uploadSaveFilePath;

  Target? get _activeTarget => TargetManager().activeTarget;

  List<MemoryRegion> get _memoryRegions {
    final hwType = _activeTarget?.profile?.hardwareType ?? '';
    return MemoryConfigurations.getByHardwareType(hwType)?.regions ?? [];
  }

  @override
  void dispose() {
    _uploadStartController.dispose();
    _uploadSizeController.dispose();
    super.dispose();
  }

  Future<void> _pickSaveLocation() async {
    final result = await FilePicker.platform.saveFile(dialogTitle: 'Save As', fileName: 'upload_output.hex', type: FileType.custom, allowedExtensions: ['hex']);
    if (result != null) {
      setState(() => _uploadSaveFilePath = result);
    }
  }

  void _performUpload() {
    if (_uploadUseCustomRange) {
      final start = CustomMemoryRange.parseHex(_uploadStartController.text);
      final size = CustomMemoryRange.parseHex(_uploadSizeController.text);
      if (start == null || size == null) {
        _log.error('Invalid custom range values');
        return;
      }
      _log.info('Uploading custom range to: $_uploadSaveFilePath (not implemented)');
    } else {
      _log.info('Uploading to: $_uploadSaveFilePath (not implemented)');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlashTabContainer(
      icon: Icons.upload,
      title: 'Upload (Read Memory)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select region to upload:', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: FlashRegionSelector(
                memoryRegions: _memoryRegions,
                selectedId: _uploadUseCustomRange ? -1 : _uploadSelectedRegion,
                onChanged: (id) => setState(() {
                  _uploadSelectedRegion = id;
                  _uploadUseCustomRange = false;
                }),
                showCustom: true,
                customSelected: _uploadUseCustomRange,
                onCustomSelected: () => setState(() {
                  _uploadUseCustomRange = true;
                  _uploadSelectedRegion = null;
                }),
                customStartController: _uploadStartController,
                customSizeController: _uploadSizeController,
              ),
            ),
          ),
          const SizedBox(height: 16),
          FlashFileSelector(label: 'Save to', value: _uploadSaveFilePath, onBrowse: _pickSaveLocation, isSave: true),
          const SizedBox(height: 16),
          FlashActionButton(
            label: 'Upload',
            icon: Icons.upload,
            onPressed: ((_uploadSelectedRegion != null || _uploadUseCustomRange) && _uploadSaveFilePath != null) ? _performUpload : null,
          ),
        ],
      ),
    );
  }
}
