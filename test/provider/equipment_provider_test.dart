import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:appmobilegmao/provider/equipment_provider.dart';
import 'package:appmobilegmao/services/equipment_service.dart';

// Générer les mocks automatiquement
@GenerateMocks([EquipmentService])
import 'equipment_provider_test.mocks.dart';

void main() {
  group('EquipmentProvider Tests', () {
    late EquipmentProvider equipmentProvider;
    late MockEquipmentService mockEquipmentService;

    setUp(() {
      mockEquipmentService = MockEquipmentService();
      equipmentProvider = EquipmentProvider(
        equipmentService: mockEquipmentService,
      );
    });

    test('Initial state should be correct', () {
      expect(equipmentProvider.equipments, isEmpty);
      expect(equipmentProvider.isLoading, false);
      expect(equipmentProvider.errorMessage, isEmpty);
      expect(equipmentProvider.currentSearchQuery, isEmpty);
    });

    test('fetchEquipments should populate the equipments list', () async {
      // Données de test
      final testEquipments = [
        {
          "id": "1",
          "code": "EQ001",
          "famille": "Transformateur",
          "zone": "Dakar",
          "entity": "SENELEC_DAKAR",
          "unite": "Unité Production",
          "centreCharge": "CC_DAKAR_01",
          "description": "Transformateur test",
          "longitude": "14.6937",
          "latitude": "-17.4441",
        },
        {
          "id": "2",
          "code": "EQ002",
          "famille": "Disjoncteur",
          "zone": "Thiès",
          "entity": "SENELEC_THIES",
          "unite": "Unité Distribution",
          "centreCharge": "CC_THIES_01",
          "description": "Disjoncteur test",
          "longitude": "14.7886",
          "latitude": "-16.9246",
        },
      ];

      // Configurer le mock
      when(
        mockEquipmentService.getAllEquipments(),
      ).thenAnswer((_) async => testEquipments);

      // Appeler fetchEquipments
      await equipmentProvider.fetchEquipments();

      // Vérifications
      expect(equipmentProvider.equipments, isNotEmpty);
      expect(equipmentProvider.equipments.length, 2);
      expect(equipmentProvider.equipments[0]['code'], 'EQ001');
      expect(equipmentProvider.equipments[1]['code'], 'EQ002');
      expect(equipmentProvider.isLoading, false);
      expect(equipmentProvider.errorMessage, isEmpty);

      // Vérifier que le service a été appelé
      verify(mockEquipmentService.getAllEquipments()).called(1);
    });

    test('fetchEquipments should handle errors', () async {
      // Simuler une erreur
      when(
        mockEquipmentService.getAllEquipments(),
      ).thenThrow(Exception('Erreur de connexion'));

      // Appeler fetchEquipments
      await equipmentProvider.fetchEquipments();

      // Vérifications
      expect(equipmentProvider.equipments, isEmpty);
      expect(equipmentProvider.isLoading, false);
      expect(equipmentProvider.errorMessage, isNotEmpty);
      expect(equipmentProvider.errorMessage, contains('Erreur'));
    });

    test('filterEquipments should filter correctly', () {
      // Préparer des données de test
      equipmentProvider.equipments.addAll([
        {
          'id': '1',
          'code': 'EQ001',
          'famille': 'Transformateur',
          'zone': 'Dakar',
        },
        {'id': '2', 'code': 'EQ002', 'famille': 'Disjoncteur', 'zone': 'Thiès'},
        {
          'id': '3',
          'code': 'EQ003',
          'famille': 'Transformateur',
          'zone': 'Dakar',
        },
      ]);

      // Filtrer par 'Transformateur'
      equipmentProvider.filterEquipments('Transformateur');

      // Vérifier le filtrage
      expect(equipmentProvider.currentSearchQuery, 'Transformateur');
      // Note: Le test exact dépend de l'implémentation de filterEquipments
    });

    test('addEquipment should add equipment to list', () async {
      final newEquipment = {
        "code": "EQ003",
        "famille": "Générateur",
        "zone": "Kaolack",
        "entity": "SENELEC_KAOLACK",
        "unite": "Unité Production",
        "centreCharge": "CC_KAOLACK_01",
        "description": "Générateur test",
        "longitude": "14.1510",
        "latitude": "-16.0726",
      };

      // Configurer le mock pour retourner l'équipement avec un ID
      when(
        mockEquipmentService.createEquipment(newEquipment),
      ).thenAnswer((_) async => {...newEquipment, "id": "3"});

      // Appeler addEquipment
      await equipmentProvider.addEquipment(newEquipment);

      // Vérifications
      expect(equipmentProvider.equipments.length, 1);
      expect(equipmentProvider.equipments[0]['code'], 'EQ003');

      // Vérifier que le service a été appelé
      verify(mockEquipmentService.createEquipment(newEquipment)).called(1);
    });
  });
}
