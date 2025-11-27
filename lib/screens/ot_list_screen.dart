import 'package:flutter/material.dart';
import 'package:appmobilegmao/models/order.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/utils/responsive.dart';
import 'package:appmobilegmao/theme/responsive_spacing.dart';
import 'package:appmobilegmao/screens/ot_detail_screen.dart';
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
    ),
  );

  /// Navigation vers l'écran de détails d'un OT spécifique
  /// Principe SOLID: Single Responsibility - méthode dédiée à la navigation
  void _navigateToDetail(Order order) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => OTDetailScreen(order: order)),
    );
  }

  /// Gestion des actions de la barre de navigation
  /// Principe SOLID: méthodes séparées pour chaque action
  void _handleHomeNavigation() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Navigation vers Accueil')));
    Navigator.pop(context);
  }

  void _handleOTNavigation() {
    // Déjà sur la page OT
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Vous êtes sur la page OT')));
  }

  void _handleDINavigation() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Navigation vers DI')));
  }

  void _handleEquipmentNavigation() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigation vers Équipements')),
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

          // Barre de navigation en bas de l'écran
          // Principe SOLID: widget séparé avec responsabilité unique
          _BottomNavigationBar(
            onHomePressed: _handleHomeNavigation,
            onOTPressed: _handleOTNavigation,
            onDIPressed: _handleDINavigation,
            onEquipmentPressed: _handleEquipmentNavigation,
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
                      Text(
                        'Famille : ${order.famille}',
                        style: TextStyle(
                          fontFamily: AppTheme.fontRoboto,
                          fontWeight: FontWeight.normal,
                          color: Colors.white,
                          fontSize: responsive.sp(12),
                        ),
                      ),
                      Text(
                        'Zone : ${order.zone}',
                        style: TextStyle(
                          fontFamily: AppTheme.fontRoboto,
                          fontWeight: FontWeight.normal,
                          color: Colors.white,
                          fontSize: responsive.sp(12),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.tiny),

                  // Ligne 3: Entité et Centre alignés
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Entité : ${order.entity}',
                        style: TextStyle(
                          fontFamily: AppTheme.fontRoboto,
                          fontWeight: FontWeight.normal,
                          color: Colors.white,
                          fontSize: responsive.sp(12),
                        ),
                      ),
                      Text(
                        'Center: ${order.centre}',
                        style: TextStyle(
                          fontFamily: AppTheme.fontRoboto,
                          fontWeight: FontWeight.normal,
                          color: Colors.white,
                          fontSize: responsive.sp(12),
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

/// Widget pour afficher la barre de navigation en bas de l'écran
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage de la barre de navigation
/// Principe DRY: Widget réutilisable séparé du code principal
class _BottomNavigationBar extends StatelessWidget {
  final VoidCallback onHomePressed;
  final VoidCallback onOTPressed;
  final VoidCallback onDIPressed;
  final VoidCallback onEquipmentPressed;

  const _BottomNavigationBar({
    required this.onHomePressed,
    required this.onOTPressed,
    required this.onDIPressed,
    required this.onEquipmentPressed,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: spacing.custom(vertical: 12, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Bouton Accueil
          _NavButton(icon: Icons.home, label: 'Accueil', onTap: onHomePressed),

          // Bouton OT (actif)
          _NavButton(
            icon: Icons.calendar_today,
            label: 'OT',
            onTap: onOTPressed,
            isActive: true,
          ),

          // Bouton DI
          _NavButton(
            icon: Icons.precision_manufacturing,
            label: 'DI',
            onTap: onDIPressed,
          ),

          // Bouton Équipements
          _NavButton(
            icon: Icons.navigation,
            label: 'Équipements',
            onTap: onEquipmentPressed,
          ),
        ],
      ),
    );
  }
}

/// Widget pour un bouton de navigation individuel
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage d'un bouton
/// Principe DRY: Widget réutilisable pour tous les boutons de navigation
class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: responsive.iconSize(24)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTheme.fontRoboto,
                color: Colors.white,
                fontSize: responsive.sp(12),
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
