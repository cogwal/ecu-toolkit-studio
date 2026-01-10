/// Models for Flash operations
///
/// Contains memory region definitions and hardware type mappings

/// Represents a memory region with address and size
class MemoryRegion {
  final int id;
  final String name;
  final int startAddress;
  final int size;

  const MemoryRegion({required this.id, required this.name, required this.startAddress, required this.size});

  /// Format start address as hex string
  String get startAddressHex => '0x${startAddress.toRadixString(16).toUpperCase().padLeft(8, '0')}';

  /// Format size in human-readable format
  String get sizeFormatted {
    if (size >= 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(0)} MB';
    } else if (size >= 1024) {
      return '${(size / 1024).toStringAsFixed(0)} KB';
    }
    return '$size B';
  }

  @override
  String toString() => '$name ($startAddressHex, $sizeFormatted)';
}

/// Memory configuration for a specific hardware type
class CPUMemoryConfig {
  final String hardwareTypeExt; // Each specific hardware type end with the an extention that determines the memory layout for the cpu
  final String CPUName;
  final List<MemoryRegion> regions;

  const CPUMemoryConfig({required this.hardwareTypeExt, required this.CPUName, required this.regions});
}

/// Predefined memory configurations for supported hardware types
class MemoryConfigurations {
  static const tc37x = CPUMemoryConfig(
    hardwareTypeExt: '80D',
    CPUName: 'TC37x',
    regions: [
      MemoryRegion(id: 0x00, name: 'Bootloader', startAddress: 0x80000000, size: 0x30000), // 192 KB
      MemoryRegion(id: 0x00, name: 'Application', startAddress: 0x80060000, size: 0x5A0000), // 5.625 MB
      MemoryRegion(id: 0x00, name: 'Branding Block', startAddress: 0xAF03E000, size: 0x1000), // 4 KB
      MemoryRegion(id: 0x00, name: 'Flash Emulated EEPROM', startAddress: 0xAF000000, size: 0x3E000), // ~248 KB
      MemoryRegion(id: 0x00, name: 'Flash Driver', startAddress: 0x7010C000, size: 0x4000), // 16 KB
      MemoryRegion(id: 0x01, name: 'External NOR Flash', startAddress: 0x00000000, size: 0x1000000), // 16 MB
      MemoryRegion(id: 0x02, name: 'External FRAM', startAddress: 0x00000000, size: 0x2000), // 8 KB
    ],
  );

  static const tc36x = CPUMemoryConfig(
    hardwareTypeExt: '40D',
    CPUName: 'TC36x',
    regions: [
      MemoryRegion(id: 0x00, name: 'Bootloader', startAddress: 0x80000000, size: 0x30000), // 192 KB
      MemoryRegion(id: 0x00, name: 'Application 1', startAddress: 0x80060000, size: 0x1A0000), // 1.625 MB
      MemoryRegion(id: 0x00, name: 'Application 2', startAddress: 0x80300000, size: 0x200000), // 2 MB
      MemoryRegion(id: 0x00, name: 'Branding Block', startAddress: 0xAF01E000, size: 0x1000), // 4 KB
      MemoryRegion(id: 0x00, name: 'Flash Emulated EEPROM', startAddress: 0xAF000000, size: 0x1E000), // 120 KB
      MemoryRegion(id: 0x00, name: 'Flash Driver', startAddress: 0x70104000, size: 0x4000), // 16 KB
    ],
  );

  static const tc39x = CPUMemoryConfig(
    hardwareTypeExt: 'C0D',
    CPUName: 'TC39x',
    regions: [
      MemoryRegion(id: 0x00, name: 'Bootloader', startAddress: 0x80000000, size: 0x30000), // 192 KB
      MemoryRegion(id: 0x00, name: 'Application', startAddress: 0x80060000, size: 0xFA0000), // 15.625 MB
      MemoryRegion(id: 0x00, name: 'Branding Block', startAddress: 0xAF0FE000, size: 0x1000), // 4 KB
      MemoryRegion(id: 0x00, name: 'Flash Emulated EEPROM', startAddress: 0xAF000000, size: 0xFE000), // ~1 MB
      MemoryRegion(id: 0x00, name: 'Flash Driver', startAddress: 0x7010C000, size: 0x4000), // 16 KB
      MemoryRegion(id: 0x01, name: 'External NOR Flash', startAddress: 0x00000000, size: 0x2000000), // 32 MB
      MemoryRegion(id: 0x02, name: 'External FRAM', startAddress: 0x00000000, size: 0x2000), // 8 KB
    ],
  );

  // List of memory configurations
  static List<CPUMemoryConfig> get all => [tc37x, tc39x, tc36x];

  /// Get configuration by hardware type name
  static CPUMemoryConfig? getByHardwareType(String hardwareType) {
    for (final config in all) {
      if (hardwareType.endsWith(config.hardwareTypeExt)) return config;
    }
    return null;
  }
}

/// Mapping of hardware type identifiers to ECU names
class EcuHardwareMap {
  static const Map<String, String> _typeToName = {
    '0x0020040D': 'TTC2038',
    '0x0020080D': 'TTC2310',
    '0x0040080D': 'TTC2380',
    '0x0060080D': 'TTC2385',
    '0x0080080D': 'VOLUTION144',
    '0x00200C0D': 'TTC2390',
    '0x00400C0D': 'TTC2740',
    '0x00600C0D': 'TTC2785',
  };

  /// Get ECU name from hardware type string
  ///
  /// The [hardwareType] string can be in formats like "0x0020040D", "(0x0020040D)", etc.
  static String? getEcuName(String hardwareType) {
    // Exact match
    if (_typeToName.containsKey(hardwareType)) {
      return _typeToName[hardwareType];
    }

    // Attempt to extract hex string (e.g., from "(0x0020040D)")
    final hexMatch = RegExp(r'0x[0-9A-Fa-f]+').firstMatch(hardwareType);
    if (hexMatch != null) {
      final hex = hexMatch.group(0)!.toUpperCase();
      // Try with upper case version
      for (final key in _typeToName.keys) {
        if (key.toUpperCase() == hex) {
          return _typeToName[key];
        }
      }
    }

    return null;
  }
}
