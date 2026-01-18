import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/log_service.dart';
import '../../services/toolkit_service.dart';
import '../../services/target_manager_service.dart';
import 'flash_tab_components.dart';

/// Download tab for flashing HEX files to target
class DownloadTab extends StatefulWidget {
  const DownloadTab({super.key});

  @override
  State<DownloadTab> createState() => _DownloadTabState();
}

class _DownloadTabState extends State<DownloadTab> {
  final LogService _log = LogService();

  Future<void> _pickHexFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['hex', 'HEX'], dialogTitle: 'Select HEX File');
    if (result != null && result.files.single.path != null) {
      setState(() => ToolkitService().setDownloadFilePath(result.files.single.path!));
    }
  }

  Future<void> _performDownload() async {
    final target = TargetManager().activeTarget;
    if (target == null) {
      _log.error('No active target connected');
      return;
    }

    if (ToolkitService().downloadFilePath == null) {
      _log.error('No HEX file selected');
      return;
    }

    // Validation: FDR must be loaded
    if (!ToolkitService().isFdrLoaded) {
      if (mounted) showFlashErrorSnackBar(context, 'FDR must be loaded before downloading.');
      return;
    }

    // Validation: Security must be set
    if (!ToolkitService().isSecuritySet) {
      if (mounted) showFlashErrorSnackBar(context, 'Security keys must be set before downloading.');
      return;
    }

    try {
      _log.info('Starting download: ${ToolkitService().downloadFilePath}');
      final result = await ToolkitService().downloadHexFile(target.targetHandle, ToolkitService().downloadFilePath!);

      if (result == 0) {
        _log.info('Download completed successfully');
      } else {
        _log.error('Download failed with error code: $result');
      }

      ToolkitService().disconnectAfterOperation(target);
    } on OperationInProgressException catch (e) {
      if (mounted) showFlashErrorSnackBar(context, 'Cannot start download: ${e.operationName} is in progress.');
    } catch (e) {
      _log.error('Download failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlashTabContainer(
      icon: Icons.download,
      title: 'Download (Flash HEX)',
      child: ListenableBuilder(
        listenable: ToolkitService(),
        builder: (context, _) {
          final isOperationPending = ToolkitService().isOperationPending;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FlashFileSelector(label: 'HEX File', value: ToolkitService().downloadFilePath, onBrowse: _pickHexFile),
              const SizedBox(height: 16),
              const FlashInfoBox(
                text: 'Select a HEX file to download to the target. The memory addresses are determined by the file contents.',
                icon: Icons.info_outline,
              ),
              const Spacer(),
              FlashActionButton(
                label: isOperationPending ? '${ToolkitService().activeOperationName}...' : 'Download',
                icon: Icons.download,
                onPressed: (!isOperationPending && ToolkitService().downloadFilePath != null) ? _performDownload : null,
              ),
            ],
          );
        },
      ),
    );
  }
}
