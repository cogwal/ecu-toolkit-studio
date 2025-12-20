class EcuProfile {
  final String name;
  final int txId; // Request ID (e.g., 0x7E0)
  final int rxId; // Response ID (e.g., 0x7E8)
  final String bootloaderVersion;
  final String bootloaderBuildDate;
  final String serialNumber;
  final String appVersion;
  final String appBuildDate;
  final String hsmVersion;
  final String hsmBuildDate;
  final String hardwareName;
  final String hardwareType;
  final String productionCode;

  EcuProfile({
    required this.name,
    required this.txId,
    required this.rxId,
    this.bootloaderVersion = '',
    this.bootloaderBuildDate = '',
    this.serialNumber = '',
    this.appVersion = '',
    this.appBuildDate = '',
    this.hsmVersion = '',
    this.hsmBuildDate = '',
    this.hardwareName = '',
    this.hardwareType = '',
    this.productionCode = '',
  });

  factory EcuProfile.fromJson(Map<String, dynamic> json) => EcuProfile(
    name: json['name'] as String? ?? 'Unknown',
    txId: (json['txId'] is int) ? json['txId'] as int : int.parse(json['txId'].toString()),
    rxId: (json['rxId'] is int) ? json['rxId'] as int : int.parse(json['rxId'].toString()),
    bootloaderVersion: json['bootloaderVersion'] as String? ?? '',
    bootloaderBuildDate: json['bootloaderBuildDate'] as String? ?? '',
    serialNumber: json['serialNumber'] as String? ?? '',
    appVersion: json['appVersion'] as String? ?? '',
    appBuildDate: json['appBuildDate'] as String? ?? '',
    hsmVersion: json['hsmVersion'] as String? ?? '',
    hsmBuildDate: json['hsmBuildDate'] as String? ?? '',
    hardwareName: json['hardwareName'] as String? ?? '',
    hardwareType: json['hardwareType'] as String? ?? '',
    productionCode: json['productionCode'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'txId': txId,
    'rxId': rxId,
    'bootloaderVersion': bootloaderVersion,
    'bootloaderBuildDate': bootloaderBuildDate,
    'serialNumber': serialNumber,
    'appVersion': appVersion,
    'appBuildDate': appBuildDate,
    'hsmVersion': hsmVersion,
    'hsmBuildDate': hsmBuildDate,
    'hardwareName': hardwareName,
    'hardwareType': hardwareType,
    'productionCode': productionCode,
  };

  EcuProfile copyWith({
    String? name,
    int? txId,
    int? rxId,
    String? bootloaderVersion,
    String? bootloaderBuildDate,
    String? serialNumber,
    String? appVersion,
    String? appBuildDate,
    String? hsmVersion,
    String? hsmBuildDate,
    String? hardwareName,
    String? hardwareType,
    String? productionCode,
  }) {
    return EcuProfile(
      name: name ?? this.name,
      txId: txId ?? this.txId,
      rxId: rxId ?? this.rxId,
      bootloaderVersion: bootloaderVersion ?? this.bootloaderVersion,
      bootloaderBuildDate: bootloaderBuildDate ?? this.bootloaderBuildDate,
      serialNumber: serialNumber ?? this.serialNumber,
      appVersion: appVersion ?? this.appVersion,
      appBuildDate: appBuildDate ?? this.appBuildDate,
      hsmVersion: hsmVersion ?? this.hsmVersion,
      hsmBuildDate: hsmBuildDate ?? this.hsmBuildDate,
      hardwareName: hardwareName ?? this.hardwareName,
      hardwareType: hardwareType ?? this.hardwareType,
      productionCode: productionCode ?? this.productionCode,
    );
  }
}
