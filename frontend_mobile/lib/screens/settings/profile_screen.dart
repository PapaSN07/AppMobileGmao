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
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: Text(
              'Mon Profil',
              style: TextStyle(
                fontFamily: AppTheme.fontMontserrat,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2B1D4C),
                fontSize: responsive.sp(18),
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: spacing.custom(all: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(responsive.spacing(8)),
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: const Color(0xFF2B1D4C),
                  size: responsive.iconSize(18),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Retour',
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: spacing.custom(horizontal: 16, vertical: 20),
              child: Column(
                children: [
                  // Carte Blanche Élevée pour le Profil
                  Container(
                    width: double.infinity,
                    padding: spacing.custom(horizontal: 20, vertical: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(responsive.spacing(16)),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Photo de profil / Initiales
                        _buildProfilePhoto(
                          authProvider,
                          responsive,
                          spacing,
                        ),

                        SizedBox(height: spacing.xlarge),

                        // Section d'informations
                        _buildUserInfo(authProvider, responsive, spacing),
                      ],
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

  Widget _buildProfilePhoto(
    AuthProvider authProvider,
    Responsive responsive,
    ResponsiveSpacing spacing,
  ) {
    final user = authProvider.currentUser;
    final userInfo = StringUtils.parseUserName(user?.username);
    final initiales = userInfo['initiales']!;
    return Container(
      width: responsive.spacing(100),
      height: responsive.spacing(100),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1B80).withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF0F1B80), width: 3),
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
          label: 'Nom & Prénom',
          value: user?.displayName ?? '',
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
          label: 'Entité Rattachée',
          value: user?.entity ?? '',
          enabled: false,
          responsive: responsive,
          spacing: spacing,
        ),
        SizedBox(height: spacing.medium), // ✅ Espacement responsive

        _buildFormField(
          label: 'Rôle & Fonction',
          value: user?.displayRole ?? '',
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
