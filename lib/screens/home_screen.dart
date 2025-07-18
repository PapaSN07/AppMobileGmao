import 'package:appmobilegmao/models/order.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/widgets/list_item.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // État pour gérer la liste affichée
  String selectedCategory = 'OT'; // Par défaut, "OT" est sélectionné

  // Exemple de données pour les listes
  final List<Order> otOrders = List.generate(
    5,
    (index) => Order(
      id: '$index',
      icon: Icons.assignment,
      code: '#OT12345$index',
      famille: 'Famille OT $index',
      zone: 'Zone OT $index',
      entity: 'Entité OT $index',
      unite: 'Unité OT $index',
      centre: 'Centre OT $index',
      description: 'Description de l\'ordre de travail OT $index',
    ),
  );

  final List<Order> diOrders = List.generate(
    5,
    (index) => Order(
      id: '$index',
      icon: Icons.build,
      code: '#DI12345$index',
      famille: 'Famille DI $index',
      zone: 'Zone DI $index',
      entity: 'Entité DI $index',
      unite: 'Unité DI $index',
      centre: 'Centre DI $index',
      description: 'Description de la demande d\'intervention DI $index',
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(),
      body: _bodyContent(),
      backgroundColor: AppTheme.primaryColor,
    );
  }

  PreferredSize _appBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(56),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: AppBar(
            title: const Text(
              'Bienvenue sur l\'accueil',
              style: TextStyle(
                fontFamily: AppTheme.fontMontserrat,
                fontWeight: FontWeight.w600,
                color: AppTheme.secondaryColor,
                fontSize: 20,
              ),
            ),
            backgroundColor: AppTheme.primaryColor,
            elevation: 0,
            scrolledUnderElevation: 0,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardSectionOne(),
          const SizedBox(height: 20),
          // Affichage du titre dynamique
          Text(
            selectedCategory == 'OT'
                ? '${otOrders.length} Ordres de Travail en cours'
                : '${diOrders.length} Demandes d\'Intervention en cours',
            style: TextStyle(
              fontFamily: AppTheme.fontMontserrat,
              fontWeight: FontWeight.normal,
              color: AppTheme.thirdColor,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child:
                  selectedCategory == 'OT'
                      ? _buildList(otOrders, 'OT')
                      : _buildList(diOrders, 'DI'),
            ),
          ),
        ],
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
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedCategory = 'OT';
                });
              },
              child: AspectRatio(aspectRatio: 170 / 200, child: _boxOne()),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedCategory = 'DI';
                });
              },
              child: AspectRatio(aspectRatio: 170 / 200, child: _boxTwo()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _boxOne() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(10),
        border:
            selectedCategory == 'OT'
                ? Border.all(color: AppTheme.secondaryColor, width: 2)
                : null,
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.assignment,
                        size: 24,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    Transform(
                      transform: Matrix4.rotationZ(-0.785398),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.arrow_back,
                        size: 24,
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Ordre de Travail',
                  style: TextStyle(
                    fontFamily: AppTheme.fontMontserrat,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondaryColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
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
                      '${otOrders.length}',
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
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
              child: SizedBox(
                height: 80,
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
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(10),
        border:
            selectedCategory == 'DI'
                ? Border.all(color: AppTheme.secondaryColor, width: 2)
                : null,
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.build,
                        size: 24,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    Transform(
                      transform: Matrix4.rotationZ(-0.785398),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.arrow_back,
                        size: 24,
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Demande d\'Intervention',
                  style: TextStyle(
                    fontFamily: AppTheme.fontMontserrat,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondaryColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
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
                      '${diOrders.length}',
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
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
              child: SizedBox(
                height: 80,
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

  Widget _buildList(List<Order> orders, String category) {
    return ListView.builder(
      key: ValueKey(category), // Clé unique pour chaque catégorie
      padding: EdgeInsets.zero,
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: ListItemCustom.order(
            id: order.id,
            code: order.code,
            famille: order.famille,
            zone: order.zone,
            entity: order.entity,
            unite: order.unite,
            centre: order.centre,
            description: order.description,
          ),
        );
      },
    );
  }
}
