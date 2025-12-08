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
class HardwareMemoryConfig {
  final String hardwareType;
  final List<MemoryRegion> regions;

  const HardwareMemoryConfig({required this.hardwareType, required this.regions});
}

/// Predefined memory configurations for supported hardware types
class MemoryConfigurations {
  static const tcu2 = HardwareMemoryConfig(
    hardwareType: 'TCU2',
    regions: [
      MemoryRegion(id: 0x01, name: 'Application', startAddress: 0x00008000, size: 0x38000), // 224 KB
      MemoryRegion(id: 0x02, name: 'FEE', startAddress: 0x00040000, size: 0x8000), // 32 KB
      MemoryRegion(id: 0x05, name: 'Branding Block', startAddress: 0x00048000, size: 0x800), // 2 KB
      MemoryRegion(id: 0x06, name: 'APDB', startAddress: 0x00049000, size: 0x800), // 2 KB
    ],
  );

  static const tcu3 = HardwareMemoryConfig(
    hardwareType: 'TCU3',
    regions: [
      MemoryRegion(id: 0x01, name: 'Application', startAddress: 0x00010000, size: 0x70000), // 448 KB
      MemoryRegion(id: 0x02, name: 'FEE', startAddress: 0x000A0000, size: 0x10000), // 64 KB
      MemoryRegion(id: 0x03, name: 'External Flash', startAddress: 0x10000000, size: 0x1000000), // 16 MB
      MemoryRegion(id: 0x04, name: 'FRAM', startAddress: 0x20000000, size: 0x2000), // 8 KB
      MemoryRegion(id: 0x05, name: 'Branding Block', startAddress: 0x00092000, size: 0x1000), // 4 KB
      MemoryRegion(id: 0x06, name: 'APDB', startAddress: 0x00090000, size: 0x1000), // 4 KB
    ],
  );

  /// Get configuration by hardware type name
  static HardwareMemoryConfig getForHardware(String? hardwareType) {
    final type = hardwareType?.toUpperCase() ?? '';
    if (type.contains('TCU3')) {
      return tcu3;
    } else if (type.contains('TCU2')) {
      return tcu2;
    }
    // Default to TCU3 if unknown
    return tcu3;
  }

  static List<HardwareMemoryConfig> get all => [tcu2, tcu3];
}

/// Security configuration for a security level
class SecurityConfig {
  final int level;
  final List<int> secretKey;

  SecurityConfig({required this.level, required this.secretKey});

  /// Parse secret key from format like: { 0x84EE5D28, 0xE75DE7CF, 0x118D5080, 0x28D3CAE2 }
  /// or comma-separated hex values: 0x84EE5D28, 0xE75DE7CF, 0x118D5080, 0x28D3CAE2
  static List<int>? parseSecretKey(String input) {
    try {
      // Remove curly braces and whitespace
      String cleaned = input.replaceAll(RegExp(r'[{}\s]'), '');
      if (cleaned.isEmpty) return null;

      // Split by comma and parse each value
      final parts = cleaned.split(',').where((s) => s.isNotEmpty).toList();
      final result = <int>[];

      for (final part in parts) {
        final trimmed = part.trim();
        if (trimmed.startsWith('0x') || trimmed.startsWith('0X')) {
          result.add(int.parse(trimmed.substring(2), radix: 16));
        } else {
          result.add(int.parse(trimmed, radix: 16));
        }
      }

      return result.isEmpty ? null : result;
    } catch (e) {
      return null;
    }
  }

  /// Format secret key back to display string
  static String formatSecretKey(List<int> keys) {
    if (keys.isEmpty) return '';
    final formatted = keys.map((k) => '0x${k.toRadixString(16).toUpperCase().padLeft(8, '0')}').join(', ');
    return '{ $formatted }';
  }
}

/// Custom memory range for erase/upload operations
class CustomMemoryRange {
  int startAddress;
  int size;

  CustomMemoryRange({this.startAddress = 0, this.size = 0x1000});

  /// Parse hex string to int, returns null if invalid
  static int? parseHex(String input) {
    try {
      String cleaned = input.trim();
      if (cleaned.startsWith('0x') || cleaned.startsWith('0X')) {
        return int.parse(cleaned.substring(2), radix: 16);
      }
      return int.parse(cleaned, radix: 16);
    } catch (e) {
      return null;
    }
  }
}
