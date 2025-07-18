class Equipment {
  String? id;
  String codeParent;
  String feeder;
  String feederDescription;
  String code;
  String famille;
  String zone;
  String entity;
  String unite;
  String centreCharge;
  String description;
  String longitude;
  String latitude;

  Equipment({
    this.id,
    required this.codeParent,
    required this.feeder,
    required this.feederDescription,
    required this.code,
    required this.famille,
    required this.zone,
    required this.entity,
    required this.unite,
    required this.centreCharge,
    required this.description,
    required this.longitude,
    required this.latitude,
  });

  Equipment.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      codeParent = json['codeParent'],
      feeder = json['feeder'],
      feederDescription = json['feederDescription'],
      code = json['code'],
      famille = json['famille'],
      zone = json['zone'],
      entity = json['entity'],
      unite = json['unite'],
      centreCharge = json['centreCharge'],
      description = json['description'],
      longitude = json['longitude'],
      latitude = json['latitude'];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codeParent': codeParent,
      'feeder': feeder,
      'feederDescription': feederDescription,
      'code': code,
      'famille': famille,
      'zone': zone,
      'entity': entity,
      'unite': unite,
      'centreCharge': centreCharge,
      'description': description,
      'longitude': longitude,
      'latitude': latitude,
    };
  }

  @override
  String toString() {
    return 'Equipment(id: $id, codeParent: $codeParent, feeder: $feeder, feederDescription: $feederDescription, code: $code, famille: $famille, zone: $zone, entity: $entity, unite: $unite, centreCharge: $centreCharge, description: $description, longitude: $longitude, latitude: $latitude)';
  }
}
