import 'package:appmobilegmao/theme/app_theme.dart';
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
      bottomNavigationBar: _bottomNavigationBar(),
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
              padding: EdgeInsets.only(
                top: 8,
              ), // Ajuste l'icône pour réduire l'espace
              child: Icon(
                Icons.assignment,
              ), // Icône pour Ordre de Transfert (OT)
            ),
            label: 'OT',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(
                top: 8,
              ), // Ajuste l'icône pour réduire l'espace
              child: Icon(
                Icons.build,
              ), // Icône pour Demande d'Intervention (DI)
            ),
            label: 'DI',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(
                top: 8,
              ), // Ajuste l'icône pour réduire l'espace
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
          pageBuilder: (
            BuildContext buildContext,
            Animation animation,
            Animation secondaryAnimation,
          ) {
            return _buildOverlay(buildContext);
          },
          transitionBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
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

  Widget _buildOverlay(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop(); // Fermer l'overlay lorsqu'on clique dessus
      },
      child: Stack(
        children: [
          // Effet de flou sur l'arrière-plan qui prend tout l'écran
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 10,
                sigmaY: 10,
              ), // Intensité du flou
              child: Container(
                color: AppTheme.primaryColor15, // Couleur semi-transparente
              ),
            ),
          ),
          // Contenu de l'overlay centré
          Center(
            child: GestureDetector(
              onTap:
                  () {}, // Empêche la fermeture lorsqu'on clique sur le contenu
              child: Container(
                width:
                    MediaQuery.of(context).size.width *
                    0.85, // 85% de la largeur
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Ajuste la taille du contenu
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      spacing: 20.0,
                      children: [
                        SizedBox(
                          width: 64, // Largeur fixe
                          height: 34, // Hauteur fixe
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop(); // Fermer l'overlay
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              padding:
                                  EdgeInsets
                                      .zero, // Supprime les marges internes
                            ),
                            child: Icon(
                              Icons.arrow_back,
                              size: 20, // Taille de l'icône
                              color: AppTheme.secondaryColor,
                            ),
                          ),
                        ),
                        Text(
                          'Détails',
                          style: TextStyle(
                            fontFamily: AppTheme.fontMontserrat,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: AppTheme.primaryColor,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 30),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Code',
                          style: TextStyle(
                            fontFamily: AppTheme.fontMontserrat,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: AppTheme.primaryColor,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          '#12345',
                          style: TextStyle(
                            fontFamily: AppTheme.fontRoboto,
                            fontWeight: FontWeight.normal,
                            fontSize: 14,
                            color: AppTheme.primaryColor,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        Divider(
                          color: AppTheme.primaryColor15, // Couleur du trait
                          thickness: 1, // Épaisseur du trait
                          indent: 0, // Espacement à gauche
                          endIndent: 0, // Espacement à droite
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    // Code
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Description',
                          style: TextStyle(
                            fontFamily: AppTheme.fontMontserrat,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: AppTheme.primaryColor,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
                          style: TextStyle(
                            fontFamily: AppTheme.fontRoboto,
                            fontWeight: FontWeight.normal,
                            fontSize: 14,
                            color: AppTheme.primaryColor,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        Divider(
                          color: AppTheme.primaryColor15, // Couleur du trait
                          thickness: 1, // Épaisseur du trait
                          indent: 0, // Espacement à gauche
                          endIndent: 0, // Espacement à droite
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    // Description
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Famille',
                          style: TextStyle(
                            fontFamily: AppTheme.fontMontserrat,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: AppTheme.primaryColor,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          '#12345',
                          style: TextStyle(
                            fontFamily: AppTheme.fontRoboto,
                            fontWeight: FontWeight.normal,
                            fontSize: 14,
                            color: AppTheme.primaryColor,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        Divider(
                          color: AppTheme.primaryColor15, // Couleur du trait
                          thickness: 1, // Épaisseur du trait
                          indent: 0, // Espacement à gauche
                          endIndent: 0, // Espacement à droite
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    // Famille
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Zone',
                          style: TextStyle(
                            fontFamily: AppTheme.fontMontserrat,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: AppTheme.primaryColor,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Dakar',
                          style: TextStyle(
                            fontFamily: AppTheme.fontRoboto,
                            fontWeight: FontWeight.normal,
                            fontSize: 14,
                            color: AppTheme.primaryColor,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        Divider(
                          color: AppTheme.primaryColor15, // Couleur du trait
                          thickness: 1, // Épaisseur du trait
                          indent: 0, // Espacement à gauche
                          endIndent: 0, // Espacement à droite
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    // Zone
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Entité',
                          style: TextStyle(
                            fontFamily: AppTheme.fontMontserrat,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: AppTheme.primaryColor,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Lorem Ipsum',
                          style: TextStyle(
                            fontFamily: AppTheme.fontRoboto,
                            fontWeight: FontWeight.normal,
                            fontSize: 14,
                            color: AppTheme.primaryColor,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        Divider(
                          color: AppTheme.primaryColor15, // Couleur du trait
                          thickness: 1, // Épaisseur du trait
                          indent: 0, // Espacement à gauche
                          endIndent: 0, // Espacement à droite
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    // Entité
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Unité',
                          style: TextStyle(
                            fontFamily: AppTheme.fontMontserrat,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: AppTheme.primaryColor,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Lorem Ipsum',
                          style: TextStyle(
                            fontFamily: AppTheme.fontRoboto,
                            fontWeight: FontWeight.normal,
                            fontSize: 14,
                            color: AppTheme.primaryColor,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        Divider(
                          color: AppTheme.primaryColor15, // Couleur du trait
                          thickness: 1, // Épaisseur du trait
                          indent: 0, // Espacement à gauche
                          endIndent: 0, // Espacement à droite
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    // Centre
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Centre',
                          style: TextStyle(
                            fontFamily: AppTheme.fontMontserrat,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: AppTheme.primaryColor,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Lorem Ipsum',
                          style: TextStyle(
                            fontFamily: AppTheme.fontRoboto,
                            fontWeight: FontWeight.normal,
                            fontSize: 14,
                            color: AppTheme.primaryColor,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        Divider(
                          color: AppTheme.primaryColor15, // Couleur du trait
                          thickness: 1, // Épaisseur du trait
                          indent: 0, // Espacement à gauche
                          endIndent: 0, // Espacement à droite
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
