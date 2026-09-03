import 'package:flutter/material.dart';
import 'package:appmobilegmao/models/work_order.dart';
import 'package:appmobilegmao/utils/responsive.dart';
import 'package:appmobilegmao/theme/responsive_spacing.dart';
import 'package:appmobilegmao/widgets/custom_app_bar.dart';
import 'package:appmobilegmao/services/ot_service.dart';
import 'package:appmobilegmao/services/api_service.dart';
import 'package:appmobilegmao/services/hive_service.dart';
import 'package:appmobilegmao/services/equipment_service.dart';
import 'package:appmobilegmao/models/equipment.dart';
import 'dart:math';

/// Écran complet pour la création et la modification d'un Ordre de Travail (OT)
/// Gère la saisie globale en mémoire (ajouts locaux et suppressions mémorisées)
/// puis applique tous les changements en base de données de manière groupée.
class OTCreateScreen extends StatefulWidget {
  final WorkOrder? orderToEdit;

  const OTCreateScreen({Key? key, this.orderToEdit}) : super(key: key);

  @override
  State<OTCreateScreen> createState() => _OTCreateScreenState();
}

class _OTCreateScreenState extends State<OTCreateScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final OTService _otService;
  bool _isSaving = false;
  bool _isLoadingData = false;

  bool get _isEditMode => widget.orderToEdit != null;

  // Clé du formulaire pour l'onglet Détails
  final _formKey = GlobalKey<FormState>();

  final EquipmentService _equipmentService = EquipmentService();
  Map<String, dynamic> _selectorsData = {};
  bool _isLoadingSelectors = false;

  // Contrôleurs pour l'onglet "Détails"
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _jobController = TextEditingController();
  final TextEditingController _jobTypeController = TextEditingController();
  final TextEditingController _jobClassController = TextEditingController();
  final TextEditingController _zoneController = TextEditingController();
  final TextEditingController _entityController = TextEditingController();
  final TextEditingController _costcentreController = TextEditingController();
  final TextEditingController _equipmentController = TextEditingController();
  final TextEditingController _supervisorController = TextEditingController();

  double _completionRate = 0.0;
  String _priority = 'MOYEN';
  String _status = 'CR';
  bool _autoGenerateCode = true;

  // Listes en mémoire pour les sous-ressources des onglets
  final List<Map<String, dynamic>> _operations = [];
  final List<Map<String, dynamic>> _comments = [];
  final List<Map<String, dynamic>> _workforce = [];
  final List<Map<String, dynamic>> _parts = [];
  final List<Map<String, dynamic>> _attributes = [];

  // Mémorisation des clés primaires (PK) à supprimer en base
  final List<int> _deletedOperations = [];
  final List<int> _deletedComments = [];
  final List<int> _deletedWorkforce = [];
  final List<int> _deletedParts = [];
  final List<int> _deletedAttributes = [];

  // Contrôleurs temporaires pour l'ajout dans les onglets
  final TextEditingController _tempOpController = TextEditingController();
  final TextEditingController _tempCommentController = TextEditingController();

  // Contrôleurs temporaires Main d'œuvre
  final TextEditingController _tempWfEmployeeController = TextEditingController();
  final TextEditingController _tempWfDescriptionController = TextEditingController();
  final TextEditingController _tempWfStartDateController = TextEditingController();
  final TextEditingController _tempWfEndDateController = TextEditingController();
  final TextEditingController _tempWfActualHoursController = TextEditingController();
  final TextEditingController _tempWfTotalHoursController = TextEditingController();
  String _tempWfStatus = 'F';
  DateTime? _tempWfStartDateTime;
  DateTime? _tempWfEndDateTime;

  Future<DateTime?> _pickDateTime(DateTime? initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: initial != null ? TimeOfDay.fromDateTime(initial) : TimeOfDay.now(),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  void _recalculateWorkforceHours() {
    if (_tempWfStartDateTime != null && _tempWfEndDateTime != null) {
      final diffInMinutes = _tempWfEndDateTime!.difference(_tempWfStartDateTime!).inMinutes;
      if (diffInMinutes >= 0) {
        final hours = (diffInMinutes / 60.0).toStringAsFixed(1);
        setState(() {
          _tempWfActualHoursController.text = hours;
          _tempWfTotalHoursController.text = hours;
        });
      }
    }
  }

  String _formatDT(DateTime dt) {
    final y = dt.year;
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  // Contrôleurs temporaires Pièces
  final TextEditingController _tempPartCodeController = TextEditingController();
  final TextEditingController _tempPartArticleController = TextEditingController();
  final TextEditingController _tempPartQtyController = TextEditingController();

  // Contrôleurs temporaires Sous-attributs
  final TextEditingController _tempAttrNameController = TextEditingController();
  final TextEditingController _tempAttrValueController = TextEditingController();
  final TextEditingController _tempAttrDescController = TextEditingController();
  final TextEditingController _tempAttrUnitController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _otService = OTService(ApiService());
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(() {
      if (mounted && _tabController.indexIsChanging) setState(() {});
    });

    // Initialisation des dates par défaut pour la main d'œuvre
    final now = DateTime.now();
    _tempWfStartDateController.text = now.toString().substring(0, 16);
    _tempWfEndDateController.text = now.add(const Duration(hours: 1)).toString().substring(0, 16);

    if (_isEditMode) {
      _autoGenerateCode = false;
      final ot = widget.orderToEdit!;
      _codeController.text = ot.wowoCode.toString();
      _jobController.text = ot.wowoJob;
      _jobTypeController.text = ot.wowoJobType;
      _jobClassController.text = ot.wowoJobClass;
      _zoneController.text = ot.wowoZone ?? '';
      _entityController.text = ot.wowoRequestEntity;
      _costcentreController.text = ot.wowoCostcentre;
      _equipmentController.text = ot.wowoEquipment;
      _supervisorController.text = ot.wowoSupervisor ?? '';
      _completionRate = ot.wowoCompletionRate ?? 0.0;
      
      final normPriority = (ot.wowoPriority ?? 'MOYEN').trim().toUpperCase();
      _priority = ['URGENT', 'MOYEN', 'BAS'].contains(normPriority) ? normPriority : 'MOYEN';

      final normStatus = ot.wowoUserStatus.trim().toUpperCase();
      _status = ['CR', 'OUV', 'CL', 'TE'].contains(normStatus) ? normStatus : 'OUV';

      _isLoadingData = true;
      _loadAllSubResources();
    } else {
      // En création, pré-charger l'utilisateur connecté
      try {
        final user = HiveService.getCurrentUser();
        if (user != null) {
          final userCode = user.code ?? '';
          final username = user.username;
          if (userCode.isNotEmpty && userCode.toLowerCase() != 'test' && RegExp(r'^\d+$').hasMatch(userCode)) {
            _supervisorController.text = userCode;
            _tempWfEmployeeController.text = userCode;
          } else {
            _supervisorController.text = 'supervisor';
            _tempWfEmployeeController.text = 'supervisor';
          }
          if (username.isNotEmpty) {
            _tempWfDescriptionController.text = username;
          }
          final userEntity = user.entity;
          if (userEntity.isNotEmpty) {
            _entityController.text = userEntity;
          }
        }
      } catch (e) {
        debugPrint('Erreur lors de la récupération de l\'utilisateur connecté: $e');
      }
    }
    _loadSelectors();
  }

  /// Charge de manière asynchrone toutes les sous-ressources de l'OT en édition
  Future<void> _loadAllSubResources() async {
    final otCode = widget.orderToEdit!.wowoCode.toString();
    try {
      // 1. Mode opératoire
      final ops = await _otService.getOperations(otCode);
      setState(() {
        _operations.addAll(ops.map((op) => {
          'pk': (op['pkOperation'] ?? op['pkWorkAction'] ?? 0) as int,
          'description': op['opopDescription']?.toString() ?? op['opopJobDescription']?.toString() ?? '',
        }));
      });

      // 2. Commentaires
      final docs = await _otService.getDocuments(otCode);
      setState(() {
        _comments.addAll(docs.map((doc) => {
          'pk': (doc['pkComment'] ?? doc['pkEmployeeFeedback'] ?? 0) as int,
          'employee': doc['woefEmployee']?.toString() ?? '',
          'description': doc['reemDescription']?.toString() ?? '',
          'startDate': doc['woefStartDate']?.toString() ?? '',
          'endDate': doc['woefEndDate']?.toString() ?? '',
          'actualHours': doc['woefActualHours']?.toString() ?? '0',
          'totalHours': doc['woefTotalHours']?.toString() ?? '0',
          'status': doc['woefUserStatus']?.toString() ?? '',
        }));
      });

      // 3. Main d'œuvre
      final wf = await _otService.getWorkforce(otCode);
      setState(() {
        _workforce.addAll(wf.map((item) => {
          'pk': (item['pkWorkforce'] ?? item['pkEmployeeAllocated'] ?? 0) as int,
          'employee': item['woeaEmployee']?.toString() ?? item['reemCode']?.toString() ?? '',
          'description': item['woeaResource']?.toString() ?? item['reemDescription']?.toString() ?? 'Intervenant',
          'startDate': item['woeaAllocationDate']?.toString() ?? '',
          'endDate': item['woeaAllocationDate']?.toString() ?? '',
          'actualHours': item['woeaPlannedHours']?.toString() ?? '0',
          'totalHours': item['woeaPlannedHours']?.toString() ?? '0',
          'status': item['woeaIsPlanned'] == true ? 'Planifié' : 'Non planifié',
        }));
      });

      // 4. Pièces
      final pts = await _otService.getParts(otCode);
      setState(() {
        _parts.addAll(pts.map((item) {
          final partCode = item['wosyPart']?.toString()
              ?? item['wosyCode']?.toString()
              ?? item['stockPart']?.toString()
              ?? '';
          final description = item['wosyDescription']?.toString()
              ?? item['partDescription']?.toString()
              ?? partCode;
          final qty = item['wosyUsedQuantity']?.toString()
              ?? item['wosyQuantity']?.toString()
              ?? item['usedQuantity']?.toString()
              ?? '0';
          return {
            'pk': (item['pkPart'] ?? item['pkStockUsed'] ?? 0) as int,
            'partCode': partCode,
            'article': description,
            'qtyUsed': double.tryParse(qty) ?? 0.0,
          };
        }));
      });

      // 5. Attributs
      final attrs = await _otService.getAttributes(otCode);
      setState(() {
        _attributes.addAll(attrs.map((item) => {
          'pk': (item['pkAttribute'] ?? item['pkWorkOrderAttribute'] ?? 0) as int,
          'name': item['woatName']?.toString() ?? '',
          'value': item['woatValue']?.toString() ?? '',
          'description': item['woatDescription']?.toString() ?? '',
          'unit': item['woatUnitSymbol']?.toString() ?? '',
        }));
      });
    } catch (e) {
      debugPrint('Erreur chargement sous-ressources: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de chargement des onglets: $e')),
      );
    } finally {
      setState(() => _isLoadingData = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeController.dispose();
    _jobController.dispose();
    _jobTypeController.dispose();
    _jobClassController.dispose();
    _zoneController.dispose();
    _entityController.dispose();
    _costcentreController.dispose();
    _equipmentController.dispose();
    _supervisorController.dispose();
    _tempOpController.dispose();
    _tempCommentController.dispose();
    _tempWfEmployeeController.dispose();
    _tempWfDescriptionController.dispose();
    _tempWfStartDateController.dispose();
    _tempWfEndDateController.dispose();
    _tempWfActualHoursController.dispose();
    _tempWfTotalHoursController.dispose();
    _tempPartCodeController.dispose();
    _tempPartArticleController.dispose();
    _tempPartQtyController.dispose();
    _tempAttrNameController.dispose();
    _tempAttrValueController.dispose();
    _tempAttrDescController.dispose();
    _tempAttrUnitController.dispose();
    super.dispose();
  }

  Future<void> _loadSelectors() async {
    final entityCode = _entityController.text.trim();
    if (entityCode.isEmpty) return;

    setState(() {
      _isLoadingSelectors = true;
    });

    try {
      final data = await _equipmentService.getEquipmentSelectors(entity: entityCode);
      if (mounted) {
        setState(() {
          _selectorsData = data;
          _isLoadingSelectors = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des sélecteurs: $e');
      if (mounted) {
        setState(() {
          _isLoadingSelectors = false;
        });
      }
    }
  }

  List<_GenericSelectionItem> _extractSelectionItems(String key) {
    final rawList = _selectorsData[key];
    if (rawList == null || rawList is! List || rawList.isEmpty) {
      return [];
    }
    final List<_GenericSelectionItem> items = [];
    for (final item in rawList) {
      String code = '';
      String desc = '';
      if (item is Map) {
        code = item['code']?.toString() ?? '';
        desc = item['description']?.toString() ?? '';
      } else {
        try {
          code = (item as dynamic).code?.toString() ?? '';
          desc = (item as dynamic).description?.toString() ?? '';
        } catch (_) {}
      }
      if (code.isNotEmpty) {
        items.add(_GenericSelectionItem(code: code, description: desc.isNotEmpty ? desc : code));
      }
    }
    return items;
  }

  void _showGenericSelector({
    required String title,
    required List<_GenericSelectionItem> items,
    required Function(String) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _GenericSelectionModal(
          title: title,
          items: items,
          onSelected: onSelected,
        );
      },
    );
  }

  void _showEquipmentSelector() {
    final entityCode = _entityController.text.trim();
    if (entityCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez d\'abord renseigner l\'Entité *')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _EquipmentSelectionModal(
          entity: entityCode,
          zone: '', // Recherche basée à 100% sur le Service/Entité et sa hiérarchie
          onSelected: (equipmentCode) {
            setState(() {
              _equipmentController.text = equipmentCode;
            });
          },
        );
      },
    );
  }

  /// Génère un code OT aléatoire si l'utilisateur a choisi la génération automatique
  String _generateRandomCode() {
    final random = Random();
    int number = 2026000000 + random.nextInt(999999);
    return number.toString();
  }

  /// Procède à la cascade d'enregistrement global de l'OT (création ou modification)
  Future<void> _handleSaveGlobal() async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      _tabController.animateTo(0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade800,
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Veuillez remplir les champs obligatoires (surlignés en rouge) *', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final code = _isEditMode ? _codeController.text.trim() : (_autoGenerateCode ? _generateRandomCode() : _codeController.text.trim());

      final Map<String, dynamic> otData = {
        'wowoCode': int.tryParse(code) ?? 2026999999,
        'wowoJob': _jobController.text.trim(),
        'wowoJobType': _jobTypeController.text.trim(),
        'wowoJobClass': _jobClassController.text.trim(),
        'wowoZone': _zoneController.text.trim(),
        'wowoRequestEntity': _entityController.text.trim(),
        'wowoCostcentre': _costcentreController.text.trim(),
        'wowoEquipment': _equipmentController.text.trim().isNotEmpty ? _equipmentController.text.trim() : 'MOCK_EQ',
        'wowoSupervisor': (RegExp(r'^\d+$').hasMatch(_supervisorController.text.trim()) || _supervisorController.text.trim() == 'supervisor') ? _supervisorController.text.trim() : 'supervisor',
        'wowoCompletionRate': _completionRate,
        'wowoPriority': _priority,
        'wowoUserStatus': _status,
      };

      final String finalOTCode;

      if (_isEditMode) {
        // Mode Édition : Mise à jour de l'OT principal
        finalOTCode = widget.orderToEdit!.wowoCode.toString();
        await _otService.updateOT(widget.orderToEdit!.wowoCode, otData);

        // --- EXÉCUTER LES SUPPRESSIONS D'ÉLÉMENTS ---
        for (final pk in _deletedOperations) {
          await _otService.deleteOperation(finalOTCode, pk);
        }
        for (final pk in _deletedComments) {
          await _otService.deleteDocument(finalOTCode, pk);
        }
        for (final pk in _deletedWorkforce) {
          await _otService.deleteWorkforce(finalOTCode, pk);
        }
        for (final pk in _deletedParts) {
          await _otService.deletePart(finalOTCode, pk);
        }
        for (final pk in _deletedAttributes) {
          await _otService.deleteAttribute(finalOTCode, pk);
        }
      } else {
        // Mode Création : Création de l'OT principal
        final WorkOrder newOT = await _otService.createOT(otData);
        finalOTCode = newOT.wowoCode.toString();
      }

      // --- EXÉCUTER LES AJOUTS DE NOUVEAUX ÉLÉMENTS (ceux sans 'pk') ---
      // 1. Mode opératoire
      for (final op in _operations) {
        if (op['pk'] == null) {
          await _otService.createOperation(finalOTCode, {
            'opopDescription': op['description'],
            'opopJobDescription': op['description'],
          });
        }
      }

      // 2. Commentaires
      for (final comment in _comments) {
        if (comment['pk'] == null) {
          await _otService.createDocument(finalOTCode, {
            'woefEmployee': comment['employee'],
            'reemDescription': comment['description'],
            'woefStartDate': comment['startDate'],
            'woefEndDate': comment['endDate'],
            'woefActualHours': comment['actualHours'],
            'woefTotalHours': comment['totalHours'],
            'woefUserStatus': comment['status'],
          });
        }
      }

      // 3. Main d'œuvre
      for (final wf in _workforce) {
        if (wf['pk'] == null) {
          await _otService.createWorkforce(finalOTCode, {
            'woeaEmployee': wf['employee'],
            'woeaResource': wf['description'],
            'woeaPlannedHours': double.tryParse(wf['actualHours']) ?? 1.0,
            'woeaAllocationDate': DateTime.now().toIso8601String(),
            'woeaIsPlanned': true,
          });
        }
      }

      // 4. Pièces de rechange
      for (final part in _parts) {
        if (part['pk'] == null) {
          await _otService.createPart(finalOTCode, {
            'wospPart': part['partCode'],
            'wospPartDescription': part['article'],
            'wospQtyUsed': part['qtyUsed'],
          });
        }
      }

      // 5. Attributs
      for (final attr in _attributes) {
        if (attr['pk'] == null) {
          await _otService.createAttribute(finalOTCode, {
            'woatName': attr['name'],
            'woatValue': attr['value'],
            'woatDescription': attr['description'],
            'woatUnitSymbol': attr['unit'],
          });
        }
      }

      // Vider le cache pour forcer le rechargement de la liste principale
      await _otService.clearCache();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEditMode ? 'OT N° $finalOTCode mis à jour avec succès !' : 'OT N° $finalOTCode créé avec succès !')),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('Erreur lors de l\'enregistrement de l\'OT global: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur d\'enregistrement: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  /// Affiche le sélecteur du taux de réalisation
  void _showTauxRealisationPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sélectionner le taux de réalisation',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F1B80)),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: 11,
                  itemBuilder: (context, index) {
                    final int val = index * 10;
                    return ListTile(
                      title: Text('$val%'),
                      onTap: () {
                        setState(() => _completionRate = val.toDouble());
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

  // --- WIDGETS D'ONGLETS ---

  /// Onglet 1: Formulaire des détails principaux
  Widget _buildDetailsTab(ResponsiveSpacing spacing, Responsive responsive) {
    return SingleChildScrollView(
      padding: spacing.custom(horizontal: 20, vertical: 20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isEditMode) ...[
              _buildInputField(
                label: 'Code OT',
                controller: _codeController,
                readOnly: true,
              ),
              SizedBox(height: spacing.medium),
            ] else ...[
              // Auto-génération de Code
              Row(
                children: [
                  Checkbox(
                    value: _autoGenerateCode,
                    onChanged: (val) {
                      setState(() => _autoGenerateCode = val ?? true);
                    },
                    activeColor: const Color(0xFF0F1B80),
                  ),
                  const Text('Générer automatiquement le Code OT'),
                ],
              ),
              if (!_autoGenerateCode) ...[
                _buildInputField(
                  label: 'Code OT *',
                  controller: _codeController,
                  validator: (val) => val == null || val.isEmpty ? 'Veuillez saisir un code numérique' : null,
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: spacing.medium),
              ],
            ],
            _buildInputField(
              label: 'Description / Travail *',
              controller: _jobController,
              validator: (val) => val == null || val.isEmpty ? 'Champ obligatoire' : null,
              maxLength: 15,
              suffixIcon: const Icon(Icons.arrow_drop_down, color: Color(0xFF0F1B80)),
              onTap: () {
                final List<_GenericSelectionItem> jobSuggestions = [
                  _GenericSelectionItem(code: 'Inspection', description: 'Contrôle et inspection générale de l\'équipement'),
                  _GenericSelectionItem(code: 'Dépannage BT', description: 'Recherche et réparation de panne sur le réseau'),
                  _GenericSelectionItem(code: 'Entretien prév', description: 'Maintenance et révision périodique'),
                  _GenericSelectionItem(code: 'Remplacement', description: 'Remplacement d\'élément défectueux'),
                  _GenericSelectionItem(code: 'Nettoyage', description: 'Nettoyage et resserrage des connexions'),
                  _GenericSelectionItem(code: 'Contrôle', description: 'Vérification électrique des paramètres'),
                  _GenericSelectionItem(code: 'Répar. fuite', description: 'Traitement de fuite sur équipement'),
                  _GenericSelectionItem(code: 'Maintenance', description: 'Intervention corrective immédiate'),
                ];
                _showGenericSelector(
                  title: 'Choisir un Travail à effectuer',
                  items: jobSuggestions,
                  onSelected: (val) => setState(() => _jobController.text = val),
                );
              },
            ),
            SizedBox(height: spacing.medium),
            Row(
              children: [
                Expanded(
                  child: _buildInputField(
                    label: 'Famille (Type) *',
                    controller: _jobTypeController,
                    validator: (val) => val == null || val.isEmpty ? 'Obligatoire' : null,
                    suffixIcon: const Icon(Icons.arrow_drop_down, color: Color(0xFF0F1B80)),
                    onTap: () {
                      final List<_GenericSelectionItem> jobTypes = [
                        _GenericSelectionItem(code: 'CORR', description: 'Correctif'),
                        _GenericSelectionItem(code: 'PREV', description: 'Préventif'),
                        _GenericSelectionItem(code: 'AMEL', description: 'Amélioration'),
                        _GenericSelectionItem(code: 'EXPT', description: 'Exploitation'),
                        _GenericSelectionItem(code: 'SECUR', description: 'Sécurité'),
                      ];
                      _showGenericSelector(
                        title: 'Choisir la Famille (Type)',
                        items: jobTypes,
                        onSelected: (val) => setState(() => _jobTypeController.text = val),
                      );
                    },
                  ),
                ),
                SizedBox(width: spacing.medium),
                Expanded(
                  child: _buildInputField(
                    label: 'Classe de travail *',
                    controller: _jobClassController,
                    validator: (val) => val == null || val.isEmpty ? 'Obligatoire' : null,
                    maxLength: 8,
                    suffixIcon: const Icon(Icons.arrow_drop_down, color: Color(0xFF0F1B80)),
                    onTap: () {
                      final List<_GenericSelectionItem> jobClasses = [
                        _GenericSelectionItem(code: 'POSTE', description: 'Poste HTA/BT'),
                        _GenericSelectionItem(code: 'HTA_S', description: 'Réseau Souterrain HTA'),
                        _GenericSelectionItem(code: 'LIGNE', description: 'Ligne Aérienne HTA/BT'),
                        _GenericSelectionItem(code: 'CEL-HTA', description: 'Cellules HTA'),
                        _GenericSelectionItem(code: 'ARM-PROT', description: 'Armoire de Protection'),
                        _GenericSelectionItem(code: 'DEPART', description: 'Départ BT/HTA'),
                        _GenericSelectionItem(code: 'BT', description: 'Réseau Basse Tension'),
                      ];
                      _showGenericSelector(
                        title: 'Choisir la Classe de travail',
                        items: jobClasses,
                        onSelected: (val) => setState(() => _jobClassController.text = val),
                      );
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.medium),
            Row(
              children: [
                Expanded(
                  child: _buildInputField(
                    label: 'Zone *',
                    controller: _zoneController,
                    validator: (val) => val == null || val.isEmpty ? 'Obligatoire' : null,
                    suffixIcon: const Icon(Icons.arrow_drop_down, color: Color(0xFF0F1B80)),
                    onTap: () {
                      _showGenericSelector(
                        title: 'Choisir la Zone',
                        items: _extractSelectionItems('zones'),
                        onSelected: (val) => setState(() => _zoneController.text = val),
                      );
                    },
                  ),
                ),
                SizedBox(width: spacing.medium),
                Expanded(
                  child: _buildInputField(
                    label: 'Entité *',
                    controller: _entityController,
                    validator: (val) => val == null || val.isEmpty ? 'Obligatoire' : null,
                    suffixIcon: const Icon(Icons.arrow_drop_down, color: Color(0xFF0F1B80)),
                    onTap: () {
                      _showGenericSelector(
                        title: 'Choisir l\'Entité',
                        items: _extractSelectionItems('entities'),
                        onSelected: (val) {
                          setState(() {
                            _entityController.text = val;
                            _loadSelectors();
                            _equipmentController.clear();
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.medium),
            Row(
              children: [
                Expanded(
                  child: _buildInputField(
                    label: 'Centre de charge *',
                    controller: _costcentreController,
                    validator: (val) => val == null || val.isEmpty ? 'Obligatoire' : null,
                    suffixIcon: const Icon(Icons.arrow_drop_down, color: Color(0xFF0F1B80)),
                    onTap: () {
                      _showGenericSelector(
                        title: 'Choisir le Centre de charge',
                        items: _extractSelectionItems('centreCharges'),
                        onSelected: (val) => setState(() => _costcentreController.text = val),
                      );
                    },
                  ),
                ),
                SizedBox(width: spacing.medium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Taux de réalisation',
                        style: TextStyle(color: Color(0xFF0F1B80), fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: _showTauxRealisationPicker,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 1)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${_completionRate.toInt()}%', style: const TextStyle(fontSize: 14)),
                              const Icon(Icons.arrow_drop_down, color: Color(0xFF0F1B80)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.medium),
            Row(
              children: [
                Expanded(
                  child: _buildInputField(
                    label: 'Équipement (Code) *',
                    controller: _equipmentController,
                    validator: (val) => val == null || val.isEmpty ? 'Obligatoire' : null,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search, color: Color(0xFF0F1B80), size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: _showEquipmentSelector,
                    ),
                  ),
                ),
                SizedBox(width: spacing.medium),
                Expanded(
                  child: _buildInputField(
                    label: 'Technicien / Superviseur *',
                    controller: _supervisorController,
                    validator: (val) => val == null || val.isEmpty ? 'Obligatoire' : null,
                    suffixIcon: const Icon(Icons.arrow_drop_down, color: Color(0xFF0F1B80)),
                    onTap: () {
                      final items = _extractSelectionItems('supervisors');
                      _showGenericSelector(
                        title: 'Choisir le Superviseur',
                        items: items.isNotEmpty ? items : [
                          _GenericSelectionItem(code: '5286', description: 'ERIC DASYLVA CARDOZO (5286)'),
                          _GenericSelectionItem(code: '6732', description: 'Mouhamadou Mansour KEBE (6732)'),
                          _GenericSelectionItem(code: 'supervisor', description: 'Superviseur Général (Système)'),
                        ],
                        onSelected: (val) => setState(() => _supervisorController.text = val),
                      );
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.medium),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Priorité',
                        style: TextStyle(color: Color(0xFF0F1B80), fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      DropdownButtonFormField<String>(
                        value: _priority,
                        onChanged: (val) => setState(() => _priority = val ?? 'MOYEN'),
                        items: const [
                          DropdownMenuItem(value: 'URGENT', child: Text('Urgent')),
                          DropdownMenuItem(value: 'MOYEN', child: Text('Moyen')),
                          DropdownMenuItem(value: 'BAS', child: Text('Bas')),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: spacing.medium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Statut de départ',
                        style: TextStyle(color: Color(0xFF0F1B80), fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      DropdownButtonFormField<String>(
                        value: _status,
                        onChanged: (val) => setState(() => _status = val ?? 'CR'),
                        items: const [
                          DropdownMenuItem(value: 'CR', child: Text('Créé (CR)')),
                          DropdownMenuItem(value: 'OUV', child: Text('Ouvert (OUV)')),
                          DropdownMenuItem(value: 'CL', child: Text('Clôturé (CL)')),
                          DropdownMenuItem(value: 'TE', child: Text('Terminé (TE)')),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Onglet 2: Mode opératoire (Ajout simple en mémoire)
  Widget _buildModeOperatoireTab(ResponsiveSpacing spacing) {
    return Column(
      children: [
        Container(
          color: Colors.grey[100],
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _tempOpController,
                  decoration: const InputDecoration(
                    labelText: 'Saisir une étape / prérequis...',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  final text = _tempOpController.text.trim();
                  if (text.isEmpty) return;
                  setState(() {
                    _operations.add({'description': text});
                    _tempOpController.clear();
                  });
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F1B80)),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ],
          ),
        ),
        Expanded(
          child: _operations.isEmpty
              ? const Center(child: Text('Aucune étape ajoutée pour le moment'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _operations.length,
                  itemBuilder: (context, index) {
                    final op = _operations[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF0F1B80).withAlpha(30),
                          child: Text('${index + 1}', style: const TextStyle(color: Color(0xFF0F1B80), fontWeight: FontWeight.bold)),
                        ),
                        title: Text(op['description']),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              final removed = _operations.removeAt(index);
                              if (removed['pk'] != null) {
                                _deletedOperations.add(removed['pk'] as int);
                              }
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// Onglet 3: Commentaires (Ajout simple en mémoire)
  Widget _buildCommentairesTab(ResponsiveSpacing spacing) {
    return Column(
      children: [
        Container(
          color: Colors.grey[100],
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _tempCommentController,
                  decoration: const InputDecoration(
                    labelText: 'Saisir un commentaire / rapport...',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  final text = _tempCommentController.text.trim();
                  if (text.isEmpty) return;
                  final user = _supervisorController.text.trim().isNotEmpty ? _supervisorController.text.trim() : 'MOCK_USER';
                  setState(() {
                    _comments.add({
                      'employee': user,
                      'description': text,
                      'startDate': DateTime.now().toString().substring(0, 16),
                      'endDate': DateTime.now().add(const Duration(hours: 1)).toString().substring(0, 16),
                      'actualHours': '1',
                      'totalHours': '1',
                      'status': 'F',
                    });
                    _tempCommentController.clear();
                  });
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F1B80)),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ],
          ),
        ),
        Expanded(
          child: _comments.isEmpty
              ? const Center(child: Text('Aucun commentaire ajouté'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _comments.length,
                  itemBuilder: (context, index) {
                    final comm = _comments[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.comment, color: Color(0xFF0F1B80)),
                        title: Text(comm['description']),
                        subtitle: Text('Par : ${comm['employee']}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              final removed = _comments.removeAt(index);
                              if (removed['pk'] != null) {
                                _deletedComments.add(removed['pk'] as int);
                              }
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// Onglet 4: Main d'œuvre (Ajout simple en mémoire)
  Widget _buildMainsOeuvreTab(ResponsiveSpacing spacing) {
    return Column(
      children: [
        Container(
          color: Colors.grey[100],
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _tempWfEmployeeController,
                      decoration: const InputDecoration(labelText: 'Code Employé *', isDense: true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _tempWfDescriptionController,
                      decoration: const InputDecoration(labelText: 'Description / Nom', isDense: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _tempWfStartDateController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Date/Heure Début',
                        isDense: true,
                        suffixIcon: Icon(Icons.calendar_today, size: 18),
                      ),
                      onTap: () async {
                        final picked = await _pickDateTime(_tempWfStartDateTime);
                        if (picked != null) {
                          setState(() {
                            _tempWfStartDateTime = picked;
                            _tempWfStartDateController.text = _formatDT(picked);
                          });
                          _recalculateWorkforceHours();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _tempWfEndDateController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Date/Heure Fin',
                        isDense: true,
                        suffixIcon: Icon(Icons.event_available, size: 18),
                      ),
                      onTap: () async {
                        final picked = await _pickDateTime(_tempWfEndDateTime ?? _tempWfStartDateTime);
                        if (picked != null) {
                          setState(() {
                            _tempWfEndDateTime = picked;
                            _tempWfEndDateController.text = _formatDT(picked);
                          });
                          _recalculateWorkforceHours();
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _tempWfActualHoursController,
                      decoration: const InputDecoration(labelText: 'Heures réelles (auto)', isDense: true),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _tempWfTotalHoursController,
                      decoration: const InputDecoration(labelText: 'Heures totales (auto)', isDense: true),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      final emp = _tempWfEmployeeController.text.trim();
                      if (emp.isEmpty) return;
                      setState(() {
                        _workforce.add({
                          'employee': emp,
                          'description': _tempWfDescriptionController.text.trim().isNotEmpty
                              ? _tempWfDescriptionController.text.trim()
                              : 'Intervenant',
                          'startDate': _tempWfStartDateController.text.trim(),
                          'endDate': _tempWfEndDateController.text.trim(),
                          'actualHours': _tempWfActualHoursController.text.trim(),
                          'totalHours': _tempWfTotalHoursController.text.trim(),
                          'status': _tempWfStatus,
                        });
                        _tempWfEmployeeController.clear();
                        _tempWfDescriptionController.clear();
                        _tempWfStartDateController.clear();
                        _tempWfEndDateController.clear();
                        _tempWfActualHoursController.clear();
                        _tempWfTotalHoursController.clear();
                        _tempWfStartDateTime = null;
                        _tempWfEndDateTime = null;
                      });
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F1B80)),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _workforce.isEmpty
              ? const Center(child: Text('Aucun intervenant affecté'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _workforce.length,
                  itemBuilder: (context, index) {
                    final wf = _workforce[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.people, color: Color(0xFF0F1B80)),
                        title: Text('${wf['description']} (${wf['employee']})'),
                        subtitle: Text('Heures : ${wf['actualHours']}h / ${wf['totalHours']}h'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              final removed = _workforce.removeAt(index);
                              if (removed['pk'] != null) {
                                _deletedWorkforce.add(removed['pk'] as int);
                              }
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// Onglet 5: Matériel / Pièces (Ajout simple en mémoire)
  Widget _buildMaterielTab(ResponsiveSpacing spacing) {
    return Column(
      children: [
        Container(
          color: Colors.grey[100],
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _tempPartCodeController,
                      decoration: const InputDecoration(labelText: 'Code Article *', isDense: true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _tempPartArticleController,
                      decoration: const InputDecoration(labelText: 'Description Article', isDense: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _tempPartQtyController,
                      decoration: const InputDecoration(labelText: 'Quantité utilisée *', isDense: true),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      final pcode = _tempPartCodeController.text.trim();
                      final qty = double.tryParse(_tempPartQtyController.text.trim()) ?? 1.0;
                      if (pcode.isEmpty) return;
                      setState(() {
                        _parts.add({
                          'partCode': pcode,
                          'article': _tempPartArticleController.text.trim().isNotEmpty
                              ? _tempPartArticleController.text.trim()
                              : 'Article $pcode',
                          'qtyUsed': qty,
                        });
                        _tempPartCodeController.clear();
                        _tempPartArticleController.clear();
                        _tempPartQtyController.text = '1';
                      });
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F1B80)),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _parts.isEmpty
              ? const Center(child: Text('Aucune pièce de rechange ajoutée'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _parts.length,
                  itemBuilder: (context, index) {
                    final part = _parts[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.settings, color: Color(0xFF0F1B80)),
                        title: Text('${part['article']} (${part['partCode']})'),
                        subtitle: Text('Quantité : ${part['qtyUsed']}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              final removed = _parts.removeAt(index);
                              if (removed['pk'] != null) {
                                _deletedParts.add(removed['pk'] as int);
                              }
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// Onglet 6: Sous-attributs (Ajout simple en mémoire)
  Widget _buildAttributesTab(ResponsiveSpacing spacing) {
    return Column(
      children: [
        Container(
          color: Colors.grey[100],
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _tempAttrNameController,
                      decoration: const InputDecoration(labelText: 'Nom Attribut *', isDense: true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _tempAttrValueController,
                      decoration: const InputDecoration(labelText: 'Valeur *', isDense: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _tempAttrDescController,
                      decoration: const InputDecoration(labelText: 'Description / Équipement', isDense: true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _tempAttrUnitController,
                      decoration: const InputDecoration(labelText: 'Unité (ex: V, A, °C)', isDense: true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      final name = _tempAttrNameController.text.trim();
                      final val = _tempAttrValueController.text.trim();
                      if (name.isEmpty || val.isEmpty) return;
                      setState(() {
                        _attributes.add({
                          'name': name,
                          'value': val,
                          'description': _tempAttrDescController.text.trim(),
                          'unit': _tempAttrUnitController.text.trim(),
                        });
                        _tempAttrNameController.clear();
                        _tempAttrValueController.clear();
                        _tempAttrDescController.clear();
                        _tempAttrUnitController.clear();
                      });
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F1B80)),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _attributes.isEmpty
              ? const Center(child: Text('Aucun sous-attribut configuré'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _attributes.length,
                  itemBuilder: (context, index) {
                    final attr = _attributes[index];
                    final unit = attr['unit'] as String;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.tune, color: Color(0xFF0F1B80)),
                        title: Text('${attr['name']} : ${attr['value']}${unit.isNotEmpty ? ' $unit' : ''}'),
                        subtitle: attr['description'].toString().isNotEmpty ? Text(attr['description']) : null,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              final removed = _attributes.removeAt(index);
                              if (removed['pk'] != null) {
                                _deletedAttributes.add(removed['pk'] as int);
                              }
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    int? maxLength,
    Widget? suffixIcon,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF0F1B80), fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          readOnly: readOnly || onTap != null,
          onTap: onTap,
          maxLength: maxLength,
          style: TextStyle(fontSize: 14, color: (readOnly || onTap != null) ? Colors.grey.shade600 : Colors.black),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            counterText: '', // Hide character counter for cleaner look
            suffixIcon: suffixIcon,
            suffixIconConstraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFCBD5E1)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF0F1B80), width: 2),
            ),
            errorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.redAccent, width: 2),
            ),
            focusedErrorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.red, width: 2),
            ),
            errorStyle: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final responsive = context.responsive;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        backgroundColor: Colors.white,
        iconColor: const Color(0xFF2B1D4C),
        title: widget.orderToEdit != null ? 'Modifier l\'OT' : 'Créer un OT',
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
      body: _isLoadingData
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF0F1B80)),
                  SizedBox(height: 16),
                  Text('Chargement des données de l\'OT en cours...', style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            )
          : (_isSaving
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF0F1B80)),
                      SizedBox(height: 16),
                      Text('Enregistrement des modifications en cours...', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    KeepAliveWrapper(child: _buildDetailsTab(spacing, responsive)),
                    KeepAliveWrapper(child: _buildModeOperatoireTab(spacing)),
                    KeepAliveWrapper(child: _buildCommentairesTab(spacing)),
                    KeepAliveWrapper(child: _buildMainsOeuvreTab(spacing)),
                    KeepAliveWrapper(child: _buildMaterielTab(spacing)),
                    KeepAliveWrapper(child: _buildAttributesTab(spacing)),
                  ],
                )),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: spacing.custom(horizontal: 16, vertical: 10, bottom: 20),
        child: Row(
          children: [
            // Bouton Annuler
            ElevatedButton(
              onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                foregroundColor: Colors.black87,
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: responsive.hp(1.6)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Annuler', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ),
            const SizedBox(width: 8),

            // Sur les onglets 0 à 4 : Afficher uniquement le bouton "Suivant ➡️"
            if (_tabController.index < 5) ...[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _tabController.animateTo(_tabController.index + 1);
                  },
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('Suivant', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F1B80),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: responsive.hp(1.6)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ]
            // Sur le dernier onglet (Onglet 5) : Afficher "Précédent" + "Enregistrer l'OT 💾"
            else ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _tabController.animateTo(_tabController.index - 1);
                  },
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: const Text('Précédent', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F1B80),
                    side: const BorderSide(color: Color(0xFF0F1B80), width: 1.5),
                    padding: EdgeInsets.symmetric(vertical: responsive.hp(1.6)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSaving || _isLoadingData ? null : _handleSaveGlobal,
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text('Enregistrer l\'OT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F1B80),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: responsive.hp(1.6)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const KeepAliveWrapper({super.key, required this.child});

  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper> with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}

class _EquipmentSelectionModal extends StatefulWidget {
  final String entity;
  final String zone;
  final Function(String) onSelected;

  const _EquipmentSelectionModal({
    Key? key,
    required this.entity,
    required this.zone,
    required this.onSelected,
  }) : super(key: key);

  @override
  State<_EquipmentSelectionModal> createState() => _EquipmentSelectionModalState();
}

class _EquipmentSelectionModalState extends State<_EquipmentSelectionModal> {
  final EquipmentService _equipmentService = EquipmentService();
  final TextEditingController _searchController = TextEditingController();
  List<Equipment> _equipments = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadEquipments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEquipments() async {
    try {
      final response = await _equipmentService.getEquipments(
        entity: widget.entity,
        zone: widget.zone.isNotEmpty ? widget.zone : null,
      );
      if (mounted) {
        setState(() {
          _equipments = response.items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = _equipments.where((eq) {
      final code = eq.code.toLowerCase();
      final desc = eq.description.toLowerCase();
      return code.contains(query) || desc.contains(query);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Choisir un équipement (${widget.entity})',
                style: const TextStyle(
                  color: Color(0xFF0F1B80),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Rechercher par code ou description...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF0F1B80)),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F1B80))))
                : _errorMessage.isNotEmpty
                    ? Center(child: Text('Erreur: $_errorMessage'))
                    : filtered.isEmpty
                        ? const Center(child: Text('Aucun équipement trouvé'))
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final eq = filtered[index];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  eq.code,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F1B80),
                                  ),
                                ),
                                subtitle: Text(
                                  eq.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () {
                                  widget.onSelected(eq.code);
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _GenericSelectionItem {
  final String code;
  final String description;

  _GenericSelectionItem({required this.code, required this.description});
}

class _GenericSelectionModal extends StatefulWidget {
  final String title;
  final List<_GenericSelectionItem> items;
  final Function(String) onSelected;

  const _GenericSelectionModal({
    Key? key,
    required this.title,
    required this.items,
    required this.onSelected,
  }) : super(key: key);

  @override
  State<_GenericSelectionModal> createState() => _GenericSelectionModalState();
}

class _GenericSelectionModalState extends State<_GenericSelectionModal> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = widget.items.where((item) {
      return item.code.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    color: Color(0xFF0F1B80),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Rechercher...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF0F1B80)),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('Aucun élément trouvé'))
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          item.code,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F1B80),
                          ),
                        ),
                        subtitle: Text(item.description),
                        onTap: () {
                          widget.onSelected(item.code);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
