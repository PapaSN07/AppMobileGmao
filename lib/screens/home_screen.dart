import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(),
      body: Center(child: const Text('Bienvenue sur l’écran d’accueil !')),
      bottomNavigationBar: _bottomNavigationBar(),
      backgroundColor: AppTheme.primaryColor,
    );
  }

  PreferredSize _appBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(56), // Hauteur de l'AppBar
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 26,
        ), // Espacement gauche et droite
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.primaryColor, // Couleur de fond de l'AppBar
            borderRadius: BorderRadius.circular(
              10,
            ), // Coins arrondis (optionnel)
          ),
          child: AppBar(
            title: const Text(
              'Bienvenue sur l’accueil',
              style: TextStyle(
                fontFamily: AppTheme.fontMontserrat,
                fontWeight: FontWeight.w600,
                color: AppTheme.secondaryColor,
                fontSize: 20,
              ),
            ),
            backgroundColor: AppTheme.primaryColor,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.menu,
                color: AppTheme.secondaryColor,
                size: 28,
              ),
              onPressed: () {
                // Action pour le menu
              },
            ),
          ),
        ),
      ),
    );
  }

  Container _bottomNavigationBar() {
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
          BottomNavigationBarItem(icon: Padding(
            padding: EdgeInsets.only(top: 8), // Ajuste l'icône pour réduire l'espace
            child: Icon(Icons.home),
          ), label: 'Accueil'),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 8), // Ajuste l'icône pour réduire l'espace
              child: Icon(Icons.assignment), // Icône pour Ordre de Transfert (OT)
            ),
            label: 'OT',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 8), // Ajuste l'icône pour réduire l'espace
              child: Icon(Icons.build), // Icône pour Demande d'Intervention (DI)
            ),
            label: 'DI',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 8), // Ajuste l'icône pour réduire l'espace
              child: Icon(Icons.settings),
            ),
            label: 'Équipements',
          ),
        ],
        currentIndex: 0, // Index de l'élément sélectionné
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
        onTap: (index) {
          // Logique de navigation en fonction de l'index
          setState(() {
            // Mettre à jour l'index sélectionné si nécessaire
          });
        },
      ),
    );
  }
}
