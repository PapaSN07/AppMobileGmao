import 'package:appmobilegmao/models/order.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/widgets/list_item.dart';
import 'package:appmobilegmao/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appmobilegmao/utils/responsive.dart';
import 'package:appmobilegmao/theme/responsive_spacing.dart';

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
      backgroundColor:
          AppTheme.primaryColor, // ✅ Fond transparent pour l'accueil
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final responsive = context.responsive;
    final spacing = context.spacing;

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Padding(
          padding: spacing.custom(
            horizontal: 20,
            vertical: 20,
          ), // ✅ Padding responsive
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _cardSectionOne(responsive, spacing),
              SizedBox(height: spacing.medium), // ✅ Espacement responsive
              // Affichage du titre dynamique
              Text(
                selectedCategory == 'OT'
                    ? '${otOrders.length} Ordres de Travail en cours'
                    : '${diOrders.length} Demandes d\'Intervention en cours',
                style: TextStyle(
                  fontFamily: AppTheme.fontMontserrat,
                  fontWeight: FontWeight.normal,
                  color: AppTheme.thirdColor,
                  fontSize: responsive.sp(15), // ✅ Texte responsive
                ),
              ),
              SizedBox(height: spacing.small), // ✅ Espacement responsive
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child:
                      selectedCategory == 'OT'
                          ? _buildList(otOrders, 'OT', responsive, spacing)
                          : _buildList(diOrders, 'DI', responsive, spacing),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _cardSectionOne(Responsive responsive, ResponsiveSpacing spacing) {
    return Container(
      padding: spacing.custom(
        horizontal: 15,
        vertical: 15,
      ), // ✅ Padding responsive
      decoration: BoxDecoration(
        color: AppTheme.blurColor,
        borderRadius: BorderRadius.circular(
          responsive.spacing(25),
        ), // ✅ Border radius responsive
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
              child: AspectRatio(
                aspectRatio: 170 / 200,
                child: _boxOne(responsive, spacing),
              ),
            ),
          ),
          SizedBox(width: spacing.small), // ✅ Espacement responsive
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedCategory = 'DI';
                });
              },
              child: AspectRatio(
                aspectRatio: 170 / 200,
                child: _boxTwo(responsive, spacing),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _boxOne(Responsive responsive, ResponsiveSpacing spacing) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(
          responsive.spacing(10),
        ), // ✅ Border radius responsive
        border:
            selectedCategory == 'OT'
                ? Border.all(color: AppTheme.secondaryColor, width: 2)
                : null,
      ),
      child: Stack(
        children: [
          Padding(
            padding: spacing.custom(all: 10), // ✅ Padding responsive
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: responsive.spacing(50), // ✅ Largeur responsive
                      height: responsive.spacing(50), // ✅ Hauteur responsive
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.assignment,
                        size: responsive.iconSize(24), // ✅ Icône responsive
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    Transform(
                      transform: Matrix4.rotationZ(-0.785398),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.arrow_back,
                        size: responsive.iconSize(24), // ✅ Icône responsive
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing.small), // ✅ Espacement responsive
                Text(
                  'Ordre de Travail',
                  style: TextStyle(
                    fontFamily: AppTheme.fontMontserrat,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondaryColor,
                    fontSize: responsive.sp(14), // ✅ Texte responsive
                  ),
                ),
                SizedBox(height: spacing.small), // ✅ Espacement responsive
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'De',
                      style: TextStyle(
                        fontFamily: AppTheme.fontMontserrat,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.thirdColor,
                        fontSize: responsive.sp(14), // ✅ Texte responsive
                      ),
                    ),
                    Text(
                      '${otOrders.length}',
                      style: TextStyle(
                        fontFamily: AppTheme.fontMontserrat,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondaryColor,
                        fontSize: responsive.sp(16), // ✅ Texte responsive
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
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(
                  responsive.spacing(8),
                ), // ✅ Border radius responsive
                bottomRight: Radius.circular(
                  responsive.spacing(8),
                ), // ✅ Border radius responsive
              ),
              child: SizedBox(
                height: responsive.spacing(80), // ✅ Hauteur responsive
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

  Widget _boxTwo(Responsive responsive, ResponsiveSpacing spacing) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(
          responsive.spacing(10),
        ), // ✅ Border radius responsive
        border:
            selectedCategory == 'DI'
                ? Border.all(color: AppTheme.secondaryColor, width: 2)
                : null,
      ),
      child: Stack(
        children: [
          Padding(
            padding: spacing.custom(all: 10), // ✅ Padding responsive
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: responsive.spacing(50), // ✅ Largeur responsive
                      height: responsive.spacing(50), // ✅ Hauteur responsive
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.build,
                        size: responsive.iconSize(24), // ✅ Icône responsive
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    Transform(
                      transform: Matrix4.rotationZ(-0.785398),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.arrow_back,
                        size: responsive.iconSize(24), // ✅ Icône responsive
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing.small), // ✅ Espacement responsive
                Text(
                  'Demande d\'Intervention',
                  style: TextStyle(
                    fontFamily: AppTheme.fontMontserrat,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondaryColor,
                    fontSize: responsive.sp(14), // ✅ Texte responsive
                  ),
                ),
                SizedBox(height: spacing.small), // ✅ Espacement responsive
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'De',
                      style: TextStyle(
                        fontFamily: AppTheme.fontMontserrat,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.thirdColor,
                        fontSize: responsive.sp(14), // ✅ Texte responsive
                      ),
                    ),
                    Text(
                      '${diOrders.length}',
                      style: TextStyle(
                        fontFamily: AppTheme.fontMontserrat,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondaryColor,
                        fontSize: responsive.sp(16), // ✅ Texte responsive
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
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(
                  responsive.spacing(8),
                ), // ✅ Border radius responsive
                bottomRight: Radius.circular(
                  responsive.spacing(8),
                ), // ✅ Border radius responsive
              ),
              child: SizedBox(
                height: responsive.spacing(80), // ✅ Hauteur responsive
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

  Widget _buildList(
    List<Order> orders,
    String category,
    Responsive responsive,
    ResponsiveSpacing spacing,
  ) {
    return ListView.builder(
      key: ValueKey(category), // Clé unique pour chaque catégorie
      padding: EdgeInsets.zero,
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return Padding(
          padding: spacing.custom(bottom: 10), // ✅ Padding responsive
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
