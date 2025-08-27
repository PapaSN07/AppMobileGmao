import 'package:flutter_test/flutter_test.dart';
import 'package:appmobilegmao/models/equipment.dart';

void main() {
  group('Equipment Model Tests', () {
    test('Equipment should be created from JSON', () {
      final json = {
        "id": "1",
        "code": "EQ001",
        "famille": "Transformateur",
        "zone": "Dakar",
        "entity": "SENELEC_DAKAR",
        "unite": "Unité Production",
        "centreCharge": "CC_DAKAR_01",
        "description": "Transformateur haute tension 225kV/30kV",
        "longitude": "14.6937",
        "latitude": "-17.4441",
        "attributs": [
          {"nom": "Puissance", "valeurs": "63 MVA"},
        ],
      };

      final equipment = Equipment.fromJson(json);

      expect(equipment.id, "1");
      expect(equipment.code, "EQ001");
      expect(equipment.famille, "Transformateur");
      expect(equipment.zone, "Dakar");
    });

    test('Equipment should convert to JSON', () {
      final equipment = Equipment(
        id: "1",
        code: "EQ001",
        famille: "Transformateur",
        zone: "Dakar",
        entity: "SENELEC_DAKAR",
        unite: "Unité Production",
        centreCharge: "CC_DAKAR_01",
        description: "Transformateur haute tension 225kV/30kV",
        longitude: "14.6937",
        latitude: "-17.4441",
      );

      final json = equipment.toJson();

      expect(json['id'], "1");
      expect(json['code'], "EQ001");
      expect(json['famille'], "Transformateur");
    });
  });
}
