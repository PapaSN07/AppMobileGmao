import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:appmobilegmao/screens/equipments/equipment_screen.dart';
import 'package:appmobilegmao/provider/equipment_provider.dart';
import 'package:appmobilegmao/provider/auth_provider.dart';

import 'dart:io';
import 'package:hive/hive.dart';

void main() {
  setUpAll(() {
    Hive.init(Directory.systemTemp.path);
  });

  testWidgets('EquipmentScreen renders correctly', (WidgetTester tester) async {
    final authProvider = AuthProvider();
    final equipmentProvider = EquipmentProvider(authProvider);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authProvider),
          ChangeNotifierProvider.value(value: equipmentProvider),
        ],
        child: const MaterialApp(home: EquipmentScreen()),
      ),
    );

    expect(find.byType(EquipmentScreen), findsOneWidget);
    expect(find.textContaining('Équipement'), findsWidgets);
  });
}
