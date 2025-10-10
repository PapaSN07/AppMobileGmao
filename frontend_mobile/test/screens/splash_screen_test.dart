import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appmobilegmao/screens/splash_screen.dart';

void main() {
  group('SplashScreen Tests', () {
    Widget createWidget() {
      return const MaterialApp(home: SplashScreen());
    }

    testWidgets('renders correctly with all components', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidget());
      await tester.pump(
        const Duration(milliseconds: 100),
      ); // Remplace pumpAndSettle

      // Vérifier que le SplashScreen est rendu
      expect(find.byType(SplashScreen), findsOneWidget);

      // Vérifier que l'image du logo est présente
      expect(find.byType(Image), findsOneWidget);
      expect(
        find.image(const AssetImage('assets/images/logo.png')),
        findsOneWidget,
      );

      // Vérifier que le CircularProgressIndicator est présent
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Vérifier qu'aucune erreur ne survient
      expect(tester.takeException(), isNull);
    });

    testWidgets('displays logo with correct dimensions', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidget());
      await tester.pump(
        const Duration(milliseconds: 100),
      ); // Remplace pumpAndSettle

      // Vérifier que l'image a les bonnes dimensions
      final image = tester.widget<Image>(find.byType(Image));
      expect(image.width, 200);
      expect(image.height, 200);
      expect(image.fit, BoxFit.cover);
    });

    testWidgets('displays CircularProgressIndicator with correct color', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidget());
      await tester.pump(
        const Duration(milliseconds: 100),
      ); // Remplace pumpAndSettle

      // Vérifier que le CircularProgressIndicator a la bonne couleur
      final progressIndicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(
        (progressIndicator.valueColor as AlwaysStoppedAnimation).value,
        equals(AppTheme.secondaryColor),
      );
    });

    testWidgets('renders centered layout', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump(
        const Duration(milliseconds: 100),
      ); // Remplace pumpAndSettle

      // Vérifier que le contenu est centré
      final column = find.byType(Column);
      expect(column, findsOneWidget);

      final columnWidget = tester.widget<Column>(column);
      expect(columnWidget.mainAxisAlignment, MainAxisAlignment.center);

      final center = find.byType(Center);
      expect(center, findsOneWidget);
    });

    testWidgets('renders spacing between logo and progress indicator', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidget());
      await tester.pump(
        const Duration(milliseconds: 100),
      ); // Remplace pumpAndSettle

      // Vérifier qu'il y a un SizedBox avec une hauteur de 20 entre les widgets
      final sizedBox = find.byType(SizedBox);
      expect(sizedBox, findsOneWidget);

      final sizedBoxWidget = tester.widget<SizedBox>(sizedBox);
      expect(sizedBoxWidget.height, 20);
    });
  });
}
