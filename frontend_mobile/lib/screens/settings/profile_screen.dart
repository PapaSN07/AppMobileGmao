import 'package:appmobilegmao/provider/auth_provider.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/utils/string_utils.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:appmobilegmao/utils/responsive.dart';
import 'package:appmobilegmao/theme/responsive_spacing.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final spacing = context.spacing;

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          backgroundColor: AppTheme.secondaryColor,
          // ✅ AJOUTÉ: AppBar standard pour uniformité avec main_screen.dart
          appBar: AppBar(
            title: Text(
              'Mon Profil', // ✅ Titre ajusté pour la visualisation
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
                  // Contenu principal
                  Expanded(
                    child: Container(
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
                          padding: spacing.allPadding, // ✅ Padding responsive
                          child: Column(
                            children: [
                              // Photo de profil
                              _buildProfilePhoto(
                                authProvider,
                                responsive,
                                spacing,
                              ),

                              SizedBox(
                                height: spacing.xxlarge,
                              ), // ✅ Espacement responsive
                              // Section d'informations (visualisation seule)
                              _buildUserInfo(authProvider, responsive, spacing),

                              SizedBox(
                                height: spacing.medium,
                              ), // ✅ Espacement responsive
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
      },
    );
  }

  // ✅ SUPPRIMÉ: _buildAppBar - plus nécessaire

  Widget _buildProfilePhoto(
    AuthProvider authProvider,
    Responsive responsive,
    ResponsiveSpacing spacing,
  ) {
    final user = authProvider.currentUser;
    // ✅ UTILISATION: Parser le username avec la méthode utilitaire
    final userInfo = StringUtils.parseUserName(user?.username);
    final initiales = userInfo['initiales']!;
    return Container(
      width: responsive.spacing(120), // ✅ Largeur responsive
      height: responsive.spacing(120), // ✅ Hauteur responsive
      decoration: BoxDecoration(
        color: AppTheme.primaryColor10,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.secondaryColor, width: 3),
      ),
      child: ClipOval(
        child:
            user?.urlImage != null && user!.urlImage!.isNotEmpty
                ? Image.network(
                  user.urlImage!, // ✅ Afficher la photo enregistrée
                  width: responsive.spacing(120), // ✅ Largeur responsive
                  height: responsive.spacing(120), // ✅ Hauteur responsive
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // En cas d'erreur de chargement, afficher les initiales
                    return Center(
                      child: Text(
                        initiales,
                        style: TextStyle(
                          fontSize: responsive.sp(36), // ✅ Texte responsive
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondaryColor,
                          fontFamily: AppTheme.fontMontserrat,
                        ),
                      ),
                    );
                  },
                )
                : Center(
                  child: Text(
                    initiales,
                    style: TextStyle(
                      fontSize: responsive.sp(36), // ✅ Texte responsive
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondaryColor,
                      fontFamily: AppTheme.fontMontserrat,
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _buildUserInfo(
    AuthProvider authProvider,
    Responsive responsive,
    ResponsiveSpacing spacing,
  ) {
    final user = authProvider.currentUser;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormField(
          label: 'Username',
          value: user?.username ?? '',
          enabled: false,
          responsive: responsive,
          spacing: spacing,
        ),
        SizedBox(height: spacing.medium), // ✅ Espacement responsive

        _buildFormField(
          label: 'Email',
          value: user?.email ?? '',
          enabled: false,
          responsive: responsive,
          spacing: spacing,
        ),
        SizedBox(height: spacing.medium), // ✅ Espacement responsive

        _buildFormField(
          label: 'Entité',
          value: user?.entity ?? '',
          enabled: false,
          responsive: responsive,
          spacing: spacing,
        ),
        SizedBox(height: spacing.medium), // ✅ Espacement responsive

        _buildFormField(
          label: 'Groupe de préférence',
          value: user?.group ?? user?.role ?? '',
          enabled: false,
          responsive: responsive,
          spacing: spacing,
        ),
      ],
    );
  }

  Widget _buildFormField({
    required String label,
    required String value,
    bool enabled = true,
    required Responsive responsive,
    required ResponsiveSpacing spacing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: responsive.sp(16), // ✅ Texte responsive
            fontWeight: FontWeight.w600,
            color: AppTheme.secondaryColor,
            fontFamily: AppTheme.fontMontserrat,
          ),
        ),
        SizedBox(height: spacing.small), // ✅ Espacement responsive
        Container(
          width: double.infinity,
          padding: spacing.custom(
            horizontal: 16,
            vertical: 16,
          ), // ✅ Padding responsive
          decoration: BoxDecoration(
            color: enabled ? Colors.white : AppTheme.primaryColor10,
            borderRadius: BorderRadius.circular(
              responsive.spacing(12),
            ), // ✅ Border radius responsive
            border: Border.all(
              color:
                  enabled ? AppTheme.secondaryColor30 : AppTheme.secondaryColor,
              width: 1.5,
            ),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: responsive.sp(16), // ✅ Texte responsive
              color: enabled ? AppTheme.secondaryColor : AppTheme.thirdColor,
              fontFamily: AppTheme.fontRoboto,
            ),
          ),
        ),
      ],
    );
  }
}
