import 'package:flutter/material.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/utils/responsive.dart';
import 'package:appmobilegmao/theme/responsive_spacing.dart';

/// Écran qui affiche la liste des employés alloués à un Ordre de Travail
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage de la liste des employés alloués
class EmployesAllouesScreen extends StatefulWidget {
  const EmployesAllouesScreen({Key? key}) : super(key: key);

  @override
  State<EmployesAllouesScreen> createState() => _EmployesAllouesScreenState();
}

class _EmployesAllouesScreenState extends State<EmployesAllouesScreen> {
  // Liste des employés alloués (données d'exemple)
  final List<Map<String, String>> employesAlloues = [
    {
      'numero': '5893',
      'description': 'Marlon Mabika',
      'metier': 'Mécanicien',
      'dateDebut': '12/10/2024',
      'dateFin': '25/11/2024',
    },
    {
      'numero': '5893',
      'description': 'Marlon Mabika',
      'metier': 'Électricien',
      'dateDebut': '15/10/2024',
      'dateFin': '25/11/2024',
    },
    {
      'numero': '5893',
      'description': 'Marlon Mabika',
      'metier': 'Technicien',
      'dateDebut': '20/10/2024',
      'dateFin': '25/11/2024',
    },
    {
      'numero': '5893',
      'description': 'Marlon Mabika',
      'metier': 'Ingénieur',
      'dateDebut': '01/11/2024',
      'dateFin': '25/11/2024',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final responsive = context.responsive;

    return Scaffold(
      // Couleur de fond de l'écran
      backgroundColor: Colors.white,

      // Barre supérieure de l'application
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Employés Alloués',
          style: TextStyle(
            fontFamily: AppTheme.fontMontserrat,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: responsive.sp(20),
          ),
        ),
        centerTitle: true,
      ),

      body: Column(
        children: [
          // Barre d'actions en haut (icônes +, refresh, filter)
          _ActionToolbar(),

          // Liste scrollable des employés alloués
          Expanded(
            child: ListView.builder(
              padding: spacing.custom(horizontal: 16, vertical: 10),
              itemCount: employesAlloues.length,
              itemBuilder: (context, index) {
                final employe = employesAlloues[index];
                return Padding(
                  padding: spacing.custom(bottom: 10),
                  child: _EmployeAlloueCard(
                    numero: employe['numero']!,
                    description: employe['description']!,
                    metier: employe['metier']!,
                    dateDebut: employe['dateDebut']!,
                    dateFin: employe['dateFin']!,
                  ),
                );
              },
            ),
          ),

          // Barre de navigation en bas (Accueil, OT, DI)
          _BottomNavigationBar(),
        ],
      ),
    );
  }
}

/// Widget pour afficher la barre d'outils avec les actions (ajouter, actualiser, filtrer)
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage de la barre d'outils
class _ActionToolbar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Container(
      color: Colors.grey[200],
      padding: spacing.custom(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Titre "Action"
          Text(
            'Action',
            style: TextStyle(
              fontFamily: AppTheme.fontMontserrat,
              fontWeight: FontWeight.w600,
              color: AppTheme.secondaryColor,
              fontSize: 16,
            ),
          ),
          Spacer(),

          // Icône ajouter
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: AppTheme.primaryColor),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ajouter un employé')),
              );
            },
          ),

          // Icône actualiser
          IconButton(
            icon: Icon(Icons.refresh, color: AppTheme.primaryColor),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Actualiser la liste')),
              );
            },
          ),

          // Icône filtrer
          IconButton(
            icon: Icon(Icons.filter_list, color: AppTheme.primaryColor),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Filtrer les employés')),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Widget pour afficher une carte d'employé alloué avec un design en arrondi bleu
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage d'une carte employé
/// Principe DRY: Widget réutilisable pour tous les employés alloués
class _EmployeAlloueCard extends StatelessWidget {
  final String numero;
  final String description;
  final String metier;
  final String dateDebut;
  final String dateFin;

  const _EmployeAlloueCard({
    required this.numero,
    required this.description,
    required this.metier,
    required this.dateDebut,
    required this.dateFin,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final responsive = context.responsive;

    return Container(
      padding: spacing.custom(all: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icône de liste à gauche dans un cercle blanc
          Container(
            width: responsive.wp(12),
            height: responsive.wp(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.list_alt,
              color: AppTheme.primaryColor,
              size: responsive.iconSize(24),
            ),
          ),
          SizedBox(width: spacing.medium),

          // Informations de l'employé
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ligne 1: Employé : NUMERO
                Text(
                  'Employé : $numero',
                  style: TextStyle(
                    fontFamily: AppTheme.fontMontserrat,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: responsive.sp(16),
                  ),
                ),
                SizedBox(height: spacing.tiny),

                // Ligne 2: Description
                Text(
                  'Description: $description',
                  style: TextStyle(
                    fontFamily: AppTheme.fontRoboto,
                    fontWeight: FontWeight.normal,
                    color: Colors.white,
                    fontSize: responsive.sp(13),
                  ),
                ),
                SizedBox(height: spacing.tiny),

                // Ligne 3: Métier
                Text(
                  'Métier: $metier',
                  style: TextStyle(
                    fontFamily: AppTheme.fontRoboto,
                    fontWeight: FontWeight.normal,
                    color: Colors.white,
                    fontSize: responsive.sp(13),
                  ),
                ),
                SizedBox(height: spacing.tiny),

                // Ligne 4: Date de début
                Text(
                  'Date de début: $dateDebut',
                  style: TextStyle(
                    fontFamily: AppTheme.fontRoboto,
                    fontWeight: FontWeight.normal,
                    color: Colors.white,
                    fontSize: responsive.sp(13),
                  ),
                ),
                SizedBox(height: spacing.tiny),

                // Ligne 5: Date de fin
                Text(
                  'Date de fin: $dateFin',
                  style: TextStyle(
                    fontFamily: AppTheme.fontRoboto,
                    fontWeight: FontWeight.normal,
                    color: Colors.white,
                    fontSize: responsive.sp(13),
                  ),
                ),
              ],
            ),
          ),

          // Icône de validation à droite
          Icon(
            Icons.check_circle,
            color: Colors.white,
            size: responsive.iconSize(24),
          ),
        ],
      ),
    );
  }
}

/// Widget pour afficher la barre de navigation en bas de l'écran
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage de la barre de navigation
class _BottomNavigationBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Container(
      color: AppTheme.primaryColor,
      padding: spacing.custom(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Bouton Accueil
          _NavButton(
            icon: Icons.home,
            label: 'Accueil',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Navigation vers Accueil')),
              );
            },
          ),

          // Bouton OT
          _NavButton(
            icon: Icons.assignment,
            label: 'OT',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Navigation vers OT')),
              );
            },
          ),

          // Bouton DI
          _NavButton(
            icon: Icons.build,
            label: 'DI',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Navigation vers DI')),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Widget pour un bouton de navigation
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage d'un bouton
/// Principe DRY: Widget réutilisable pour tous les boutons de navigation
class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: responsive.iconSize(24)),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontRoboto,
              color: Colors.white,
              fontSize: responsive.sp(12),
            ),
          ),
        ],
      ),
    );
  }
}
