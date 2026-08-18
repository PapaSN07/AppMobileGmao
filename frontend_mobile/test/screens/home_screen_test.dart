import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appmobilegmao/screens/home_screen.dart';
import 'package:appmobilegmao/provider/auth_provider.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:hive/hive.dart';

void main() {
  setUpAll(() {
    Hive.init(Directory.systemTemp.path);
  });

  group('HomeScreen Tests', () {
    Widget createWidget() {
      final authProvider = AuthProvider();
      return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authProvider),
        ],
        child: const MaterialApp(home: HomeScreen()),
      );
    }

    testWidgets('renders correctly without crashing', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));

      await tester.pumpWidget(createWidget());
      await tester.pump();

      // Check for some main elements to ensure it rendered
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Ordres de Travail'), findsWidgets);
      expect(find.text('Demandes d\'Intervention'), findsWidgets);

      expect(tester.takeException(), isNull);
    });
    
    testWidgets('can tap on DI category', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));

      await tester.pumpWidget(createWidget());
      await tester.pump();

      // Tap on DI card
      final diCard = find.text('Demandes d\'Intervention').first;
      await tester.tap(diCard);
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
