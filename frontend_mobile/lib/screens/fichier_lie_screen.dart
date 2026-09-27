import 'package:flutter/material.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/utils/responsive.dart';
import 'package:appmobilegmao/theme/responsive_spacing.dart';
import 'package:appmobilegmao/services/hive_service.dart';
import 'package:appmobilegmao/models/attached_file_note.dart';
import 'package:image_picker/image_picker.dart';

/// Écran pour ajouter un fichier lié
/// Principe SOLID: Single Responsibility - Cet écran gère uniquement l'ajout de fichiers liés
class FichierLieScreen extends StatefulWidget {
  const FichierLieScreen({super.key});

  @override
  State<FichierLieScreen> createState() => _FichierLieScreenState();
}

class _FichierLieScreenState extends State<FichierLieScreen> {
  // Clé globale pour gérer la validation du formulaire
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs pour gérer le texte de chaque champ
  late TextEditingController _nomController;
  late TextEditingController _descriptionController;
  late TextEditingController _urlController;
  late TextEditingController _typeFichierController;
  late TextEditingController _categorieController;
  late TextEditingController _createurController;
  late TextEditingController _dateCreationController;

  // État pour la checkbox "Imprimable"
  bool _isImprimable = false;

  @override
  void initState() {
    super.initState();
    // Récupération de l'utilisateur connecté (DRY)
    final currentUser = HiveService.getCurrentUser();
    final userCode = currentUser?.code ?? currentUser?.username ?? 'supervisor';
    final now = DateTime.now();
    final formattedDate =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    // Initialisation des contrôleurs - les champs grisâtres sont auto-déduits
    _nomController = TextEditingController();
    _descriptionController = TextEditingController();
    _urlController = TextEditingController(
      text:
          'http://10.101.1.103:8080/coswin-repository/content/default/SENELEC/DD/DXMD/SDDV',
    );
    _typeFichierController = TextEditingController(text: 'FICHIER');
    _categorieController = TextEditingController();
    _createurController = TextEditingController(text: userCode);
    _dateCreationController = TextEditingController(text: formattedDate);
  }

  @override
  void dispose() {
    // Libération de la mémoire en disposant tous les contrôleurs
    _nomController.dispose();
    _descriptionController.dispose();
    _urlController.dispose();
    _typeFichierController.dispose();
    _categorieController.dispose();
    _createurController.dispose();
    _dateCreationController.dispose();
    super.dispose();
  }

  /// Gestion du clic sur le bouton Retour
  void _handleBack() {
    Navigator.pop(context);
  }

  /// Gestion du clic sur le bouton "Enregistrer"
  void _handleSave() {
    // Validation du formulaire
    if (_formKey.currentState!.validate()) {
      final fileData = {
        'nom': _nomController.text.trim().isNotEmpty ? _nomController.text.trim() : 'Document_${DateTime.now().millisecondsSinceEpoch}',
        'description': _descriptionController.text.trim(),
        'url': _urlController.text.trim(),
        'type': _typeFichierController.text.trim(),
        'categorie': _categorieController.text.trim(),
        'createur': _createurController.text.trim(),
        'dateCreation': _dateCreationController.text.trim(),
        'isImprimable': _isImprimable,
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fichier "${fileData['nom']}" noté dans le commentaire (non envoyé à Coswin)'),
          backgroundColor: AppTheme.senelecReflexBlue,
        ),
      );
      Navigator.pop(context, fileData);
    }
  }

  /// Gestion du clic sur l'icône trombone (attacher un fichier)
  Future<void> _handleAttachFile() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        final ext = picked.name.contains('.')
            ? picked.name.split('.').last.toUpperCase()
            : 'IMG';
        setState(() {
          _nomController.text = picked.name;
          _typeFichierController.text = ext;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fichier sélectionné : ${picked.name} ($ext)'),
            backgroundColor: AppTheme.senelecReflexBlue,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de charger le fichier : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final spacing = context.spacing;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: IconButton(
          icon: Container(
            padding: spacing.custom(all: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(responsive.spacing(8)),
            ),
            child: Icon(
              Icons.arrow_back,
              color: AppTheme.senelecIndigo,
              size: responsive.iconSize(18),
            ),
          ),
          onPressed: _handleBack,
        ),
        title: Text(
          'Fichier Lié',
          style: TextStyle(
            fontFamily: AppTheme.fontMontserrat,
            fontWeight: FontWeight.w700,
            color: AppTheme.senelecIndigo,
            fontSize: responsive.sp(18),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Formulaire scrollable avec tous les champs
          Expanded(
            child: SingleChildScrollView(
              padding: spacing.custom(horizontal: 20, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avertissement : le fichier n'est pas encore transmis à Coswin
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade300),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${AttachedFileNote.notSentWarning} '
                              "L'envoi réel du fichier sera disponible avec le passage par le serveur.",
                              style: TextStyle(fontSize: 13, color: Colors.orange.shade900),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: spacing.large),

                    // Champ Nom avec fond jaune et icône trombone
                    _NomField(
                      controller: _nomController,
                      onAttachTap: _handleAttachFile,
                    ),
                    SizedBox(height: spacing.medium),

                    // Champ Description
                    _SimpleFormField(
                      label: 'Description',
                      controller: _descriptionController,
                    ),
                    SizedBox(height: spacing.medium),

                    // Champ URL avec icône de lien
                    _UrlField(controller: _urlController),
                    SizedBox(height: spacing.medium),

                    // Checkbox "Imprimable"
                    _CheckboxField(
                      label: 'Imprimable',
                      value: _isImprimable,
                      onChanged: (value) {
                        setState(() {
                          _isImprimable = value ?? false;
                        });
                      },
                    ),
                    SizedBox(height: spacing.medium),

                    // Ligne avec Type de fichier (Grisâtre/Auto) et Catégorie
                    Row(
                      children: [
                        Expanded(
                          child: _SimpleFormField(
                            label: 'Type de fichier',
                            controller: _typeFichierController,
                            readOnly: true,
                            backgroundColor: const Color(0xFFEEEEEE),
                          ),
                        ),
                        SizedBox(width: spacing.medium),
                        Expanded(
                          child: _SimpleFormField(
                            label: 'Catégorie',
                            controller: _categorieController,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: spacing.medium),

                    // Ligne avec Créateur du lien (Grisâtre/Auto) et Date de création (Grisâtre/Auto)
                    Row(
                      children: [
                        Expanded(
                          child: _SimpleFormField(
                            label: 'Créateur du lien',
                            controller: _createurController,
                            readOnly: true,
                            backgroundColor: const Color(0xFFEEEEEE),
                          ),
                        ),
                        SizedBox(width: spacing.medium),
                        Expanded(
                          child: _DateFormField(
                            label: 'Date de création du lien',
                            controller: _dateCreationController,
                            readOnly: true,
                            backgroundColor: const Color(0xFFEEEEEE),
                            onDateTap: null,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: spacing.large),
                  ],
                ),
              ),
            ),
          ),

          // Boutons en bas de l'écran
          _BottomButtons(onBack: _handleBack, onSave: _handleSave),
        ],
      ),
    );
  }
}

/// Widget pour afficher le champ Nom avec fond jaune et icône trombone
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage du champ Nom
class _NomField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onAttachTap;

  const _NomField({required this.controller, required this.onAttachTap});

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final spacing = context.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nom',
          style: TextStyle(
            fontFamily: AppTheme.fontMontserrat,
            fontWeight: FontWeight.w600,
            color: AppTheme.secondaryColor,
            fontSize: responsive.sp(14),
          ),
        ),
        SizedBox(height: spacing.tiny),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFFF99), // Fond jaune
            border: Border.all(color: AppTheme.thirdColor),
          ),
          child: Row(
            children: [
              // Icône trombone cliquable
              InkWell(
                onTap: onAttachTap,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.attach_file,
                    color: AppTheme.secondaryColor,
                    size: responsive.iconSize(20),
                  ),
                ),
              ),
              // Champ de texte
              Expanded(
                child: TextFormField(
                  controller: controller,
                  style: TextStyle(
                    color: AppTheme.secondaryColor,
                    fontFamily: AppTheme.fontRoboto,
                    fontSize: responsive.sp(14),
                  ),
                  decoration: InputDecoration(
                    contentPadding: spacing.custom(vertical: 8, horizontal: 8),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Widget pour afficher le champ URL
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage du champ URL
class _UrlField extends StatelessWidget {
  final TextEditingController controller;

  const _UrlField({required this.controller});

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final spacing = context.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'URL',
          style: TextStyle(
            fontFamily: AppTheme.fontMontserrat,
            fontWeight: FontWeight.w600,
            color: AppTheme.secondaryColor,
            fontSize: responsive.sp(14),
          ),
        ),
        SizedBox(height: spacing.tiny),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                style: TextStyle(
                  color: AppTheme.secondaryColor,
                  fontFamily: AppTheme.fontRoboto,
                  fontSize: responsive.sp(14),
                ),
                decoration: InputDecoration(
                  contentPadding: spacing.custom(vertical: 8, horizontal: 0),
                  border: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.thirdColor),
                  ),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.thirdColor),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: AppTheme.secondaryColor,
                      width: 2.0,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Widget pour afficher un champ simple avec label
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage d'un champ simple
class _SimpleFormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool readOnly;
  final Color? backgroundColor;

  const _SimpleFormField({
    required this.label,
    required this.controller,
    this.readOnly = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final spacing = context.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.fontMontserrat,
            fontWeight: FontWeight.w600,
            color: AppTheme.secondaryColor,
            fontSize: responsive.sp(14),
          ),
        ),
        SizedBox(height: spacing.tiny),
        Container(
          decoration: backgroundColor != null
              ? BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey.shade400),
                )
              : null,
          child: TextFormField(
            controller: controller,
            readOnly: readOnly,
            style: TextStyle(
              color: readOnly ? Colors.grey.shade800 : AppTheme.secondaryColor,
              fontFamily: AppTheme.fontRoboto,
              fontWeight: readOnly ? FontWeight.w600 : FontWeight.normal,
              fontSize: responsive.sp(14),
            ),
            decoration: InputDecoration(
              contentPadding: spacing.custom(
                vertical: 8,
                horizontal: backgroundColor != null ? 8 : 0,
              ),
              border: backgroundColor != null
                  ? InputBorder.none
                  : const UnderlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.thirdColor),
                    ),
              enabledBorder: backgroundColor != null
                  ? InputBorder.none
                  : const UnderlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.thirdColor),
                    ),
              focusedBorder: backgroundColor != null
                  ? InputBorder.none
                  : const UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: AppTheme.secondaryColor,
                        width: 2.0,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Widget pour afficher un champ de date avec icône calendrier
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage d'un champ de date
class _DateFormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final VoidCallback? onDateTap;
  final bool readOnly;
  final Color? backgroundColor;

  const _DateFormField({
    required this.label,
    required this.controller,
    this.onDateTap,
    this.readOnly = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final spacing = context.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.fontMontserrat,
            fontWeight: FontWeight.w600,
            color: AppTheme.secondaryColor,
            fontSize: responsive.sp(14),
          ),
        ),
        SizedBox(height: spacing.tiny),
        Container(
          decoration: backgroundColor != null
              ? BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey.shade400),
                )
              : null,
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller,
                  readOnly: true,
                  style: TextStyle(
                    color: readOnly ? Colors.grey.shade800 : AppTheme.secondaryColor,
                    fontFamily: AppTheme.fontRoboto,
                    fontWeight: readOnly ? FontWeight.w600 : FontWeight.normal,
                    fontSize: responsive.sp(14),
                  ),
                  decoration: InputDecoration(
                    contentPadding: spacing.custom(
                      vertical: 8,
                      horizontal: backgroundColor != null ? 8 : 0,
                    ),
                    hintText: 'dd/mm/yyyy HH:mm',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: responsive.sp(14),
                    ),
                    border: backgroundColor != null
                        ? InputBorder.none
                        : const UnderlineInputBorder(
                            borderSide: BorderSide(color: AppTheme.thirdColor),
                          ),
                    enabledBorder: backgroundColor != null
                        ? InputBorder.none
                        : const UnderlineInputBorder(
                            borderSide: BorderSide(color: AppTheme.thirdColor),
                          ),
                    focusedBorder: backgroundColor != null
                        ? InputBorder.none
                        : const UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: AppTheme.secondaryColor,
                              width: 2.0,
                            ),
                          ),
                  ),
                ),
              ),
              // Icône calendrier
              Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.calendar_today,
                  color: readOnly ? Colors.grey.shade600 : AppTheme.secondaryColor,
                  size: responsive.iconSize(18),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Widget pour afficher une checkbox avec label
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage de la checkbox
class _CheckboxField extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _CheckboxField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Row(
      children: [
        // Checkbox
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: const Color.fromARGB(255, 1, 92, 192),
        ),
        // Label de la checkbox
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.fontMontserrat,
            fontWeight: FontWeight.normal,
            color: AppTheme.secondaryColor,
            fontSize: responsive.sp(14),
          ),
        ),
      ],
    );
  }
}

/// Widget qui affiche les boutons en bas de l'écran
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage des boutons
class _BottomButtons extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onSave;

  const _BottomButtons({required this.onBack, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final responsive = context.responsive;

    final bottomInset = MediaQuery.of(context).viewPadding.bottom > 0
        ? MediaQuery.of(context).viewPadding.bottom
        : MediaQuery.of(context).padding.bottom;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 10,
        bottom: bottomInset + 14,
      ),
      child: Row(
        children: [
          // Bouton Retour
          Expanded(
            child: OutlinedButton(
              onPressed: onBack,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color.fromARGB(255, 189, 182, 182), width: 2),
                padding: EdgeInsets.symmetric(vertical: responsive.hp(1.8)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Retour',
                style: TextStyle(
                  fontFamily: AppTheme.fontMontserrat,
                  fontWeight: FontWeight.w600,
                  fontSize: responsive.sp(16),
                  color: const Color.fromARGB(255, 1, 92, 192),
                ),
              ),
            ),
          ),
          SizedBox(width: spacing.medium),
          // Bouton Enregistrer
          Expanded(
            child: ElevatedButton(
              onPressed: onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 1, 92, 192),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: responsive.hp(1.8)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
              child: Text(
                'Enregistrer',
                style: TextStyle(
                  fontFamily: AppTheme.fontMontserrat,
                  fontWeight: FontWeight.w600,
                  fontSize: responsive.sp(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
