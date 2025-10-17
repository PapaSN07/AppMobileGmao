import 'package:appmobilegmao/screens/settings/profile_screen.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:appmobilegmao/utils/responsive.dart';
import 'package:appmobilegmao/theme/responsive_spacing.dart';

class ProfilMenu extends StatelessWidget {
  final String nom;
  final String prenom;
  final String email;
  final String role;
  final Function() onLogout;
  final bool isLoading;

  const ProfilMenu({
    super.key,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.role,
    required this.onLogout,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final spacing = context.spacing;

    if (isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.primaryColor,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.secondaryColor),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.secondaryColor,
      // ✅ AJOUTÉ: AppBar standard pour uniformité avec main_screen.dart
      appBar: AppBar(
        title: Text(
          'Paramètres',
          style: TextStyle(
            fontFamily: AppTheme.fontMontserrat,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: responsive.sp(20), // ✅ Texte responsive
          ),
        ),
        backgroundColor: AppTheme.secondaryColor,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: spacing.custom(all: 8), // ✅ Padding responsive
            decoration: BoxDecoration(
              color: AppTheme.primaryColor20,
              borderRadius: BorderRadius.circular(
                responsive.spacing(8),
              ), // ✅ Border radius responsive
            ),
            child: Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: responsive.iconSize(20), // ✅ Icône responsive
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Retour',
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: spacing.custom(all: 8), // ✅ Padding responsive
              decoration: BoxDecoration(
                color: AppTheme.primaryColor20,
                borderRadius: BorderRadius.circular(
                  responsive.spacing(8),
                ), // ✅ Border radius responsive
              ),
              child: Icon(
                Icons.notifications_none,
                color: Colors.white,
                size: responsive.iconSize(20), // ✅ Icône responsive
              ),
            ),
            onPressed: () {},
            tooltip: 'Notifications',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.secondaryColor, AppTheme.secondaryColor80],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Contenu principal - Scrollable et taille adaptée
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      margin: spacing.custom(
                        horizontal: 15,
                        vertical: 20,
                      ), // ✅ Margin responsive
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(
                          Radius.circular(
                            responsive.spacing(20),
                          ), // ✅ Border radius responsive
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.boxShadowColor,
                            blurRadius: responsive.spacing(
                              20,
                            ), // ✅ Blur radius responsive
                            offset: Offset(
                              0,
                              responsive.spacing(-5),
                            ), // ✅ Offset responsive
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: spacing.custom(
                            horizontal: 10,
                            vertical: 20,
                          ), // ✅ Padding responsive
                          child: Column(
                            children: [
                              // Photo de profil avec taille réduite
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: responsive.spacing(
                                      100,
                                    ), // ✅ Largeur responsive
                                    height: responsive.spacing(
                                      100,
                                    ), // ✅ Hauteur responsive
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor10,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppTheme.secondaryColor,
                                        width: 3,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        "${prenom[0].toUpperCase()}${nom[0].toUpperCase()}",
                                        style: TextStyle(
                                          fontSize: responsive.sp(
                                            30,
                                          ), // ✅ Texte responsive
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.secondaryColor,
                                          fontFamily: AppTheme.fontMontserrat,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: spacing.custom(
                                        all: 8,
                                      ), // ✅ Padding responsive
                                      decoration: BoxDecoration(
                                        color: AppTheme.secondaryColor,
                                        borderRadius: BorderRadius.circular(
                                          responsive.spacing(10),
                                        ), // ✅ Border radius responsive
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.photo_camera,
                                        color: Colors.white,
                                        size: responsive.iconSize(
                                          16,
                                        ), // ✅ Icône responsive
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(
                                height: spacing.medium,
                              ), // ✅ Espacement responsive
                              // Nom complet
                              Text(
                                "$prenom $nom",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: responsive.sp(
                                    22,
                                  ), // ✅ Texte responsive
                                  fontFamily: AppTheme.fontMontserrat,
                                ),
                              ),

                              // Email
                              Text(
                                email,
                                style: TextStyle(
                                  color: AppTheme.thirdColor,
                                  fontSize: responsive.sp(
                                    14,
                                  ), // ✅ Texte responsive
                                  fontFamily: AppTheme.fontRoboto,
                                ),
                              ),

                              SizedBox(
                                height: spacing.tiny,
                              ), // ✅ Espacement responsive
                              // Rôle avec badge
                              Container(
                                padding: spacing.custom(
                                  horizontal: 12,
                                  vertical: 4,
                                ), // ✅ Padding responsive
                                decoration: BoxDecoration(
                                  color: AppTheme.secondaryColor10,
                                  borderRadius: BorderRadius.circular(
                                    responsive.spacing(16),
                                  ), // ✅ Border radius responsive
                                  border: Border.all(
                                    color: AppTheme.secondaryColor30,
                                  ),
                                ),
                                child: Text(
                                  role,
                                  style: TextStyle(
                                    color: AppTheme.secondaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: responsive.sp(
                                      12,
                                    ), // ✅ Texte responsive
                                    fontFamily: AppTheme.fontRoboto,
                                  ),
                                ),
                              ),

                              SizedBox(
                                height: spacing.xlarge,
                              ), // ✅ Espacement responsive
                              // Options de menu
                              Column(
                                children: [
                                  _profilMenuItem(
                                    Icons.person_outline,
                                    "Voir mon profil",
                                    () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const ProfileScreen(),
                                        ),
                                      );
                                    },
                                    AppTheme.secondaryColor,
                                    responsive,
                                    spacing,
                                  ),
                                  _buildDivider(responsive, spacing),
                                  _profilMenuItem(
                                    Icons.notifications_outlined,
                                    "Notifications",
                                    () {},
                                    AppTheme.secondaryColor,
                                    responsive,
                                    spacing,
                                  ),
                                  _buildDivider(responsive, spacing),
                                  _profilMenuItemWithValue(
                                    Icons.translate,
                                    "Langue",
                                    "Français",
                                    () {},
                                    AppTheme.secondaryColor,
                                    responsive,
                                    spacing,
                                  ),
                                  _buildDivider(responsive, spacing),
                                  _profilMenuItem(
                                    Icons.shield_outlined,
                                    "Conditions d'utilisation",
                                    () {},
                                    AppTheme.secondaryColor,
                                    responsive,
                                    spacing,
                                  ),
                                  _buildDivider(responsive, spacing),
                                  _profilMenuItem(
                                    Icons.help_outline,
                                    "Centre d'Aide",
                                    () {},
                                    AppTheme.secondaryColor,
                                    responsive,
                                    spacing,
                                  ),
                                  _buildDivider(responsive, spacing),
                                  _profilMenuItem(
                                    Icons.info_outline,
                                    "À propos",
                                    () {},
                                    AppTheme.secondaryColor,
                                    responsive,
                                    spacing,
                                  ),
                                  SizedBox(
                                    height: spacing.medium,
                                  ), // ✅ Espacement responsive
                                  // Bouton de déconnexion
                                  Container(
                                    margin: spacing.custom(
                                      horizontal: 16,
                                    ), // ✅ Margin responsive
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: onLogout,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        padding: spacing.custom(
                                          vertical: 14,
                                        ), // ✅ Padding responsive
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            responsive.spacing(12),
                                          ), // ✅ Border radius responsive
                                        ),
                                        elevation: 2,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.logout,
                                            size: responsive.iconSize(
                                              18,
                                            ), // ✅ Icône responsive
                                          ),
                                          SizedBox(
                                            width: spacing.small,
                                          ), // ✅ Espacement responsive
                                          Text(
                                            'Déconnexion',
                                            style: TextStyle(
                                              fontSize: responsive.sp(
                                                14,
                                              ), // ✅ Texte responsive
                                              fontWeight: FontWeight.bold,
                                              fontFamily:
                                                  AppTheme.fontMontserrat,
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: spacing.medium,
                                  ), // ✅ Espacement responsive
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ SUPPRIMÉ: _buildAppBar - plus nécessaire

  Widget _profilMenuItem(
    IconData icon,
    String label,
    VoidCallback onTap,
    Color iconColor,
    Responsive responsive,
    ResponsiveSpacing spacing,
  ) {
    return Container(
      margin: spacing.custom(horizontal: 4, vertical: 2), // ✅ Margin responsive
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          responsive.spacing(10),
        ), // ✅ Border radius responsive
        color: Colors.transparent,
      ),
      child: ListTile(
        leading: Container(
          padding: spacing.custom(all: 6), // ✅ Padding responsive
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(
              responsive.spacing(6),
            ), // ✅ Border radius responsive
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: responsive.iconSize(20),
          ), // ✅ Icône responsive
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: responsive.sp(14), // ✅ Texte responsive
            fontFamily: AppTheme.fontRoboto,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: responsive.iconSize(14), // ✅ Icône responsive
          color: AppTheme.thirdColor,
        ),
        onTap: onTap,
        contentPadding: spacing.custom(
          horizontal: 12,
          vertical: 2,
        ), // ✅ Padding responsive
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(responsive.spacing(10)),
        ), // ✅ Border radius responsive
      ),
    );
  }

  Widget _profilMenuItemWithValue(
    IconData icon,
    String label,
    String value,
    VoidCallback onTap,
    Color iconColor,
    Responsive responsive,
    ResponsiveSpacing spacing,
  ) {
    return Container(
      margin: spacing.custom(horizontal: 4, vertical: 2), // ✅ Margin responsive
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          responsive.spacing(10),
        ), // ✅ Border radius responsive
        color: Colors.transparent,
      ),
      child: ListTile(
        leading: Container(
          padding: spacing.custom(all: 6), // ✅ Padding responsive
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(
              responsive.spacing(6),
            ), // ✅ Border radius responsive
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: responsive.iconSize(20),
          ), // ✅ Icône responsive
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: responsive.sp(14), // ✅ Texte responsive
            fontFamily: AppTheme.fontRoboto,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                color: AppTheme.thirdColor,
                fontWeight: FontWeight.w500,
                fontSize: responsive.sp(12), // ✅ Texte responsive
              ),
            ),
            SizedBox(width: spacing.small), // ✅ Espacement responsive
            Icon(
              Icons.arrow_forward_ios,
              size: responsive.iconSize(14), // ✅ Icône responsive
              color: AppTheme.thirdColor,
            ),
          ],
        ),
        onTap: onTap,
        contentPadding: spacing.custom(
          horizontal: 12,
          vertical: 2,
        ), // ✅ Padding responsive
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(responsive.spacing(10)),
        ), // ✅ Border radius responsive
      ),
    );
  }

  Widget _buildDivider(Responsive responsive, ResponsiveSpacing spacing) {
    return Container(
      margin: spacing.custom(
        horizontal: 20,
        vertical: 4,
      ), // ✅ Margin responsive
      height: 1,
      color: AppTheme.thirdColor20,
    );
  }
}
