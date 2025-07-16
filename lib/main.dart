import 'package:flutter/material.dart';
import 'package:appmobilegmao/screens/main_screen.dart'; // Import de MainScreen
import 'package:appmobilegmao/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GMAO',
      theme: ThemeData(primaryColor: AppTheme.primaryColor),
      home: const MainScreen(), // Utilisation de MainScreen comme page principale
      // debugShowCheckedModeBanner: false,
    );
  }
}
