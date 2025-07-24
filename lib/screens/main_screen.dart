import 'package:flutter/material.dart';
import 'package:appmobilegmao/screens/home_screen.dart';
import 'package:appmobilegmao/screens/ot/ot_screen.dart';
import 'package:appmobilegmao/screens/di/di_screen.dart';
import 'package:appmobilegmao/screens/equipments/equipment_screen.dart';
import 'package:appmobilegmao/widgets/bottom_navigation_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Créer les pages avec injection des services
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    // Initialiser les pages avec les services injectés
    _pages = [
      const HomeScreen(),
      EquipmentScreen(),
      const OtScreen(),
      const DiScreen(),
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
