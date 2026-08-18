import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:appmobilegmao/main.dart';
import 'package:appmobilegmao/provider/auth_provider.dart';
import 'package:appmobilegmao/provider/equipment_provider.dart';
import 'package:appmobilegmao/provider/notification_provider.dart';
import 'dart:io';
import 'package:hive/hive.dart';

void main() {
  setUpAll(() async {
    Hive.init(Directory.systemTemp.path);
    // Note: HiveService.init() removed - it uses path_provider plugin
    // which is not available in the test environment.
  });

  testWidgets('MyApp smoke test', (WidgetTester tester) async {
    final authProvider = AuthProvider();
    final equipmentProvider = EquipmentProvider(authProvider);
    final notificationProvider = NotificationProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authProvider),
          ChangeNotifierProvider.value(value: equipmentProvider),
          ChangeNotifierProvider.value(value: notificationProvider),
        ],
        child: const MyApp(),
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);

    // Flush pending timer from SplashScreen (5s delay + animation)
    await tester.pump(const Duration(seconds: 6));
  });
}
