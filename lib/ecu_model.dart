class EcuProfile {
  final String name;
  final int txId; // Request ID (e.g., 0x7E0)
  final int rxId; // Response ID (e.g., 0x7E8)
  final String protocol;
  final String vin;

  EcuProfile({
    required this.name,
    required this.txId,
    required this.rxId,
    this.protocol = "ISO-15765-4 (UDS)",
    this.vin = "UNKNOWN",
  });
}