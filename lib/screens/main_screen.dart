import 'package:appmobilegmao/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:appmobilegmao/screens/home_screen.dart';
import 'package:appmobilegmao/screens/ot_screen.dart';
import 'package:appmobilegmao/screens/di_screen.dart';
import 'package:appmobilegmao/screens/equipment_screen.dart';
import 'package:appmobilegmao/services/equipment_service.dart';
import 'package:appmobilegmao/widgets/bottom_navigation_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Créer une instance du service
  final ApiService _apiService = ApiService();
  late final EquipmentService _equipmentService;

  // Créer les pages avec injection des services
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    // Initialisez les services spécifiques ici
    _equipmentService = EquipmentService(_apiService);

    // Initialiser les pages avec les services injectés
    _pages = [
      const HomeScreen(),
      const OtScreen(),
      const DiScreen(),
      EquipmentScreen(
        equipmentService: _equipmentService,
      ), // Injection du service
    ];
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
