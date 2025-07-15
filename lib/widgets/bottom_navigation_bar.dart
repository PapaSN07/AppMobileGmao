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
      child: BottomNavigationBar(
        type:
            BottomNavigationBarType
                .fixed, // Force l'utilisation de la couleur personnalisée
        backgroundColor:
            Colors
                .transparent, // Transparent pour laisser le Container gérer la couleur
        elevation: 0, // Supprime l'ombre
        items: const [
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(
                top: 8,
              ), // Ajuste l'icône pour réduire l'espace
              child: Icon(Icons.home),
            ),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 8),
              child: Icon(
                Icons.assignment,
              ), // Icône pour Ordre de Transfert (OT)
            ),
            label: 'OT',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 8),
              child: Icon(
                Icons.build,
              ), // Icône pour Demande d'Intervention (DI)
            ),
            label: 'DI',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 8),
              child: Icon(Icons.settings),
            ),
            label: 'Équipements',
          ),
        ],
        currentIndex: currentIndex, // Index de l'élément sélectionné
        selectedItemColor:
            AppTheme.primaryColor, // Couleur de l'élément sélectionné
        unselectedItemColor:
            AppTheme.primaryColor75, // Couleur des éléments non sélectionnés
        selectedLabelStyle: TextStyle(
          fontFamily: AppTheme.fontMontserrat,
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryColor,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: AppTheme.fontMontserrat,
          fontWeight: FontWeight.normal,
          color: AppTheme.primaryColor75,
        ),
        onTap: onTap, // Appelle la fonction passée en paramètre
      ),
    );
  }
}
