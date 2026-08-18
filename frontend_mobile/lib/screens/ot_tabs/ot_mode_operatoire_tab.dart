import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appmobilegmao/provider/auth_provider.dart';
import 'package:appmobilegmao/models/order.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/utils/responsive.dart';
import 'package:appmobilegmao/theme/responsive_spacing.dart';
import 'package:appmobilegmao/widgets/custom_bottom_navigation_bar.dart';
import 'package:appmobilegmao/widgets/custom_app_bar.dart';
import 'package:appmobilegmao/screens/fichier_lie_screen.dart';
import 'package:appmobilegmao/screens/main_screen.dart';
import 'package:appmobilegmao/services/ot_service.dart';
import 'package:appmobilegmao/services/api_service.dart';
import 'package:appmobilegmao/services/hive_service.dart';

/// Onglet "Mode Opératoire" - Affiche les prérequis et permet d'ajouter des fichiers
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage du mode opératoire
class ModeOperatoireTab extends StatefulWidget {
  final String otCode;
  final OTService otService;

  const ModeOperatoireTab({Key? key, required this.otCode, required this.otService}) : super(key: key);

  @override
  State<ModeOperatoireTab> createState() => ModeOperatoireTabState();
}

class ModeOperatoireTabState extends State<ModeOperatoireTab> {
  List<dynamic> _operations = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOperations();
  }

  Future<void> _loadOperations() async {
    setState(() => _isLoading = true);
    try {
      final list = await widget.otService.getOperations(widget.otCode);
      setState(() {
        _operations = list;
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
    final descController = TextEditingController();
    final durationController = TextEditingController(text: '1.0');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ajouter une étape'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description de l\'opération *'),
                  validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                ),
                TextFormField(
                  controller: durationController,
                  decoration: const InputDecoration(labelText: 'Durée (heures)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                    await widget.otService.createOperation(widget.otCode, {
                      "operationCode": "OP_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}",
                      "opopDescription": descController.text.trim(),
                      "opopJobDescription": descController.text.trim(),
                      "duration": double.tryParse(durationController.text) ?? 1.0,
                    });
                    _loadOperations();
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

  void _showEditDialog(Map<String, dynamic> op) {
    final formKey = GlobalKey<FormState>();
    final desc = op['opopDescription']?.toString() ?? op['opopJobDescription']?.toString() ?? '';
    final descController = TextEditingController(text: desc);
    final durationController = TextEditingController(text: (op['duration'] ?? 1.0).toString());
    final pk = (op['pkOperation'] ?? op['pkWorkAction'] ?? 0) as int;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Modifier l\'étape'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description de l\'opération *'),
                  validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                ),
                TextFormField(
                  controller: durationController,
                  decoration: const InputDecoration(labelText: 'Durée (heures)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                    await widget.otService.updateOperation(widget.otCode, pk, {
                      "operationCode": op['operationCode'] ?? 'OP',
                      "opopDescription": descController.text.trim(),
                      "opopJobDescription": descController.text.trim(),
                      "duration": double.tryParse(durationController.text) ?? 1.0,
                    });
                    _loadOperations();
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
          title: const Text('Supprimer l\'étape'),
          content: const Text('Voulez-vous supprimer cette étape du mode opératoire ?'),
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
                  await widget.otService.deleteOperation(widget.otCode, pk);
                  _loadOperations();
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Prérequis / Étapes',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F1B80),
                  fontSize: 18,
                ),
              ),
              // Bouton d'ajout masqué en mode lecture seule
            ],
          ),
        ),
        Expanded(
          child: _operations.isEmpty
              ? const Center(
                  child: Text('Aucun mode opératoire pour cet OT', style: TextStyle(fontSize: 16, color: Colors.grey)),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _operations.asMap().entries.map((entry) {
                      int index = entry.key;
                      final op = entry.value;
                      String text = op['opopDescription']?.toString() ?? op['opopJobDescription']?.toString() ?? 'Opération sans description';
                      final pk = (op['pkOperation'] ?? op['pkWorkAction'] ?? 0) as int;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${index + 1}. ',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F1B80),
                                fontSize: 14,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                text,
                                style: const TextStyle(
                                  fontWeight: FontWeight.normal,
                                  color: Color(0xFF0F1B80),
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
        ),
      ],
    );
  }
}
