import 'package:flutter/material.dart';
import 'package:appmobilegmao/screens/home_screen.dart';
import 'package:appmobilegmao/screens/ot_screen.dart';
import 'package:appmobilegmao/screens/di_screen.dart';
import 'package:appmobilegmao/screens/equipment_screen.dart';
import 'package:appmobilegmao/widgets/bottom_navigation_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0; // Index de la page active

  final List<Widget> _pages = [
    const HomeScreen(),
    const OtScreen(),
    const DiScreen(),
    const EquipmentScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index; // Met à jour l'index actif
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex, // Affiche uniquement la page active
        children: _pages, // Liste des pages
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped, // Appelle la fonction de mise à jour
      ),
    );
  }
}
