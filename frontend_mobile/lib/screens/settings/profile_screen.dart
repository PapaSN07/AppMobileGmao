import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.secondaryColor,
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
              // AppBar personnalisée
              _buildAppBar(context),

              // Contenu principal
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
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
                          _buildProfilePhoto(),

                          const SizedBox(height: 32),

                          // Formulaire
                          _buildForm(),

                          const SizedBox(height: 32),

                          // Bouton sauvegarder
                          _buildSaveButton(),

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
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryColor30,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryColor50, width: 1),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Modifier le profil',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: AppTheme.fontMontserrat,
                ),
              ),
            ),
          ),
          const SizedBox(width: 48), // Pour équilibrer avec le bouton back
        ],
      ),
    );
  }

  Widget _buildProfilePhoto() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor10,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.secondaryColor, width: 3),
          ),
          child: ClipOval(
            child:
                _selectedImage != null
                    ? Image.file(
                      _selectedImage!,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    )
                    : Center(
                      child: Text(
                        "MP", // Initiales par défaut
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondaryColor,
                          fontFamily: AppTheme.fontMontserrat,
                        ),
                      ),
                    ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: () {
              _showPhotoOptions();
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Icon(
                Icons.photo_camera,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormField(label: 'Nom', value: 'Peters', enabled: false),
        const SizedBox(height: 20),

        _buildFormField(label: 'Prénom', value: 'Melissa', enabled: false),
        const SizedBox(height: 20),

        _buildFormField(
          label: 'Email',
          value: 'melpeters@gmail.com',
          enabled: false,
        ),
        const SizedBox(height: 20),

        _buildFormField(label: 'Rôle', value: 'Technicien', enabled: false),
        const SizedBox(height: 20),

        _buildFormField(
          label: 'Département',
          value: 'Maintenance',
          enabled: false,
        ),
        const SizedBox(height: 20),

        _buildFormField(
          label: 'Date d\'embauche',
          value: '15/01/2023',
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

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _selectedImage != null ? () => _saveChanges() : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              _selectedImage != null
                  ? AppTheme.secondaryColor
                  : AppTheme.thirdColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Text(
          _selectedImage != null
              ? 'Sauvegarder les modifications'
              : 'Aucune modification à sauvegarder',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: AppTheme.fontMontserrat,
          ),
        ),
      ),
    );
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Poignée de la bottom sheet
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.thirdColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: 10),

              Text(
                'Sélectionner une photo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondaryColor,
                  fontFamily: AppTheme.fontMontserrat,
                ),
              ),

              const SizedBox(height: 20),

              // Options
              _buildPhotoOption(
                Icons.photo_camera,
                'Prendre une photo',
                () => _pickImage(ImageSource.camera),
              ),

              _buildPhotoOption(
                Icons.photo_library,
                'Choisir depuis la galerie',
                () => _pickImage(ImageSource.gallery),
              ),

              if (_selectedImage != null)
                _buildPhotoOption(
                  Icons.delete,
                  'Supprimer la photo',
                  () => _removeImage(),
                  isDelete: true,
                ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPhotoOption(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDelete = false,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color:
              isDelete
                  ? const Color.fromRGBO(244, 67, 54, 0.1)
                  : AppTheme.primaryColor10,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isDelete ? Colors.red : AppTheme.secondaryColor,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDelete ? Colors.red : AppTheme.secondaryColor,
          fontFamily: AppTheme.fontRoboto,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });

        if (kDebugMode) {
          print("Photo sélectionnée: ${image.path}");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Erreur lors de la sélection de l'image: $e");
      }

      // Afficher un message d'erreur à l'utilisateur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Erreur lors de la sélection de l\'image'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });

    if (kDebugMode) {
      print("Photo supprimée");
    }
  }

  void _saveChanges() {
    if (_selectedImage != null) {
      // Implémenter la sauvegarde de la photo sur le serveur
      if (kDebugMode) {
        print("Sauvegarde de la photo: ${_selectedImage!.path}");
      }

      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Photo de profil mise à jour avec succès !'),
          backgroundColor: AppTheme.secondaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      // Retourner à l'écran précédent après la sauvegarde
      Navigator.pop(context);
    }
  }
}
