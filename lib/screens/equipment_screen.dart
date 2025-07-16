import 'package:appmobilegmao/models/order.dart';
import 'package:appmobilegmao/screens/add_equipment_screen.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/widgets/work_order_item.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class EquipmentScreen extends StatefulWidget {
  const EquipmentScreen({super.key});

  @override
  State<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends State<EquipmentScreen> {
  final _formKey = GlobalKey<FormState>();
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
      backgroundColor: AppTheme.primaryColor,
      body: Stack(
        children: [
          // AppBar personnalisée
          Positioned(
            top: -70,
            left: 0,
            right: 0,
            child: Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(color: AppTheme.secondaryColor),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 0, left: 16, right: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.menu,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () {
                          // Action pour le menu
                        },
                      ),
                      const Text(
                        'Équipement',
                        style: TextStyle(
                          fontFamily: AppTheme.fontMontserrat,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddEquipmentScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Contenu du body
          Positioned(
            top: 156, // Commence après l'AppBar
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.only(
                top: 40, // Espace pour la carte qui déborde
                left: 0,
                right: 0,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Expanded(
                    child: SizedBox(
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: 20,
                          right: 16,
                          left: 16,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            _searchBar(),
                            SizedBox(height: 20),
                            _boxOne(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Carte des statistiques (au-dessus de tout)
          Positioned(
            top:
                136, // Position pour sortir de l'AppBar et être au-dessus du body
            left: 26,
            right: 26,
            child: Container(
              width: double.infinity,
              height: 90, // Hauteur définie
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
              decoration: BoxDecoration(
                color:
                    Colors
                        .white, // Changé en blanc comme dans l'image de référence
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatCard('222', 'OT'),
                  _buildStatCard('222', 'OT'),
                  _buildStatCard('222', 'OT'),
                  _buildStatCard('222', 'OT'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Méthode pour construire les cartes de statistiques
  Widget _buildStatCard(String value, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: AppTheme.fontMontserrat,
            fontWeight: FontWeight.bold,
            color:
                AppTheme
                    .secondaryColor, // Changé en noir pour contraster avec le fond blanc
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.fontRoboto,
            fontWeight: FontWeight.normal,
            color:
                AppTheme
                    .secondaryColor, // Changé en noir pour contraster avec le fond blanc
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // Méthode pour construire la barre de recherche
  Widget _searchBar() {
    return Form(
      key: _formKey,
      child: TextFormField(
        decoration: InputDecoration(
          labelText: 'Rechercher par...',
          labelStyle: TextStyle(
            color: AppTheme.thirdColor,
            fontFamily: AppTheme.fontRoboto,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          border: UnderlineInputBorder(),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppTheme.thirdColor),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppTheme.secondaryColor, width: 2.0),
          ),
          suffixIcon: IconButton(
            icon: Icon(Icons.search, color: AppTheme.secondaryColor),
            onPressed: () {
              setState(() {
                // Recherche
                if (kDebugMode) {
                  print("click search");
                }
              });
            },
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Veuillez entrer quelque chose';
          }
          return null;
        },
      ),
    );
  }

  // Méthode pour construire la liste des ordres de travail
  Widget _boxOne() {
    return Expanded(
      // Prend tout l'espace disponible
      child: ListView.builder(
        padding: EdgeInsets.zero, // Supprime le padding par défaut
        itemCount: 10, // Augmenté pour tester le scroll
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

  // Méthode pour construire un item de la liste
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
