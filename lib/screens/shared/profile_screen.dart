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
      backgroundColor:
          AppTheme.secondaryColor, // ✅ CHANGÉ: Fond bleu pour voir les boutons
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.secondaryColor, // ✅ CHANGÉ: Commence par bleu
              AppTheme.secondaryColor.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // AppBar personnalisée avec meilleur contraste
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(
                          0.3,
                        ), // ✅ AMÉLIORÉ: Plus de contraste
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 24, // ✅ RÉDUIT: Taille plus adaptée
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Mon Profil',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: AppTheme.fontMontserrat,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(
                          0.3,
                        ), // ✅ AMÉLIORÉ: Plus de contraste
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.notifications_none,
                          color: Colors.white,
                          size: 24, // ✅ RÉDUIT: Taille plus adaptée
                        ),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10), // ✅ RÉDUIT: Moins d'espace
              // Contenu principal - Scrollable et taille adaptée
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                  ), // ✅ RÉDUIT: Marges plus petites
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(
                        24,
                      ), // ✅ RÉDUIT: Coins moins arrondis
                      topRight: Radius.circular(24),
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
                    // ✅ AJOUTÉ: Rendre scrollable
                    child: Padding(
                      padding: const EdgeInsets.all(
                        20,
                      ), // ✅ RÉDUIT: Padding plus petit
                      child: Column(
                        children: [
                          // Photo de profil avec taille réduite
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 100, // ✅ RÉDUIT: Taille plus petite
                                height: 100,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.secondaryColor,
                                    width: 3, // ✅ RÉDUIT: Bordure plus fine
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    "${prenom[0].toUpperCase()}${nom[0].toUpperCase()}",
                                    style: TextStyle(
                                      fontSize:
                                          30, // ✅ RÉDUIT: Police plus petite
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
                                  padding: const EdgeInsets.all(
                                    8,
                                  ), // ✅ RÉDUIT: Padding plus petit
                                  decoration: BoxDecoration(
                                    color: AppTheme.secondaryColor,
                                    borderRadius: BorderRadius.circular(
                                      10,
                                    ), // ✅ RÉDUIT: Coins moins arrondis
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2, // ✅ RÉDUIT: Bordure plus fine
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.photo_camera,
                                    color: Colors.white,
                                    size: 16, // ✅ RÉDUIT: Icône plus petite
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(
                            height: 20,
                          ), // ✅ RÉDUIT: Moins d'espace
                          // Nom complet
                          Text(
                            "$prenom $nom",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 22, // ✅ RÉDUIT: Police plus petite
                              fontFamily: AppTheme.fontMontserrat,
                            ),
                          ),

                          const SizedBox(height: 6), // ✅ RÉDUIT: Moins d'espace
                          // Email
                          Text(
                            email,
                            style: TextStyle(
                              color: AppTheme.thirdColor,
                              fontSize: 14, // ✅ RÉDUIT: Police plus petite
                              fontFamily: AppTheme.fontRoboto,
                            ),
                          ),

                          const SizedBox(height: 4),

                          // Rôle avec badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ), // ✅ RÉDUIT: Padding plus petit
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                16,
                              ), // ✅ RÉDUIT: Coins moins arrondis
                              border: Border.all(
                                color: AppTheme.secondaryColor.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              role,
                              style: TextStyle(
                                color: AppTheme.secondaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12, // ✅ RÉDUIT: Police plus petite
                                fontFamily: AppTheme.fontRoboto,
                              ),
                            ),
                          ),

                          const SizedBox(
                            height: 24,
                          ), // ✅ RÉDUIT: Moins d'espace
                          // Options de menu
                          Column(
                            // ✅ CHANGÉ: Column au lieu de ListView pour éviter les conflits de scroll
                            children: [
                              _profilMenuItem(
                                Icons.person_outline,
                                "Modifier Profil",
                                () {},
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

                              // ✅ IMPORTANT: Bouton de déconnexion maintenant visible
                              Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                width:
                                    double
                                        .infinity, // ✅ AJOUTÉ: Largeur complète
                                child: ElevatedButton(
                                  onPressed: onLogout,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ), // ✅ RÉDUIT: Padding plus petit
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(
                                        Icons.logout,
                                        size: 18,
                                      ), // ✅ RÉDUIT: Icône plus petite
                                      SizedBox(width: 8),
                                      Text(
                                        'Déconnexion',
                                        style: TextStyle(
                                          fontSize:
                                              14, // ✅ RÉDUIT: Police plus petite
                                          fontWeight: FontWeight.bold,
                                          fontFamily: AppTheme.fontMontserrat,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: 20,
                              ), // ✅ AJOUTÉ: Espace en bas pour le scroll
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profilMenuItem(
    IconData icon,
    String label,
    VoidCallback onTap,
    Color iconColor,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 2,
      ), // ✅ RÉDUIT: Marges plus petites
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          10,
        ), // ✅ RÉDUIT: Coins moins arrondis
        color: Colors.transparent,
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(6), // ✅ RÉDUIT: Padding plus petit
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(
              6,
            ), // ✅ RÉDUIT: Coins moins arrondis
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ), // ✅ RÉDUIT: Icône plus petite
        ),
        title: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14, // ✅ RÉDUIT: Police plus petite
            fontFamily: AppTheme.fontRoboto,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 14, // ✅ RÉDUIT: Icône plus petite
          color: AppTheme.thirdColor,
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 2,
        ), // ✅ RÉDUIT: Padding plus petit
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
      margin: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 2,
      ), // ✅ RÉDUIT: Marges plus petites
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          10,
        ), // ✅ RÉDUIT: Coins moins arrondis
        color: Colors.transparent,
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(6), // ✅ RÉDUIT: Padding plus petit
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(
              6,
            ), // ✅ RÉDUIT: Coins moins arrondis
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ), // ✅ RÉDUIT: Icône plus petite
        ),
        title: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14, // ✅ RÉDUIT: Police plus petite
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
                fontSize: 12, // ✅ RÉDUIT: Police plus petite
              ),
            ),
            const SizedBox(width: 6), // ✅ RÉDUIT: Moins d'espace
            Icon(
              Icons.arrow_forward_ios,
              size: 14, // ✅ RÉDUIT: Icône plus petite
              color: AppTheme.thirdColor,
            ),
          ],
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 2,
        ), // ✅ RÉDUIT: Padding plus petit
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 4,
      ), // ✅ RÉDUIT: Marges plus petites
      height: 1,
      color: AppTheme.thirdColor.withOpacity(0.2),
    );
  }
}
