import 'package:flutter/material.dart';
import 'package:appmobilegmao/models/order.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/utils/responsive.dart';
import 'package:appmobilegmao/theme/responsive_spacing.dart';
import 'package:appmobilegmao/screens/ot_info_details_screen.dart';
import 'package:appmobilegmao/widgets/custom_app_bar.dart';

/// Écran qui affiche la liste des Ordres de Travail (OT)
/// Principe SOLID: Single Responsibility - Cet écran est responsable uniquement de l'affichage de la liste des OT
class OTListScreen extends StatefulWidget {
  const OTListScreen({Key? key}) : super(key: key);

  @override
  State<OTListScreen> createState() => _OTListScreenState();
}

class _OTListScreenState extends State<OTListScreen> {
  // Génération de données de test pour simuler 10 ordres de travail
  // En production, ces données viendront d'une API ou d'une base de données
  final List<Order> otOrders = List.generate(
    5,
    (index) => Order(
      id: '$index',
      icon: Icons.assignment,
      code: 'LM04213981GH',
      famille: 'LMU801981321',
      zone: 'Dakar',
      entity: 'LOREM',
      unite: 'Unité $index',
      centre: 'Dakar',
      description: 'Description de l\'ordre de travail $index',
      status: 'OUV',
      // MODIFICATION: Taux de realisation fictif pour les donnees de demonstration
      completionRate: 45.0,
    ),
  );

  /// Navigation vers l'écran d'informations détaillées d'un OT spécifique
  /// Principe SOLID: Single Responsibility - méthode dédiée à la navigation
  void _navigateToDetail(Order order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OTInfoDetailsScreen(otNumber: order.code),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Récupération des utilitaires responsive et spacing depuis le contexte
    // pour adapter l'interface à différentes tailles d'écran
    final responsive = context.responsive;
    final spacing = context.spacing;

    return Scaffold(
      backgroundColor: Colors.white,
      // Barre d'application en haut de l'écran avec menu hamburger
      appBar: CustomAppBar(
        title: 'Liste des ordres de travail',
        showBackButton: false,
        backgroundColor: Colors.white,
        titleColor: AppTheme.secondaryColor,
        iconColor: AppTheme.secondaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: AppTheme.secondaryColor),
            onPressed: () {
              // TODO: Ouvrir le drawer/menu
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Affichage du nombre d'ordres de travail
          Padding(
            padding: spacing.custom(horizontal: 16, top: 16, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${otOrders.length} Derniers Ordre de Travail',
                style: TextStyle(
                  fontFamily: AppTheme.fontRoboto,
                  fontWeight: FontWeight.normal,
                  color: AppTheme.thirdColor,
                  fontSize: responsive.sp(14),
                ),
              ),
            ),
          ),

          // Liste scrollable des ordres de travail avec cartes bleues
          // Principe SOLID: Expanded permet à la ListView de prendre l'espace disponible
          Expanded(
            child: ListView.builder(
              padding: spacing.custom(horizontal: 16, bottom: 16),
              itemCount: otOrders.length,
              itemBuilder: (context, index) {
                final order = otOrders[index];
                return Padding(
                  padding: spacing.custom(bottom: 12),
                  // Widget réutilisable pour chaque carte OT
                  // Principe DRY: évite la duplication de code
                  child: _OTCard(
                    order: order,
                    onTap: () => _navigateToDetail(order),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget pour afficher une carte d'ordre de travail avec design bleu arrondi
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage d'une carte OT
/// Principe DRY: Widget réutilisable pour tous les OT de la liste
class _OTCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;

  const _OTCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final spacing = context.spacing;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: spacing.custom(all: 12),
        decoration: BoxDecoration(
          color: AppTheme.secondaryColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icône document à gauche dans un carré blanc arrondi
            Container(
              width: responsive.wp(14),
              height: responsive.wp(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.format_list_bulleted,
                color: AppTheme.secondaryColor,
                size: responsive.iconSize(28),
              ),
            ),
            SizedBox(width: spacing.medium),

            // Informations de l'ordre de travail
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ligne 1: Code de l'OT avec icône flèche cliquable
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Code : ${order.code}',
                          style: TextStyle(
                            fontFamily: AppTheme.fontMontserrat,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: responsive.sp(15),
                          ),
                        ),
                      ),
                      // Icône flèche cliquable en haut à droite
                      InkWell(
                        onTap: onTap,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: responsive.iconSize(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.tiny),

                  // Ligne 2: Famille et Zone alignés
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Famille : ${order.famille}',
                          style: TextStyle(
                            fontFamily: AppTheme.fontRoboto,
                            fontWeight: FontWeight.normal,
                            color: Colors.white,
                            fontSize: responsive.sp(12),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: spacing.tiny),
                      Flexible(
                        child: Text(
                          'Zone : ${order.zone}',
                          style: TextStyle(
                            fontFamily: AppTheme.fontRoboto,
                            fontWeight: FontWeight.normal,
                            color: Colors.white,
                            fontSize: responsive.sp(12),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.tiny),

                  // Ligne 3: Entité et Centre alignés
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Entité : ${order.entity}',
                          style: TextStyle(
                            fontFamily: AppTheme.fontRoboto,
                            fontWeight: FontWeight.normal,
                            color: Colors.white,
                            fontSize: responsive.sp(12),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: spacing.tiny),
                      Flexible(
                        child: Text(
                          'Center: ${order.centre}',
                          style: TextStyle(
                            fontFamily: AppTheme.fontRoboto,
                            fontWeight: FontWeight.normal,
                            color: Colors.white,
                            fontSize: responsive.sp(12),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
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
