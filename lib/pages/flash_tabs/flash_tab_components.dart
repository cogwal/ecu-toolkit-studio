import 'package:flutter/material.dart';
import '../../models/hardware_models.dart';

/// Reusable container for flash operation tabs
class FlashTabContainer extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const FlashTabContainer({super.key, required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Ensure a minimum height so content doesn't get squashed when log panel is open
        final minHeight = constraints.maxHeight < 500 ? 500.0 : constraints.maxHeight;

        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: IntrinsicHeight(
              child: Container(
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
              ),
            ),
          ),
        );
      },
    );
  }
}

/// File selector widget for HEX files
class FlashFileSelector extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback onBrowse;
  final bool isSave;

  const FlashFileSelector({super.key, required this.label, required this.value, required this.onBrowse, this.isSave = false});

  @override
  Widget build(BuildContext context) {
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
}

/// Memory region selector with custom range option
class FlashRegionSelector extends StatelessWidget {
  final List<MemoryRegion> memoryRegions;
  final int? selectedId;
  final void Function(int) onChanged;
  final bool showCustom;
  final bool customSelected;
  final VoidCallback? onCustomSelected;
  final TextEditingController? customStartController;
  final TextEditingController? customSizeController;

  const FlashRegionSelector({
    super.key,
    required this.memoryRegions,
    required this.selectedId,
    required this.onChanged,
    required this.showCustom,
    this.customSelected = false,
    this.onCustomSelected,
    this.customStartController,
    this.customSizeController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...memoryRegions.map(
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
}

/// Info box widget
class FlashInfoBox extends StatelessWidget {
  final String text;
  final IconData icon;

  const FlashInfoBox({super.key, required this.text, this.icon = Icons.info_outline});

  @override
  Widget build(BuildContext context) {
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
}

/// Warning box widget
class FlashWarningBox extends StatelessWidget {
  final String text;

  const FlashWarningBox({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
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
}

/// Status indicator widget
class FlashStatusIndicator extends StatelessWidget {
  final String label;
  final String value;
  final bool isOk;

  const FlashStatusIndicator({super.key, required this.label, required this.value, required this.isOk});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
        Icon(isOk ? Icons.check_circle : Icons.cancel, size: 16, color: isOk ? Colors.green : Colors.grey),
        const SizedBox(width: 4),
        Text(value, style: TextStyle(color: isOk ? Colors.green : Colors.grey)),
      ],
    );
  }
}

/// Action button widget
class FlashActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isDestructive;

  const FlashActionButton({super.key, required this.label, required this.icon, required this.onPressed, this.isDestructive = false});

  @override
  Widget build(BuildContext context) {
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
