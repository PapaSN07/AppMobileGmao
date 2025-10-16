import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appmobilegmao/widgets/custom_overlay.dart';

void main() {
  group('CustomOverlay Tests', () {
    testWidgets('renders correctly with content', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomOverlay(
              content: const Text('Overlay Content'),
              onClose: () {},
            ),
          ),
        ),
      );

      // Vérifier que le contenu est affiché
      expect(find.text('Overlay Content'), findsOneWidget);

      // Vérifier que l'arrière-plan avec effet de flou est présent
      expect(find.byType(BackdropFilter), findsOneWidget);
    });

    testWidgets('calls onClose when tapped outside the content', (
      WidgetTester tester,
    ) async {
      bool wasClosed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomOverlay(
              content: const Text('Overlay Content'),
              onClose: () {
                wasClosed = true;
              },
            ),
          ),
        ),
      );

      // Appuyer en dehors du contenu
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Vérifier que la fonction onClose a été appelée
      expect(wasClosed, true);
    });

    testWidgets('does not call onClose when isDismissible is false', (
      WidgetTester tester,
    ) async {
      bool wasClosed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomOverlay(
              content: const Text('Overlay Content'),
              onClose: () {
                wasClosed = true;
              },
              isDismissible: false,
            ),
          ),
        ),
      );

      // Appuyer en dehors du contenu
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Vérifier que la fonction onClose n'a pas été appelée
      expect(wasClosed, false);
    });

    testWidgets('does not close when tapping on the content', (
      WidgetTester tester,
    ) async {
      bool wasClosed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomOverlay(
              content: const Text('Overlay Content'),
              onClose: () {
                wasClosed = true;
              },
            ),
          ),
        ),
      );

      // Appuyer sur le contenu
      await tester.tap(find.text('Overlay Content'));
      await tester.pumpAndSettle();

      // Vérifier que la fonction onClose n'a pas été appelée
      expect(wasClosed, false);
    });

    testWidgets('applies custom width and maxHeight', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomOverlay(
              content: const Text('Overlay Content'),
              onClose: () {},
              width: 300,
              maxHeight: 400,
            ),
          ),
        ),
      );

      // Vérifier que les dimensions personnalisées sont appliquées
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(Center),
          matching: find.byType(Container),
        ),
      );

      final constraints = container.constraints as BoxConstraints;
      expect(constraints.maxWidth, 300);
      expect(constraints.maxHeight, 400);
    });
  });
}
