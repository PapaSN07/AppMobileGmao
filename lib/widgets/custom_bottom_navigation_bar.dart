import 'package:appmobilegmao/provider/auth_provider.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/utils/responsive.dart';
import 'package:appmobilegmao/theme/responsive_spacing.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final spacing = context.spacing;

    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // ✅ Déterminer les items selon le rôle
        final items =
            authProvider.isPrestataire
                ? _buildPrestataireItems(responsive)
                : _buildLdapItems(responsive);

        return Container(
          height: responsive.spacing(100), // ✅ Hauteur responsive
          decoration: BoxDecoration(
            color: AppTheme.secondaryColor, // Couleur de fond
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20), // Coins arrondis en haut à gauche
              topRight: Radius.circular(20), // Coins arrondis en haut à droite
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.small,
            ), // ✅ Padding responsive
            child: BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: onTap,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor:
                  AppTheme.primaryColor, // Couleur des éléments sélectionnés
              unselectedItemColor:
                  AppTheme
                      .primaryColor75, // Couleur des éléments non sélectionnés
              selectedLabelStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: responsive.sp(12), // ✅ Taille de texte responsive
                fontFamily: AppTheme.fontRoboto,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: responsive.sp(11), // ✅ Taille de texte responsive
                fontFamily: AppTheme.fontRoboto,
              ),
              items: items,
            ),
          ),
        );
      },
    );
  }

  // ✅ Items pour PRESTATAIRE (2 onglets)
  List<BottomNavigationBarItem> _buildPrestataireItems(Responsive responsive) {
    return [
      BottomNavigationBarItem(
        icon: Icon(
          Icons.shopping_bag_outlined,
          size: responsive.iconSize(24), // ✅ Icône responsive
        ),
        activeIcon: Icon(
          Icons.shopping_bag,
          size: responsive.iconSize(24), // ✅ Icône responsive
        ),
        label: 'Équipements',
      ),
      BottomNavigationBarItem(
        icon: Icon(
          Icons.history_outlined,
          size: responsive.iconSize(24), // ✅ Icône responsive
        ),
        activeIcon: Icon(
          Icons.history,
          size: responsive.iconSize(24), // ✅ Icône responsive
        ),
        label: 'Historiques',
      ),
    ];
  }

  // ✅ Items pour LDAP (4 onglets)
  List<BottomNavigationBarItem> _buildLdapItems(Responsive responsive) {
    return [
      BottomNavigationBarItem(
        icon: Icon(
          Icons.home_outlined,
          size: responsive.iconSize(24), // ✅ Icône responsive
        ),
        activeIcon: Icon(
          Icons.home,
          size: responsive.iconSize(24), // ✅ Icône responsive
        ),
        label: 'Accueil',
      ),
      BottomNavigationBarItem(
        icon: Icon(
          Icons.shopping_bag_outlined,
          size: responsive.iconSize(24), // ✅ Icône responsive
        ),
        activeIcon: Icon(
          Icons.shopping_bag,
          size: responsive.iconSize(24), // ✅ Icône responsive
        ),
        label: 'Équipements',
      ),
      BottomNavigationBarItem(
        icon: Icon(
          Icons.assignment_outlined,
          size: responsive.iconSize(24), // ✅ Icône responsive
        ),
        activeIcon: Icon(
          Icons.assignment,
          size: responsive.iconSize(24), // ✅ Icône responsive
        ),
        label: 'OT',
      ),
      BottomNavigationBarItem(
        icon: Icon(
          Icons.build_outlined,
          size: responsive.iconSize(24), // ✅ Icône responsive
        ),
        activeIcon: Icon(
          Icons.build,
          size: responsive.iconSize(24), // ✅ Icône responsive
        ),
        label: 'DI',
      ),
    ];
  }
}
