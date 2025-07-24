import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:appmobilegmao/services/equipment_service.dart';
import 'package:appmobilegmao/services/api_service.dart';

// Générer les mocks automatiquement
@GenerateMocks([ApiService])
import 'equipment_service_test.mocks.dart';

void main() {
  group('EquipmentService Tests', () {
    late EquipmentService equipmentService;
    late MockApiService mockApiService;

    setUp(() {
      mockApiService = MockApiService();
      equipmentService = EquipmentService(mockApiService); // Injecter le mock
    });

    test('getAllEquipments should return a list of equipments', () async {
      // Simuler une réponse réussie
      final mockEquipments = [
        {
          'id': '1',
          'code': 'EQ001',
          'famille': 'Transformateur',
          'zone': 'Dakar',
        },
        {'id': '2', 'code': 'EQ002', 'famille': 'Disjoncteur', 'zone': 'Thiès'},
      ];

      when(
        mockApiService.get('/equipments'),
      ).thenAnswer((_) async => mockEquipments);

      final equipments = await equipmentService.getAllEquipments();

      // Vérifier que la méthode get a été appelée
      verify(mockApiService.get('/equipments')).called(1);

      // Vérifier le résultat
      expect(equipments, isNotEmpty);
      expect(equipments.length, 2);
      expect(equipments[0]['code'], 'EQ001');
    });

    test('getEquipmentById should return a single equipment', () async {
      // Simuler une réponse réussie
      final mockEquipment = {
        'id': '1',
        'code': 'EQ001',
        'famille': 'Transformateur',
        'zone': 'Dakar',
      };

      when(
        mockApiService.get('/equipments/1'),
      ).thenAnswer((_) async => mockEquipment);

      final equipment = await equipmentService.getEquipmentById('1');

      // Vérifier que la méthode get a été appelée
      verify(mockApiService.get('/equipments/1')).called(1);

      // Vérifier le résultat
      expect(equipment, isNotNull);
      expect(equipment['code'], 'EQ001');
    });

    test('createEquipment should create a new equipment', () async {
      // Simuler une réponse réussie
      final newEquipment = {
        'code': 'EQ003',
        'famille': 'Générateur',
        'zone': 'Kaolack',
      };

      final mockResponse = {'id': '3', ...newEquipment};

      when(
        mockApiService.post('/equipments', newEquipment),
      ).thenAnswer((_) async => mockResponse);

      final createdEquipment = await equipmentService.createEquipment(
        newEquipment,
      );

      // Vérifier que la méthode post a été appelée
      verify(mockApiService.post('/equipments', newEquipment)).called(1);

      // Vérifier le résultat
      expect(createdEquipment, isNotNull);
      expect(createdEquipment['id'], '3');
      expect(createdEquipment['code'], 'EQ003');
    });

    test('updateEquipment should update an existing equipment', () async {
      // Simuler une réponse réussie
      final updatedData = {'famille': 'Transformateur', 'zone': 'Saint-Louis'};

      final mockResponse = {'id': '1', 'code': 'EQ001', ...updatedData};

      when(
        mockApiService.patch('/equipments/1', updatedData),
      ).thenAnswer((_) async => mockResponse);

      final updatedEquipment = await equipmentService.updateEquipment(
        '1',
        updatedData,
      );

      // Vérifier que la méthode patch a été appelée
      verify(mockApiService.patch('/equipments/1', updatedData)).called(1);

      // Vérifier le résultat
      expect(updatedEquipment, isNotNull);
      expect(updatedEquipment['zone'], 'Saint-Louis');
    });

    test('deleteEquipment should delete an equipment', () async {
      // Simuler une réponse réussie
      when(
        mockApiService.delete('/equipments/1'),
      ).thenAnswer((_) async => null);

      await equipmentService.deleteEquipment('1');

      // Vérifier que la méthode delete a été appelée
      verify(mockApiService.delete('/equipments/1')).called(1);
    });
  });
}
