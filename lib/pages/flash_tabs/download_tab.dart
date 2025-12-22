import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/log_service.dart';
import 'flash_tab_components.dart';

/// Download tab for flashing HEX files to target
class DownloadTab extends StatefulWidget {
  const DownloadTab({super.key});

  @override
  State<DownloadTab> createState() => _DownloadTabState();
}

class _DownloadTabState extends State<DownloadTab> {
  final LogService _log = LogService();

  String? _downloadFilePath;

  Future<void> _pickHexFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['hex', 'HEX'], dialogTitle: 'Select HEX File');
    if (result != null && result.files.single.path != null) {
      setState(() => _downloadFilePath = result.files.single.path!);
    }
  }

  void _performDownload() {
    _log.info('Downloading: $_downloadFilePath (not implemented)');
  }

  @override
  Widget build(BuildContext context) {
    return FlashTabContainer(
      icon: Icons.download,
      title: 'Download (Flash HEX)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FlashFileSelector(label: 'HEX File', value: _downloadFilePath, onBrowse: _pickHexFile),
          const SizedBox(height: 16),
          const FlashInfoBox(
            text: 'Select a HEX file to download to the target. The memory addresses are determined by the file contents.',
            icon: Icons.info_outline,
          ),
          const Spacer(),
          FlashActionButton(label: 'Download', icon: Icons.download, onPressed: _downloadFilePath != null ? _performDownload : null),
        ],
      ),
    );
  }
}
