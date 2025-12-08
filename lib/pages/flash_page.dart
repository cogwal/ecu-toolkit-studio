import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/target.dart';
import '../models/flash_models.dart';
import '../services/log_service.dart';

/// Flash operations page with tabbed interface
class FlashWizardPage extends StatefulWidget {
  final Target? target;
  const FlashWizardPage({super.key, this.target});

  @override
  State<FlashWizardPage> createState() => _FlashWizardPageState();
}

class _FlashWizardPageState extends State<FlashWizardPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final LogService _log = LogService();

  // FDR Setup state
  String? _fdrFilePath;
  bool _fdrLoaded = false;

  // Security state
  final TextEditingController _secretKey1Controller = TextEditingController();
  final TextEditingController _secretKey2Controller = TextEditingController();

  // Bootloader state
  String? _bootloaderFilePath;

  // Download state
  String? _downloadFilePath;

  // Erase state
  int? _eraseSelectedRegion;
  bool _eraseUseCustomRange = false;
  final TextEditingController _eraseStartController = TextEditingController(text: '0x00000000');
  final TextEditingController _eraseSizeController = TextEditingController(text: '0x1000');

  // Upload state
  int? _uploadSelectedRegion;
  bool _uploadUseCustomRange = false;
  final TextEditingController _uploadStartController = TextEditingController(text: '0x00000000');
  final TextEditingController _uploadSizeController = TextEditingController(text: '0x1000');
  String? _uploadSaveFilePath;

  // Get memory regions for connected hardware
  List<MemoryRegion> get _memoryRegions {
    final hwType = widget.target?.profile?.hardwareType;
    return MemoryConfigurations.getForHardware(hwType).regions;
  }

  String get _hardwareType {
    return widget.target?.profile?.hardwareType ?? 'Unknown';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _secretKey1Controller.dispose();
    _secretKey2Controller.dispose();
    _eraseStartController.dispose();
    _eraseSizeController.dispose();
    _uploadStartController.dispose();
    _uploadSizeController.dispose();
    super.dispose();
  }

  Future<void> _pickHexFile(void Function(String) onPicked) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['hex', 'HEX'], dialogTitle: 'Select HEX File');
    if (result != null && result.files.single.path != null) {
      onPicked(result.files.single.path!);
    }
  }

  Future<void> _pickSaveLocation(void Function(String) onPicked) async {
    final result = await FilePicker.platform.saveFile(dialogTitle: 'Save As', fileName: 'upload_output.hex', type: FileType.custom, allowedExtensions: ['hex']);
    if (result != null) {
      onPicked(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.target == null) {
      return const Center(child: Text('No target connected'));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Flash Operations', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text('Hardware: $_hardwareType', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                ],
              ),
              const Spacer(),
              if (_fdrLoaded)
                Chip(
                  avatar: const Icon(Icons.check_circle, color: Colors.green, size: 18),
                  label: const Text('FDR Loaded'),
                  backgroundColor: Colors.green.withOpacity(0.1),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Tab bar
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'FDR Setup', icon: Icon(Icons.settings, size: 18)),
                Tab(text: 'Security', icon: Icon(Icons.lock, size: 18)),
                Tab(text: 'Bootloader', icon: Icon(Icons.system_update, size: 18)),
                Tab(text: 'Download', icon: Icon(Icons.download, size: 18)),
                Tab(text: 'Erase', icon: Icon(Icons.delete_forever, size: 18)),
                Tab(text: 'Upload', icon: Icon(Icons.upload, size: 18)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildFdrTab(), _buildSecurityTab(), _buildBootloaderTab(), _buildDownloadTab(), _buildEraseTab(), _buildUploadTab()],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TAB 1: FDR Setup
  // ============================================================
  Widget _buildFdrTab() {
    return _buildTabContainer(
      icon: Icons.settings,
      title: 'Flash Driver (FDR)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFileSelector(label: 'FDR File', value: _fdrFilePath, onBrowse: () => _pickHexFile((path) => setState(() => _fdrFilePath = path))),
          const SizedBox(height: 16),
          _buildInfoBox('The flash driver must be loaded before any flash, erase, or upload operations.', icon: Icons.info_outline),
          const SizedBox(height: 16),
          Text('Recommended FDR files for $_hardwareType:', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text('• fdr_${_hardwareType.toLowerCase()}.hex', style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildStatusIndicator(label: 'Status', value: _fdrLoaded ? 'Loaded' : 'Not loaded', isOk: _fdrLoaded),
              ),
            ],
          ),
          const Spacer(),
          _buildActionButton(label: 'Load Programming Routine', icon: Icons.upload_file, onPressed: _fdrFilePath != null ? _loadFdr : null),
        ],
      ),
    );
  }

  void _loadFdr() {
    _log.info('Loading FDR from: $_fdrFilePath (not implemented)');
    setState(() => _fdrLoaded = true);
  }

  // ============================================================
  // TAB 2: Security Access
  // ============================================================
  Widget _buildSecurityTab() {
    return _buildTabContainer(
      icon: Icons.lock,
      title: 'Security Access',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoBox(
            'Security keys are required for privileged flash operations. Enter keys in format:\n{ 0x84EE5D28, 0xE75DE7CF, 0x118D5080, 0x28D3CAE2 }',
            icon: Icons.info_outline,
          ),
          const SizedBox(height: 24),
          _buildSecretKeyField(label: 'Security Level 1', controller: _secretKey1Controller, hint: '{ 0x84EE5D28, 0xE75DE7CF, ... }'),
          const SizedBox(height: 16),
          _buildSecretKeyField(label: 'Security Level 2', controller: _secretKey2Controller, hint: '{ 0x84EE5D28, 0xE75DE7CF, ... }'),
          const Spacer(),
          _buildActionButton(label: 'Apply Security Settings', icon: Icons.lock_open, onPressed: _applySecuritySettings),
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

    _log.info('Security settings applied (not implemented)');
    if (key1 != null) _log.debug('Level 1: ${key1.length} words');
    if (key2 != null) _log.debug('Level 2: ${key2.length} words');
  }

  // ============================================================
  // TAB 3: Bootloader
  // ============================================================
  Widget _buildBootloaderTab() {
    return _buildTabContainer(
      icon: Icons.system_update,
      title: 'Flash Bootloader',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFileSelector(
            label: 'Bootloader File',
            value: _bootloaderFilePath,
            onBrowse: () => _pickHexFile((path) => setState(() => _bootloaderFilePath = path)),
          ),
          const SizedBox(height: 16),
          _buildWarningBox('Flashing the bootloader is a critical operation. Ensure the correct file is selected and power is stable.'),
          const Spacer(),
          _buildActionButton(
            label: 'Flash Bootloader',
            icon: Icons.flash_on,
            isDestructive: true,
            onPressed: _bootloaderFilePath != null ? _flashBootloader : null,
          ),
        ],
      ),
    );
  }

  void _flashBootloader() {
    _log.info('Flashing bootloader from: $_bootloaderFilePath (not implemented)');
  }

  // ============================================================
  // TAB 4: Download (Flash HEX)
  // ============================================================
  Widget _buildDownloadTab() {
    return _buildTabContainer(
      icon: Icons.download,
      title: 'Download (Flash HEX)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFileSelector(label: 'HEX File', value: _downloadFilePath, onBrowse: () => _pickHexFile((path) => setState(() => _downloadFilePath = path))),
          const SizedBox(height: 16),
          _buildInfoBox('Select a HEX file to download to the target. The memory addresses are determined by the file contents.', icon: Icons.info_outline),
          const Spacer(),
          _buildActionButton(label: 'Download', icon: Icons.download, onPressed: _downloadFilePath != null ? _performDownload : null),
        ],
      ),
    );
  }

  void _performDownload() {
    _log.info('Downloading: $_downloadFilePath (not implemented)');
  }

  // ============================================================
  // TAB 5: Erase
  // ============================================================
  Widget _buildEraseTab() {
    return _buildTabContainer(
      icon: Icons.delete_forever,
      title: 'Erase Memory',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select region to erase:', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: _buildRegionSelector(
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
          _buildWarningBox('Erasing is irreversible. Double-check your selection.'),
          const SizedBox(height: 16),
          _buildActionButton(
            label: 'Erase',
            icon: Icons.delete_forever,
            isDestructive: true,
            onPressed: (_eraseSelectedRegion != null || _eraseUseCustomRange) ? _performErase : null,
          ),
        ],
      ),
    );
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
      final region = _memoryRegions.firstWhere((r) => r.id == _eraseSelectedRegion);
      _log.info('Erasing ${region.name} (not implemented)');
    }
  }

  // ============================================================
  // TAB 6: Upload (Read)
  // ============================================================
  Widget _buildUploadTab() {
    return _buildTabContainer(
      icon: Icons.upload,
      title: 'Upload (Read Memory)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select region to upload:', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: _buildRegionSelector(
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
          _buildFileSelector(
            label: 'Save to',
            value: _uploadSaveFilePath,
            onBrowse: () => _pickSaveLocation((path) => setState(() => _uploadSaveFilePath = path)),
            isSave: true,
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            label: 'Upload',
            icon: Icons.upload,
            onPressed: ((_uploadSelectedRegion != null || _uploadUseCustomRange) && _uploadSaveFilePath != null) ? _performUpload : null,
          ),
        ],
      ),
    );
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
      final region = _memoryRegions.firstWhere((r) => r.id == _uploadSelectedRegion);
      _log.info('Uploading ${region.name} to: $_uploadSaveFilePath (not implemented)');
    }
  }

  // ============================================================
  // Reusable UI Components
  // ============================================================

  Widget _buildTabContainer({required IconData icon, required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 24, color: Colors.blue),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 24),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildFileSelector({required String label, required String? value, required VoidCallback onBrowse, bool isSave = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(8),
                  color: Theme.of(context).scaffoldBackgroundColor,
                ),
                child: Text(
                  value ?? (isSave ? 'Select save location...' : 'Select file...'),
                  style: TextStyle(color: value != null ? null : Colors.grey, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(onPressed: onBrowse, icon: Icon(isSave ? Icons.save : Icons.folder_open, size: 18), label: const Text('Browse')),
          ],
        ),
      ],
    );
  }

  Widget _buildRegionSelector({
    required int? selectedId,
    required void Function(int) onChanged,
    required bool showCustom,
    bool customSelected = false,
    VoidCallback? onCustomSelected,
    TextEditingController? customStartController,
    TextEditingController? customSizeController,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._memoryRegions.map(
            (region) => RadioListTile<int>(
              value: region.id,
              groupValue: selectedId,
              onChanged: (v) => onChanged(v!),
              title: Text(region.name),
              subtitle: Text(
                '${region.startAddressHex}, ${region.sizeFormatted}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontFamily: 'monospace'),
              ),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          if (showCustom) ...[
            const Divider(),
            RadioListTile<int>(
              value: -1,
              groupValue: customSelected ? -1 : selectedId,
              onChanged: (v) => onCustomSelected?.call(),
              title: const Text('Custom Range'),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            if (customSelected && customStartController != null && customSizeController != null)
              Padding(
                padding: const EdgeInsets.only(left: 32, top: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: customStartController,
                        decoration: const InputDecoration(
                          labelText: 'Start Address',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          isDense: true,
                        ),
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: customSizeController,
                        decoration: const InputDecoration(
                          labelText: 'Size',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          isDense: true,
                        ),
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoBox(String text, {IconData icon = Icons.info_outline}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildWarningBox(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber, size: 18, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator({required String label, required String value, required bool isOk}) {
    return Row(
      children: [
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
        Icon(isOk ? Icons.check_circle : Icons.cancel, size: 16, color: isOk ? Colors.green : Colors.grey),
        const SizedBox(width: 4),
        Text(value, style: TextStyle(color: isOk ? Colors.green : Colors.grey)),
      ],
    );
  }

  Widget _buildActionButton({required String label, required IconData icon, required VoidCallback? onPressed, bool isDestructive = false}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), backgroundColor: isDestructive ? Colors.red.shade700 : null),
      ),
    );
  }
}
