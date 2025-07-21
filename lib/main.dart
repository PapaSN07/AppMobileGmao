import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appmobilegmao/screens/main_screen.dart';
import 'package:appmobilegmao/provider/equipment_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => EquipmentProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GMAO',
      theme: ThemeData(primaryColor: Colors.blue),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
