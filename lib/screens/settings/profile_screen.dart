import 'package:appmobilegmao/provider/auth_provider.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          backgroundColor: AppTheme.secondaryColor,
          // ✅ AJOUTÉ: AppBar standard pour uniformité avec main_screen.dart
          appBar: AppBar(
            title: const Text(
              'Mon Profil', // ✅ Titre ajusté pour la visualisation
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
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 20,
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
                      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
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
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              // Photo de profil
                              _buildProfilePhoto(authProvider),

                              const SizedBox(height: 32),

                              // Section d'informations (visualisation seule)
                              _buildUserInfo(authProvider),

                              const SizedBox(height: 20),
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

  Widget _buildProfilePhoto(AuthProvider authProvider) {
    final user = authProvider.currentUser;
    String nom = user?.username.split('.').last ?? '';
    String prenom = user?.username.split('.').first ?? '';
    return Container(
      width: 120,
      height: 120,
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
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // En cas d'erreur de chargement, afficher les initiales
                    return Center(
                      child: Text(
                        "${prenom[0].toUpperCase()}${nom[0].toUpperCase()}",
                        style: TextStyle(
                          fontSize: 36,
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
                    "${prenom[0].toUpperCase()}${nom[0].toUpperCase()}", // Initiales par défaut
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondaryColor,
                      fontFamily: AppTheme.fontMontserrat,
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _buildUserInfo(AuthProvider authProvider) {
    final user = authProvider.currentUser;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormField(
          label: 'Username',
          value: user?.username ?? '',
          enabled: false,
        ),
        const SizedBox(height: 20),

        _buildFormField(
          label: 'Email',
          value: user?.email ?? '',
          enabled: false,
        ),
        const SizedBox(height: 20),

        _buildFormField(
          label: 'Entité',
          value: user?.entity ?? '',
          enabled: false,
        ),
        const SizedBox(height: 20),

        _buildFormField(
          label: 'Groupe de préférence',
          value: user?.group ?? user?.role ?? '',
          enabled: false,
        ),
      ],
    );
  }

  Widget _buildFormField({
    required String label,
    required String value,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.secondaryColor,
            fontFamily: AppTheme.fontMontserrat,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: enabled ? Colors.white : AppTheme.primaryColor10,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  enabled ? AppTheme.secondaryColor30 : AppTheme.secondaryColor,
              width: 1.5,
            ),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: enabled ? AppTheme.secondaryColor : AppTheme.thirdColor,
              fontFamily: AppTheme.fontRoboto,
            ),
          ),
        ),
      ],
    );
  }
}
