import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/widgets/bottom_navigation_bar.dart';
import 'package:appmobilegmao/widgets/custom_overlay.dart';
import 'package:appmobilegmao/widgets/overlay_content.dart';
import 'package:flutter/material.dart';
import 'dart:ui'; // Import nécessaire pour ImageFilter

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
      body: _bodyContent(),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: 0, // Index de la page actuelle
        onTap: (index) {
          // Logique de navigation en fonction de l'index
          setState(() {
            // Mettre à jour l'index sélectionné si nécessaire
          });
        },
      ),
      backgroundColor: AppTheme.primaryColor,
    );
  }

  PreferredSize _appBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(56), // Hauteur de l'AppBar
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
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

  Widget _bodyContent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardSectionOne(),
            SizedBox(height: 20),
            _cardSectionTwo(),
          ],
        ),
      ),
    );
  }

  Widget _cardSectionOne() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      decoration: BoxDecoration(
        color: AppTheme.blurColor,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [_boxOne(), _boxTwo()],
      ),
    );
  }

  Widget _boxOne() {
    return Container(
      width: 170,
      height: 220,
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
                    fontSize: 16,
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

  Widget _boxTwo() {
    return Container(
      width: 170,
      height: 220,
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
                    fontSize: 16,
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

  Widget _cardSectionTwo() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
        SizedBox(height: 10),
        _boxThree(),
      ],
    );
  }

  Widget _boxThree() {
    return SizedBox(
      height: 364, // Hauteur fixe pour la zone scrollable
      child: ListView.builder(
        itemCount: 5, // Nombre d'éléments dans la liste
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(
              bottom: 10,
            ), // Espacement entre les items
            child: _itemBuilder(),
          );
        },
      ),
    );
  }

  Widget _itemBuilder() {
    return GestureDetector(
      onTap: () {
        // Afficher l'overlay plein écran
        showGeneralDialog(
          context: context,
          barrierDismissible: true,
          barrierLabel:
              MaterialLocalizations.of(context).modalBarrierDismissLabel,
          barrierColor:
              AppTheme
                  .primaryColor15, // Transparent car on gère le flou nous-mêmes
          transitionDuration: Duration(milliseconds: 300),
          pageBuilder: (BuildContext buildContext, Animation animation, Animation secondaryAnimation) {
          return CustomOverlay(
            onClose: () {
              Navigator.of(context).pop(); // Fermer l'overlay
            },
            content: OverlayContent(
              title: 'Détails',
              details: {
                'Code': '#12345',
                'Description': 'Lorem ipsum dolor sit amet.',
                'Famille': '#12345',
                'Zone': 'Dakar',
                'Entité': 'Lorem Ipsum',
                'Unité': 'Lorem Ipsum',
                'Centre': 'Lorem Ipsum',
              },
            ),
          );
        },
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.secondaryColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 56, // Taille du cercle
              height: 56, // Taille du cercle
              decoration: BoxDecoration(
                color:
                    AppTheme.primaryColor, // Couleur de fond du cercle (bleu)
                shape: BoxShape.rectangle, // Forme rectangulaire
                borderRadius: BorderRadius.circular(15), // Coins arrondis
              ),
              child: Icon(
                Icons.assignment, // Icône à afficher
                size: 30, // Taille de l'icône
                color: AppTheme.secondaryColor, // Couleur de l'icône (blanc)
              ),
            ),
            SizedBox(width: 10), // Ajout d'espace entre l'icône et les textes
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Code: #12345',
                        style: TextStyle(
                          fontFamily: AppTheme.fontMontserrat,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                          fontSize: 18,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Transform(
                        transform: Matrix4.rotationZ(-0.785398),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.arrow_back,
                          size: 24,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Famille: #12345',
                        style: TextStyle(
                          fontFamily: AppTheme.fontRoboto,
                          fontWeight: FontWeight.normal,
                          color: AppTheme.primaryColor,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Zone: Dakar',
                        style: TextStyle(
                          fontFamily: AppTheme.fontRoboto,
                          fontWeight: FontWeight.normal,
                          color: AppTheme.primaryColor,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Entité: Lorem',
                        style: TextStyle(
                          fontFamily: AppTheme.fontRoboto,
                          fontWeight: FontWeight.normal,
                          color: AppTheme.primaryColor,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Centre: Dakar',
                        style: TextStyle(
                          fontFamily: AppTheme.fontRoboto,
                          fontWeight: FontWeight.normal,
                          color: AppTheme.primaryColor,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
