import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appmobilegmao/widgets/custom_buttons.dart';

void main() {
  group('PrimaryButton Tests', () {
    testWidgets('renders correctly with text and icon', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              text: 'Valider',
              icon: Icons.check,
              onPressed: () {},
            ),
          ),
        ),
      );

      // Vérifier que le texte et l'icône sont affichés
      expect(find.text('Valider'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('displays loading indicator when isLoading is true', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              text: 'Valider',
              isLoading: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      // Utiliser pump() au lieu de pumpAndSettle() pour éviter le timeout
      await tester.pump();

      // Vérifier que le CircularProgressIndicator est affiché
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Vérifier que le texte n'est pas affiché
      expect(find.text('Valider'), findsNothing);
    });

    testWidgets('is disabled when isLoading is true', (
      WidgetTester tester,
    ) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              text: 'Valider',
              isLoading: true,
              onPressed: () {
                wasPressed = true;
              },
            ),
          ),
        ),
      );

      // Utiliser pump() au lieu de pumpAndSettle()
      await tester.pump();

      // Trouver le bouton ElevatedButton sous-jacent
      final elevatedButton = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );

      // Vérifier que le bouton sous-jacent a onPressed = null
      expect(elevatedButton.onPressed, isNull);

      // Essayer de taper sur le bouton (cela ne devrait rien faire)
      await tester.tap(find.byType(PrimaryButton));
      await tester.pump(); // Utiliser pump() au lieu de pumpAndSettle()

      // Vérifier que la fonction n'a pas été appelée
      expect(wasPressed, false);
    });

    testWidgets('calls onPressed when tapped', (WidgetTester tester) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              text: 'Valider',
              onPressed: () {
                wasPressed = true;
              },
            ),
          ),
        ),
      );

      // Appuyer sur le bouton
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      // Vérifier que le bouton a été pressé
      expect(wasPressed, true);
    });
  });

  group('SecondaryButton Tests', () {
    testWidgets('renders correctly with text and icon', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecondaryButton(
              text: 'Annuler',
              icon: Icons.close,
              onPressed: () {},
            ),
          ),
        ),
      );

      // Vérifier que le texte et l'icône sont affichés
      expect(find.text('Annuler'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('displays loading indicator when isLoading is true', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecondaryButton(
              text: 'Annuler',
              isLoading: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      // Utiliser pump() au lieu de pumpAndSettle()
      await tester.pump();

      // Vérifier que le CircularProgressIndicator est affiché
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Vérifier que le texte n'est pas affiché
      expect(find.text('Annuler'), findsNothing);
    });

    testWidgets('is disabled when isLoading is true', (
      WidgetTester tester,
    ) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecondaryButton(
              text: 'Annuler',
              isLoading: true,
              onPressed: () {
                wasPressed = true;
              },
            ),
          ),
        ),
      );

      // Utiliser pump() au lieu de pumpAndSettle()
      await tester.pump();

      // Trouver le bouton OutlinedButton sous-jacent
      final outlinedButton = tester.widget<OutlinedButton>(
        find.byType(OutlinedButton),
      );

      // Vérifier que le bouton sous-jacent a onPressed = null
      expect(outlinedButton.onPressed, isNull);

      // Essayer de taper sur le bouton (cela ne devrait rien faire)
      await tester.tap(find.byType(SecondaryButton));
      await tester.pump(); // Utiliser pump() au lieu de pumpAndSettle()

      // Vérifier que la fonction n'a pas été appelée
      expect(wasPressed, false);
    });

    testWidgets('calls onPressed when tapped', (WidgetTester tester) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecondaryButton(
              text: 'Annuler',
              onPressed: () {
                wasPressed = true;
              },
            ),
          ),
        ),
      );

      // Appuyer sur le bouton
      await tester.tap(find.byType(SecondaryButton));
      await tester.pumpAndSettle();

      // Vérifier que le bouton a été pressé
      expect(wasPressed, true);
    });
  });
}
