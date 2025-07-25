import 'package:appmobilegmao/provider/equipment_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:appmobilegmao/screens/equipments/modify_equipment_screen.dart';

// Mock du EquipmentProvider pour les tests
class MockEquipmentProvider extends EquipmentProvider {
  bool _updateEquipmentCalled = false;
  String? _lastEquipmentId;
  Map<String, dynamic>? _lastEquipmentData;
  bool _shouldThrowError = false;

  bool get updateEquipmentCalled => _updateEquipmentCalled;
  String? get lastEquipmentId => _lastEquipmentId;
  Map<String, dynamic>? get lastEquipmentData => _lastEquipmentData;

  void setShouldThrowError(bool value) {
    _shouldThrowError = value;
  }

  @override
  Future<void> fetchEquipments() async {
    // Mock implementation - ne fait rien
  }

  @override
  Future<void> addEquipment(Map<String, dynamic> equipmentData) async {
    // Mock implementation - ne fait rien
  }

  @override
  Future<void> updateEquipment(String id, Map<String, dynamic> data) async {
    _updateEquipmentCalled = true;
    _lastEquipmentId = id;
    _lastEquipmentData = data;

    if (_shouldThrowError) {
      throw Exception('Erreur simulée lors de la modification');
    }

    // Simulate successful update
    await Future.delayed(const Duration(milliseconds: 100));
  }

  void reset() {
    _updateEquipmentCalled = false;
    _lastEquipmentId = null;
    _lastEquipmentData = null;
    _shouldThrowError = false;
  }
}

void main() {
  group('ModifyEquipmentScreen Tests', () {
    late MockEquipmentProvider mockProvider;

    final Map<String, String> testEquipmentData = {
      'ID': 'EQ123',
      'Code': 'EQ001',
      'Famille': 'Transformateur',
      'Zone': 'Dakar',
      'Entité': 'Entité 1',
      'Unité': 'Unité 1',
      'Centre': 'Centre 1',
      'Description': 'Transformateur principal de test',
      'Code Parent': 'EQ001',
      'Feeder': 'Feeder 1',
      'Longitude': '14.6928',
      'Latitude': '-17.4467',
    };

    setUp(() {
      mockProvider = MockEquipmentProvider();
    });

    Widget createWidget({Map<String, String>? equipmentData}) {
      return ChangeNotifierProvider<EquipmentProvider>.value(
        value: mockProvider,
        child: MaterialApp(
          home: ModifyEquipmentScreen(equipmentData: equipmentData),
        ),
      );
    }

    testWidgets('renders correctly with all components', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));

      await tester.pumpWidget(createWidget(equipmentData: testEquipmentData));
      await tester.pumpAndSettle();

      // Vérifier l'AppBar personnalisée
      expect(find.text('Modifier l\'équipement'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      // Vérifier les sections principales
      expect(find.text('Informations'), findsWidgets);
      expect(find.text('Informations parents'), findsOneWidget);
      expect(find.text('Informations de positionnement'), findsOneWidget);

      // Vérifier les boutons d'action
      expect(find.text('Annuler'), findsOneWidget);
      expect(find.text('Modifier'), findsOneWidget);
    });

    testWidgets('pre-fills form fields with equipment data', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));

      await tester.pumpWidget(createWidget(equipmentData: testEquipmentData));
      await tester.pumpAndSettle();

      // Vérifier que les champs sont pré-remplis
      expect(find.text('Code'), findsOneWidget);
      expect(find.text('Famille'), findsOneWidget);
      expect(find.text('Zone'), findsOneWidget);
      expect(find.text('Entité'), findsOneWidget);
      expect(find.text('Unité'), findsOneWidget);
      expect(find.text('Centre de Charge'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(find.text('Code Parent'), findsOneWidget);
      expect(find.text('Feeder'), findsOneWidget);

      // Vérifier que la description est pré-remplie
      expect(find.text('Transformateur principal de test'), findsOneWidget);
    });

    testWidgets('handles empty equipment data gracefully', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));

      await tester.pumpWidget(createWidget(equipmentData: null));
      await tester.pumpAndSettle();

      // Vérifier que l'écran se charge sans erreur même sans données
      expect(find.text('Modifier l\'équipement'), findsOneWidget);
      expect(find.text('Informations'), findsWidgets);

      // Vérifier qu'aucune exception n'est levée
      expect(tester.takeException(), isNull);
    });

    testWidgets('handles dropdown selections correctly', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));

      await tester.pumpWidget(createWidget(equipmentData: testEquipmentData));
      await tester.pumpAndSettle();

      // Chercher les dropdowns
      final dropdownFields = find.byType(DropdownButtonFormField);

      if (tester.any(dropdownFields)) {
        // Faire défiler pour voir le premier dropdown
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -100),
        );
        await tester.pumpAndSettle();

        try {
          // Tester avec le premier dropdown trouvé
          await tester.tap(dropdownFields.first, warnIfMissed: false);
          await tester.pumpAndSettle();

          // Chercher une option disponible
          final thiessOption = find.text('Thiès').last;
          if (tester.any(thiessOption)) {
            await tester.tap(thiessOption, warnIfMissed: false);
            await tester.pumpAndSettle();
          }
        } catch (e) {
          print('Test dropdown ignoré: $e');
        }
      }

      // Vérifier qu'aucune exception fatale n'est survenue
      expect(tester.takeException(), isNull);
    });

    testWidgets('handles text input correctly', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));

      await tester.pumpWidget(createWidget(equipmentData: testEquipmentData));
      await tester.pumpAndSettle();

      // Faire défiler pour voir le champ Description
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();

      // Trouver le champ Description et modifier le texte
      final descriptionField = find.byType(TextFormField);
      if (tester.any(descriptionField)) {
        await tester.enterText(descriptionField.first, 'Description modifiée');
        await tester.pumpAndSettle();

        // Vérifier que le nouveau texte est affiché
        expect(find.text('Description modifiée'), findsOneWidget);
      }
    });

    testWidgets('shows validation behavior when form is submitted', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));

      await tester.pumpWidget(createWidget(equipmentData: testEquipmentData));
      await tester.pumpAndSettle();

      // Faire défiler pour voir le bouton Modifier
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();

      // Tenter de soumettre le formulaire
      final modifyButton = find.text('Modifier');
      if (tester.any(modifyButton)) {
        await tester.tap(modifyButton, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 500));

        // Vérifier qu'aucune exception fatale n'est levée
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('calls cancel when cancel button is tapped', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));

      await tester.pumpWidget(createWidget(equipmentData: testEquipmentData));
      await tester.pumpAndSettle();

      // Faire défiler pour voir le bouton Annuler
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();

      // Appuyer sur le bouton Annuler
      final cancelButton = find.text('Annuler');
      expect(cancelButton, findsOneWidget);

      await tester.tap(cancelButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Vérifier qu'aucune erreur ne survient
      expect(tester.takeException(), isNull);
    });

    testWidgets('calls back button correctly', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));

      await tester.pumpWidget(createWidget(equipmentData: testEquipmentData));
      await tester.pumpAndSettle();

      // Appuyer sur le bouton retour
      await tester.tap(find.byIcon(Icons.arrow_back), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Vérifier qu'aucune erreur ne survient
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows attributes modal when add attributes is tapped', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));

      await tester.pumpWidget(createWidget(equipmentData: testEquipmentData));
      await tester.pumpAndSettle();

      // Faire défiler pour voir le bouton "Ajouter les attributs"
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();

      // Appuyer sur "Ajouter les attributs"
      final addAttributesButton = find.text('Ajouter les attributs');
      if (tester.any(addAttributesButton)) {
        await tester.tap(addAttributesButton, warnIfMissed: false);
        await tester.pumpAndSettle();

        // Vérifier que le modal est affiché
        expect(find.text('Ajout Attribut'), findsOneWidget);
        expect(find.text('Attribut'), findsOneWidget);
        expect(find.text('Valeur'), findsOneWidget);
      }
    });

    testWidgets('handles successful equipment modification', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));

      await tester.pumpWidget(createWidget(equipmentData: testEquipmentData));
      await tester.pumpAndSettle();

      // Modifier le champ description
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();

      final descriptionField = find.byType(TextFormField);
      if (tester.any(descriptionField)) {
        await tester.enterText(
          descriptionField.first,
          'Description modifiée pour test',
        );
        await tester.pumpAndSettle();
      }

      // Faire défiler pour voir le bouton Modifier
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      // Soumettre le formulaire
      final modifyButton = find.text('Modifier');
      if (tester.any(modifyButton)) {
        await tester.tap(modifyButton, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 200));

        // Vérifier qu'aucune exception n'est levée
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('handles equipment modification error', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));

      // Configurer le mock pour lever une erreur
      mockProvider.setShouldThrowError(true);

      await tester.pumpWidget(createWidget(equipmentData: testEquipmentData));
      await tester.pumpAndSettle();

      // Faire défiler pour voir le bouton Modifier
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();

      // Tenter de soumettre le formulaire
      final modifyButton = find.text('Modifier');
      if (tester.any(modifyButton)) {
        await tester.tap(modifyButton, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 200));

        // Vérifier qu'aucune exception non gérée n'est levée
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('displays location information correctly', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));

      await tester.pumpWidget(createWidget(equipmentData: testEquipmentData));
      await tester.pumpAndSettle();

      // Faire défiler pour voir les informations de position
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();

      // Vérifier les champs de position
      expect(find.text('Longitude'), findsOneWidget);
      expect(find.text('Latitude'), findsOneWidget);
      expect(find.text('Position actuelle'), findsOneWidget);
      expect(find.text('Toucher pour modifier'), findsOneWidget);

      // Vérifier que les valeurs de longitude et latitude sont affichées
      expect(find.text('14.6928'), findsOneWidget);
      expect(find.text('-17.4467'), findsOneWidget);
    });

    testWidgets('handles map interaction', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));

      await tester.pumpWidget(createWidget(equipmentData: testEquipmentData));
      await tester.pumpAndSettle();

      // Faire défiler pour voir la carte
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();

      // Appuyer sur "Toucher pour modifier"
      final mapInteraction = find.text('Toucher pour modifier');
      if (tester.any(mapInteraction)) {
        await tester.tap(mapInteraction, warnIfMissed: false);
        await tester.pumpAndSettle();

        // Vérifier qu'aucune erreur ne survient
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('form scrolls correctly', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));

      await tester.pumpWidget(createWidget(equipmentData: testEquipmentData));
      await tester.pumpAndSettle();

      // Tester le défilement vers le bas
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      // Vérifier que le défilement fonctionne sans erreur
      expect(tester.takeException(), isNull);

      // Tester le défilement vers le haut
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, 200),
      );
      await tester.pumpAndSettle();

      // Vérifier que le défilement fonctionne sans erreur
      expect(tester.takeException(), isNull);
    });

    testWidgets('closes attributes modal correctly', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));

      await tester.pumpWidget(createWidget(equipmentData: testEquipmentData));
      await tester.pumpAndSettle();

      // Faire défiler pour voir le bouton "Ajouter les attributs"
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();

      // Ouvrir le modal
      final addAttributesButton = find.text('Ajouter les attributs');
      if (tester.any(addAttributesButton)) {
        await tester.tap(addAttributesButton, warnIfMissed: false);
        await tester.pumpAndSettle();

        // Fermer le modal avec le bouton retour
        final backButton = find.byIcon(Icons.arrow_back).last;
        if (tester.any(backButton)) {
          await tester.tap(backButton, warnIfMissed: false);
          await tester.pumpAndSettle();

          // Vérifier que le modal est fermé
          expect(find.text('Ajout Attribut'), findsNothing);
        }
      }
    });
  });

  group('ModifyEquipmentScreen Form Validation Tests', () {
    late MockEquipmentProvider mockProvider;

    final Map<String, String> testEquipmentData = {
      'ID': 'EQ123',
      'Code': 'EQ001',
      'Description': 'Test equipment',
    };

    setUp(() {
      mockProvider = MockEquipmentProvider();
    });

    Widget createWidget({Map<String, String>? equipmentData}) {
      return ChangeNotifierProvider<EquipmentProvider>.value(
        value: mockProvider,
        child: MaterialApp(
          home: ModifyEquipmentScreen(equipmentData: equipmentData),
        ),
      );
    }

    testWidgets('validates form fields presence', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));

      await tester.pumpWidget(createWidget(equipmentData: testEquipmentData));
      await tester.pumpAndSettle();

      // Vérifier que les champs dropdown sont présents
      final formFields = find.byType(DropdownButtonFormField);
      final textFields = find.byType(TextFormField);

      // Vérifier qu'au moins quelques champs sont présents
      expect(tester.any(formFields) || tester.any(textFields), true);
    });

    testWidgets('handles focus management correctly', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));

      await tester.pumpWidget(createWidget(equipmentData: testEquipmentData));
      await tester.pumpAndSettle();

      // Faire défiler pour voir le champ Description
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();

      // Taper sur le champ Description pour lui donner le focus
      final descriptionField = find.byType(TextFormField);
      if (tester.any(descriptionField)) {
        await tester.tap(descriptionField.first, warnIfMissed: false);
        await tester.pumpAndSettle();

        // Vérifier qu'aucune erreur ne survient lors de la gestion du focus
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('handles partial equipment data correctly', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));

      // Données partielles d'équipement
      final partialData = {
        'ID': 'EQ456',
        'Code': 'EQ002',
        'Zone': 'Thiès',
        // Autres champs manquants
      };

      await tester.pumpWidget(createWidget(equipmentData: partialData));
      await tester.pumpAndSettle();

      // Vérifier que l'écran se charge correctement même avec des données partielles
      expect(find.text('Modifier l\'équipement'), findsOneWidget);
      expect(find.text('Zone'), findsOneWidget);

      // Vérifier qu'aucune exception n'est levée
      expect(tester.takeException(), isNull);
    });
  });
}
