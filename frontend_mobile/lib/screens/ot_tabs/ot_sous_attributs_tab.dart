import 'package:flutter/material.dart' hide FormField;
import 'ot_shared_widgets.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/utils/responsive.dart';
import 'package:appmobilegmao/theme/responsive_spacing.dart';
import 'package:appmobilegmao/services/ot_service.dart';

/// Onglet "Attributs" - Affiche le tableau des attributs avec formulaire
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage des attributs
/// Principe DRY: Réutilise le pattern de _MoyensTab
class SousAttributsTab extends StatefulWidget {
  final String otCode;
  final OTService otService;

  const SousAttributsTab({Key? key, required this.otCode, required this.otService}) : super(key: key);

  @override
  State<SousAttributsTab> createState() => SousAttributsTabState();
}

class SousAttributsTabState extends State<SousAttributsTab> {
  List<dynamic> _attributes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAttributes();
  }

  Future<void> _loadAttributes() async {
    setState(() => _isLoading = true);
    try {
      final list = await widget.otService.getAttributes(widget.otCode);
      setState(() {
        _attributes = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showAddDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final valController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ajouter un sous-attribut'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nom de l\'attribut *'),
                  validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                ),
                TextFormField(
                  controller: valController,
                  decoration: const InputDecoration(labelText: 'Valeur *'),
                  validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                ),
                TextFormField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(context);
                  try {
                    await widget.otService.createAttribute(widget.otCode, {
                      "woatName": nameController.text.trim(),
                      "woatValue": valController.text.trim(),
                      "woatDescription": descController.text.trim(),
                    });
                    _loadAttributes();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                  }
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(Map<String, dynamic> attr) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: attr['woatName']?.toString() ?? '');
    final valController = TextEditingController(text: attr['woatValue']?.toString() ?? '');
    final descController = TextEditingController(text: attr['woatDescription']?.toString() ?? '');
    final pk = (attr['pkAttribute'] ?? attr['pkWorkOrderAttribute'] ?? 0) as int;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Modifier le sous-attribut'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nom de l\'attribut *'),
                  validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                ),
                TextFormField(
                  controller: valController,
                  decoration: const InputDecoration(labelText: 'Valeur *'),
                  validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                ),
                TextFormField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(context);
                  try {
                    await widget.otService.updateAttribute(widget.otCode, pk, {
                      "woatName": nameController.text.trim(),
                      "woatValue": valController.text.trim(),
                      "woatDescription": descController.text.trim(),
                    });
                    _loadAttributes();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                  }
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(int pk) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer l\'attribut'),
          content: const Text('Voulez-vous supprimer ce sous-attribut ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await widget.otService.deleteAttribute(widget.otCode, pk);
                  _loadAttributes();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                }
              },
              child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF0F1B80)));
    }
    if (_error != null) {
      return Center(child: Text('Erreur: $_error', style: const TextStyle(color: Colors.red)));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sous-attributs',
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F1B80), fontSize: 16),
              ),
              // Bouton d'ajout masqué en mode lecture seule
            ],
          ),
        ),
        Expanded(
          child: _attributes.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.list_alt, size: 64, color: Color(0xFF0F1B80)),
                      SizedBox(height: 16),
                      Text('Aucun sous-attribut pour cet OT', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _attributes.length,
                  itemBuilder: (context, index) {
                    final attr = _attributes[index];
                    final name       = attr['woatName']?.toString() ?? 'Attribut';
                    final value      = attr['woatValue']?.toString() ?? '';
                    final equipment  = attr['woatDescription']?.toString() ?? '';
                    final unit       = attr['woatUnitSymbol']?.toString() ?? '';
                    final displayVal = value.isNotEmpty ? (unit.isNotEmpty ? '$value $unit' : value) : '-';
                    final pk         = (attr['pkAttribute'] ?? attr['pkWorkOrderAttribute'] ?? 0) as int;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 1,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF0F1B80).withAlpha(20),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(color: Color(0xFF0F1B80), fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        subtitle: equipment.isNotEmpty
                            ? Text(equipment, style: const TextStyle(fontSize: 11, color: Colors.grey))
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: value.isNotEmpty
                                    ? const Color(0xFF0F1B80).withAlpha(20)
                                    : Colors.grey.withAlpha(30),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                displayVal,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: value.isNotEmpty ? const Color(0xFF0F1B80) : Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}



/// Widget pour afficher les champs d'en-tête des attributs
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage des champs d'en-tête
/// Principe DRY: Réutilise le pattern de formulaire
class _AttributsHeaderFields extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final responsive = context.responsive;

    return Container(
      color: Colors.grey[100],
      padding: spacing.custom(horizontal: 20, vertical: 15),
      child: Column(
        children: [
          // Ligne 1: Numéro de jeu
          Row(
            children: [
              Expanded(
                flex: 1,
                child: Text(
                  'Numéro de jeu',
                  style: TextStyle(
                    fontFamily: AppTheme.fontMontserrat,
                    fontWeight: FontWeight.w600,
                    fontSize: responsive.sp(12),
                    color: AppTheme.secondaryColor,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  padding: spacing.custom(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '1',
                    style: TextStyle(
                      fontFamily: AppTheme.fontRoboto,
                      fontSize: responsive.sp(12),
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.medium),
          // Ligne 2: Créateur et Date
          Row(
            children: [
              Expanded(
                flex: 1,
                child: Row(
                  children: [
                    Text(
                      'Créateur',
                      style: TextStyle(
                        fontFamily: AppTheme.fontMontserrat,
                        fontWeight: FontWeight.w600,
                        fontSize: responsive.sp(12),
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                    SizedBox(width: spacing.small),
                    Expanded(
                      child: Container(
                        padding: spacing.custom(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Cheikhou Oumar Kane',
                          style: TextStyle(
                            fontFamily: AppTheme.fontRoboto,
                            fontSize: responsive.sp(11),
                            color: AppTheme.secondaryColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: spacing.medium),
              Expanded(
                flex: 1,
                child: Container(
                  padding: spacing.custom(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '20/10/2025 17:57',
                          style: TextStyle(
                            fontFamily: AppTheme.fontRoboto,
                            fontSize: responsive.sp(11),
                            color: AppTheme.secondaryColor,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.calendar_today,
                        size: responsive.iconSize(16),
                        color: AppTheme.secondaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Widget pour afficher le formulaire de détails d'un attribut
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage du formulaire
/// Principe DRY: Réutilise EmployeFormField
class _AttributsDetailsTab extends StatefulWidget {
  final VoidCallback onBack;

  const _AttributsDetailsTab({required this.onBack});

  @override
  State<_AttributsDetailsTab> createState() => _AttributsDetailsTabState();
}

class _AttributsDetailsTabState extends State<_AttributsDetailsTab> {
  late TextEditingController _classeAttributController;
  late TextEditingController _attributController;
  late TextEditingController _valeurController;
  late TextEditingController _uniteController;
  late TextEditingController _symboleUniteController;
  late TextEditingController _valeurEtalonController;

  @override
  void initState() {
    super.initState();
    _classeAttributController = TextEditingController(text: '3');
    _attributController = TextEditingController();
    _valeurController = TextEditingController();
    _uniteController = TextEditingController();
    _symboleUniteController = TextEditingController();
    _valeurEtalonController = TextEditingController();
  }

  @override
  void dispose() {
    _classeAttributController.dispose();
    _attributController.dispose();
    _valeurController.dispose();
    _uniteController.dispose();
    _symboleUniteController.dispose();
    _valeurEtalonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final responsive = context.responsive;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: spacing.custom(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MaterielActionBar(onAddTap: () {}),
                SizedBox(height: spacing.large),

                // Ligne 1: Classe d'attribut et Attribut
                Row(
                  children: [
                    Expanded(
                      child: EmployeFormField(
                        label: 'Classe d\'attribut',
                        controller: _classeAttributController,
                        hasDropdown: true,
                      ),
                    ),
                    SizedBox(width: spacing.medium),
                    Expanded(
                      child: EmployeFormField(
                        label: 'Attribut',
                        controller: _attributController,
                        hasDropdown: true,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing.medium),

                // Ligne 2: Valeur et Unité
                Row(
                  children: [
                    Expanded(
                      child: EmployeFormField(
                        label: 'Valeur',
                        controller: _valeurController,
                      ),
                    ),
                    SizedBox(width: spacing.medium),
                    Expanded(
                      child: EmployeFormField(
                        label: 'Unité',
                        controller: _uniteController,
                        hasDropdown: true,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing.medium),

                // Ligne 3: Symbole de l'unité et Valeur étalon
                Row(
                  children: [
                    Expanded(
                      child: EmployeFormField(
                        label: 'Symbole de l\'unité',
                        controller: _symboleUniteController,
                      ),
                    ),
                    SizedBox(width: spacing.medium),
                    Expanded(
                      child: EmployeFormField(
                        label: 'Valeur étalon',
                        controller: _valeurEtalonController,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Bouton Retour en bas
        Container(
          color: Colors.white,
          padding: spacing.custom(horizontal: 20, vertical: 10, bottom: 20),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onBack,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F1B80),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: responsive.hp(1.8)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
              child: Text(
                'Retour',
                style: TextStyle(
                  fontFamily: AppTheme.fontMontserrat,
                  fontWeight: FontWeight.w600,
                  fontSize: responsive.sp(16),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Widget pour afficher l'en-tête du tableau Attributs
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage de l'en-tête
class _AttributsTableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final responsive = context.responsive;

    return Container(
      color: const Color(0xFF0F1B80),
      padding: spacing.custom(horizontal: 5, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: _HeaderText('Classe d\'attribut', responsive),
          ),
          Expanded(flex: 2, child: _HeaderText('Attribut', responsive)),
          Expanded(flex: 1, child: _HeaderText('Valeur', responsive)),
          Expanded(flex: 1, child: _HeaderText('Unité', responsive)),
          Expanded(
            flex: 1,
            child: _HeaderText('Symbole de l\'unité', responsive),
          ),
          Expanded(flex: 1, child: _HeaderText('Valeur étalon', responsive)),
          Expanded(flex: 1, child: _HeaderText('État', responsive)),
          Expanded(flex: 1, child: _HeaderText('Vérifié', responsive)),
          Expanded(flex: 1, child: _HeaderText('Attribut MAJ', responsive)),
        ],
      ),
    );
  }

  Widget _HeaderText(String text, Responsive responsive) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: AppTheme.fontMontserrat,
        fontWeight: FontWeight.w600,
        fontSize: responsive.sp(10),
        color: Colors.white,
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// Widget pour afficher une ligne d'attribut dans le tableau
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage d'une ligne
/// Principe DRY: Réutilise le pattern de checkbox avec callback
class _AttributsRow extends StatelessWidget {
  final int index;
  final String classeAttribut;
  final String attribut;
  final String valeur;
  final String unite;
  final String symboleUnite;
  final String valeurEtalon;
  final String? selectedCheckbox;
  final Function(String) onCheckboxChanged;

  const _AttributsRow({
    required this.index,
    required this.classeAttribut,
    required this.attribut,
    required this.valeur,
    required this.unite,
    required this.symboleUnite,
    required this.valeurEtalon,
    required this.selectedCheckbox,
    required this.onCheckboxChanged,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final responsive = context.responsive;

    return Container(
      color: index % 2 == 0 ? Colors.white : Colors.grey[100],
      padding: spacing.custom(horizontal: 5, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 1, child: _CellText(classeAttribut, responsive)),
          Expanded(flex: 2, child: _CellText(attribut, responsive)),
          Expanded(flex: 1, child: _CellText(valeur, responsive)),
          Expanded(flex: 1, child: _CellText(unite, responsive)),
          Expanded(flex: 1, child: _CellText(symboleUnite, responsive)),
          Expanded(flex: 1, child: _CellText(valeurEtalon, responsive)),
          Expanded(
            flex: 1,
            child: _RadioCheckboxCell(
              isSelected: selectedCheckbox == 'etat',
              onTap: () => onCheckboxChanged('etat'),
            ),
          ),
          Expanded(
            flex: 1,
            child: _RadioCheckboxCell(
              isSelected: selectedCheckbox == 'verifie',
              onTap: () => onCheckboxChanged('verifie'),
            ),
          ),
          Expanded(
            flex: 1,
            child: _RadioCheckboxCell(
              isSelected: selectedCheckbox == 'attributMaj',
              onTap: () => onCheckboxChanged('attributMaj'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _CellText(String text, Responsive responsive) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: AppTheme.fontRoboto,
        color: AppTheme.secondaryColor,
        fontSize: responsive.sp(10),
      ),
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Widget pour afficher une checkbox cliquable (comportement radio button)
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage et le clic d'une checkbox
/// Principe DRY: Réutilisable pour toutes les checkboxes du tableau
class _RadioCheckboxCell extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _RadioCheckboxCell({required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkWell(
        onTap: onTap,
        child: Icon(
          isSelected ? Icons.check_box : Icons.check_box_outline_blank,
          color: isSelected ? const Color(0xFF0F1B80) : Colors.grey,
          size: 20,
        ),
      ),
    );
  }
}


