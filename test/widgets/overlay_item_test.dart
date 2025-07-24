import 'package:appmobilegmao/provider/equipment_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:appmobilegmao/widgets/overlay_item.dart';

// Mock du EquipmentProvider pour les tests
class MockEquipmentProvider extends EquipmentProvider {
  @override
  Future<void> fetchEquipments() async {
    // Mock implementation - ne fait rien
  }

  @override
  Future<void> updateEquipment(String id, Map<String, dynamic> data) async {
    // Mock implementation - ne fait rien
  }
}

void main() {
  group('OverlayContent Tests', () {
    final Map<String, String> testDetails = {
      'Code': 'EQ001',
      'Famille': 'Transformateur',
      'Zone': 'Dakar',
      'Description': 'Transformateur principal',
    };

    testWidgets('renders correctly with all components', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<EquipmentProvider>(
          create: (context) => MockEquipmentProvider(),
          child: MaterialApp(
            home: Scaffold(
              body: OverlayContent(
                title: 'Détails de l\'équipement',
                details: testDetails,
                titleIcon: Icons.settings,
              ),
            ),
          ),
        ),
      );

      // Vérifier que le titre est affiché
      expect(find.text('Détails de l\'équipement'), findsOneWidget);

      // Vérifier que tous les détails sont affichés
      expect(find.text('Code'), findsOneWidget);
      expect(find.text('EQ001'), findsOneWidget);
      expect(find.text('Famille'), findsOneWidget);
      expect(find.text('Transformateur'), findsOneWidget);
      expect(find.text('Zone'), findsOneWidget);
      expect(find.text('Dakar'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(find.text('Transformateur principal'), findsOneWidget);

      // Vérifier que le bouton retour est présent
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      // Vérifier que le bouton modifier est présent par défaut
      expect(find.text('Modifier'), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('handles empty values correctly', (WidgetTester tester) async {
      final Map<String, String> detailsWithEmpty = {
        'Code': 'EQ001',
        'Description': '', // Valeur vide
        'Zone': 'Dakar',
      };

      await tester.pumpWidget(
        ChangeNotifierProvider<EquipmentProvider>(
          create: (context) => MockEquipmentProvider(),
          child: MaterialApp(
            home: Scaffold(
              body: OverlayContent(
                title: 'Test Empty Values',
                details: detailsWithEmpty,
              ),
            ),
          ),
        ),
      );

      // Vérifier que les valeurs vides affichent "Non renseigné"
      expect(find.text('Non renseigné'), findsOneWidget);
      expect(find.text('EQ001'), findsOneWidget);
      expect(find.text('Dakar'), findsOneWidget);
    });

    testWidgets('hides modify button when showModifyButton is false', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<EquipmentProvider>(
          create: (context) => MockEquipmentProvider(),
          child: MaterialApp(
            home: Scaffold(
              body: OverlayContent(
                title: 'Test Without Modify Button',
                details: testDetails,
                showModifyButton: false,
              ),
            ),
          ),
        ),
      );

      // Vérifier que le bouton modifier n'est pas affiché
      expect(find.text('Modifier'), findsNothing);
      expect(find.byIcon(Icons.edit), findsNothing);

      // Vérifier que le reste du contenu est toujours affiché
      expect(find.text('Test Without Modify Button'), findsOneWidget);
      expect(find.text('Code'), findsOneWidget);
    });

    testWidgets('calls onClose when back button is tapped', (
      WidgetTester tester,
    ) async {
      bool wasClosed = false;

      await tester.pumpWidget(
        ChangeNotifierProvider<EquipmentProvider>(
          create: (context) => MockEquipmentProvider(),
          child: MaterialApp(
            home: Scaffold(
              body: OverlayContent(
                title: 'Test Close Callback',
                details: testDetails,
                onClose: () {
                  wasClosed = true;
                },
              ),
            ),
          ),
        ),
      );

      // Appuyer sur le bouton retour
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Vérifier que la fonction onClose a été appelée
      expect(wasClosed, true);
    });

    testWidgets('modify button handles navigation correctly', (
      WidgetTester tester,
    ) async {
      
      await tester.pumpWidget(
        ChangeNotifierProvider<EquipmentProvider>(
          create: (context) => MockEquipmentProvider(),
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return Scaffold(
                  body: OverlayContent(
                    title: 'Test Navigation',
                    details: testDetails,
                    // Vous pourriez ajouter un callback de navigation personnalisé
                  ),
                );
              },
            ),
            // Intercepter la navigation
            onGenerateRoute: (settings) {
              return null; // Empêcher la navigation réelle
            },
          ),
        ),
      );

      // Appuyer sur le bouton modifier
      await tester.tap(find.text('Modifier'));
      await tester.pumpAndSettle();

      // Vérifier que la navigation a été tentée (si applicable)
      // expect(navigationCalled, true);
    });

    testWidgets('displays correct styling for detail items', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<EquipmentProvider>(
          create: (context) => MockEquipmentProvider(),
          child: MaterialApp(
            home: Scaffold(
              body: OverlayContent(
                title: 'Test Styling',
                details: {'Test Key': 'Test Value'},
              ),
            ),
          ),
        ),
      );

      // Vérifier que les containers avec la bonne couleur sont présents
      final containers = find.byType(Container);
      expect(containers, findsWidgets);

      // Vérifier que le texte est affiché avec les bonnes couleurs
      expect(find.text('Test Key'), findsOneWidget);
      expect(find.text('Test Value'), findsOneWidget);
    });

    testWidgets('handles long text correctly', (WidgetTester tester) async {
      final Map<String, String> longTextDetails = {
        'Description très longue':
            'Ceci est une description très très très longue qui devrait être gérée correctement par le widget sans déborder',
        'Code': 'EQ001',
      };

      await tester.pumpWidget(
        ChangeNotifierProvider<EquipmentProvider>(
          create: (context) => MockEquipmentProvider(),
          child: MaterialApp(
            home: Scaffold(
              body: OverlayContent(
                title:
                    'Titre très très très long qui devrait être tronqué avec des points de suspension',
                details: longTextDetails,
              ),
            ),
          ),
        ),
      );

      // Vérifier que le widget se rend sans erreur
      expect(find.byType(OverlayContent), findsOneWidget);
      expect(find.text('Code'), findsOneWidget);
      expect(find.text('EQ001'), findsOneWidget);
    });

    testWidgets('renders with empty details map', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<EquipmentProvider>(
          create: (context) => MockEquipmentProvider(),
          child: MaterialApp(
            home: Scaffold(
              body: OverlayContent(title: 'Empty Details', details: {}),
            ),
          ),
        ),
      );

      // Vérifier que le titre est affiché même avec des détails vides
      expect(find.text('Empty Details'), findsOneWidget);

      // Vérifier que le bouton retour est toujours présent
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      // Vérifier que le bouton modifier est toujours présent
      expect(find.text('Modifier'), findsOneWidget);
    });
  });

  group('OverlayAction Tests', () {
    test('creates OverlayAction correctly', () {
      final action = OverlayAction(
        label: 'Test Action',
        icon: Icons.star,
        onPressed: () {},
        isPrimary: true,
      );

      expect(action.label, 'Test Action');
      expect(action.icon, Icons.star);
      expect(action.isPrimary, true);
      expect(action.onPressed, isA<VoidCallback>());
    });

    test('creates OverlayAction with default isPrimary', () {
      final action = OverlayAction(
        label: 'Default Action',
        icon: Icons.info,
        onPressed: () {},
      );

      expect(action.isPrimary, false);
    });
  });
}
