import 'package:appmobilegmao/provider/auth_provider.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // ✅ Déterminer les items selon le rôle
        final items =
            authProvider.isPrestataire
                ? _buildPrestataireItems()
                : _buildLdapItems();

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
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor:
                  AppTheme.primaryColor, // Couleur des éléments sélectionnés
              unselectedItemColor:
                  AppTheme
                      .primaryColor75, // Couleur des éléments non sélectionnés
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                fontFamily: AppTheme.fontRoboto,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 11,
                fontFamily: AppTheme.fontRoboto,
              ),
              items: items,
            ),
          ),
        );
      },
    );
  }

  // ✅ Items pour PRESTATAIRE (2 onglets)
  List<BottomNavigationBarItem> _buildPrestataireItems() {
    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.shopping_bag_outlined),
        activeIcon: Icon(Icons.shopping_bag),
        label: 'Équipements',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.history_outlined),
        activeIcon: Icon(Icons.history),
        label: 'Historiques',
      ),
    ];
  }

  // ✅ Items pour LDAP (4 onglets)
  List<BottomNavigationBarItem> _buildLdapItems() {
    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Accueil',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.shopping_bag_outlined),
        activeIcon: Icon(Icons.shopping_bag),
        label: 'Équipements',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.assignment_outlined),
        activeIcon: Icon(Icons.assignment),
        label: 'OT',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.build_outlined),
        activeIcon: Icon(Icons.build),
        label: 'DI',
      ),
    ];
  }
}
