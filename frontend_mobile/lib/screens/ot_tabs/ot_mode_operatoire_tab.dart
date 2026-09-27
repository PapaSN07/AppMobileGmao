import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:appmobilegmao/services/ot_service.dart';

/// Onglet "Mode Opératoire" - Affiche les prérequis et permet d'ajouter des fichiers
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage du mode opératoire
class ModeOperatoireTab extends StatefulWidget {
  final String otCode;
  final OTService otService;

  const ModeOperatoireTab({super.key, required this.otCode, required this.otService});

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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Prérequis / Étapes',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.senelecReflexBlue,
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

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${index + 1}. ',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.senelecReflexBlue,
                                fontSize: 14,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                text,
                                style: const TextStyle(
                                  fontWeight: FontWeight.normal,
                                  color: AppTheme.senelecReflexBlue,
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
