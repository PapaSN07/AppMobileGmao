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

  const SousAttributsTab({super.key, required this.otCode, required this.otService});

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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.senelecReflexBlue));
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
                style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.senelecReflexBlue, fontSize: 16),
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
                      Icon(Icons.list_alt, size: 64, color: AppTheme.senelecReflexBlue),
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

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 1,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.senelecReflexBlue.withAlpha(20),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(color: AppTheme.senelecReflexBlue, fontWeight: FontWeight.bold, fontSize: 12),
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
                                    ? AppTheme.senelecReflexBlue.withAlpha(20)
                                    : Colors.grey.withAlpha(30),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                displayVal,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: value.isNotEmpty ? AppTheme.senelecReflexBlue : Colors.grey,
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
                backgroundColor: AppTheme.senelecReflexBlue,
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


