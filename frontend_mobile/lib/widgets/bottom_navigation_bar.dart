import 'package:flutter/material.dart';
import 'package:appmobilegmao/theme/app_theme.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100, // Augmente la hauteur du BottomNavigationBar
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor, // Couleur de fond
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20), // Coins arrondis en haut à gauche
          topRight: Radius.circular(20), // Coins arrondis en haut à droite
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor:
              AppTheme.primaryColor, // Couleur des éléments sélectionnés
          unselectedItemColor:
              AppTheme.primaryColor75, // Couleur des éléments non sélectionnés
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(top: 8),
                child: Icon(Icons.home),
              ),
              label: 'Accueil',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(top: 8),
                child: Icon(Icons.settings),
              ),
              label: 'Équipements',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(top: 8),
                child: Icon(Icons.assignment),
              ),
              label: 'OT',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(top: 8),
                child: Icon(Icons.build),
              ),
              label: 'DI',
            ),
          ],
        ),
      ),
    );
  }
}
