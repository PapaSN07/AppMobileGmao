class ReferenceData {
  List<ReferenceItem> zones;
  List<ReferenceItem> familles;
  List<ReferenceItem> entities;

  ReferenceData({
    required this.zones,
    required this.familles,
    required this.entities,
  });

  factory ReferenceData.fromJson(Map<String, dynamic> json) {
    return ReferenceData(
      zones:
          (json['zones'] as List? ?? [])
              .map((z) => ReferenceItem.fromJson(z))
              .toList(),
      familles:
          (json['familles'] as List? ?? [])
              .map((f) => ReferenceItem.fromJson(f))
              .toList(),
      entities:
          (json['entities'] as List? ?? [])
              .map((e) => ReferenceItem.fromJson(e))
              .toList(),
    );
  }
}

class ReferenceItem {
  String name;
  int count;

  ReferenceItem({required this.name, required this.count});

  factory ReferenceItem.fromJson(Map<String, dynamic> json) {
    return ReferenceItem(name: json['name'] ?? '', count: json['count'] ?? 0);
  }
}
