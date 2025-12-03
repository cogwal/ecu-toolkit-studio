class EcuProfile {
  final String name;
  final int txId; // Request ID (e.g., 0x7E0)
  final int rxId; // Response ID (e.g., 0x7E8)
  final String bootloaderVersion;
  final String serialNumber;
  final String appVersion;
  final String appBuildDate;
  final String hardwareType;
  final String productionCode;

  EcuProfile({
    required this.name,
    required this.txId,
    required this.rxId,
    this.bootloaderVersion = '',
    this.serialNumber = '',
    this.appVersion = '',
    this.appBuildDate = '',
    this.hardwareType = '',
    this.productionCode = '',
  });

  factory EcuProfile.fromJson(Map<String, dynamic> json) => EcuProfile(
    name: json['name'] as String? ?? 'Unknown',
    txId: (json['txId'] is int) ? json['txId'] as int : int.parse(json['txId'].toString()),
    rxId: (json['rxId'] is int) ? json['rxId'] as int : int.parse(json['rxId'].toString()),
    bootloaderVersion: json['bootloaderVersion'] as String? ?? '',
    serialNumber: json['serialNumber'] as String? ?? '',
    appVersion: json['appVersion'] as String? ?? '',
    appBuildDate: json['appBuildDate'] as String? ?? '',
    hardwareType: json['hardwareType'] as String? ?? '',
    productionCode: json['productionCode'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'txId': txId,
    'rxId': rxId,
    'bootloaderVersion': bootloaderVersion,
    'serialNumber': serialNumber,
    'appVersion': appVersion,
    'appBuildDate': appBuildDate,
    'hardwareType': hardwareType,
    'productionCode': productionCode,
  };
}
