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

  bool _isDownloading = false;

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
      _showErrorSnackBar('FDR must be loaded before downloading.');
      return;
    }

    // Validation: Security must be set
    if (!ToolkitService().isSecuritySet) {
      _showErrorSnackBar('Security keys must be set before downloading.');
      return;
    }

    setState(() => _isDownloading = true);

    try {
      _log.info('Starting download: ${ToolkitService().downloadFilePath}');
      final result = await ToolkitService().downloadHexFile(target.targetHandle, ToolkitService().downloadFilePath!);

      if (result == 0) {
        _log.info('Download completed successfully');
      } else {
        _log.error('Download failed with error code: $result');
      }
    } on OperationInProgressException catch (e) {
      _showErrorSnackBar('Cannot start download: ${e.operationName} is in progress.');
    } catch (e) {
      _log.error('Download failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
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
      icon: Icons.download,
      title: 'Download (Flash HEX)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FlashFileSelector(label: 'HEX File', value: ToolkitService().downloadFilePath, onBrowse: _pickHexFile),
          const SizedBox(height: 16),
          const FlashInfoBox(
            text: 'Select a HEX file to download to the target. The memory addresses are determined by the file contents.',
            icon: Icons.info_outline,
          ),
          const Spacer(),
          if (_isDownloading)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 12),
                    Text('Downloading...'),
                  ],
                ),
              ),
            ),
          FlashActionButton(
            label: _isDownloading ? 'Downloading...' : 'Download',
            icon: Icons.download,
            onPressed: (!_isDownloading && ToolkitService().downloadFilePath != null) ? _performDownload : null,
          ),
        ],
      ),
    );
  }
}
