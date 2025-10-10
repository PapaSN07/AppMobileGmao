import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appmobilegmao/widgets/list_item.dart';

void main() {
  group('ListItemCustom Tests', () {
    testWidgets('renders correctly with basic properties', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListItemCustom(
              icon: Icons.settings,
              primaryText: 'EQ001',
              primaryLabel: 'Code',
              fields: [
                ItemField(label: 'Famille', value: 'Transformateur'),
                ItemField(label: 'Zone', value: 'Dakar'),
              ],
              overlayDetails: {
                'Code': 'EQ001',
                'Famille': 'Transformateur',
                'Zone': 'Dakar',
              },
            ),
          ),
        ),
      );

      // Vérifier que l'icône est affichée
      expect(find.byIcon(Icons.settings), findsOneWidget);

      // Vérifier que le texte principal est affiché
      expect(find.text('Code:'), findsOneWidget);
      expect(find.text('EQ001'), findsOneWidget);

      // Vérifier que les champs sont affichés
      expect(find.text('Famille:'), findsOneWidget);
      expect(find.text('Transformateur'), findsOneWidget);
      expect(find.text('Zone:'), findsOneWidget);
      expect(find.text('Dakar'), findsOneWidget);

      // Vérifier que l'icône de flèche est présente
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('equipment constructor creates correct widget', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListItemCustom.equipment(
              id: '1',
              codeParent: 'PARENT001',
              feeder: 'FEED001',
              feederDescription: 'Feeder principal',
              code: 'EQ001',
              famille: 'Transformateur',
              zone: 'Dakar',
              entity: 'SENELEC_DAKAR',
              unite: 'Unité Production',
              centre: 'CC_DAKAR_01',
              description: 'Transformateur test',
              longitude: '14.6937',
              latitude: '-17.4441',
            ),
          ),
        ),
      );

      // Vérifier que l'icône des équipements est affichée
      expect(find.byIcon(Icons.settings), findsOneWidget);

      // Vérifier que le code est affiché
      expect(find.text('Code:'), findsOneWidget);
      expect(find.text('EQ001'), findsOneWidget);

      // Vérifier que les champs principaux sont affichés
      expect(find.text('Famille:'), findsOneWidget);
      expect(find.text('Transformateur'), findsOneWidget);
      expect(find.text('Zone:'), findsOneWidget);
      expect(find.text('Dakar'), findsOneWidget);
    });

    testWidgets('order constructor creates correct widget', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListItemCustom.order(
              id: '1',
              code: 'OT001',
              famille: 'Maintenance',
              zone: 'Thiès',
              entity: 'SENELEC_THIES',
              unite: 'Unité Distribution',
              centre: 'CC_THIES_01',
              description: 'Ordre de travail test',
            ),
          ),
        ),
      );

      // Vérifier que l'icône des ordres de travail est affichée
      expect(find.byIcon(Icons.assignment), findsOneWidget);

      // Vérifier que le code est affiché
      expect(find.text('Code:'), findsOneWidget);
      expect(find.text('OT001'), findsOneWidget);

      // Vérifier que les champs sont affichés
      expect(find.text('Famille:'), findsOneWidget);
      expect(find.text('Maintenance'), findsOneWidget);
      expect(find.text('Zone:'), findsOneWidget);
      expect(find.text('Thiès'), findsOneWidget);
    });

    testWidgets('intervention constructor creates correct widget', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListItemCustom.intervention(
              id: '1',
              code: 'DI001',
              famille: 'Urgence',
              zone: 'Kaolack',
              entity: 'SENELEC_KAOLACK',
              unite: 'Unité Maintenance',
              centre: 'CC_KAOLACK_01',
              description: 'Demande d\'intervention urgente',
            ),
          ),
        ),
      );

      // Vérifier que l'icône des demandes d'intervention est affichée
      expect(find.byIcon(Icons.build), findsOneWidget);

      // Vérifier que le code est affiché
      expect(find.text('Code:'), findsOneWidget);
      expect(find.text('DI001'), findsOneWidget);

      // Vérifier que les champs sont affichés
      expect(find.text('Famille:'), findsOneWidget);
      expect(find.text('Urgence'), findsOneWidget);
      expect(find.text('Zone:'), findsOneWidget);
      expect(find.text('Kaolack'), findsOneWidget);
    });

    testWidgets('calls onTap when provided', (WidgetTester tester) async {
      bool wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListItemCustom(
              icon: Icons.settings,
              primaryText: 'EQ001',
              primaryLabel: 'Code',
              fields: [ItemField(label: 'Famille', value: 'Transformateur')],
              overlayDetails: {'Code': 'EQ001'},
              onTap: () {
                wasTapped = true;
              },
            ),
          ),
        ),
      );

      // Appuyer sur l'élément
      await tester.tap(find.byType(ListItemCustom));
      await tester.pumpAndSettle();

      // Vérifier que la fonction onTap a été appelée
      expect(wasTapped, true);
    });

    testWidgets('applies custom colors correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListItemCustom(
              icon: Icons.settings,
              primaryText: 'EQ001',
              primaryLabel: 'Code',
              fields: [ItemField(label: 'Famille', value: 'Transformateur')],
              overlayDetails: {'Code': 'EQ001'},
              backgroundColor: Colors.red,
              textColor: Colors.white,
              iconColor: Colors.blue,
            ),
          ),
        ),
      );

      // Vérifier que le container principal a la bonne couleur de fond
      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(GestureDetector),
              matching: find.byType(Container),
            )
            .first,
      );
      expect((container.decoration as BoxDecoration).color, Colors.red);

      // Vérifier que l'icône a la bonne couleur de fond
      final iconContainer = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(GestureDetector),
              matching: find.byType(Container),
            )
            .at(1),
      );
      expect((iconContainer.decoration as BoxDecoration).color, Colors.blue);
    });

    testWidgets('shows overlay when tapped and no onTap provided', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListItemCustom(
              icon: Icons.settings,
              primaryText: 'EQ001',
              primaryLabel: 'Code',
              fields: [ItemField(label: 'Famille', value: 'Transformateur')],
              overlayDetails: {'Code': 'EQ001', 'Famille': 'Transformateur'},
              overlayTitle: 'Détails de test',
            ),
          ),
        ),
      );

      // Appuyer sur l'élément pour ouvrir l'overlay
      await tester.tap(find.byType(ListItemCustom));
      await tester.pumpAndSettle();

      // Vérifier que l'overlay est affiché
      expect(find.text('Détails de test'), findsOneWidget);
    });
  });

  group('ItemField Tests', () {
    test('creates ItemField correctly', () {
      final field = ItemField(label: 'Zone', value: 'Dakar');

      expect(field.label, 'Zone');
      expect(field.value, 'Dakar');
    });
  });
}
