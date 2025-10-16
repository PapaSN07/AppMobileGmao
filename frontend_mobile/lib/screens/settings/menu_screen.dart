import 'package:appmobilegmao/screens/settings/profile_screen.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:flutter/material.dart';

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
        title: const Text(
          'Paramètres',
          style: TextStyle(
            fontFamily: AppTheme.fontMontserrat,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppTheme.secondaryColor,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor20,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Retour',
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor20,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.notifications_none,
                color: Colors.white,
                size: 20,
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
                      margin: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 20,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.boxShadowColor,
                            blurRadius: 20,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 20,
                          ),
                          child: Column(
                            children: [
                              // Photo de profil avec taille réduite
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
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
                                          fontSize: 30,
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
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppTheme.secondaryColor,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.photo_camera,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),
                              // Nom complet
                              Text(
                                "$prenom $nom",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                  fontFamily: AppTheme.fontMontserrat,
                                ),
                              ),

                              // Email
                              Text(
                                email,
                                style: TextStyle(
                                  color: AppTheme.thirdColor,
                                  fontSize: 14,
                                  fontFamily: AppTheme.fontRoboto,
                                ),
                              ),

                              const SizedBox(height: 4),

                              // Rôle avec badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.secondaryColor10,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppTheme.secondaryColor30,
                                  ),
                                ),
                                child: Text(
                                  role,
                                  style: TextStyle(
                                    color: AppTheme.secondaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    fontFamily: AppTheme.fontRoboto,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),
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
                                  ),
                                  _buildDivider(),
                                  _profilMenuItem(
                                    Icons.notifications_outlined,
                                    "Notifications",
                                    () {},
                                    AppTheme.secondaryColor,
                                  ),
                                  _buildDivider(),
                                  _profilMenuItemWithValue(
                                    Icons.translate,
                                    "Langue",
                                    "Français",
                                    () {},
                                    AppTheme.secondaryColor,
                                  ),
                                  _buildDivider(),
                                  _profilMenuItem(
                                    Icons.shield_outlined,
                                    "Conditions d'utilisation",
                                    () {},
                                    AppTheme.secondaryColor,
                                  ),
                                  _buildDivider(),
                                  _profilMenuItem(
                                    Icons.help_outline,
                                    "Centre d'Aide",
                                    () {},
                                    AppTheme.secondaryColor,
                                  ),
                                  _buildDivider(),
                                  _profilMenuItem(
                                    Icons.info_outline,
                                    "À propos",
                                    () {},
                                    AppTheme.secondaryColor,
                                  ),
                                  const SizedBox(height: 20),

                                  // Bouton de déconnexion
                                  Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: onLogout,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        elevation: 2,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: const [
                                          Icon(Icons.logout, size: 18),
                                          SizedBox(width: 8),
                                          Text(
                                            'Déconnexion',
                                            style: TextStyle(
                                              fontSize: 14,
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
                                  const SizedBox(height: 20),
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
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.transparent,
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            fontFamily: AppTheme.fontRoboto,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: AppTheme.thirdColor,
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _profilMenuItemWithValue(
    IconData icon,
    String label,
    String value,
    VoidCallback onTap,
    Color iconColor,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.transparent,
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
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
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.thirdColor),
          ],
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      height: 1,
      color: AppTheme.thirdColor20,
    );
  }
}
