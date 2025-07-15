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
    return Container(
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
              color: AppTheme.primaryColor, // Couleur de fond du cercle (bleu)
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
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween, // Espacement automatique
                  children: [
                    Text(
                      'Code: #12345',
                      style: TextStyle(
                        fontFamily: AppTheme.fontMontserrat,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                        fontSize: 18,
                      ),
                      overflow:
                          TextOverflow.ellipsis, // Pour gérer le débordement
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
                            AppTheme.primaryColor, // Couleur de l'icône (blanc)
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween, // Espacement automatique
                  children: [
                    Text(
                      'Famille: #12345',
                      style: TextStyle(
                        fontFamily: AppTheme.fontRoboto,
                        fontWeight: FontWeight.normal,
                        color: AppTheme.primaryColor,
                        fontSize: 12,
                      ),
                      overflow:
                          TextOverflow.ellipsis, // Pour gérer le débordement
                    ),
                    Text(
                      'Zone: Dakar',
                      style: TextStyle(
                        fontFamily: AppTheme.fontRoboto,
                        fontWeight: FontWeight.normal,
                        color: AppTheme.primaryColor,
                        fontSize: 12,
                      ),
                      overflow:
                          TextOverflow.ellipsis, // Pour gérer le débordement
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween, // Espacement automatique
                  children: [
                    Text(
                      'Entité: Lorem',
                      style: TextStyle(
                        fontFamily: AppTheme.fontRoboto,
                        fontWeight: FontWeight.normal,
                        color: AppTheme.primaryColor,
                        fontSize: 12,
                      ),
                      overflow:
                          TextOverflow.ellipsis, // Pour gérer le débordement
                    ),
                    Text(
                      'Centre: Dakar',
                      style: TextStyle(
                        fontFamily: AppTheme.fontRoboto,
                        fontWeight: FontWeight.normal,
                        color: AppTheme.primaryColor,
                        fontSize: 12,
                      ),
                      overflow:
                          TextOverflow.ellipsis, // Pour gérer le débordement
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
