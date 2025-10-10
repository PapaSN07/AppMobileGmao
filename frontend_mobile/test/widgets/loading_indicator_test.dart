import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appmobilegmao/widgets/loading_indicator.dart';
import 'package:appmobilegmao/theme/app_theme.dart';

void main() {
  group('LoadingIndicator Tests', () {
    testWidgets('renders CircularProgressIndicator', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: LoadingIndicator())),
      );

      // Vérifier que le CircularProgressIndicator est affiché
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('applies correct color from AppTheme', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: LoadingIndicator())),
      );

      // Vérifier que la couleur du CircularProgressIndicator est correcte
      final circularProgressIndicator = tester
          .widget<CircularProgressIndicator>(
            find.byType(CircularProgressIndicator),
          );
      expect(circularProgressIndicator.color, AppTheme.secondaryColor);
    });

    testWidgets('is centered on the screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: LoadingIndicator())),
      );

      // Vérifier que le widget est centré
      final center = find.byType(Center);
      expect(center, findsOneWidget);

      // Vérifier que le CircularProgressIndicator est un enfant de Center
      expect(
        find.descendant(
          of: center,
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
    });
  });
}
