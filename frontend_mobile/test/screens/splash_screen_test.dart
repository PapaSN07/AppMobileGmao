import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appmobilegmao/screens/splash_screen.dart';
import 'package:provider/provider.dart';
import 'package:appmobilegmao/provider/auth_provider.dart';
import 'package:appmobilegmao/provider/equipment_provider.dart';
import 'package:appmobilegmao/provider/notification_provider.dart';
import 'dart:io';
import 'package:hive/hive.dart';

void main() {
  setUpAll(() {
    Hive.init(Directory.systemTemp.path);
  });

  group('SplashScreen Tests', () {
    Widget createWidget() {
      final authProvider = AuthProvider();
      return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authProvider),
          ChangeNotifierProvider(create: (_) => EquipmentProvider(authProvider)),
          ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ],
        child: const MaterialApp(home: SplashScreen(testMode: true)),
      );
    }

    testWidgets('renders correctly with all components', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidget());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(
        find.image(const AssetImage('assets/images/logo.png')),
        findsOneWidget,
      );
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Flush 5s timer + 600ms page transition
      await tester.pump(const Duration(seconds: 6));
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('displays logo with correct fit', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidget());
      await tester.pump(const Duration(milliseconds: 500));

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.fit, BoxFit.contain);

      await tester.pump(const Duration(seconds: 6));
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('displays LinearProgressIndicator with correct color', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidget());
      await tester.pump(const Duration(milliseconds: 500));

      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(
        (progressIndicator.valueColor as AlwaysStoppedAnimation).value,
        equals(AppTheme.senelecOrange),
      );

      await tester.pump(const Duration(seconds: 6));
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('renders centered layout', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump(const Duration(milliseconds: 500));

      final center = find.byType(Center);
      expect(center, findsWidgets);

      final column = find.descendant(
        of: find.byType(Center),
        matching: find.byType(Column)
      ).first;
      expect(column, findsOneWidget);

      await tester.pump(const Duration(seconds: 6));
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('renders specific texts', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidget());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('GMAO'), findsOneWidget);
      expect(find.text('Initialisation des modules...'), findsOneWidget);

      await tester.pump(const Duration(seconds: 6));
      await tester.pump(const Duration(seconds: 1));
    });
  });
}
