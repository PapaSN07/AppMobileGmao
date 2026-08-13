import 'package:appmobilegmao/widgets/custom_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appmobilegmao/theme/app_theme.dart';

void main() {
  group('CustomBottomNavigationBar Tests', () {
    testWidgets('renders all navigation items correctly', (
      WidgetTester tester,
    ) async {
      int selectedIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: CustomBottomNavigationBar(
              currentIndex: selectedIndex,
              onTap: (index) {
                selectedIndex = index;
              },
            ),
          ),
        ),
      );

      expect(find.text('Accueil'), findsOneWidget);
      expect(find.text('Équipements'), findsOneWidget);
      expect(find.text('OT'), findsOneWidget);
      expect(find.text('DI'), findsOneWidget);

      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.byIcon(Icons.assignment), findsOneWidget);
      expect(find.byIcon(Icons.build), findsOneWidget);
    });

    testWidgets('calls onTap when an item is tapped', (
      WidgetTester tester,
    ) async {
      int selectedIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: CustomBottomNavigationBar(
              currentIndex: selectedIndex,
              onTap: (index) {
                selectedIndex = index;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Équipements'));
      await tester.pumpAndSettle();
      expect(selectedIndex, 1);

      await tester.tap(find.text('OT'));
      await tester.pumpAndSettle();
      expect(selectedIndex, 2);
    });

    testWidgets('applies correct styles to selected and unselected items', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: CustomBottomNavigationBar(
              currentIndex: 1, // Sélectionner "Équipements"
              onTap: (_) {},
            ),
          ),
        ),
      );

      // Vérifier que l'élément sélectionné a la bonne couleur
      final selectedText = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(selectedText.selectedItemColor, AppTheme.primaryColor);

      // Vérifier que les éléments non sélectionnés ont la bonne couleur
      expect(selectedText.unselectedItemColor, AppTheme.primaryColor75);
    });
  });
}
