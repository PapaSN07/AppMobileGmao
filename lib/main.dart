import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appmobilegmao/screens/splash_screen.dart';
import 'package:appmobilegmao/provider/auth_provider.dart';
import 'package:appmobilegmao/provider/equipment_provider.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/services/hive_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser le service Hive (qui gère l'init et les adaptateurs)
  await HiveService.init();

  // HiveService.clearAllCache();  // Nettoyer le cache au démarrage

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => EquipmentProvider()),
        ChangeNotifierProvider(
          create: (context) => AuthProvider()..initialize(),
        ),
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
      title: 'GMAO - Senelec',
      theme: ThemeData(
        primaryColor: AppTheme.secondaryColor,
        fontFamily: AppTheme.fontRoboto,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTheme.secondaryColor,
          primary: AppTheme.secondaryColor,
          secondary: AppTheme.thirdColor,
        ),
        useMaterial3: true,
        textTheme: const TextTheme(
          headlineLarge: AppTheme.headline1,
          bodyLarge: AppTheme.bodyText1,
          bodyMedium: AppTheme.bodyText2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.secondaryColor,
            foregroundColor: AppTheme.primaryColor,
            textStyle: const TextStyle(
              fontFamily: AppTheme.fontMontserrat,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      // ✅ Commencer par le Splash Screen
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
