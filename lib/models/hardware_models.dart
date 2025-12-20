/// Models for Flash operations
///
/// Contains memory region definitions, hardware configurations,
/// and security settings for flash memory operations.

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
      MemoryRegion(id: 0x01, name: 'Application', startAddress: 0x00008000, size: 0x38000), // 224 KB
      MemoryRegion(id: 0x02, name: 'FEE', startAddress: 0x00040000, size: 0x8000), // 32 KB
      MemoryRegion(id: 0x05, name: 'Branding Block', startAddress: 0x00048000, size: 0x800), // 2 KB
      MemoryRegion(id: 0x06, name: 'APDB', startAddress: 0x00049000, size: 0x800), // 2 KB
    ],
  );

  static const tc39x = CPUMemoryConfig(
    hardwareTypeExt: 'C0D',
    CPUName: 'TC39x',
    regions: [
      MemoryRegion(id: 0x01, name: 'Application', startAddress: 0x00010000, size: 0x70000), // 448 KB
      MemoryRegion(id: 0x02, name: 'FEE', startAddress: 0x000A0000, size: 0x10000), // 64 KB
      MemoryRegion(id: 0x03, name: 'External Flash', startAddress: 0x10000000, size: 0x1000000), // 16 MB
      MemoryRegion(id: 0x04, name: 'FRAM', startAddress: 0x20000000, size: 0x2000), // 8 KB
      MemoryRegion(id: 0x05, name: 'Branding Block', startAddress: 0x00092000, size: 0x1000), // 4 KB
      MemoryRegion(id: 0x06, name: 'APDB', startAddress: 0x00090000, size: 0x1000), // 4 KB
    ],
  );

  // List of memory configurations
  static List<CPUMemoryConfig> get all => [tc37x, tc39x];

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
