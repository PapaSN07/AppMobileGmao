import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:appmobilegmao/screens/main_screen.dart';
import 'package:appmobilegmao/provider/equipment_provider.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/services/hive_service.dart';
import 'package:appmobilegmao/models/equipment_hive.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Hive
  await Hive.initFlutter();

  // Enregistrer les adaptateurs Hive
  Hive.registerAdapter(EquipmentHiveAdapter());
  Hive.registerAdapter(AttributeValueHiveAdapter());
  Hive.registerAdapter(ReferenceDataHiveAdapter());

  // Initialiser le service Hive
  await HiveService.init();

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
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
