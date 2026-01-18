import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/target.dart';
import '../../models/hardware_models.dart';
import '../../services/toolkit_service.dart';
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

  int? _uploadSelectedIndex;
  bool _uploadUseCustomRange = false;
  bool _isUploading = false;
  final TextEditingController _uploadStartController = TextEditingController(text: '0x00000000');
  final TextEditingController _uploadSizeController = TextEditingController(text: '0x1000');

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
    // Determine default file name based on selection
    String fileName = 'upload_output.bin';
    if (_uploadSelectedIndex != null && !_uploadUseCustomRange) {
      final region = _memoryRegions[_uploadSelectedIndex!];
      fileName = '${region.name.replaceAll(' ', '_')}.bin';
    }

    final result = await FilePicker.platform.saveFile(dialogTitle: 'Save As', fileName: fileName, type: FileType.custom, allowedExtensions: ['bin']);

    if (result != null) {
      setState(() => ToolkitService().setUploadSaveFilePath(result));
    }
  }

  Future<void> _performUpload() async {
    final target = _activeTarget;
    if (target == null) {
      _log.error('No active target connected');
      return;
    }

    // Validation: Check if save path is selected
    if (ToolkitService().uploadSaveFilePath == null) {
      if (mounted) showFlashErrorSnackBar(context, 'Please select a save location.');
      return;
    }

    // Validation: FDR must be loaded
    if (!ToolkitService().isFdrLoaded) {
      if (mounted) showFlashErrorSnackBar(context, 'FDR must be loaded before uploading.');
      return;
    }

    // Validation: Security must be set
    if (!ToolkitService().isSecuritySet) {
      if (mounted) showFlashErrorSnackBar(context, 'Security keys must be set before uploading.');
      return;
    }

    int startAddress;
    int size;
    int memId;

    if (_uploadUseCustomRange) {
      final start = CustomMemoryRange.parseHex(_uploadStartController.text);
      final sz = CustomMemoryRange.parseHex(_uploadSizeController.text);
      if (start == null || sz == null) {
        _log.error('Invalid custom range values');
        return;
      }
      startAddress = start;
      size = sz;
      memId = 0; // Default memId for custom range
    } else if (_uploadSelectedIndex != null) {
      final region = _memoryRegions[_uploadSelectedIndex!];
      startAddress = region.startAddress;
      size = region.size;
      memId = region.id;
    } else {
      return;
    }

    setState(() => _isUploading = true);

    try {
      _log.info('Reading memory: 0x${startAddress.toRadixString(16)} size 0x${size.toRadixString(16)} memId=$memId');
      _log.info('Saving to: ${ToolkitService().uploadSaveFilePath}');

      final result = await ToolkitService().readMemoryToFile(target.targetHandle, startAddress, size, memId, ToolkitService().uploadSaveFilePath!);

      if (result == 0) {
        _log.info('Upload completed successfully');
      } else {
        _log.error('Upload failed with error code: $result');
      }

      ToolkitService().disconnectAfterOperation(target);
    } on OperationInProgressException catch (e) {
      if (mounted) showFlashErrorSnackBar(context, 'Cannot start upload: ${e.operationName} is in progress.');
    } catch (e) {
      _log.error('Upload failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
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
                selectedIndex: _uploadUseCustomRange ? -1 : _uploadSelectedIndex,
                onChanged: (index) => setState(() {
                  _uploadSelectedIndex = index;
                  _uploadUseCustomRange = false;
                  // Clear save path when changing selection as filename might change
                  ToolkitService().setUploadSaveFilePath(null);
                }),
                showCustom: true,
                customSelected: _uploadUseCustomRange,
                onCustomSelected: () => setState(() {
                  _uploadUseCustomRange = true;
                  _uploadSelectedIndex = null;
                  // Clear save path when changing selection
                  ToolkitService().setUploadSaveFilePath(null);
                }),
                customStartController: _uploadStartController,
                customSizeController: _uploadSizeController,
              ),
            ),
          ),
          const SizedBox(height: 16),
          FlashFileSelector(label: 'Save to', value: ToolkitService().uploadSaveFilePath, onBrowse: _pickSaveLocation, isSave: true),
          const SizedBox(height: 16),
          if (_isUploading)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 12),
                    Text('Uploading (Reading)...'),
                  ],
                ),
              ),
            ),
          FlashActionButton(
            label: _isUploading ? 'Uploading...' : 'Upload',
            icon: Icons.upload,
            onPressed: (!_isUploading && (_uploadSelectedIndex != null || _uploadUseCustomRange) && ToolkitService().uploadSaveFilePath != null)
                ? _performUpload
                : null,
          ),
        ],
      ),
    );
  }
}
