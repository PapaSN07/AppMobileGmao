import 'package:appmobilegmao/models/order.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/widgets/work_order_item.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Exemple de données pour l'ordre de travail
  final Order order = Order(
    id: '1',
    icon: Icons.assignment,
    code: '#12345',
    famille: 'Famille 1',
    zone: 'Dakar',
    entity: 'Lorem Ipsum',
    unite: 'DK, SN',
    centre: 'Centre 1',
    description: 'Description de l\'ordre de travail',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(),
      body: _bodyContent(),
      backgroundColor: AppTheme.primaryColor,
    );
  }

  // Méthodes pour construire l'AppBar et le contenu du corps
  PreferredSize _appBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(56), // Hauteur de l'AppBar
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
        ), // Espacement gauche et droite
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.primaryColor, // Couleur de fond de l'AppBar
            borderRadius: BorderRadius.circular(10),
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

  // Méthodes pour construire le contenu du corps
  Widget _bodyContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardSectionOne(),
          const SizedBox(height: 20),
          Expanded(
            // Permet à _cardSectionTwo de prendre tout l'espace restant
            child: _cardSectionTwo(),
          ),
        ],
      ),
    );
  }

  // Méthodes pour construire les sections de cartes
  // Section 1: Deux cartes côte à côte
  // Section 2: Liste d'ordres de travail
  // Chaque section est construite avec des widgets personnalisés
  // pour une meilleure lisibilité et réutilisation du code.
  Widget _cardSectionOne() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      decoration: BoxDecoration(
        color: AppTheme.blurColor,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          // Box 1 adaptative
          Expanded(
            child: AspectRatio(
              aspectRatio: 170 / 200, // ratio largeur / hauteur d’origine
              child: _boxOne(),
            ),
          ),
          const SizedBox(width: 10),
          // Box 2 adaptative
          Expanded(
            child: AspectRatio(aspectRatio: 170 / 200, child: _boxTwo()),
          ),
        ],
      ),
    );
  }

  // Méthode pour construire la première boîte de la section 1
  Widget _boxOne() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          // Contenu principal
          Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start, // Aligne tout à gauche
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 50, // Taille du cercle
                      height: 50, // Taille du cercle
                      decoration: BoxDecoration(
                        color:
                            AppTheme
                                .secondaryColor, // Couleur de fond du cercle (bleu)
                        shape: BoxShape.circle, // Forme circulaire
                      ),
                      child: Icon(
                        Icons.assignment, // Icône à afficher
                        size: 24, // Taille de l'icône
                        color:
                            AppTheme.primaryColor, // Couleur de l'icône (blanc)
                      ),
                    ),
                    Transform(
                      transform: Matrix4.rotationZ(
                        -0.785398,
                      ), // Inclinaison de 45 degrés (en radians)
                      alignment: Alignment.center, // Centre de rotation
                      child: Icon(
                        Icons.arrow_back, // Icône à afficher
                        size: 24, // Taille de l'icône
                        color:
                            AppTheme
                                .secondaryColor, // Couleur de l'icône (blanc)
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  'Order de Travail',
                  style: TextStyle(
                    fontFamily: AppTheme.fontMontserrat,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondaryColor,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'De',
                      style: TextStyle(
                        fontFamily: AppTheme.fontMontserrat,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.thirdColor,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '22',
                      style: TextStyle(
                        fontFamily: AppTheme.fontMontserrat,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondaryColor,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Image positionnée en bas du container
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
              child: SizedBox(
                height: 80, // Hauteur fixe pour l'image
                child: Image.asset(
                  'assets/images/bg_card.png',
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Méthode pour construire la deuxième boîte de la section 1
  Widget _boxTwo() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          // Contenu principal
          Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 50, // Taille du cercle
                      height: 50, // Taille du cercle
                      decoration: BoxDecoration(
                        color:
                            AppTheme
                                .secondaryColor, // Couleur de fond du cercle (bleu)
                        shape: BoxShape.circle, // Forme circulaire
                      ),
                      child: Icon(
                        Icons.build, // Icône à afficher
                        size: 24, // Taille de l'icône
                        color:
                            AppTheme.primaryColor, // Couleur de l'icône (blanc)
                      ),
                    ),
                    Transform(
                      transform: Matrix4.rotationZ(
                        -0.785398,
                      ), // Inclinaison de 45 degrés (en radians)
                      alignment: Alignment.center, // Centre de rotation
                      child: Icon(
                        Icons.arrow_back, // Icône à afficher
                        size: 24, // Taille de l'icône
                        color:
                            AppTheme
                                .secondaryColor, // Couleur de l'icône (blanc)
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  'Demande d\'Intervention',
                  style: TextStyle(
                    fontFamily: AppTheme.fontMontserrat,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondaryColor,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.start,
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'De',
                      style: TextStyle(
                        fontFamily: AppTheme.fontMontserrat,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.thirdColor,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '22',
                      style: TextStyle(
                        fontFamily: AppTheme.fontMontserrat,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondaryColor,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Image positionnée en bas du container
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
              child: SizedBox(
                height: 80, // Hauteur fixe pour l'image
                child: Image.asset(
                  'assets/images/bg_card.png',
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Méthode pour construire la deuxième section de cartes
  Widget _cardSectionTwo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '5 Ordres de Travail en cours',
          style: TextStyle(
            fontFamily: AppTheme.fontMontserrat,
            fontWeight: FontWeight.normal,
            color: AppTheme.thirdColor,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          // Permet à _boxThree de prendre tout l'espace restant
          child: _boxThree(),
        ),
      ],
    );
  }

  // Méthode pour construire la zone scrollable avec les ordres de travail
  Widget _boxThree() {
    return ListView.builder(
      padding: EdgeInsets.zero, // Supprime le padding par défaut
      itemCount: 5, // Augmenté pour tester le scroll
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(
            bottom: 10,
          ), // Espacement entre les items
          child: _itemBuilder(),
        );
      },
    );
  }

  // Méthode pour construire un item de la liste des ordres de travail
  Widget _itemBuilder() {
    return WorkOrderItem(
      order: order,
      overlayDetails: {
        'Code': order.code,
        'Description': order.description,
        'Famille': order.famille,
        'Zone': order.zone,
        'Entité': order.entity,
        'Unité': order.unite,
        'Centre': order.centre,
      },
    );
  }
}
