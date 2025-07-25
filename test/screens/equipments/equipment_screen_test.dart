import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:appmobilegmao/screens/equipments/equipment_screen.dart';
import 'package:appmobilegmao/provider/equipment_provider.dart';

void main() {
  testWidgets('EquipmentScreen renders correctly', (WidgetTester tester) async {
    final equipmentProvider = EquipmentProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider.value(value: equipmentProvider)],
        child: const MaterialApp(home: EquipmentScreen()),
      ),
    );

    expect(find.byType(EquipmentScreen), findsOneWidget);
    expect(find.text('Équipements'), findsOneWidget);
  });
}
