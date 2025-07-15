import 'package:appmobilegmao/screens/home_screen.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GMAO',
      theme: ThemeData(primaryColor: AppTheme.primaryColor),
      home: const HomeScreen(),
      // debugShowCheckedModeBanner: false,
    );
  }
}
