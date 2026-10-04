import 'package:appmobilegmao/widgets/custom_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:appmobilegmao/provider/auth_provider.dart';
import 'dart:io';
import 'package:hive/hive.dart';

void main() {
  setUpAll(() {
    Hive.init(Directory.systemTemp.path);
  });

  group('adapts to every phone', () {
    // Largeur × hauteur (points), zone système du bas (barre de gestes, 3 boutons), taille de police
    const screens = [Size(320, 568), Size(360, 640), Size(393, 852), Size(412, 915), Size(800, 1280)];
    const systemBars = [0.0, 24.0, 48.0];
    const fontScales = [1.0, 1.3, 2.0];

    for (final screen in screens) {
      for (final systemBar in systemBars) {
        for (final fontScale in fontScales) {
          testWidgets(
              'no overflow on ${screen.width.toInt()}×${screen.height.toInt()}, '
              'system bar $systemBar, font ×$fontScale', (tester) async {
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = screen;
            tester.view.padding = FakeViewPadding(bottom: systemBar);
            tester.view.viewPadding = FakeViewPadding(bottom: systemBar);
            tester.platformDispatcher.textScaleFactorTestValue = fontScale;
            addTearDown(tester.view.reset);
            addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

            await tester.pumpWidget(
              ChangeNotifierProvider.value(
                value: AuthProvider(),
                child: MaterialApp(
                  home: Scaffold(
                    bottomNavigationBar: CustomBottomNavigationBar(currentIndex: 1, onTap: (_) {}),
                  ),
                ),
              ),
            );

            // Une barre qui déborde lève une erreur « RenderFlex overflowed »
            expect(tester.takeException(), isNull);
            expect(find.text('Équipements'), findsOneWidget);

            // La zone système n'est comptée qu'une fois : pas de grande bande vide sous les icônes
            final bar = tester.getSize(find.byType(CustomBottomNavigationBar));
            expect(bar.height, lessThanOrEqualTo(110 + systemBar));
          });
        }
      }
    }
  });

  group('CustomBottomNavigationBar Tests', () {
    testWidgets('renders all navigation items correctly', (
      WidgetTester tester,
    ) async {
      int selectedIndex = 0;

      final authProvider = AuthProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
          ],
          child: MaterialApp(
            home: Scaffold(
              bottomNavigationBar: CustomBottomNavigationBar(
                currentIndex: selectedIndex,
                onTap: (index) {
                  selectedIndex = index;
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Accueil'), findsOneWidget);
      expect(find.text('Équipements'), findsOneWidget);
      expect(find.text('OT'), findsOneWidget);
      expect(find.text('DI'), findsOneWidget);

      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.shopping_bag_outlined), findsOneWidget);
      expect(find.byIcon(Icons.assignment_outlined), findsOneWidget);
      expect(find.byIcon(Icons.build_outlined), findsOneWidget);
    });

    testWidgets('calls onTap when an item is tapped', (
      WidgetTester tester,
    ) async {
      int selectedIndex = 0;

      final authProvider = AuthProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
          ],
          child: MaterialApp(
            home: Scaffold(
              bottomNavigationBar: CustomBottomNavigationBar(
                currentIndex: selectedIndex,
                onTap: (index) {
                  selectedIndex = index;
                },
              ),
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
      final authProvider = AuthProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
          ],
          child: MaterialApp(
            home: Scaffold(
              bottomNavigationBar: CustomBottomNavigationBar(
                currentIndex: 1, // Sélectionner "Équipements"
                onTap: (_) {},
              ),
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
