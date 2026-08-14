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

/// Écran qui affiche les détails d'un Ordre de Travail (OT) avec des onglets
/// Principe SOLID: Single Responsibility - Cet écran gère l'affichage des détails OT avec navigation par onglets
class OTDetailScreen extends StatefulWidget {
  // L'ordre de travail dont on veut afficher les détails
  final Order order;

  const OTDetailScreen({Key? key, required this.order}) : super(key: key);

  @override
  State<OTDetailScreen> createState() => _OTDetailScreenState();
}

class _OTDetailScreenState extends State<OTDetailScreen>
    with SingleTickerProviderStateMixin {
  // Contrôleur pour gérer les onglets (TabBar et TabBarView)
  late TabController _tabController;
  late final OTService _otService;

  // Index de l'onglet actuellement sélectionné (0 = Détails, 1 = Mode Opératoire, etc.)
  int _currentTabIndex = 0;

  // Index pour la barre de navigation en bas (initialisé à 2 pour "OT")
  int _currentBottomIndex = 2;

  @override
  void initState() {
    super.initState();
    _otService = OTService(ApiService());
    // Initialisation du TabController avec 6 onglets
    _tabController = TabController(length: 6, vsync: this);

    // Écouter les changements d'onglets pour mettre à jour l'état
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    // Libération de la mémoire en disposant le contrôleur
    _tabController.dispose();
    super.dispose();
  }

  /// Gestion du clic sur un élément de la barre de navigation en bas
  void _onBottomNavTapped(int index) {
    if (index == _currentBottomIndex) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => MainScreen(initialIndex: index)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Barre d'application en haut avec le titre et le bouton retour
      appBar: CustomAppBar(
        backgroundColor: Colors.white,
        iconColor: const Color(0xFF2B1D4C),
        title: 'Détails OT ${widget.order.code}',
        bottom: CustomTabBar(
          tabController: _tabController,
          tabLabels: const [
            'Détails',
            'Mode Opératoire',
            'Commentaires',
            'Mains d\'œuvre',
            'Matériel',
            'Sous d\'attributs',
          ],
        ),
      ),
      // Corps de l'écran avec le contenu des onglets
      body: TabBarView(
        controller: _tabController,
        children: [
          // Onglet 1: Détails (contenu du formulaire)
          _DetailsTab(order: widget.order),
          // Onglet 2: Mode Opératoire (actions Coswin)
          _ModeOperatoireTab(otCode: widget.order.code, otService: _otService),
          // Onglet 3: Commentaires (employeefeedbacks Coswin)
          _CommentairesTab(otCode: widget.order.code, otService: _otService),
          // Onglet 4: Mains d'œuvre (allocatedemployees Coswin)
          _MainsOeuvreTab(otCode: widget.order.code, otService: _otService),
          // Onglet 5: Matériel (stockused Coswin)
          _MaterielTab(otCode: widget.order.code, otService: _otService),
          // Onglet 6: Sous d'attributs (attributes Coswin)
          _SousAttributsTab(otCode: widget.order.code, otService: _otService),
        ],
      ),
      // Barre de navigation en bas de l'écran
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentBottomIndex,
        onTap: _onBottomNavTapped,
      ),
    );
  }
}

/// Onglet "Détails" - Affiche le taux de réalisation et un bouton pour accéder aux détails complets
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage du taux de réalisation
class _DetailsTab extends StatefulWidget {
  final Order order;

  const _DetailsTab({required this.order});

  @override
  State<_DetailsTab> createState() => _DetailsTabState();
}

class _DetailsTabState extends State<_DetailsTab> {
  // Contrôleur pour le champ taux de réalisation
  late TextEditingController _tauxRealisationController;

  @override
  void initState() {
    super.initState();
    try {
      final rate = widget.order.completionRate;
      _tauxRealisationController = TextEditingController(
        text: rate != null ? '${rate.toInt()}%' : '0%',
      );
    } catch (e) {
      debugPrint('Erreur initState _DetailsTab: $e');
    }
  }

  @override
  void dispose() {
    try {
      _tauxRealisationController.dispose();
    } catch (e) {
      debugPrint('Erreur dispose _DetailsTab: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    try {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailField(
              label: 'Code OT',
              value: widget.order.code,
              spacing: spacing,
            ),
            const SizedBox(height: 16),
            _buildDetailField(
              label: 'Description',
              value: widget.order.description,
              spacing: spacing,
            ),
            const SizedBox(height: 16),
            _buildDetailField(
              label: 'Famille / Classe',
              value: widget.order.famille,
              spacing: spacing,
            ),
            const SizedBox(height: 16),
            _buildDetailField(
              label: 'Zone',
              value: widget.order.zone,
              spacing: spacing,
            ),
            const SizedBox(height: 16),
            _buildDetailField(
              label: 'Entité',
              value: widget.order.entity,
              spacing: spacing,
            ),
            const SizedBox(height: 16),
            _buildDetailField(
              label: 'Centre de charge',
              value: widget.order.centre,
              spacing: spacing,
            ),
            const SizedBox(height: 16),
            // Champ "Taux de réalisation"
            const Text(
              'Taux de réalisation',
              style: TextStyle(
                color: Color(0xFF0F1B80),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _tauxRealisationController,
                      readOnly: true,
                      style: const TextStyle(
                        color: Color(0xFF9E9E9E),
                        fontSize: 14,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Erreur build _DetailsTab: $e');
      return Center(
        child: Text('Erreur: $e'),
      );
    }
  }

  /// Widget réutilisable pour afficher un champ de détail en lecture seule
  Widget _buildDetailField({
    required String label,
    required String value,
    required ResponsiveSpacing spacing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF0F1B80),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
          ),
          child: TextFormField(
            initialValue: value,
            readOnly: true,
            style: const TextStyle(
              color: Color(0xFF9E9E9E),
              fontSize: 14,
            ),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  void _showTauxRealisationPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Sélectionner le taux de réalisation',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F1B80),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: 101,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(
                        '$index%',
                        style: const TextStyle(fontSize: 14),
                      ),
                      onTap: () {
                        setState(() {
                          _tauxRealisationController.text = '$index%';
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Onglet "Mode Opératoire" - Affiche les prérequis et permet d'ajouter des fichiers
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage du mode opératoire
class _ModeOperatoireTab extends StatefulWidget {
  final String otCode;
  final OTService otService;

  const _ModeOperatoireTab({Key? key, required this.otCode, required this.otService}) : super(key: key);

  @override
  State<_ModeOperatoireTab> createState() => _ModeOperatoireTabState();
}

class _ModeOperatoireTabState extends State<_ModeOperatoireTab> {
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

/// Onglet "Commentaires" - Affiche les commentaires et les pièces jointes
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage des commentaires et pièces jointes
class _CommentairesTab extends StatefulWidget {
  final String otCode;
  final OTService otService;

  const _CommentairesTab({Key? key, required this.otCode, required this.otService}) : super(key: key);

  @override
  State<_CommentairesTab> createState() => _CommentairesTabState();
}

class _CommentairesTabState extends State<_CommentairesTab> {
  List<dynamic> _comments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    setState(() => _isLoading = true);
    try {
      final list = await widget.otService.getDocuments(widget.otCode);
      setState(() {
        _comments = list;
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
    final contentController = TextEditingController();
    final currentUser = HiveService.getCurrentUser();
    final authorController = TextEditingController(text: currentUser?.code ?? '5893');
    DateTime startDate = DateTime.now().subtract(const Duration(hours: 1));
    DateTime endDate = DateTime.now();

    final startDateController = TextEditingController(
      text: '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')} ${startDate.hour.toString().padLeft(2, '0')}:${startDate.minute.toString().padLeft(2, '0')}'
    );
    final endDateController = TextEditingController(
      text: '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')} ${endDate.hour.toString().padLeft(2, '0')}:${endDate.minute.toString().padLeft(2, '0')}'
    );

    double actualHours = (endDate.difference(startDate).inMinutes / 60.0);
    final actualHoursController = TextEditingController(text: actualHours.toStringAsFixed(1));
    final totalHoursController = TextEditingController(text: actualHours.toStringAsFixed(1));

    Future<DateTime?> pickDT(DateTime initial) async {
      final date = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
      );
      if (date == null) return null;
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initial),
      );
      if (time == null) return null;
      return DateTime(date.year, date.month, date.day, time.hour, time.minute);
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void recalc() {
              final diff = endDate.difference(startDate).inMinutes;
              if (diff >= 0) {
                final h = (diff / 60.0).toStringAsFixed(1);
                setDialogState(() {
                  actualHoursController.text = h;
                  totalHoursController.text = h;
                });
              }
            }

            return AlertDialog(
              title: const Text('Ajouter un compte-rendu / commentaire'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: contentController,
                        decoration: const InputDecoration(labelText: 'Commentaire / Rapport *'),
                        maxLines: 2,
                        validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: authorController,
                        decoration: const InputDecoration(labelText: 'Auteur / Code Employé *'),
                        validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: startDateController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Date/Heure Début',
                          suffixIcon: Icon(Icons.calendar_today, size: 18),
                        ),
                        onTap: () async {
                          final picked = await pickDT(startDate);
                          if (picked != null) {
                            setDialogState(() {
                              startDate = picked;
                              startDateController.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')} ${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                            });
                            recalc();
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: endDateController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Date/Heure Fin',
                          suffixIcon: Icon(Icons.event_available, size: 18),
                        ),
                        onTap: () async {
                          final picked = await pickDT(endDate);
                          if (picked != null) {
                            setDialogState(() {
                              endDate = picked;
                              endDateController.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')} ${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                            });
                            recalc();
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: actualHoursController,
                              decoration: const InputDecoration(labelText: 'Heures réelles (auto)'),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: totalHoursController,
                              decoration: const InputDecoration(labelText: 'Heures totales (auto)'),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
                        await widget.otService.createDocument(widget.otCode, {
                          "woefEmployee": authorController.text.trim(),
                          "reemDescription": "Intervenant",
                          "woefUserStatus": contentController.text.trim(),
                          "woefStartDate": startDate.toIso8601String(),
                          "woefEndDate": endDate.toIso8601String(),
                          "woefActualHours": double.tryParse(actualHoursController.text) ?? 0.0,
                          "woefTotalHours": double.tryParse(totalHoursController.text) ?? 0.0,
                        });
                        _loadComments();
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
      },
    );
  }

  void _showEditDialog(Map<String, dynamic> comment) {
    final formKey = GlobalKey<FormState>();
    final contentController = TextEditingController(text: comment['woefUserStatus']?.toString() ?? '');
    final currentUser = HiveService.getCurrentUser();
    final authorController = TextEditingController(
      text: comment['woefEmployee']?.toString() ?? comment['reemCode']?.toString() ?? (currentUser?.code ?? '5893')
    );
    final pk = (comment['pkComment'] ?? comment['pkEmployeeFeedback'] ?? 0) as int;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Modifier le commentaire'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: contentController,
                  decoration: const InputDecoration(labelText: 'Commentaire *'),
                  maxLines: 3,
                  validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                ),
                TextFormField(
                  controller: authorController,
                  decoration: const InputDecoration(labelText: 'Auteur / Code Employé *'),
                  validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
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
                    await widget.otService.updateDocument(widget.otCode, pk, {
                      "woefEmployee": authorController.text.trim(),
                      "reemDescription": comment['reemDescription'] ?? "Intervenant",
                      "woefUserStatus": contentController.text.trim(),
                      "woefStartDate": comment['woefStartDate'] ?? DateTime.now().toIso8601String(),
                      "woefEndDate": comment['woefEndDate'] ?? DateTime.now().toIso8601String(),
                    });
                    _loadComments();
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
          title: const Text('Supprimer le commentaire'),
          content: const Text('Voulez-vous supprimer ce commentaire ?'),
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
                  await widget.otService.deleteDocument(widget.otCode, pk);
                  _loadComments();
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
                'Commentaires / Rapports',
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
          child: _comments.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.comment_bank, size: 64, color: Color(0xFF0F1B80)),
                      SizedBox(height: 16),
                      Text('Aucun commentaire pour cet OT', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _comments.length,
                  itemBuilder: (context, index) {
                    final fb = _comments[index];
                    final commentText = fb['wodoComment']?.toString() ??
                        fb['wodoDescription']?.toString() ??
                        fb['wodoText']?.toString() ??
                        fb['comment']?.toString() ??
                        fb['reemDescription']?.toString() ??
                        'Commentaire sans texte';
                    final author = fb['wodoCreationUser']?.toString() ??
                        fb['wodoUser']?.toString() ??
                        fb['author']?.toString() ??
                        fb['woefEmployee']?.toString() ??
                        'Agent';
                    final docType = fb['wodoType']?.toString() ?? fb['type']?.toString() ?? '';
                    final dateStr = _formatDate(fb['wodoCreationDate'] ?? fb['woefStartDate'] ?? fb['createdAt']);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.account_circle, color: Color(0xFF0F1B80), size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    author,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2B1D4C)),
                                  ),
                                ),
                                if (docType.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F1B80).withAlpha(20),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      docType,
                                      style: const TextStyle(color: Color(0xFF0F1B80), fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              commentText,
                              style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.3),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                const Icon(Icons.access_time, size: 13, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  dateStr,
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
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

  String _formatDate(dynamic raw) {
    final s = raw?.toString() ?? '';
    if (s.isEmpty) return '';
    return s.replaceAll('T', ' ').substring(0, s.length > 16 ? 16 : s.length);
  }
}

/// Widget pour afficher la barre d'actions en haut de l'onglet Commentaires
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage de la barre d'actions
class _CommentairesActionBar extends StatelessWidget {
  final VoidCallback onAddTap;

  const _CommentairesActionBar({required this.onAddTap});

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Container(
      color: Colors.grey[200],
      padding: spacing.custom(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          // Icône maison (home)
          InkWell(
            onTap: () {
              Navigator.pop(context);
            },
            child: const Icon(Icons.home, color: Color(0xFF0F1B80), size: 24),
          ),
          SizedBox(width: spacing.medium),
          // Icône ajouter - ajoute une nouvelle pièce jointe
          InkWell(
            onTap: onAddTap,
            child: const Icon(Icons.add, color: Color(0xFF0F1B80), size: 24),
          ),
          SizedBox(width: spacing.medium),
          // Icône télécharger
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Télécharger')));
            },
            child: const Icon(
              Icons.download,
              color: Color(0xFF0F1B80),
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget qui affiche une pièce jointe avec son commentaire
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage d'un bloc pièce jointe + commentaire
/// Principe DRY: Widget réutilisable pour tous les blocs
class _CommentaireWithAttachmentItem extends StatelessWidget {
  final VoidCallback onDelete;

  const _CommentaireWithAttachmentItem({required this.onDelete});

  /// Gestion du clic sur l'icône de trombone
  void _handleAttachFile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FichierLieScreen()),
    );
  }

  /// Gestion du clic sur l'icône de microphone
  void _handleMicrophone(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enregistrement vocal (à implémenter)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final responsive = context.responsive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Zone de pièce jointe avec icône de trombone et poubelle
        Container(
          width: double.infinity,
          height: responsive.hp(10),
          padding: spacing.custom(all: 12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // Icône de trombone dans un cercle bleu (cliquable)
              InkWell(
                onTap: () => _handleAttachFile(context),
                borderRadius: BorderRadius.circular(100),
                child: Container(
                  width: responsive.wp(10),
                  height: responsive.wp(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F1B80),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.attach_file,
                    color: Colors.white,
                    size: responsive.iconSize(20),
                  ),
                ),
              ),
              SizedBox(width: spacing.small),
              // Espace pour afficher le nom du fichier
              Expanded(
                child: Text(
                  '', // Vide pour l'instant
                  style: TextStyle(
                    fontFamily: AppTheme.fontRoboto,
                    fontSize: responsive.sp(14),
                    color: AppTheme.secondaryColor,
                  ),
                ),
              ),
              // Icône de poubelle pour supprimer
              InkWell(
                onTap: onDelete,
                child: Icon(
                  Icons.delete,
                  color: Colors.red,
                  size: responsive.iconSize(24),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: spacing.small),

        // Zone de commentaire avec icône de microphone cliquable
        Container(
          width: double.infinity,
          height: responsive.hp(12),
          padding: spacing.custom(all: 12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icône de microphone cliquable
              InkWell(
                onTap: () => _handleMicrophone(context),
                child: Icon(
                  Icons.mic_none,
                  color: const Color(0xFF0F1B80),
                  size: responsive.iconSize(24),
                ),
              ),
              SizedBox(width: spacing.small),
              // Zone de texte pour écrire le commentaire
              Expanded(
                child: TextFormField(
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: 'Écrire un commentaire...',
                    hintStyle: TextStyle(
                      fontFamily: AppTheme.fontRoboto,
                      fontSize: responsive.sp(14),
                      color: Colors.grey[500],
                    ),
                    border: InputBorder.none,
                  ),
                  style: TextStyle(
                    fontFamily: AppTheme.fontRoboto,
                    fontSize: responsive.sp(14),
                    color: const Color(0xFF0F1B80),
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

/// Widget qui affiche les boutons en bas de l'onglet Commentaires
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage des boutons d'action
class _CommentairesBottomButton extends StatelessWidget {
  /// Gestion du clic sur le bouton Enregistrer
  void _handleSave(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Commentaires enregistrés')));
  }

  /// Gestion du clic sur le bouton Retour - retour à la page OT Info
  void _handleBack(BuildContext context) {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final responsive = context.responsive;

    return Container(
      color: Colors.white,
      padding: spacing.custom(horizontal: 20, vertical: 10, bottom: 20),
      child: Row(
        children: [
          // Bouton Enregistrer
          Expanded(
            child: ElevatedButton(
              onPressed: () => _handleSave(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 1, 92, 192), // bleu
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
          SizedBox(width: spacing.medium),
          // Bouton Retour
          Expanded(
            child: ElevatedButton(
              onPressed: () => _handleBack(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: const Color.fromARGB(255, 1, 92, 192),
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
        ],
      ),
    );
  }
}

/// Onglet "Mains d'œuvre" - Affiche la liste des employés affectés avec sous-onglets
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage des mains d'œuvre
class _MainsOeuvreTab extends StatefulWidget {
  final String otCode;
  final OTService otService;

  const _MainsOeuvreTab({Key? key, required this.otCode, required this.otService}) : super(key: key);

  @override
  State<_MainsOeuvreTab> createState() => _MainsOeuvreTabState();
}

class _MainsOeuvreTabState extends State<_MainsOeuvreTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> employes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
    _loadWorkforce();
  }

  Future<void> _loadWorkforce() async {
    try {
      final list = await widget.otService.getWorkforce(widget.otCode);
      setState(() {
        employes = list.map((item) {
          final isPlanned = item['woeaIsPlanned'] == true ? 'Planifié' : 'Non planifié';
          return {
            'pk':               (item['pkWorkforce'] ?? item['pkEmployeeAllocated'] ?? 0) as int,
            'employe':          item['reemCode']?.toString() ?? item['woeaEmployee']?.toString() ?? '',
            'description':      item['reemDescription']?.toString() ?? item['woeaResource']?.toString() ?? 'Intervenant',
            'dateDebut':        _formatDate(item['woeaAllocationDate']),
            'dateFin':          '',
            'heuresRealisees':  '0',
            'etatOT':           isPlanned,
            'ressource':        item['woeaResource']?.toString() ?? 'RDEF',
            'heuresPlanifiees': item['woeaPlannedHours']?.toString() ?? '0',
            'heuresJour':       '0',
            'taux':             'Taux normal',
            'etatRejet':        item['woeaQualifRejection']?.toString()
                               ?? item['woeaQualificationRejection']?.toString()
                               ?? item['woeaQualifRej']?.toString()
                               ?? '',
            'aPermis':          item['woeaWorkPermit']?.toString()
                               ?? item['woeaPermit']?.toString()
                               ?? item['woeaHasPermit']?.toString()
                               ?? '',
            'sequence':         item['woeaSequence']?.toString()
                               ?? item['woeaSeq']?.toString()
                               ?? item['woeaSequenceNumber']?.toString()
                               ?? '',
          };
        }).toList();
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
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser;
    final userMatricule = currentUser?.code ?? currentUser?.username ?? '';
    final userName = currentUser?.username ?? '';

    final codeController = TextEditingController(text: userMatricule);
    final nameController = TextEditingController(text: userName);
    final hoursController = TextEditingController(text: '1.0');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Affecter un intervenant'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: codeController,
                  decoration: const InputDecoration(labelText: 'Code employé *'),
                  validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                ),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nom de l\'employé *'),
                  validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                ),
                TextFormField(
                  controller: hoursController,
                  decoration: const InputDecoration(labelText: 'Heures planifiées'),
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
                    await widget.otService.createWorkforce(widget.otCode, {
                      "woeaEmployee": codeController.text.trim(),
                      "woeaResource": nameController.text.trim(),
                      "woeaPlannedHours": double.tryParse(hoursController.text) ?? 1.0,
                      "woeaAllocationDate": DateTime.now().toIso8601String(),
                      "woeaIsPlanned": true,
                    });
                    _loadWorkforce();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                  }
                }
              },
              child: const Text('Affecter'),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(Map<String, dynamic> emp) {
    final formKey = GlobalKey<FormState>();
    final codeController = TextEditingController(text: emp['employe']?.toString() ?? '');
    final nameController = TextEditingController(text: emp['description']?.toString() ?? '');
    final hoursController = TextEditingController(text: emp['heuresPlanifiees']?.toString() ?? '1.0');
    final pk = emp['pk'] as int;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Modifier l\'affectation'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: codeController,
                  decoration: const InputDecoration(labelText: 'Code employé *'),
                  validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                ),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nom de l\'employé *'),
                  validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                ),
                TextFormField(
                  controller: hoursController,
                  decoration: const InputDecoration(labelText: 'Heures planifiées'),
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
                    await widget.otService.updateWorkforce(widget.otCode, pk, {
                      "woeaEmployee": codeController.text.trim(),
                      "woeaResource": nameController.text.trim(),
                      "woeaPlannedHours": double.tryParse(hoursController.text) ?? 1.0,
                      "woeaAllocationDate": DateTime.now().toIso8601String(),
                      "woeaIsPlanned": true,
                    });
                    _loadWorkforce();
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
          title: const Text('Supprimer l\'affectation'),
          content: const Text('Voulez-vous retirer cet intervenant de l\'OT ?'),
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
                  await widget.otService.deleteWorkforce(widget.otCode, pk);
                  _loadWorkforce();
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

  String _formatDate(dynamic raw) {
    final s = raw?.toString() ?? '';
    if (s.isEmpty) return '';
    return s.replaceAll('T', ' ').substring(0, s.length > 16 ? 16 : s.length);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        _MainsOeuvreActionBar(onAddPressed: _showAddDialog),
        _ActionSearchBar(),
        _MainsOeuvreTabBar(tabController: _tabController),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _IntervenantsContent(
                employes: employes,
                onEdit: _showEditDialog,
                onDelete: _confirmDelete,
              ),
              _EmployesAllouesContent(employes: employes),
            ],
          ),
        ),
      ],
    );
  }
}

/// Widget pour afficher la barre d'onglets fonctionnelle (Intervenants / Employés Alloués / Ressources)
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage des onglets cliquables
/// Principe DRY: Réutilise le pattern TabBar standard de Flutter
class _MainsOeuvreTabBar extends StatelessWidget {
  final TabController tabController;

  const _MainsOeuvreTabBar({required this.tabController});

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Container(
      color: Colors.grey[200],
      child: TabBar(
        controller: tabController,
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.secondaryColor,
        indicator: BoxDecoration(
          color: const Color(0xFF0F1B80),
          borderRadius: BorderRadius.circular(4),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: TextStyle(
          fontFamily: AppTheme.fontMontserrat,
          fontWeight: FontWeight.w600,
          fontSize: responsive.sp(12),
        ),
        tabs: const [Tab(text: 'INTERVENANTS'), Tab(text: 'EMPLOYÉS ALLOUÉS')],
      ),
    );
  }
}

/// Widget pour afficher le contenu de l'onglet Intervenants
/// Principe SOLID: Single Responsibility - Gère uniquement le contenu de l'onglet Intervenants
class _IntervenantsContent extends StatelessWidget {
  final List<Map<String, dynamic>> employes;
  final Function(Map<String, dynamic>) onEdit;
  final Function(int) onDelete;

  const _IntervenantsContent({
    required this.employes,
    required this.onEdit,
    required this.onDelete,
  });

  void _showRowOptions(BuildContext context, Map<String, dynamic> emp) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Modifier'),
                onTap: () {
                  Navigator.pop(context);
                  onEdit(emp);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Supprimer'),
                onTap: () {
                  Navigator.pop(context);
                  onDelete(emp['pk'] as int);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Column(
      children: [
        // En-tête du tableau
        _TableHeader(),
        // Corps du tableau avec liste d'employés
        Expanded(
          child: ListView.builder(
            padding: spacing.custom(horizontal: 10, vertical: 5),
            itemCount: employes.length,
            itemBuilder: (context, index) {
              final employe = employes[index];
              return GestureDetector(
                onTap: null,
                behavior: HitTestBehavior.opaque,
                child: _EmployeRow(
                  index: index + 1,
                  employe: employe['employe']!,
                  description: employe['description']!,
                  dateDebut: employe['dateDebut']!,
                  dateFin: employe['dateFin']!,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Widget pour afficher le contenu de l'onglet Employés Alloués avec sous-onglet DÉTAILS
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage du contenu Employés Alloués
class _EmployesAllouesContent extends StatefulWidget {
  final List<Map<String, dynamic>> employes;

  const _EmployesAllouesContent({required this.employes});

  @override
  State<_EmployesAllouesContent> createState() =>
      _EmployesAllouesContentState();
}

class _EmployesAllouesContentState extends State<_EmployesAllouesContent> {
  bool _showDetails = false; // État pour afficher ou masquer les détails

  Map<String, dynamic>? _selectedEmployee;

  void _toggleDetails([Map<String, dynamic>? employee]) {
    setState(() {
      _selectedEmployee = employee;
      _showDetails = !_showDetails;
    });
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final responsive = context.responsive;

    if (_showDetails) {
      // Affiche le formulaire de détails avec les données de l'employé sélectionné
      return _EmployesAllouesDetailsTab(
        onBack: () => _toggleDetails(null),
        initialData: _selectedEmployee,
      );
    }

    // Affiche directement le tableau des employés alloués (image fournie)
    return Column(
      children: [
        // En-tête du tableau avec toutes les colonnes
        _EmployesAllouesTableHeader(),

        // Liste scrollable des employés
        Expanded(
          child: widget.employes.isEmpty
              ? const Center(child: Text('Aucun employé alloué pour cet OT', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: widget.employes.length,
                  itemBuilder: (context, index) {
                    final employe = widget.employes[index];
                    return GestureDetector(
                      onTap: () => _toggleDetails(employe),
                      behavior: HitTestBehavior.opaque,
                      child: _EmployesAllouesRow(
                        index: index + 1,
                        employe: employe['employe'] ?? '',
                        description: employe['description'] ?? '',
                        dateAllocation: employe['dateDebut'] ?? '',
                        heuresAllouees: employe['heuresPlanifiees'] ?? '0',
                        etatAllocation: employe['etatOT'] ?? '0. Non réalisé',
                        etatRejet: '0. Pas d\'objection',
                        aPermis: '0. Non',
                        numeroSequence: '',
                      ),
                    );
                  },
                ),
        ),

        // Bouton DÉTAILS en bas (ouvre le premier employé s'il y en a)
        Container(
          color: Colors.white,
          padding: spacing.custom(horizontal: 20, vertical: 10, bottom: 20),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (widget.employes.isNotEmpty) {
                  _toggleDetails(widget.employes.first);
                } else {
                  _toggleDetails(null);
                }
              },
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
                'DÉTAILS',
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

/// Widget pour afficher le formulaire de détails d'un employé alloué
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage du formulaire
/// Principe DRY: Réutilise les patterns de formulaire existants
class _EmployesAllouesDetailsTab extends StatefulWidget {
  final VoidCallback onBack;
  final Map<String, dynamic>? initialData;

  const _EmployesAllouesDetailsTab({required this.onBack, this.initialData});

  @override
  State<_EmployesAllouesDetailsTab> createState() =>
      _EmployesAllouesDetailsTabState();
}

class _EmployesAllouesDetailsTabState
    extends State<_EmployesAllouesDetailsTab> {
  // Contrôleurs pour les champs du formulaire
  late TextEditingController _employeController;
  late TextEditingController _descriptionController;
  late TextEditingController _dateAllocationController;
  late TextEditingController _heuresAlloueesController;
  late TextEditingController _etatAllocationController;
  late TextEditingController _etatRejetController;
  late TextEditingController _aPermisController;
  late TextEditingController _numeroSequenceController;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    final currentUser = HiveService.getCurrentUser();
    
    // Initialisation des contrôleurs avec données réelles si disponibles, sinon exemples
    _employeController = TextEditingController(
      text: data != null ? '${data['employe']}' : '${currentUser?.code ?? "5893"}',
    );
    _descriptionController = TextEditingController(
      text: data != null ? (data['description']?.toString() ?? '') : (currentUser?.username ?? 'Intervenant'),
    );
    _dateAllocationController = TextEditingController(
      text: data != null ? (data['dateDebut']?.toString() ?? '') : '22/10/2025 07:30',
    );
    _heuresAlloueesController = TextEditingController(
      text: data != null ? (data['heuresPlanifiees']?.toString() ?? '0') : '3.00',
    );
    _etatAllocationController = TextEditingController(
      text: data != null ? (data['etatOT']?.toString() ?? '0. Non réalisé') : '0. Non réalisé',
    );
    _etatRejetController = TextEditingController(
      text: data != null && data['etatRejet'] != null ? data['etatRejet'].toString() : '',
    );
    _aPermisController = TextEditingController(
      text: data != null && data['aPermis'] != null ? data['aPermis'].toString() : '',
    );
    _numeroSequenceController = TextEditingController(
      text: data != null && data['sequence'] != null ? data['sequence'].toString() : '',
    );
  }

  @override
  void dispose() {
    _employeController.dispose();
    _descriptionController.dispose();
    _dateAllocationController.dispose();
    _heuresAlloueesController.dispose();
    _etatAllocationController.dispose();
    _etatRejetController.dispose();
    _aPermisController.dispose();
    _numeroSequenceController.dispose();
    super.dispose();
  }


  /// Affiche le sélecteur de date
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: AppTheme.secondaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateAllocationController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
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
                // Barre d'icônes d'action (similaire à l'image)
                _EmployesAllouesActionBar(),
                SizedBox(height: spacing.large),

                // Ligne 1: Employé et Description de l'employé
                Row(
                  children: [
                    Expanded(
                      child: _EmployeFormField(
                        label: 'Employé',
                        controller: _employeController,
                        hasDropdown: true,
                      ),
                    ),
                    SizedBox(width: spacing.medium),
                    Expanded(
                      child: _EmployeFormField(
                        label: 'Description de l\'employé',
                        controller: _descriptionController,
                        readOnly: true,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing.medium),

                // Ligne 2: Date d'allocation et Heures allouées
                Row(
                  children: [
                    Expanded(
                      child: _EmployeFormField(
                        label: 'Date d\'allocation',
                        controller: _dateAllocationController,
                        isDateField: true,
                        backgroundColor: const Color(0xFFFFFF99), // Fond jaune
                        onDateTap: _selectDate,
                      ),
                    ),
                    SizedBox(width: spacing.medium),
                    Expanded(
                      child: _EmployeFormField(
                        label: 'Heures allouées',
                        controller: _heuresAlloueesController,
                        backgroundColor: const Color(0xFFFFFF99), // Fond jaune
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing.medium),

                // Ligne 3: État de l'allocation et État de rejet de la qualification
                Row(
                  children: [
                    Expanded(
                      child: _EmployeFormField(
                        label: 'État de l\'allocation',
                        controller: _etatAllocationController,
                        hasDropdown: true,
                      ),
                    ),
                    SizedBox(width: spacing.medium),
                    Expanded(
                      child: _EmployeFormField(
                        label: 'État de rejet de la qualification',
                        controller: _etatRejetController,
                        hasDropdown: true,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing.medium),

                // Ligne 4: À des permis de travail
                Row(
                  children: [
                    Expanded(
                      child: _EmployeFormField(
                        label: 'À des permis de travail',
                        controller: _aPermisController,
                        hasDropdown: true,
                      ),
                    ),
                    SizedBox(width: spacing.medium),
                    Expanded(child: Container()), // Espace vide pour alignement
                  ],
                ),
                SizedBox(height: spacing.large),

                // Ligne 5: N° de séquence et Action
                Row(
                  children: [
                    Expanded(
                      child: _EmployeFormField(
                        label: 'N° de séquence',
                        controller: _numeroSequenceController,
                      ),
                    ),
                    SizedBox(width: spacing.medium),
                    Expanded(
                      child: _EmployeFormField(
                        label: 'Action',
                        controller: TextEditingController(),
                        hasDropdown: true,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing.medium),

                // Champ Action large (en dessous)
                Container(
                  width: double.infinity,
                  height: responsive.hp(15),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: TextFormField(
                    maxLines: null,
                    expands: true,
                    decoration: InputDecoration(
                      contentPadding: spacing.custom(all: 10),
                      border: InputBorder.none,
                    ),
                  ),
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

/// Widget pour afficher la barre d'action avec icônes pour les employés alloués
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage des icônes d'action
class _EmployesAllouesActionBar extends StatelessWidget {
  const _EmployesAllouesActionBar();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

/// Widget pour un champ de formulaire employé
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage d'un champ
/// Principe DRY: Réutilisable pour tous les champs du formulaire
class _EmployeFormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool hasDropdown;
  final bool isDateField;
  final bool readOnly;
  final bool enabled;
  final Color? backgroundColor;
  final VoidCallback? onDateTap;
  final Function(String)? onChanged;

  const _EmployeFormField({
    required this.label,
    required this.controller,
    this.hasDropdown = false,
    this.isDateField = false,
    this.readOnly = false,
    this.enabled = true,
    this.backgroundColor,
    this.onDateTap,
    this.onChanged,
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
            fontSize: responsive.sp(13),
          ),
        ),
        SizedBox(height: spacing.tiny),
        Container(
          decoration:
              backgroundColor != null
                  ? BoxDecoration(
                    color: backgroundColor,
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(4),
                  )
                  : null,
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller,
                  enabled: enabled,
                  readOnly: readOnly || isDateField,
                  onChanged: onChanged,
                  style: TextStyle(
                    color: AppTheme.secondaryColor,
                    fontFamily: AppTheme.fontRoboto,
                    fontSize: responsive.sp(13),
                  ),
                  decoration: InputDecoration(
                    contentPadding: spacing.custom(vertical: 8, horizontal: 8),
                    border:
                        backgroundColor == null
                            ? const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey),
                            )
                            : InputBorder.none,
                  ),
                ),
              ),
              if (hasDropdown)
                InkWell(
                  onTap: () {},
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.arrow_drop_down,
                      color: AppTheme.secondaryColor,
                      size: responsive.iconSize(20),
                    ),
                  ),
                ),
              if (isDateField)
                InkWell(
                  onTap: onDateTap,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.calendar_today,
                      color: AppTheme.secondaryColor,
                      size: responsive.iconSize(18),
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

/// Widget pour afficher la barre de sous-onglets avec bouton +
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage des sous-onglets
class _SubTabsBar extends StatelessWidget {
  final List<String> tabs;
  final TabController tabController;
  final VoidCallback onAddTap;

  const _SubTabsBar({
    required this.tabs,
    required this.tabController,
    required this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final spacing = context.spacing;

    return Container(
      color: Colors.grey[200],
      padding: spacing.custom(horizontal: 10, vertical: 5),
      child: Row(
        children: [
          // Flèche gauche pour navigation
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 16),
            onPressed: () {},
            color: AppTheme.secondaryColor,
          ),
          // Flèche droite pour navigation
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 16),
            onPressed: () {},
            color: AppTheme.secondaryColor,
          ),
          // Bouton +
          IconButton(
            icon: const Icon(Icons.add, size: 20),
            onPressed: onAddTap,
            color: AppTheme.secondaryColor,
            tooltip: 'Ajouter un employé',
          ),
          SizedBox(width: spacing.small),
          // Onglets DÉTAILS / GLOBAL
          Expanded(
            child: TabBar(
              controller: tabController,
              labelColor: Colors.white,
              unselectedLabelColor: AppTheme.secondaryColor,
              indicator: BoxDecoration(
                color: const Color(0xFF0F1B80),
                borderRadius: BorderRadius.circular(4),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: TextStyle(
                fontFamily: AppTheme.fontMontserrat,
                fontWeight: FontWeight.w600,
                fontSize: responsive.sp(12),
              ),
              tabs: tabs.map((tab) => Tab(text: tab)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget pour afficher l'onglet DÉTAILS avec les informations de l'employé
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage des détails de l'employé
/// Principe DRY: Réutilise le pattern de formulaire de ot_info_details_screen
class _EmployeDetailsTab extends StatelessWidget {
  final Map<String, dynamic> employe;

  const _EmployeDetailsTab({required this.employe});

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final responsive = context.responsive;

    return SingleChildScrollView(
      padding: spacing.custom(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ligne 1: Employé et Description
          Row(
            children: [
              Expanded(
                child: _DetailField(
                  label: 'Employé',
                  value: employe['employe'] ?? '5893',
                  hasDropdown: true,
                ),
              ),
              SizedBox(width: spacing.medium),
              Expanded(
                child: _DetailField(
                  label: '',
                  value: employe['description'] ?? 'Intervenant',
                  readOnly: true,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.medium),

          // Ligne 2: Date d'allocation et Heures allouées
          Row(
            children: [
              Expanded(
                child: _DetailField(
                  label: 'Date d\'allocation',
                  value: employe['dateDebut'] ?? '22/10/2025 07:30',
                  hasDatePicker: true,
                ),
              ),
              SizedBox(width: spacing.medium),
              Expanded(
                child: _DetailField(
                  label: 'Heures allouées',
                  value: employe['heuresRealisees'] ?? '3,00',
                  backgroundColor: const Color(0xFFFFFF99), // Fond jaune
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.medium),

          // Ligne 3: État de l'allocation et État de rejet de la qualification
          Row(
            children: [
              Expanded(
                child: _DetailField(
                  label: 'État de l\'allocation',
                  value: employe['etatOT'] ?? '0. Non réalisé',
                  hasDropdown: true,
                ),
              ),
              SizedBox(width: spacing.medium),
              Expanded(
                child: _DetailField(
                  label: 'État de rejet de la qualification',
                  value: '0. Pas d\'objection',
                  hasDropdown: true,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.medium),

          // Ligne 4: À des permis de travail et N° de séquence
          Row(
            children: [
              Expanded(
                child: _DetailField(
                  label: 'À des permis de travail',
                  value: '0. Non',
                  hasDropdown: true,
                ),
              ),
              SizedBox(width: spacing.medium),
              Expanded(child: _DetailField(label: 'N° de séquence', value: '')),
            ],
          ),
          SizedBox(height: spacing.medium),

          // Ligne 5: Action
          Row(
            children: [
              Expanded(
                flex: 1,
                child: _DetailField(label: 'Action', value: ''),
              ),
              SizedBox(width: spacing.medium),
              Expanded(flex: 1, child: Container()),
            ],
          ),
        ],
      ),
    );
  }
}

/// Widget pour afficher l'onglet GLOBAL
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage de la vue globale
class _GlobalTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Vue globale (à implémenter)',
        style: TextStyle(
          fontFamily: AppTheme.fontMontserrat,
          color: AppTheme.secondaryColor,
        ),
      ),
    );
  }
}

/// Widget pour afficher un champ de détail avec label
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage d'un champ
/// Principe DRY: Réutilisable pour tous les champs de détails
class _DetailField extends StatelessWidget {
  final String label;
  final String value;
  final bool hasDropdown;
  final bool hasDatePicker;
  final bool readOnly;
  final Color? backgroundColor;

  const _DetailField({
    required this.label,
    required this.value,
    this.hasDropdown = false,
    this.hasDatePicker = false,
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
        if (label.isNotEmpty)
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontMontserrat,
              fontWeight: FontWeight.w600,
              color: AppTheme.secondaryColor,
              fontSize: responsive.sp(13),
            ),
          ),
        if (label.isNotEmpty) SizedBox(height: spacing.tiny),
        Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(color: AppTheme.thirdColor),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: value,
                  readOnly: readOnly,
                  style: TextStyle(
                    color: AppTheme.secondaryColor,
                    fontFamily: AppTheme.fontRoboto,
                    fontSize: responsive.sp(13),
                  ),
                  decoration: InputDecoration(
                    contentPadding: spacing.custom(vertical: 8, horizontal: 8),
                    border: InputBorder.none,
                  ),
                ),
              ),
              if (hasDropdown)
                Icon(
                  Icons.arrow_drop_down,
                  color: AppTheme.secondaryColor,
                  size: responsive.iconSize(24),
                ),
              if (hasDatePicker)
                Icon(
                  Icons.calendar_today,
                  color: AppTheme.secondaryColor,
                  size: responsive.iconSize(18),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Widget pour afficher une carte d'employé avec ses informations
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage d'une carte d'employé
/// Principe DRY: Réutilise le pattern _FormField pour chaque champ
class _EmployeCard extends StatelessWidget {
  final String employe;
  final String dateDebut;
  final String dateFin;

  const _EmployeCard({
    required this.employe,
    required this.dateDebut,
    required this.dateFin,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Container(
      padding: spacing.custom(all: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Champ Employé (lecture seule via _DetailField)
          _DetailField(label: 'Employé', value: employe, readOnly: true),
          SizedBox(height: spacing.large),

          // Champ Date de début (utilise hasDatePicker pour afficher l'icône)
          _DetailField(
            label: 'Date de début',
            value: dateDebut,
            hasDatePicker: true,
          ),
          SizedBox(height: spacing.large),

          // Champ Date de fin
          _DetailField(
            label: 'Date de fin',
            value: dateFin,
            hasDatePicker: true,
          ),
        ],
      ),
    );
  }
}

/// Widget pour afficher un champ de formulaire dans la carte employé
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage d'un champ
/// Principe DRY: Inspiré du widget _FormField de ot_info_details_screen
/// Widget pour afficher le contenu de l'onglet Ressources
/// Principe SOLID: Single Responsibility - Gère uniquement le contenu de l'onglet Ressources
class _RessourcesContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Contenu Ressources à implémenter',
        style: TextStyle(
          fontFamily: AppTheme.fontMontserrat,
          color: AppTheme.secondaryColor,
        ),
      ),
    );
  }
}

/// Widget pour afficher la barre d'actions en haut de l'onglet Mains d'œuvre
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage de la barre d'actions avec icônes
/// Principe DRY: Réutilise le pattern des autres barres d'action
class _MainsOeuvreActionBar extends StatelessWidget {
  final VoidCallback onAddPressed;

  const _MainsOeuvreActionBar({required this.onAddPressed});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

/// Widget pour afficher une icône d'action cliquable
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage d'une icône d'action
/// Principe DRY: Réutilisable pour toutes les icônes d'action
class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _ActionIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          icon,
          color: const Color(0xFF0F1B80),
          size: responsive.iconSize(20),
        ),
      ),
    );
  }
}

/// Widget pour afficher la barre "Action" avec champ de recherche
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage de la barre de recherche
class _ActionSearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

/// Widget pour afficher la barre des onglets (Intervenants / Employés Alloués / Ressources)
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage des onglets
class _TabsBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final responsive = context.responsive;

    return Container(
      color: Colors.grey[200],
      padding: spacing.custom(horizontal: 15, vertical: 8),
      child: Row(
        children: [
          _TabButton(label: 'INTERVENANTS', isActive: true),
          SizedBox(width: spacing.small),
          _TabButton(label: 'EMPLOYÉS ALLOUÉS', isActive: false),
          SizedBox(width: spacing.small),
          _TabButton(label: 'RESSOURCES', isActive: false),
        ],
      ),
    );
  }
}

/// Widget pour afficher un bouton d'onglet
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage d'un bouton d'onglet
/// Principe DRY: Réutilisable pour tous les onglets
class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;

  const _TabButton({required this.label, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final responsive = context.responsive;

    return Container(
      padding: spacing.custom(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF0F1B80) : Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isActive ? const Color(0xFF0F1B80) : AppTheme.thirdColor,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTheme.fontMontserrat,
          fontWeight: FontWeight.w600,
          color: isActive ? Colors.white : AppTheme.secondaryColor,
          fontSize: responsive.sp(12),
        ),
      ),
    );
  }
}

/// Widget pour afficher l'en-tête du tableau
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage de l'en-tête du tableau
class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final responsive = context.responsive;

    return Container(
      color: const Color(0xFF0F1B80),
      padding: spacing.custom(horizontal: 10, vertical: 12),
      child: Row(
        children: [
          // Colonne numéro
          SizedBox(width: 40, child: _HeaderText('', responsive)),
          // Colonne Employé
          Expanded(flex: 2, child: _HeaderText('Employé', responsive)),
          // Colonne Description
          Expanded(
            flex: 3,
            child: _HeaderText('Description de l\'employé', responsive),
          ),
          // Colonne Date de début
          Expanded(flex: 2, child: _HeaderText('Date de début', responsive)),
          // Colonne Date de fin
          Expanded(flex: 2, child: _HeaderText('Date de fin', responsive)),
        ],
      ),
    );
  }

  Widget _HeaderText(String text, Responsive responsive) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: AppTheme.fontMontserrat,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        fontSize: responsive.sp(12),
      ),
    );
  }
}

/// Widget pour afficher une ligne d'employé dans le tableau
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage d'une ligne d'employé
/// Principe DRY: Réutilisable pour toutes les lignes d'employés
class _EmployeRow extends StatelessWidget {
  final int index;
  final String employe;
  final String description;
  final String dateDebut;
  final String dateFin;

  const _EmployeRow({
    required this.index,
    required this.employe,
    required this.description,
    required this.dateDebut,
    required this.dateFin,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final responsive = context.responsive;

    return Container(
      padding: spacing.custom(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: index.isOdd ? Colors.white : Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1)),
      ),
      child: Row(
        children: [
          // Numéro de ligne
          SizedBox(width: 40, child: _CellText(index.toString(), responsive)),
          // Employé
          Expanded(flex: 2, child: _CellText(employe, responsive)),
          // Description
          Expanded(flex: 3, child: _CellText(description, responsive)),
          // Date de début
          Expanded(flex: 2, child: _CellText(dateDebut, responsive)),
          // Date de fin
          Expanded(flex: 2, child: _CellText(dateFin, responsive)),
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
        fontSize: responsive.sp(12),
      ),
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Widget pour afficher l'en-tête du tableau Employés Alloués
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage de l'en-tête du tableau
/// Principe DRY: Réutilise le pattern de _TableHeader
class _EmployesAllouesTableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final responsive = context.responsive;

    return Container(
      color: const Color(0xFF0F1B80),
      padding: spacing.custom(horizontal: 10, vertical: 12),
      child: Row(
        children: [
          // Numéro
          SizedBox(width: 40, child: _HeaderText('', responsive)),
          // Employé
          Expanded(flex: 2, child: _HeaderText('Employé', responsive)),
          // Description de l'employé
          Expanded(
            flex: 2,
            child: _HeaderText('Description de l\'employé', responsive),
          ),
          // Date d'allocation
          Expanded(
            flex: 2,
            child: _HeaderText('Date d\'allocation', responsive),
          ),
          // Heures allouées
          Expanded(flex: 2, child: _HeaderText('Heures allouées', responsive)),
          // État de l'allocation
          Expanded(
            flex: 2,
            child: _HeaderText('État de l\'allocation', responsive),
          ),
          // État de rejet de la qualification
          Expanded(
            flex: 2,
            child: _HeaderText('État de rejet de la qualification', responsive),
          ),
          // A des permis de travail
          Expanded(
            flex: 2,
            child: _HeaderText('À des permis de travail', responsive),
          ),
          // N° de séquence
          Expanded(flex: 2, child: _HeaderText('N° de séquence', responsive)),
        ],
      ),
    );
  }

  Widget _HeaderText(String text, Responsive responsive) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: AppTheme.fontMontserrat,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        fontSize: responsive.sp(11),
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 2,
    );
  }
}

/// Widget pour afficher une ligne d'employé alloué dans le tableau
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage d'une ligne
/// Principe DRY: Réutilisable pour toutes les lignes
class _EmployesAllouesRow extends StatelessWidget {
  final int index;
  final String employe;
  final String description;
  final String dateAllocation;
  final String heuresAllouees;
  final String etatAllocation;
  final String etatRejet;
  final String aPermis;
  final String numeroSequence;

  const _EmployesAllouesRow({
    required this.index,
    required this.employe,
    required this.description,
    required this.dateAllocation,
    required this.heuresAllouees,
    required this.etatAllocation,
    required this.etatRejet,
    required this.aPermis,
    required this.numeroSequence,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final responsive = context.responsive;

    return Container(
      padding: spacing.custom(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: index.isOdd ? Colors.white : Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1)),
      ),
      child: Row(
        children: [
          // Numéro
          SizedBox(width: 40, child: _CellText(index.toString(), responsive)),
          // Employé
          Expanded(flex: 2, child: _CellText(employe, responsive)),
          // Description
          Expanded(flex: 2, child: _CellText(description, responsive)),
          // Date d'allocation
          Expanded(flex: 2, child: _CellText(dateAllocation, responsive)),
          // Heures allouées
          Expanded(flex: 2, child: _CellText(heuresAllouees, responsive)),
          // État de l'allocation
          Expanded(flex: 2, child: _CellText(etatAllocation, responsive)),
          // État de rejet
          Expanded(flex: 2, child: _CellText(etatRejet, responsive)),
          // A des permis
          Expanded(flex: 2, child: _CellText(aPermis, responsive)),
          // N° de séquence
          Expanded(flex: 2, child: _CellText(numeroSequence, responsive)),
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
        fontSize: responsive.sp(11),
      ),
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Onglet "Matériel" - Affiche la liste du matériel utilisé avec sous-onglets
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage du matériel
/// Principe DRY: Réutilise le pattern TabController comme _MainsOeuvreTab
class _MaterielTab extends StatefulWidget {
  final String otCode;
  final OTService otService;

  const _MaterielTab({Key? key, required this.otCode, required this.otService}) : super(key: key);

  @override
  State<_MaterielTab> createState() => _MaterielTabState();
}

class _MaterielTabState extends State<_MaterielTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Initialisation du TabController avec 2 onglets (Moyens, Stock)
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barre d'onglets (Moyens / Stock)
        _MaterielTabBar(tabController: _tabController),
        // Contenu des onglets
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Onglet MOYENS
              _MoyensTab(otCode: widget.otCode, otService: widget.otService),
              // Onglet STOCK (avec sous-onglets Pièces et Services)
              _StockTab(otCode: widget.otCode, otService: widget.otService),
            ],
          ),
        ),
      ],
    );
  }
}

/// Widget pour afficher la barre d'onglets du matériel
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage des onglets
/// Principe DRY: Réutilise le pattern de _MainsOeuvreTabBar
class _MaterielTabBar extends StatelessWidget {
  final TabController tabController;

  const _MaterielTabBar({required this.tabController});

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Container(
      color: Colors.grey[200],
      child: TabBar(
        controller: tabController,
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.secondaryColor,
        indicator: BoxDecoration(
          color: const Color(0xFF0F1B80),
          borderRadius: BorderRadius.circular(4),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: TextStyle(
          fontFamily: AppTheme.fontMontserrat,
          fontWeight: FontWeight.w600,
          fontSize: responsive.sp(11),
        ),
        tabs: const [Tab(text: 'MOYENS'), Tab(text: 'STOCK')],
      ),
    );
  }
}

/// Onglet STOCK - Contient les sous-onglets Pièces et Services
/// Principe SOLID: Single Responsibility - Gère uniquement l'onglet Stock
/// Principe DRY: Réutilise le pattern TabController
class _StockTab extends StatefulWidget {
  final String otCode;
  final OTService otService;

  const _StockTab({Key? key, required this.otCode, required this.otService}) : super(key: key);

  @override
  State<_StockTab> createState() => _StockTabState();
}

class _StockTabState extends State<_StockTab>
    with SingleTickerProviderStateMixin {
  late TabController _subTabController;

  @override
  void initState() {
    super.initState();
    // Initialisation du sous-TabController avec 2 onglets (Pièces, Services)
    _subTabController = TabController(length: 2, vsync: this, initialIndex: 0);
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barre de sous-onglets (Pièces / Services)
        _StockSubTabBar(tabController: _subTabController),
        // Contenu des sous-onglets
        Expanded(
          child: TabBarView(
            controller: _subTabController,
            children: [
              // Sous-onglet PIÈCES
              _StockPiecesTab(otCode: widget.otCode, otService: widget.otService),
              // Sous-onglet SERVICES
              _StockServicesTab(otCode: widget.otCode, otService: widget.otService),
            ],
          ),
        ),
      ],
    );
  }
}

/// Widget pour afficher la barre de sous-onglets Stock (Pièces / Services)
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage des sous-onglets
/// Principe DRY: Réutilise le pattern de _StockSubTabBar
class _StockSubTabBar extends StatelessWidget {
  final TabController tabController;

  const _StockSubTabBar({required this.tabController});

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Container(
      color: Colors.grey[300],
      child: TabBar(
        controller: tabController,
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.secondaryColor,
        indicator: BoxDecoration(
          color: const Color(0xFF0F1B80),
          borderRadius: BorderRadius.circular(4),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: TextStyle(
          fontFamily: AppTheme.fontMontserrat,
          fontWeight: FontWeight.w600,
          fontSize: responsive.sp(11),
        ),
        tabs: const [Tab(text: 'PIÈCES'), Tab(text: 'SERVICES')],
      ),
    );
  }
}

/// Onglet MOYENS - Affiche le tableau des moyens depuis les API réelles
class _MoyensTab extends StatefulWidget {
  final String otCode;
  final OTService otService;

  const _MoyensTab({Key? key, required this.otCode, required this.otService}) : super(key: key);

  @override
  State<_MoyensTab> createState() => _MoyensTabState();
}

class _MoyensTabState extends State<_MoyensTab> {
  bool _showDetails = false;

  Map<String, dynamic>? _selectedMoyen;

  void _toggleDetails([Map<String, dynamic>? moyen]) {
    setState(() {
      _selectedMoyen = moyen;
      _showDetails = !_showDetails;
    });
  }

  String _formatDate(dynamic raw) {
    final s = raw?.toString() ?? '';
    if (s.isEmpty) return '';
    return s.replaceAll('T', ' ').substring(0, s.length > 16 ? 16 : s.length);
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    if (_showDetails) {
      return _MoyensDetailsTab(
        onBack: () => _toggleDetails(null),
        initialData: _selectedMoyen,
      );
    }

    return FutureBuilder<List<dynamic>>(
      future: widget.otService.getMoyens(widget.otCode),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF0F1B80)));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }

        final list = snapshot.data ?? [];
        if (list.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.commute, size: 64, color: Color(0xFF0F1B80)),
                SizedBox(height: 16),
                Text('Aucun moyen utilisé pour cet OT', style: TextStyle(fontSize: 16, color: Colors.grey)),
              ],
            ),
          );
        }

        return Column(
          children: [
            _MaterielActionBar(onAddTap: () => _toggleDetails(list.isNotEmpty ? list.first : null)),
            SizedBox(height: spacing.small),
            _MoyensTableHeader(),
            Expanded(
              child: ListView.builder(
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final item         = list[index];
                  final moyen        = item['wofuFacility']?.toString() ?? '';
                  final equipement   = item['wofuEquipment']?.toString() ?? item['reemDescription']?.toString() ?? moyen;
                  final dateDebut    = _formatDate(item['wofuStartDate'] ?? item['wofuAllocationDate'] ?? '');
                  final tempsUtilise = item['wofuDuration']?.toString() ?? item['wofuQuantity']?.toString() ?? '0.00';
                  final dateFin      = _formatDate(item['wofuEndDate'] ?? '');

                  return GestureDetector(
                    onTap: () => _toggleDetails(item),
                    behavior: HitTestBehavior.opaque,
                    child: _MoyensRow(
                      index: index,
                      moyen: moyen,
                      equipement: equipement,
                      dateDebut: dateDebut.isNotEmpty ? dateDebut : '-',
                      tempsUtilise: tempsUtilise,
                      dateFin: dateFin.isNotEmpty ? dateFin : '-',
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}


/// Widget pour afficher le formulaire de détails des moyens
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage du formulaire
/// Principe DRY: Réutilise _EmployeFormField
class _MoyensDetailsTab extends StatefulWidget {
  final VoidCallback onBack;
  final Map<String, dynamic>? initialData;

  const _MoyensDetailsTab({required this.onBack, this.initialData});

  @override
  State<_MoyensDetailsTab> createState() => _MoyensDetailsTabState();
}

class _MoyensDetailsTabState extends State<_MoyensDetailsTab> {
  late TextEditingController _moyenController;
  late TextEditingController _equipementController;
  late TextEditingController _dateDebutController;
  late TextEditingController _tempsUtiliseController;
  late TextEditingController _dateFinController;

  String _formatDate(dynamic raw) {
    final s = raw?.toString() ?? '';
    if (s.isEmpty) return '';
    return s.replaceAll('T', ' ').substring(0, s.length > 16 ? 16 : s.length);
  }

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    final moyen        = data?['wofuFacility']?.toString() ?? '';
    final equipement   = data?['reemDescription']?.toString() ?? moyen;
    final dateDebut    = _formatDate(data?['wofuStartDate'] ?? data?['wofuAllocationDate'] ?? '');
    final tempsUtilise = data?['wofuDuration']?.toString() ?? data?['wofuQuantity']?.toString() ?? '0.00';
    final dateFin      = _formatDate(data?['wofuEndDate'] ?? '');

    _moyenController = TextEditingController(text: moyen.isNotEmpty ? moyen : 'VEHICULE');
    _equipementController = TextEditingController(text: equipement.isNotEmpty ? equipement : 'AA-555-BA');
    _dateDebutController = TextEditingController(text: dateDebut.isNotEmpty ? dateDebut : '21/10/2025 07:30');
    _tempsUtiliseController = TextEditingController(text: tempsUtilise);
    _dateFinController = TextEditingController(text: dateFin.isNotEmpty ? dateFin : '21/10/2025 07:30');
  }

  @override
  void dispose() {
    _moyenController.dispose();
    _equipementController.dispose();
    _dateDebutController.dispose();
    _tempsUtiliseController.dispose();
    _dateFinController.dispose();
    super.dispose();
  }

  Future<void> _selectDateDebut() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF0F1B80)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateDebutController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year} 07:30';
        _calculateDateFin();
      });
    }
  }

  /// Calcule automatiquement la date de fin en fonction de la date de début et du temps utilisé
  void _calculateDateFin() {
    try {
      final dateDebutText = _dateDebutController.text;
      final tempsUtiliseText = _tempsUtiliseController.text;

      final parts = dateDebutText.split(' ');
      final dateParts = parts[0].split('/');

      if (dateParts.length >= 3 && tempsUtiliseText.isNotEmpty) {
        final day = int.parse(dateParts[0]);
        final month = int.parse(dateParts[1]);
        final year = int.parse(dateParts[2]);

        DateTime debut = DateTime(year, month, day);
        final heures = double.parse(tempsUtiliseText);
        final fin = debut.add(Duration(hours: heures.toInt()));

        setState(() {
          _dateFinController.text =
              '${fin.day.toString().padLeft(2, '0')}/${fin.month.toString().padLeft(2, '0')}/${fin.year} ${fin.hour.toString().padLeft(2, '0')}:00';
        });
      }
    } catch (e) {
      // En cas d'erreur, ne rien faire
    }
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
                _MaterielActionBar(onAddTap: () {}),
                SizedBox(height: spacing.large),

                // Ligne 1: Moyen et Équipement
                Row(
                  children: [
                    Expanded(
                      child: _EmployeFormField(
                        label: 'Moyen',
                        controller: _moyenController,
                        hasDropdown: true,
                      ),
                    ),
                    SizedBox(width: spacing.medium),
                    Expanded(
                      child: _EmployeFormField(
                        label: 'Équipement',
                        controller: _equipementController,
                        hasDropdown: true,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing.medium),

                // Ligne 2: Date de début et Temps utilisé
                Row(
                  children: [
                    Expanded(
                      child: _EmployeFormField(
                        label: 'Date de début',
                        controller: _dateDebutController,
                        isDateField: true,
                        onDateTap: _selectDateDebut,
                      ),
                    ),
                    SizedBox(width: spacing.medium),
                    Expanded(
                      child: _EmployeFormField(
                        label: 'Temps utilisé',
                        controller: _tempsUtiliseController,
                        onChanged: (value) => _calculateDateFin(),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing.medium),

                // Ligne 3: Date de fin (calculée automatiquement)
                Row(
                  children: [
                    Expanded(
                      child: _EmployeFormField(
                        label: 'Date de fin (calculée)',
                        controller: _dateFinController,
                        enabled: false,
                      ),
                    ),
                    SizedBox(width: spacing.medium),
                    Expanded(child: Container()), // Espace vide pour alignement
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

/// Widget pour afficher la barre d'actions en haut de l'onglet Matériel
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage de la barre d'actions
/// Principe DRY: Réutilise le pattern _ActionIconButton
class _MaterielActionBar extends StatelessWidget {
  final VoidCallback onAddTap;

  const _MaterielActionBar({required this.onAddTap});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

/// Widget pour afficher l'en-tête du tableau Moyens
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage de l'en-tête
/// Principe DRY: Réutilise le pattern _HeaderText
class _MoyensTableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final responsive = context.responsive;

    return Container(
      color: const Color(0xFF0F1B80),
      padding: spacing.custom(horizontal: 10, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 2, child: _HeaderText('Moyen', responsive)),
          Expanded(flex: 2, child: _HeaderText('Équipement', responsive)),
          Expanded(flex: 2, child: _HeaderText('Date début', responsive)),
          Expanded(flex: 2, child: _HeaderText('Temps utilisé', responsive)),
          Expanded(flex: 2, child: _HeaderText('Date fin', responsive)),
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
        fontSize: responsive.sp(12),
        color: Colors.white,
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// Widget pour afficher une ligne de moyens dans le tableau
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage d'une ligne
/// Principe DRY: Réutilise le pattern _CellText
class _MoyensRow extends StatelessWidget {
  final int index;
  final String moyen;
  final String equipement;
  final String dateDebut;
  final String tempsUtilise;
  final String dateFin;

  const _MoyensRow({
    required this.index,
    required this.moyen,
    required this.equipement,
    required this.dateDebut,
    required this.tempsUtilise,
    required this.dateFin,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final responsive = context.responsive;

    return Container(
      color: index % 2 == 0 ? Colors.white : Colors.grey[100],
      padding: spacing.custom(horizontal: 10, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 2, child: _CellText(moyen, responsive)),
          Expanded(flex: 2, child: _CellText(equipement, responsive)),
          Expanded(flex: 2, child: _CellText(dateDebut, responsive)),
          Expanded(flex: 2, child: _CellText(tempsUtilise, responsive)),
          Expanded(flex: 2, child: _CellText(dateFin, responsive)),
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
        fontSize: responsive.sp(11),
      ),
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Onglet STOCK/PIÈCES - Affiche le tableau des pièces avec formulaire
/// Principe SOLID: Single Responsibility - Gère uniquement les pièces
/// Principe DRY: Réutilise le pattern de _MoyensTab
class _StockPiecesTab extends StatefulWidget {
  final String otCode;
  final OTService otService;

  const _StockPiecesTab({Key? key, required this.otCode, required this.otService}) : super(key: key);

  @override
  State<_StockPiecesTab> createState() => _StockPiecesTabState();
}

class _StockPiecesTabState extends State<_StockPiecesTab> {
  bool _showDetails = false;
  List<Map<String, dynamic>> pieces = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadParts();
  }

  Future<void> _loadParts() async {
    try {
      final list = await widget.otService.getParts(widget.otCode);
      setState(() {
        pieces = list.map((item) {
          final partCode = item['wosyPart']?.toString()
              ?? item['wosyCode']?.toString()
              ?? item['stockPart']?.toString()
              ?? '';
          final description = item['wosyDescription']?.toString()
              ?? item['partDescription']?.toString()
              ?? partCode;
          final label = description.isNotEmpty ? description : partCode;
          final qty = item['wosyUsedQuantity']?.toString()
              ?? item['wosyQuantity']?.toString()
              ?? item['usedQuantity']?.toString()
              ?? '0';
          return {
            'pk': (item['pkPart'] ?? item['pkStockUsed'] ?? 0) as int,
            'partCode': partCode,
            'article': label.isNotEmpty ? label : 'Article',
            'quantiteUtilise': qty,
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic>? _selectedPiece;

  void _toggleDetails([Map<String, dynamic>? piece]) {
    setState(() {
      _selectedPiece = piece;
      _showDetails = !_showDetails;
    });
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF0F1B80)));
    }
    if (_error != null) {
      return Center(child: Text('Erreur: $_error', style: const TextStyle(color: Colors.red)));
    }

    if (_showDetails) {
      return _StockPiecesDetailsTab(
        otCode: widget.otCode,
        otService: widget.otService,
        onBack: () => _toggleDetails(null),
        onSaved: _loadParts,
        initialData: _selectedPiece,
      );
    }

    return Column(
      children: [
        _MaterielActionBar(onAddTap: () => _toggleDetails(null)),
        SizedBox(height: spacing.small),
        _StockPiecesTableHeader(),
        Expanded(
          child: pieces.isEmpty
              ? const Center(child: Text('Aucune pièce de rechange pour cet OT', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  itemCount: pieces.length,
                  itemBuilder: (context, index) {
                    final piece = pieces[index];
                    return GestureDetector(
                      onTap: () => _toggleDetails(piece),
                      behavior: HitTestBehavior.opaque,
                      child: _StockPiecesRow(
                        index: index,
                        article: piece['article'] ?? '',
                        quantiteUtilise: piece['quantiteUtilise'] ?? '0.00',
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _StockPiecesDetailsTab extends StatefulWidget {
  final String otCode;
  final OTService otService;
  final VoidCallback onBack;
  final VoidCallback onSaved;
  final Map<String, dynamic>? initialData;

  const _StockPiecesDetailsTab({
    required this.otCode,
    required this.otService,
    required this.onBack,
    required this.onSaved,
    this.initialData,
  });

  @override
  State<_StockPiecesDetailsTab> createState() => _StockPiecesDetailsTabState();
}

class _StockPiecesDetailsTabState extends State<_StockPiecesDetailsTab> {
  late TextEditingController _partCodeController;
  late TextEditingController _articleController;
  late TextEditingController _quantiteUtiliseController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    _partCodeController = TextEditingController(text: data?['partCode'] ?? '');
    _articleController = TextEditingController(text: data?['article'] ?? '');
    _quantiteUtiliseController = TextEditingController(text: data?['quantiteUtilise'] ?? '1.0');
  }

  @override
  void dispose() {
    _partCodeController.dispose();
    _articleController.dispose();
    _quantiteUtiliseController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final partCode = _partCodeController.text.trim();
    final article = _articleController.text.trim();
    final qty = double.tryParse(_quantiteUtiliseController.text) ?? 1.0;

    if (partCode.isEmpty || article.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir le code article et la description.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      if (widget.initialData == null) {
        // Ajouter
        await widget.otService.createPart(widget.otCode, {
          "wosyPart": partCode,
          "wosyCode": partCode,
          "wosyDescription": article,
          "wosyUsedQuantity": qty,
          "wosyQuantity": qty,
          "wosyUnit": "U",
        });
      } else {
        // Modifier
        final pk = widget.initialData!['pk'] as int;
        await widget.otService.updatePart(widget.otCode, pk, {
          "wosyPart": partCode,
          "wosyCode": partCode,
          "wosyDescription": article,
          "wosyUsedQuantity": qty,
          "wosyQuantity": qty,
          "wosyUnit": "U",
        });
      }
      widget.onSaved();
      widget.onBack();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de l\'enregistrement: $e')));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _confirmDelete() {
    final pk = widget.initialData!['pk'] as int;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer la pièce'),
          content: const Text('Voulez-vous retirer cette pièce de rechange de l\'OT ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.pop(context);
                setState(() => _isSaving = true);
                try {
                  await widget.otService.deletePart(widget.otCode, pk);
                  widget.onSaved();
                  widget.onBack();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de la suppression: $e')));
                } finally {
                  setState(() => _isSaving = false);
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
                Row(
                  children: [
                    Expanded(
                      child: _EmployeFormField(
                        label: 'Code Article *',
                        controller: _partCodeController,
                        readOnly: true,
                      ),
                    ),
                    SizedBox(width: spacing.medium),
                    Expanded(
                      child: _EmployeFormField(
                        label: 'Quantité utilisée *',
                        controller: _quantiteUtiliseController,
                        readOnly: true,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing.medium),
                _EmployeFormField(
                  label: 'Description Article *',
                  controller: _articleController,
                  readOnly: true,
                ),
              ],
            ),
          ),
        ),

        // Actions en bas
        Container(
          color: Colors.white,
          padding: spacing.custom(horizontal: 20, vertical: 10, bottom: 20),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.onBack,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F1B80),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: responsive.hp(1.8)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    'Retour',
                    style: TextStyle(
                      fontFamily: AppTheme.fontMontserrat,
                      fontWeight: FontWeight.w600,
                      fontSize: responsive.sp(14),
                    ),
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

/// Widget pour afficher l'en-tête du tableau Stock/Pièces
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage de l'en-tête
class _StockPiecesTableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final responsive = context.responsive;

    return Container(
      color: const Color(0xFF0F1B80),
      padding: spacing.custom(horizontal: 10, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 1, child: _HeaderText('Article', responsive)),
          Expanded(
            flex: 1,
            child: _HeaderText('Quantité utilisée', responsive),
          ),
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
        fontSize: responsive.sp(12),
        color: Colors.white,
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// Widget pour afficher une ligne de pièce dans le tableau
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage d'une ligne
class _StockPiecesRow extends StatelessWidget {
  final int index;
  final String article;
  final String quantiteUtilise;

  const _StockPiecesRow({
    required this.index,
    required this.article,
    required this.quantiteUtilise,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final responsive = context.responsive;

    return Container(
      color: index % 2 == 0 ? Colors.white : Colors.grey[100],
      padding: spacing.custom(horizontal: 10, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 1, child: _CellText(article, responsive)),
          Expanded(flex: 1, child: _CellText(quantiteUtilise, responsive)),
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
        fontSize: responsive.sp(11),
      ),
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Onglet STOCK/SERVICES - Affiche le tableau des services avec formulaire
/// Principe SOLID: Single Responsibility - Gère uniquement les services
/// Principe DRY: Réutilise le pattern de _MoyensTab
class _StockServicesTab extends StatefulWidget {
  final String otCode;
  final OTService otService;

  const _StockServicesTab({required this.otCode, required this.otService});

  @override
  State<_StockServicesTab> createState() => _StockServicesTabState();
}

class _StockServicesTabState extends State<_StockServicesTab> {
  bool _showDetails = false;
  List<Map<String, dynamic>> services = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    try {
      final list = await widget.otService.getServices(widget.otCode);
      setState(() {
        services = list.map((item) {
          final serviceCode = item['woseService']?.toString()
              ?? item['woseCode']?.toString()
              ?? item['service']?.toString()
              ?? '';
          final description = item['woseDescription']?.toString()
              ?? item['serviceDescription']?.toString()
              ?? serviceCode;
          final label = description.isNotEmpty ? description : serviceCode;
          
          final qtyPlan = item['wosePlannedQuantity']?.toString()
              ?? item['woseQuantity']?.toString()
              ?? item['wosePlannedTime']?.toString()
              ?? '0.00';
              
          final qtyCons = item['woseUsedQuantity']?.toString()
              ?? item['woseActualQuantity']?.toString()
              ?? item['woseActualTime']?.toString()
              ?? qtyPlan;
          
          return {
            'article': label.isNotEmpty ? label : 'Service',
            'quantitePlanifiee': qtyPlan,
            'quantiteConsommee': qtyCons,
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic>? _selectedService;

  void _toggleDetails([Map<String, dynamic>? service]) {
    setState(() {
      _selectedService = service;
      _showDetails = !_showDetails;
    });
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF0F1B80)));
    }
    if (_error != null) {
      return Center(child: Text('Erreur: $_error', style: const TextStyle(color: Colors.red)));
    }

    if (_showDetails) {
      return _StockServicesDetailsTab(
        onBack: () => _toggleDetails(null),
        initialData: _selectedService,
      );
    }

    return Column(
      children: [
        // Barre d'icônes d'action
        _MaterielActionBar(onAddTap: () => _toggleDetails(services.isNotEmpty ? services.first : null)),
        SizedBox(height: spacing.small),
        // En-tête du tableau
        _StockServicesTableHeader(),
        // Liste des services
        Expanded(
          child: services.isEmpty
              ? const Center(child: Text('Aucun service pour cet OT', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    final service = services[index];
                    return GestureDetector(
                      onTap: () => _toggleDetails(service),
                      behavior: HitTestBehavior.opaque,
                      child: _StockServicesRow(
                        index: index,
                        article: service['article'] ?? '',
                        quantitePlanifiee: service['quantitePlanifiee'] ?? '0.00',
                        quantiteConsommee: service['quantiteConsommee'] ?? '0.00',
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// Widget pour afficher le formulaire de détails des services
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage du formulaire
/// Principe DRY: Réutilise _EmployeFormField
class _StockServicesDetailsTab extends StatefulWidget {
  final VoidCallback onBack;
  final Map<String, dynamic>? initialData;

  const _StockServicesDetailsTab({required this.onBack, this.initialData});

  @override
  State<_StockServicesDetailsTab> createState() =>
      _StockServicesDetailsTabState();
}

class _StockServicesDetailsTabState extends State<_StockServicesDetailsTab> {
  late TextEditingController _articleController;
  late TextEditingController _quantitePlanifieeController;
  late TextEditingController _quantiteConsommeeController;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    _articleController = TextEditingController(text: data?['article'] ?? 'SERVICE');
    _quantitePlanifieeController = TextEditingController(text: data?['quantitePlanifiee'] ?? '0.00');
    _quantiteConsommeeController = TextEditingController(text: data?['quantiteConsommee'] ?? '0.00');
  }


  @override
  void dispose() {
    _articleController.dispose();
    _quantitePlanifieeController.dispose();
    _quantiteConsommeeController.dispose();
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
                _MaterielActionBar(onAddTap: () {}),
                SizedBox(height: spacing.large),

                // Ligne 1: Article et Quantité planifiée
                Row(
                  children: [
                    Expanded(
                      child: _EmployeFormField(
                        label: 'Article',
                        controller: _articleController,
                        hasDropdown: true,
                      ),
                    ),
                    SizedBox(width: spacing.medium),
                    Expanded(
                      child: _EmployeFormField(
                        label: 'Quantité planifiée',
                        controller: _quantitePlanifieeController,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing.medium),

                // Ligne 2: Quantité consommée
                Row(
                  children: [
                    Expanded(
                      child: _EmployeFormField(
                        label: 'Quantité consommée',
                        controller: _quantiteConsommeeController,
                      ),
                    ),
                    SizedBox(width: spacing.medium),
                    Expanded(child: Container()), // Espace vide
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

/// Widget pour afficher l'en-tête du tableau Stock/Services
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage de l'en-tête
class _StockServicesTableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final responsive = context.responsive;

    return Container(
      color: const Color(0xFF0F1B80),
      padding: spacing.custom(horizontal: 10, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 2, child: _HeaderText('Article', responsive)),
          Expanded(
            flex: 1,
            child: _HeaderText('Quantité planifiée', responsive),
          ),
          Expanded(
            flex: 1,
            child: _HeaderText('Quantité consommée', responsive),
          ),
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
        fontSize: responsive.sp(12),
        color: Colors.white,
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// Widget pour afficher une ligne de service dans le tableau
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage d'une ligne
class _StockServicesRow extends StatelessWidget {
  final int index;
  final String article;
  final String quantitePlanifiee;
  final String quantiteConsommee;

  const _StockServicesRow({
    required this.index,
    required this.article,
    required this.quantitePlanifiee,
    required this.quantiteConsommee,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final responsive = context.responsive;

    return Container(
      color: index % 2 == 0 ? Colors.white : Colors.grey[100],
      padding: spacing.custom(horizontal: 10, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 2, child: _CellText(article, responsive)),
          Expanded(flex: 1, child: _CellText(quantitePlanifiee, responsive)),
          Expanded(flex: 1, child: _CellText(quantiteConsommee, responsive)),
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
        fontSize: responsive.sp(11),
      ),
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Widget pour afficher la barre d'actions en haut de l'onglet Matériel (ancien code conservé pour compatibilité)
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage de la barre d'actions
/// Principe DRY: Réutilise le pattern _ActionIconButton
class _MaterielActionBarOld extends StatelessWidget {
  final VoidCallback onAddTap;

  const _MaterielActionBarOld({required this.onAddTap});

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Container(
      color: Colors.grey[200],
      padding: spacing.custom(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          _ActionIconButton(icon: Icons.add, onPressed: onAddTap),
          SizedBox(width: spacing.small),
          _ActionIconButton(icon: Icons.refresh, onPressed: () {}),
          SizedBox(width: spacing.small),
          _ActionIconButton(icon: Icons.check, onPressed: () {}),
          SizedBox(width: spacing.small),
          _ActionIconButton(icon: Icons.close, onPressed: () {}),
          SizedBox(width: spacing.small),
          _ActionIconButton(icon: Icons.insert_chart, onPressed: () {}),
          SizedBox(width: spacing.small),
          _ActionIconButton(icon: Icons.view_module, onPressed: () {}),
          SizedBox(width: spacing.small),
          _ActionIconButton(icon: Icons.help_outline, onPressed: () {}),
        ],
      ),
    );
  }
}

/// Widget pour afficher l'en-tête du tableau Matériel
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage de l'en-tête
class _MaterielTableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final responsive = context.responsive;

    return Container(
      color: const Color(0xFF0F1B80),
      padding: spacing.custom(horizontal: 10, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 2, child: _HeaderText('Moyen', responsive)),
          Expanded(flex: 2, child: _HeaderText('Équipement', responsive)),
          Expanded(flex: 2, child: _HeaderText('Date début', responsive)),
          Expanded(flex: 2, child: _HeaderText('Temps utilisé', responsive)),
          Expanded(flex: 2, child: _HeaderText('Date fin', responsive)),
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
        fontSize: responsive.sp(12),
        color: Colors.white,
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// Widget pour afficher une ligne de matériel dans le tableau
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage d'une ligne
class _MaterielRow extends StatelessWidget {
  final int index;
  final String moyen;
  final String equipement;
  final String dateDebut;
  final String tempsUtilise;
  final String dateFin;

  const _MaterielRow({
    required this.index,
    required this.moyen,
    required this.equipement,
    required this.dateDebut,
    required this.tempsUtilise,
    required this.dateFin,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final responsive = context.responsive;

    return Container(
      color: index % 2 == 0 ? Colors.white : Colors.grey[100],
      padding: spacing.custom(horizontal: 10, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 2, child: _CellText(moyen, responsive)),
          Expanded(flex: 2, child: _CellText(equipement, responsive)),
          Expanded(flex: 2, child: _CellText(dateDebut, responsive)),
          Expanded(flex: 2, child: _CellText(tempsUtilise, responsive)),
          Expanded(flex: 2, child: _CellText(dateFin, responsive)),
        ],
      ),
    );
  }

  Widget _CellText(String text, Responsive responsive) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: AppTheme.fontMontserrat,
        fontSize: responsive.sp(11),
        color: Colors.black87,
      ),
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Onglet "Attributs" - Affiche le tableau des attributs avec formulaire
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage des attributs
/// Principe DRY: Réutilise le pattern de _MoyensTab
class _SousAttributsTab extends StatefulWidget {
  final String otCode;
  final OTService otService;

  const _SousAttributsTab({Key? key, required this.otCode, required this.otService}) : super(key: key);

  @override
  State<_SousAttributsTab> createState() => _SousAttributsTabState();
}

class _SousAttributsTabState extends State<_SousAttributsTab> {
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
/// Principe DRY: Réutilise _EmployeFormField
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
                _MaterielActionBar(onAddTap: () {}),
                SizedBox(height: spacing.large),

                // Ligne 1: Classe d'attribut et Attribut
                Row(
                  children: [
                    Expanded(
                      child: _EmployeFormField(
                        label: 'Classe d\'attribut',
                        controller: _classeAttributController,
                        hasDropdown: true,
                      ),
                    ),
                    SizedBox(width: spacing.medium),
                    Expanded(
                      child: _EmployeFormField(
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
                      child: _EmployeFormField(
                        label: 'Valeur',
                        controller: _valeurController,
                      ),
                    ),
                    SizedBox(width: spacing.medium),
                    Expanded(
                      child: _EmployeFormField(
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
                      child: _EmployeFormField(
                        label: 'Symbole de l\'unité',
                        controller: _symboleUniteController,
                      ),
                    ),
                    SizedBox(width: spacing.medium),
                    Expanded(
                      child: _EmployeFormField(
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

/// Widget qui affiche un champ de formulaire avec ou sans dropdown
/// Principe SOLID: Single Responsibility - Responsable uniquement de l'affichage d'un champ
class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool hasDropdown;
  final bool isDateField;
  final VoidCallback? onDropdownTap;

  const _FormField({
    required this.label,
    required this.controller,
    this.hasDropdown = false,
    this.isDateField = false,
    this.onDropdownTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label du champ en bleu
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF0F1B80), // Bleu
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        // Champ de saisie avec icône dropdown ou calendrier
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller,
                  readOnly:
                      isDateField, // Seul le champ date est en lecture seule
                  style: const TextStyle(
                    color: Color(0xFF9E9E9E), // Gris clair pour la valeur
                    fontSize: 14,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                    border: InputBorder.none,
                  ),
                  onTap: isDateField ? () => _selectDate(context) : null,
                ),
              ),
              if (isDateField)
                InkWell(
                  onTap: () => _selectDate(context),
                  child: const Icon(
                    Icons.calendar_today,
                    color: Color(0xFF0F1B80),
                    size: 20,
                  ),
                )
              else if (hasDropdown)
                InkWell(
                  onTap: onDropdownTap ?? () => _showDropdownOptions(context),
                  child: const Icon(
                    Icons.arrow_drop_down,
                    color: Color(0xFF0F1B80),
                    size: 24,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0F1B80), // Couleur bleue
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      controller.text =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
    }
  }

  void _showDropdownOptions(BuildContext context) {
    // Pour l'instant, affiche un message simple
    // Plus tard, on pourra afficher une liste de choix spécifiques
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sélectionner $label',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F1B80),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Options à venir...',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }
}
