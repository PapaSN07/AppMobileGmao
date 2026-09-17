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
import 'package:appmobilegmao/screens/fichier_lie_screen.dart';
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
  final TextEditingController _equipmentDescController = TextEditingController(); // Description Équipement (Grisâtre/Auto)
  final TextEditingController _supervisorController = TextEditingController();
  final TextEditingController _priorityController = TextEditingController(text: 'Non définie / Par défaut');

  List<_GenericSelectionItem> _priorities = [
    _GenericSelectionItem(code: 'NORMALE', description: 'Normale'),
    _GenericSelectionItem(code: '', description: 'Non définie / Par défaut'),
  ];

  List<_GenericSelectionItem> _jobTypes = [
    _GenericSelectionItem(code: 'CORR', description: 'Correctif'),
    _GenericSelectionItem(code: 'PREV', description: 'Préventif'),
    _GenericSelectionItem(code: 'AMEL', description: 'Amélioration'),
    _GenericSelectionItem(code: 'EXPT', description: 'Exploitation'),
    _GenericSelectionItem(code: 'PALL', description: 'Palliatif'),
  ];

  List<_GenericSelectionItem> _jobClasses = [
    _GenericSelectionItem(code: 'POSTE', description: 'Poste HTA/BT'),
    _GenericSelectionItem(code: 'HTA_S', description: 'Réseau Souterrain HTA'),
    _GenericSelectionItem(code: 'LIGNE', description: 'Ligne Aérienne HTA/BT'),
    _GenericSelectionItem(code: 'CEL-HTA', description: 'Cellules HTA'),
    _GenericSelectionItem(code: 'ARM-PROT', description: 'Armoire de Protection'),
    _GenericSelectionItem(code: 'DEPART', description: 'Départ BT/HTA'),
    _GenericSelectionItem(code: 'BT', description: 'Réseau Basse Tension'),
    _GenericSelectionItem(code: 'ELEC', description: 'Électricité générale'),
  ];

  List<_GenericSelectionItem> _supervisors = [
    _GenericSelectionItem(code: '6073', description: 'Technicien Référent (6073)'),
    _GenericSelectionItem(code: '5286', description: 'ERIC DASYLVA CARDOZO (5286)'),
    _GenericSelectionItem(code: '6732', description: 'Mouhamadou Mansour KEBE (6732)'),
  ];

  static final List<_GenericSelectionItem> _standardActions = [
    _GenericSelectionItem(code: 'DIAG', description: 'Diagnostic et contrôle préliminaire'),
    _GenericSelectionItem(code: 'REMPL', description: 'Remplacement de pièce / composant'),
    _GenericSelectionItem(code: 'REPAR', description: 'Réparation et remise en état'),
    _GenericSelectionItem(code: 'CONT', description: 'Contrôle et mesures électriques'),
    _GenericSelectionItem(code: 'NETT', description: 'Nettoyage et dépoussiérage'),
    _GenericSelectionItem(code: 'SERR', description: 'Serrage des connexions et bornes'),
    _GenericSelectionItem(code: 'ESSAI', description: 'Essais et mise en service'),
    _GenericSelectionItem(code: 'SECUR', description: 'Consignation et mise en sécurité'),
  ];

  static final List<_GenericSelectionItem> _standardResources = [
    _GenericSelectionItem(code: 'RDEF', description: 'Ressource par défaut (RDEF)'),
    _GenericSelectionItem(code: 'ELEC', description: 'Électricien Réseau'),
    _GenericSelectionItem(code: 'MECAN', description: 'Mécanicien'),
    _GenericSelectionItem(code: 'TECH', description: 'Technicien de Maintenance'),
    _GenericSelectionItem(code: 'CHEF', description: 'Chef d\'équipe / Superviseur'),
    _GenericSelectionItem(code: 'LIGNE', description: 'Lignard HTA/BT'),
    _GenericSelectionItem(code: 'AGENT', description: 'Agent d\'intervention'),
  ];

  List<_GenericSelectionItem> _resources = [
    _GenericSelectionItem(code: 'RDEF', description: 'Ressource par défaut (RDEF)'),
    _GenericSelectionItem(code: 'ELEC', description: 'Électricien Réseau'),
    _GenericSelectionItem(code: 'MECAN', description: 'Mécanicien'),
    _GenericSelectionItem(code: 'TECH', description: 'Technicien de Maintenance'),
    _GenericSelectionItem(code: 'CHEF', description: 'Chef d\'équipe / Superviseur'),
    _GenericSelectionItem(code: 'LIGNE', description: 'Lignard HTA/BT'),
    _GenericSelectionItem(code: 'AGENT', description: 'Agent d\'intervention'),
  ];

  List<_GenericSelectionItem> _standardParts = [
    _GenericSelectionItem(code: '0110002', description: 'POTEAU BOIS S140  10 M (P)'),
    _GenericSelectionItem(code: '1R0750', description: 'ROULEAU DE FIL SOUPLE (PI)'),
    _GenericSelectionItem(code: 'TRVX00003', description: 'TERRAINS CIMENTES  L=0,8 et P=1 (PI)'),
    _GenericSelectionItem(code: 'TRVX00004', description: 'TERRAINS CIMENTES  L=1,2 et P=0,8 (PI)'),
    _GenericSelectionItem(code: '123456', description: 'Test reparable (PI)'),
  ];

  List<_GenericSelectionItem> _standardAttributes = [
    _GenericSelectionItem(code: 'Tension assignée', description: 'Tension assignée [kV]'),
    _GenericSelectionItem(code: 'Section câble', description: 'Section câble [MM²]'),
    _GenericSelectionItem(code: 'Longueur ligne', description: 'Longueur ligne [KM]'),
    _GenericSelectionItem(code: 'Puissance nominale', description: 'Puissance nominale [kVA]'),
    _GenericSelectionItem(code: 'Courant assigné', description: 'Courant assigné [A]'),
  ];

  final List<_GenericSelectionItem> _standardFacilities = [
    _GenericSelectionItem(code: 'VEH_LEGER', description: 'Véhicule Léger'),
    _GenericSelectionItem(code: 'VEH_LOURD', description: 'Véhicule Lourd'),
    _GenericSelectionItem(code: 'ENGIN', description: 'Engin de chantier'),
    _GenericSelectionItem(code: 'NACELLE', description: 'Nacelle élévatrice'),
    _GenericSelectionItem(code: 'GROUPE_ELEC', description: 'Groupe électrogène'),
    _GenericSelectionItem(code: 'OUTILLAGE_SPEC', description: 'Outillage spécialisé'),
  ];

  String _formatPriorityLabel(String code) {
    if (code.isEmpty) return 'Non définie / Par défaut';
    for (final item in _priorities) {
      if (item.code == code) {
        return item.code.isNotEmpty ? '${item.code} - ${item.description}' : item.description;
      }
    }
    return code;
  }

  double _completionRate = 0.0;
  String _priority = '';
  String _status = 'CR';
  bool _autoGenerateCode = true;

  // Listes en mémoire pour les sous-ressources des onglets
  final List<Map<String, dynamic>> _operations = [];
  final List<Map<String, dynamic>> _comments = [];
  final List<Map<String, dynamic>> _workforce = [];
  final List<Map<String, dynamic>> _parts = [];
  final List<Map<String, dynamic>> _facilities = [];
  final List<Map<String, dynamic>> _services = [];
  final List<Map<String, dynamic>> _attributes = [];

  // Mémorisation des clés primaires (PK) à supprimer en base
  final List<int> _deletedOperations = [];
  final List<int> _deletedComments = [];
  final List<int> _deletedWorkforce = [];
  final List<int> _deletedParts = [];
  final List<int> _deletedFacilities = [];
  final List<int> _deletedServices = [];
  final List<int> _deletedAttributes = [];

  // Contrôleurs temporaires pour l'ajout dans les onglets
  final TextEditingController _tempOpController = TextEditingController();
  final TextEditingController _tempCommentController = TextEditingController();
  Map<String, dynamic>? _tempCommentAttachedFile;

  // Contrôleurs temporaires Main d'œuvre
  final TextEditingController _tempWfEmployeeController = TextEditingController();
  final TextEditingController _tempWfDescriptionController = TextEditingController(); // Nom employé (Grisâtre/Auto)
  final TextEditingController _tempWfResourceController = TextEditingController(text: 'RDEF'); // Ressource métier (Grisâtre/Auto)
  final TextEditingController _tempWfStartDateController = TextEditingController();
  final TextEditingController _tempWfEndDateController = TextEditingController();
  final TextEditingController _tempWfActualHoursController = TextEditingController();
  final TextEditingController _tempWfTotalHoursController = TextEditingController();
  String _tempWfStatus = 'AV'; // 'AV' (À valider) correspond à la valeur officielle Coswin 8i (Capture 1)
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
  final TextEditingController _tempPartPlannedQtyController = TextEditingController();
  final TextEditingController _tempPartQtyController = TextEditingController();

  // Contrôleurs temporaires Moyens / Véhicules
  int _materielSubTabIndex = 0; // 0: Pièces, 1: Moyens, 2: Services
  final TextEditingController _tempFacMoyenController = TextEditingController();
  final TextEditingController _tempFacMoyenDescController = TextEditingController();
  final TextEditingController _tempFacEquipementController = TextEditingController();
  final TextEditingController _tempFacDurationController = TextEditingController(text: '1.0');

  // Contrôleurs temporaires Services (Alignés capture Coswin 8i)
  final TextEditingController _tempServiceArticleController = TextEditingController();
  final TextEditingController _tempServiceDescController = TextEditingController();
  final TextEditingController _tempServicePlannedQtyController = TextEditingController(text: '1.00');
  final TextEditingController _tempServiceUsedQtyController = TextEditingController(text: '0.00');
  final TextEditingController _tempServiceUnitController = TextEditingController(text: 'U');
  final TextEditingController _tempServiceCostController = TextEditingController();
  final TextEditingController _tempServiceSeqController = TextEditingController();
  final TextEditingController _tempServiceCompteurController = TextEditingController();
  final TextEditingController _tempServiceActionController = TextEditingController();
  String _tempServiceReplacementType = '0. Systématique';
  bool _tempServiceMajDirecte = false;
  bool _tempServiceSansBS = false;

  static final List<_GenericSelectionItem> _standardServices = [
    _GenericSelectionItem(code: 'PREST_ELEC', description: 'Prestation Électrique Externe'),
    _GenericSelectionItem(code: 'PREST_MECAN', description: 'Prestation Mécanique / Usinage'),
    _GenericSelectionItem(code: 'CONTROLE_APAVE', description: 'Contrôle Réglementaire APAVE / Bureau Veritas'),
    _GenericSelectionItem(code: 'NETTOYAGE_INDUS', description: 'Nettoyage Industriel et Dépoussiérage HTA'),
    _GenericSelectionItem(code: 'TRANSPORT_ENGIN', description: 'Transport et Levage par Grue'),
    _GenericSelectionItem(code: 'LOCATION_GROUPE', description: 'Location Groupe Électrogène de Secours'),
  ];

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

    // Initialisation des dates et valeurs par défaut pour la main d'œuvre (Capture 1 Coswin 8i)
    final now = DateTime.now();
    _tempWfStartDateController.text = now.toString().substring(0, 16);
    _tempWfEndDateController.text = now.add(const Duration(hours: 1)).toString().substring(0, 16);
    _tempWfDescriptionController.text = 'Mbaye NIANG';
    _tempWfResourceController.text = 'ELEC';
    _tempPartPlannedQtyController.text = '0.00';
    _tempPartQtyController.text = '1.00';

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
      _equipmentDescController.text = ot.wowoEquipmentDescription;
      _supervisorController.text = (ot.wowoSupervisor != null && ot.wowoSupervisor!.isNotEmpty && ot.wowoSupervisor!.toLowerCase() != 'supervisor')
          ? ot.wowoSupervisor!
          : '6073';
      _tempWfEmployeeController.text = _supervisorController.text;
      _completionRate = ot.wowoCompletionRate ?? 0.0;
      
      final normPriority = (ot.wowoPriority ?? '').trim().toUpperCase();
      _priority = normPriority == 'NORMALE' ? 'NORMALE' : '';
      _priorityController.text = _formatPriorityLabel(_priority);

      final normStatus = ot.wowoUserStatus.trim().toUpperCase();
      _status = ['CR', 'OUV', 'EC', 'CL', 'TE', 'SUSP', 'AY'].contains(normStatus) ? normStatus : 'OUV';

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
            _supervisorController.text = '6073';
            _tempWfEmployeeController.text = '6073';
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

  /// Formate un commentaire pour l'enregistrement Coswin avec ses métadonnées de fichier joint (WAF safe)
  static String _formatCommentWithAttachment(String text, Map<String, dynamic>? attached) {
    final cleanText = text.trim();
    if (attached == null) return cleanText;

    final nom = (attached['nom'] ?? '').toString().trim();
    final fileDesc = (attached['description'] ?? '').toString().trim();
    final type = (attached['type'] ?? '').toString().trim();
    final cat = (attached['categorie'] ?? '').toString().trim();
    final url = (attached['url'] ?? '').toString().trim();
    final imp = (attached['isImprimable'] == true || attached['isImprimable']?.toString().toLowerCase() == 'true') ? 'Oui' : 'Non';
    final date = (attached['dateCreation'] ?? '').toString().trim();
    final author = (attached['createur'] ?? '').toString().trim();

    final parts = <String>[];
    if (nom.isNotEmpty) parts.add('Nom: $nom');
    if (fileDesc.isNotEmpty) parts.add('Desc: $fileDesc');
    if (type.isNotEmpty) parts.add('Type: $type');
    if (cat.isNotEmpty) parts.add('Cat: $cat');
    if (url.isNotEmpty) parts.add('URL: $url');
    if (imp == 'Oui') parts.add('Imprimable: Oui');
    if (date.isNotEmpty) parts.add('Date: $date');
    if (author.isNotEmpty) parts.add('Auteur: $author');

    final fileMeta = parts.join(' ; ');
    if (cleanText.isNotEmpty) {
      return '$cleanText\n[PJ: $fileMeta]';
    } else {
      return '[PJ: $fileMeta]';
    }
  }

  /// Décode les métadonnées d'un fichier joint stocké dans le texte du commentaire
  static Map<String, dynamic>? _parseAttachedFileFromComment(String rawText) {
    String tag = '';
    if (rawText.contains('[PJ:')) {
      tag = '[PJ:';
    } else if (rawText.contains('📎 [Fichier joint:')) {
      tag = '📎 [Fichier joint:';
    } else {
      return null;
    }

    final startIdx = rawText.indexOf(tag);
    final endIdx = rawText.indexOf(']', startIdx);
    final content = endIdx != -1
        ? rawText.substring(startIdx + tag.length, endIdx).trim()
        : rawText.substring(startIdx + tag.length).trim();

    final map = <String, dynamic>{};
    final delimiter = content.contains(' ; ') ? ' ; ' : '|';
    final tokens = content.split(delimiter);
    for (final token in tokens) {
      final t = token.trim();
      if (t.startsWith('Nom:')) {
        map['nom'] = t.substring(4).trim();
      } else if (t.startsWith('Desc:')) {
        map['description'] = t.substring(5).trim();
      } else if (t.startsWith('Type:')) {
        map['type'] = t.substring(5).trim();
      } else if (t.startsWith('Cat:')) {
        map['categorie'] = t.substring(4).trim();
      } else if (t.startsWith('URL:')) {
        map['url'] = t.substring(4).trim();
      } else if (t.startsWith('Imprimable:')) {
        map['isImprimable'] = t.substring(11).trim() == 'Oui';
      } else if (t.startsWith('Date:')) {
        map['dateCreation'] = t.substring(5).trim();
      } else if (t.startsWith('Auteur:')) {
        map['createur'] = t.substring(7).trim();
      }
    }
    if (map.isEmpty && content.isNotEmpty) {
      map['nom'] = content;
    }
    return map.isNotEmpty ? map : null;
  }

  /// Extrait le texte pur du commentaire sans les balises de fichier joint
  static String _extractCleanCommentText(String rawText) {
    if (rawText.contains('[PJ:')) {
      return rawText.split('[PJ:')[0].trim();
    }
    if (rawText.contains('📎 [Fichier joint:')) {
      return rawText.split('📎 [Fichier joint:')[0].trim();
    }
    return rawText.trim();
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
        _comments.addAll(docs.map((doc) {
          final rawText = (doc['wodoComment'] ?? doc['wodoDescription'] ?? doc['comment'] ?? doc['reemDescription'] ?? '').toString();
          final attached = _parseAttachedFileFromComment(rawText);
          final cleanDesc = _extractCleanCommentText(rawText);
          return {
            'pk': (doc['pkDocument'] ?? doc['pkEmployeeFeedback'] ?? doc['pkComment'] ?? 0) as int,
            'employee': (doc['author'] ?? doc['wodoCreationUser'] ?? doc['woefEmployee'] ?? '').toString(),
            'description': cleanDesc,
            'startDate': (doc['createdAt'] ?? doc['woefStartDate'] ?? '').toString(),
            'endDate': (doc['woefEndDate'] ?? '').toString(),
            'actualHours': doc['woefActualHours']?.toString() ?? '1',
            'totalHours': doc['woefTotalHours']?.toString() ?? '1',
            'status': (doc['wodoType'] ?? doc['woefUserStatus'] ?? 'CR').toString(),
            'attachedFile': attached,
          };
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

      // 4b. Moyens / Véhicules
      try {
        final facs = await _otService.getMoyens(otCode);
        setState(() {
          _facilities.addAll(facs.map((item) => {
            'pk': (item['pkFacility'] ?? item['pk'] ?? 0) as int,
            'moyen': item['wofuFacility']?.toString() ?? item['moyen']?.toString() ?? '',
            'equipement': item['wofuEquipment']?.toString() ?? item['equipement']?.toString() ?? '',
            'duration': double.tryParse(item['wofuDuration']?.toString() ?? '1.0') ?? 1.0,
          }));
        });
      } catch (e) {
        debugPrint('Erreur chargement moyens: $e');
      }

      // 4c. Services
      try {
        final srvs = await _otService.getServices(otCode);
        setState(() {
          _services.addAll(srvs.map((item) {
            final serviceCode = item['woseService']?.toString()
                ?? item['woseCode']?.toString()
                ?? item['service']?.toString()
                ?? '';
            final description = item['woseDescription']?.toString()
                ?? item['serviceDescription']?.toString()
                ?? serviceCode;
            final label = description.isNotEmpty ? description : serviceCode;
            final qtyPlan = item['wosePlannedQuantity']?.toString() ?? '1.00';
            final qtyCons = item['woseUsedQuantity']?.toString() ?? '0.00';
            return {
              'pk': (item['pkService'] ?? item['pkServiceUsed'] ?? item['pk'] ?? 0) as int,
              'article': label.isNotEmpty ? label : 'Service',
              'serviceCode': serviceCode,
              'plannedQty': double.tryParse(qtyPlan) ?? 1.0,
              'usedQty': double.tryParse(qtyCons) ?? 0.0,
              'unit': item['woseUnit']?.toString() ?? 'U',
            };
          }));
        });
      } catch (e) {
        debugPrint('Erreur chargement services: $e');
      }

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
    _equipmentDescController.dispose();
    _supervisorController.dispose();
    _priorityController.dispose();
    _tempOpController.dispose();
    _tempCommentController.dispose();
    _tempWfEmployeeController.dispose();
    _tempWfDescriptionController.dispose();
    _tempWfResourceController.dispose();
    _tempWfStartDateController.dispose();
    _tempWfEndDateController.dispose();
    _tempWfActualHoursController.dispose();
    _tempWfTotalHoursController.dispose();
    _tempPartCodeController.dispose();
    _tempPartArticleController.dispose();
    _tempPartPlannedQtyController.dispose();
    _tempPartQtyController.dispose();
    _tempFacMoyenController.dispose();
    _tempFacMoyenDescController.dispose();
    _tempFacEquipementController.dispose();
    _tempFacDurationController.dispose();
    _tempServiceArticleController.dispose();
    _tempServiceDescController.dispose();
    _tempServicePlannedQtyController.dispose();
    _tempServiceUsedQtyController.dispose();
    _tempServiceUnitController.dispose();
    _tempServiceCostController.dispose();
    _tempServiceSeqController.dispose();
    _tempServiceCompteurController.dispose();
    _tempServiceActionController.dispose();
    _tempAttrNameController.dispose();
    _tempAttrValueController.dispose();
    _tempAttrDescController.dispose();
    _tempAttrUnitController.dispose();
    super.dispose();
  }

  Future<void> _loadSelectors() async {
    // 1. Charger les référentiels officiels Coswin Senelec (types, classes, priorités, superviseurs)
    try {
      final refs = await _otService.getReferentials();
      if (mounted && refs.isNotEmpty) {
        setState(() {
          if (refs['jobTypes'] is List) {
            final items = (refs['jobTypes'] as List)
                .map((e) => _GenericSelectionItem(
                      code: e['code']?.toString() ?? '',
                      description: e['description']?.toString() ?? e['code']?.toString() ?? '',
                    ))
                .where((item) => item.code.isNotEmpty)
                .toList();
            if (items.isNotEmpty) _jobTypes = items;
          }

          if (refs['jobClasses'] is List) {
            final items = (refs['jobClasses'] as List)
                .map((e) => _GenericSelectionItem(
                      code: e['code']?.toString() ?? '',
                      description: e['description']?.toString() ?? e['code']?.toString() ?? '',
                    ))
                .where((item) => item.code.isNotEmpty)
                .toList();
            if (items.isNotEmpty) _jobClasses = items;
          }

          if (refs['priorities'] is List) {
            final items = (refs['priorities'] as List)
                .map((e) => _GenericSelectionItem(
                      code: e['code']?.toString() ?? '',
                      description: e['description']?.toString() ??
                          (e['code']?.toString().isNotEmpty == true
                              ? e['code'].toString()
                              : 'Non définie / Par défaut'),
                    ))
                .toList();
            if (items.isNotEmpty) _priorities = items;
          }

          if (refs['supervisors'] is List) {
            final items = (refs['supervisors'] as List)
                .map((e) => _GenericSelectionItem(
                      code: e['code']?.toString() ?? '',
                      description: e['description']?.toString() ?? e['code']?.toString() ?? '',
                    ))
                .where((item) => item.code.isNotEmpty)
                .toList();
            if (items.isNotEmpty) _supervisors = items;
          }

          if (refs['resources'] is List) {
            final items = (refs['resources'] as List)
                .map((e) => _GenericSelectionItem(
                      code: e['code']?.toString() ?? '',
                      description: e['description']?.toString() ?? e['code']?.toString() ?? '',
                    ))
                .where((item) => item.code.isNotEmpty)
                .toList();
            if (items.isNotEmpty) _resources = items;
          }

          if (refs['items'] is List) {
            final items = (refs['items'] as List)
                .map((e) => _GenericSelectionItem(
                      code: e['code']?.toString() ?? '',
                      description: e['description']?.toString() ?? e['code']?.toString() ?? '',
                    ))
                .where((item) => item.code.isNotEmpty)
                .toList();
            if (items.isNotEmpty) _standardParts = items;
          }

          if (refs['specifications'] is List) {
            final items = (refs['specifications'] as List)
                .map((e) => _GenericSelectionItem(
                      code: e['code']?.toString() ?? '',
                      description: e['description']?.toString() ?? e['code']?.toString() ?? '',
                    ))
                .where((item) => item.code.isNotEmpty)
                .toList();
            if (items.isNotEmpty) _standardAttributes = items;
          }
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement référentiels Coswin: $e');
    }

    // Charger les articles Coswin si non encore chargés dans les référentiels
    try {
      if (_standardParts.length <= 5) {
        final realItems = await _otService.getItems();
        if (mounted && realItems.isNotEmpty) {
          setState(() {
            _standardParts = realItems
                .map((e) {
                  final c = (e['sritCode'] ?? e['code'])?.toString() ?? '';
                  final d = (e['sritDescription'] ?? e['description'])?.toString() ?? c;
                  final u = (e['sritStockUnit'] ?? e['unit'])?.toString() ?? '';
                  final fullDesc = u.isNotEmpty ? '$d ($u)' : d;
                  return _GenericSelectionItem(code: c, description: fullDesc);
                })
                .where((it) => it.code.isNotEmpty)
                .toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Erreur chargement articles Coswin: $e');
    }

    // Charger les spécifications Coswin si non encore chargées
    try {
      if (_standardAttributes.length <= 5) {
        final realSpecs = await _otService.getSpecifications();
        if (mounted && realSpecs.isNotEmpty) {
          setState(() {
            _standardAttributes = realSpecs
                .map((e) {
                  final n = (e['name'] ?? e['code'])?.toString() ?? '';
                  final u = (e['unit'] ?? '')?.toString() ?? '';
                  final full = u.isNotEmpty && !n.contains(u) ? '$n [$u]' : n;
                  return _GenericSelectionItem(code: n, description: full);
                })
                .where((it) => it.code.isNotEmpty)
                .toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Erreur chargement spécifications Coswin: $e');
    }

    // 2. Charger les sélecteurs de zones/entités de l'équipement
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
          equipmentService: _equipmentService,
          onSelected: (equipmentCode, equipmentDesc) {
            setState(() {
              _equipmentController.text = equipmentCode;
              _equipmentDescController.text = equipmentDesc;
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
        if (_priority.trim().isNotEmpty) 'wowoPriority': _priority.trim(),
        'wowoUserStatus': _status,
      };

      final String finalOTCode;

      if (_isEditMode) {
        // Mode Édition : Mise à jour de l'OT principal (Onglet 0)
        finalOTCode = widget.orderToEdit!.wowoCode.toString();
        try {
          await _otService.updateOT(widget.orderToEdit!.wowoCode, otData);
        } catch (e) {
          _tabController.animateTo(0);
          throw Exception("Informations générales : $e");
        }

        // --- EXÉCUTER LES SUPPRESSIONS D'ÉLÉMENTS ---
        for (final pk in _deletedOperations) {
          try {
            await _otService.deleteOperation(finalOTCode, pk);
          } catch (e) {
            _tabController.animateTo(1);
            throw Exception("Mode opératoire (suppression) : $e");
          }
        }
        for (final pk in _deletedComments) {
          try {
            await _otService.deleteDocument(finalOTCode, pk);
          } catch (e) {
            _tabController.animateTo(2);
            throw Exception("Compte-rendu (suppression) : $e");
          }
        }
        for (final pk in _deletedWorkforce) {
          try {
            await _otService.deleteWorkforce(finalOTCode, pk);
          } catch (e) {
            _tabController.animateTo(3);
            throw Exception("Main d'œuvre (suppression) : $e");
          }
        }
        for (final pk in _deletedParts) {
          try {
            await _otService.deletePart(finalOTCode, pk);
          } catch (e) {
            _tabController.animateTo(4);
            throw Exception("Matériel (suppression) : $e");
          }
        }
        for (final pk in _deletedFacilities) {
          try {
            await _otService.deleteFacilityUsed(finalOTCode, pk);
          } catch (e) {
            _tabController.animateTo(4);
            throw Exception("Matériel / Moyens (suppression) : $e");
          }
        }
        for (final pk in _deletedServices) {
          try {
            await _otService.deleteServiceUsed(finalOTCode, pk);
          } catch (e) {
            _tabController.animateTo(4);
            throw Exception("Matériel / Services (suppression) : $e");
          }
        }
        for (final pk in _deletedAttributes) {
          try {
            await _otService.deleteAttribute(finalOTCode, pk);
          } catch (e) {
            _tabController.animateTo(5);
            throw Exception("Sous d'attributs (suppression) : $e");
          }
        }
      } else {
        // Mode Création : Création de l'OT principal (Onglet 0)
        try {
          final WorkOrder newOT = await _otService.createOT(otData);
          finalOTCode = newOT.wowoCode.toString();
        } catch (e) {
          _tabController.animateTo(0);
          throw Exception("Informations générales : $e");
        }
      }

      // --- EXÉCUTER LES AJOUTS DE NOUVEAUX ÉLÉMENTS (ceux sans 'pk') ---
      // 1. Mode opératoire (Onglet 1)
      for (final op in _operations) {
        if (op['pk'] == null) {
          try {
            await _otService.createOperation(finalOTCode, {
              'opopDescription': op['description'],
              'opopJobDescription': op['description'],
            });
          } catch (e) {
            _tabController.animateTo(1);
            throw Exception("Mode opératoire : $e");
          }
        }
      }

      // 2. Commentaires / Compte-rendu (Onglet 2)
      for (final comment in _comments) {
        if (comment['pk'] == null) {
          try {
            final fullDesc = _formatCommentWithAttachment(
              comment['description']?.toString() ?? '',
              comment['attachedFile'] as Map<String, dynamic>?,
            );
            await _otService.createDocument(finalOTCode, {
              'woefEmployee': comment['employee'],
              'reemDescription': fullDesc,
              'woefStartDate': comment['startDate'],
              'woefEndDate': comment['endDate'],
              'woefActualHours': comment['actualHours'],
              'woefTotalHours': comment['totalHours'],
              'woefUserStatus': comment['status'],
            });
          } catch (e) {
            _tabController.animateTo(2);
            throw Exception("Compte-rendu : $e");
          }
        }
      }

      // 3. Main d'œuvre (Onglet 3)
      for (final wf in _workforce) {
        if (wf['pk'] == null) {
          try {
            final rawRes = (wf['resource'] as String? ?? '').trim();
            String resourceCode = rawRes.contains(' - ') ? rawRes.split(' - ')[0].trim() : rawRes;
            if (resourceCode.isEmpty || resourceCode == wf['employee']) {
              resourceCode = 'RDEF';
            }
            final emp = (wf['employee'] != null && wf['employee'].toString().trim().isNotEmpty && wf['employee'].toString().trim().toLowerCase() != 'supervisor')
                ? wf['employee'].toString().trim()
                : (_supervisorController.text.trim().isNotEmpty && _supervisorController.text.trim().toLowerCase() != 'supervisor' ? _supervisorController.text.trim() : '6073');
            await _otService.createWorkforce(finalOTCode, {
              'woeaEmployee': emp,
              'woeaResource': resourceCode,
              'woeaPlannedHours': double.tryParse(wf['actualHours']?.toString() ?? '1.0') ?? 1.0,
              'woeaAllocationDate': DateTime.now().toIso8601String(),
              'woeaIsPlanned': true,
            });
          } catch (e) {
            _tabController.animateTo(3);
            throw Exception("Main d'œuvre : $e");
          }
        }
      }

      // 4. Pièces de rechange (Onglet 4)
      for (final part in _parts) {
        if (part['pk'] == null) {
          try {
            await _otService.createPart(finalOTCode, {
              'wospItem': part['partCode'],
              'wospPart': part['partCode'],
              'wospPartDescription': part['article'],
              'wospQtyPlanned': part['plannedQty'] ?? 0.0,
              'wospQtyUsed': part['qtyUsed'] ?? 1.0,
            });
          } catch (e) {
            _tabController.animateTo(4);
            throw Exception("Matériel / Pièces : $e");
          }
        }
      }

      // 4b. Moyens / Véhicules (Onglet 4)
      for (final fac in _facilities) {
        if (fac['pk'] == null) {
          try {
            await _otService.createFacilityUsed(finalOTCode, {
              'wofuFacility': fac['moyen'],
              'wofuEquipment': fac['equipement'],
              'wofuDuration': fac['duration'] ?? 1.0,
            });
          } catch (e) {
            _tabController.animateTo(4);
            throw Exception("Matériel / Moyens : $e");
          }
        }
      }

      // 4c. Services (Onglet 4)
      for (final srv in _services) {
        if (srv['pk'] == null) {
          try {
            await _otService.createServiceUsed(finalOTCode, {
              'woseService': srv['article'],
              'woseDescription': srv['article'],
              'wosePlannedQuantity': srv['plannedQty'] ?? 1.0,
              'woseUsedQuantity': srv['usedQty'] ?? 0.0,
              'woseQuantity': (srv['usedQty'] ?? 0.0) > 0 ? srv['usedQty'] : (srv['plannedQty'] ?? 1.0),
              'woseUnit': srv['unit'] ?? 'U',
            });
          } catch (e) {
            _tabController.animateTo(4);
            throw Exception("Matériel / Services : $e");
          }
        }
      }

      // 5. Attributs (Onglet 5)
      for (final attr in _attributes) {
        if (attr['pk'] == null) {
          try {
            await _otService.createAttribute(finalOTCode, {
              'woatName': attr['name'],
              'woatValue': attr['value'],
              'woatDescription': attr['description'],
              'woatUnitSymbol': attr['unit'],
              'woatValueType': 'ALPHANUMERIC',
            });
          } catch (e) {
            _tabController.animateTo(5);
            throw Exception("Sous d'attributs : $e");
          }
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
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade800,
          duration: const Duration(seconds: 5),
          content: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  errorMsg,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
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
                      _showGenericSelector(
                        title: 'Choisir la Famille (Type)',
                        items: _jobTypes,
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
                      _showGenericSelector(
                        title: 'Choisir la Classe de travail',
                        items: _jobClasses,
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
                    onTap: _showEquipmentSelector,
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
                        items: items.isNotEmpty ? items : _supervisors,
                        onSelected: (val) => setState(() => _supervisorController.text = val),
                      );
                    },
                  ),
                ),
              ],
            ),
            if (_equipmentDescController.text.isNotEmpty || _equipmentController.text.isNotEmpty) ...[
              SizedBox(height: spacing.small),
              _buildInputField(
                label: 'Description de l\'équipement (Auto/Coswin)',
                controller: _equipmentDescController,
                readOnly: true,
                isGreyedOut: true,
              ),
            ],
            SizedBox(height: spacing.medium),
            Row(
              children: [
                Expanded(
                  child: _buildInputField(
                    label: 'Priorité',
                    controller: _priorityController,
                    suffixIcon: const Icon(Icons.arrow_drop_down, color: Color(0xFF0F1B80)),
                    onTap: () {
                      _showGenericSelector(
                        title: 'Choisir la Priorité',
                        items: _priorities,
                        onSelected: (code) {
                          setState(() {
                            _priority = code;
                            _priorityController.text = _formatPriorityLabel(code);
                          });
                        },
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
                        'Statut de départ',
                        style: TextStyle(color: Color(0xFF0F1B80), fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      DropdownButtonFormField<String>(
                        value: _status,
                        onChanged: (val) => setState(() => _status = val ?? 'CR'),
                        items: const [
                          DropdownMenuItem(value: 'CR', child: Text('Créé (CR)')),
                          DropdownMenuItem(value: 'OUV', child: Text('Ouvert (OUV)')),
                          DropdownMenuItem(value: 'EC', child: Text('En cours (EC)')),
                          DropdownMenuItem(value: 'SUSP', child: Text('Suspendu (SUSP)')),
                          DropdownMenuItem(value: 'CL', child: Text('Clôturé (CL)')),
                          DropdownMenuItem(value: 'TE', child: Text('Terminé (TE)')),
                          DropdownMenuItem(value: 'AY', child: Text('Archivé (AY)')),
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
                  decoration: InputDecoration(
                    labelText: 'Saisir ou choisir une étape...',
                    isDense: true,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF0F1B80)),
                      tooltip: 'Choisir une action type',
                      onPressed: () {
                        _showGenericSelector(
                          title: 'Choisir une Action / Étape',
                          items: _standardActions,
                          onSelected: (code) {
                            final match = _standardActions.firstWhere((a) => a.code == code);
                            setState(() {
                              _tempOpController.text = '${match.code} - ${match.description}';
                            });
                          },
                        );
                      },
                    ),
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

  /// Onglet 3: Commentaires (Ajout de commentaire avec pièce jointe / fichier lié)
  Widget _buildCommentairesTab(ResponsiveSpacing spacing) {
    return Column(
      children: [
        Container(
          color: Colors.grey[100],
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Zone de saisie multi-lignes
              TextFormField(
                controller: _tempCommentController,
                maxLines: 3,
                minLines: 2,
                decoration: InputDecoration(
                  hintText: 'Saisir une observation, un compte-rendu ou un commentaire...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF0F1B80), width: 1.5),
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 10),

              // Affichage du fichier joint temporaire s'il a été sélectionné
              if (_tempCommentAttachedFile != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EDFF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF0F1B80).withAlpha(80)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.attach_file, size: 18, color: Color(0xFF0F1B80)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _tempCommentAttachedFile!['nom']?.toString().isNotEmpty == true
                                  ? _tempCommentAttachedFile!['nom'].toString()
                                  : 'Document joint',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F1B80),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if ((_tempCommentAttachedFile!['type'] ?? '').toString().isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F1B80),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _tempCommentAttachedFile!['type'].toString().toUpperCase(),
                                style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18, color: Colors.red),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Retirer la pièce jointe',
                            onPressed: () {
                              setState(() => _tempCommentAttachedFile = null);
                            },
                          ),
                        ],
                      ),
                      if ((_tempCommentAttachedFile!['description'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Description : ${_tempCommentAttachedFile!['description']}',
                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ],
                      if ((_tempCommentAttachedFile!['categorie'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Catégorie : ${_tempCommentAttachedFile!['categorie']}',
                          style: const TextStyle(fontSize: 11, color: Colors.black54),
                        ),
                      ],
                      if ((_tempCommentAttachedFile!['url'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'URL : ${_tempCommentAttachedFile!['url']}',
                          style: const TextStyle(fontSize: 11, color: Colors.blueAccent),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // Ligne d'actions : [📎 Joindre un fichier lié] + [Ajouter le commentaire]
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push<Map<String, dynamic>>(
                        context,
                        MaterialPageRoute(builder: (context) => const FichierLieScreen()),
                      );
                      if (result != null) {
                        setState(() {
                          _tempCommentAttachedFile = result;
                        });
                      }
                    },
                    icon: const Icon(Icons.attach_file, size: 16, color: Color(0xFF0F1B80)),
                    label: Text(
                      _tempCommentAttachedFile == null ? 'Joindre un fichier lié' : 'Modifier le fichier',
                      style: const TextStyle(
                        color: Color(0xFF0F1B80),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF0F1B80)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () {
                      final text = _tempCommentController.text.trim();
                      if (text.isEmpty && _tempCommentAttachedFile == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Veuillez saisir un texte ou joindre un fichier'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }
                      final user = _supervisorController.text.trim().isNotEmpty
                          ? _supervisorController.text.trim()
                          : 'supervisor';
                      final effectiveDesc = text.isNotEmpty
                          ? text
                          : ((_tempCommentAttachedFile?['description']?.toString().isNotEmpty == true)
                              ? _tempCommentAttachedFile!['description'].toString()
                              : (_tempCommentAttachedFile?['nom'] ?? 'Document joint'));
                      setState(() {
                        _comments.add({
                          'employee': user,
                          'description': effectiveDesc,
                          'startDate': DateTime.now().toString().substring(0, 16),
                          'endDate': DateTime.now().add(const Duration(hours: 1)).toString().substring(0, 16),
                          'actualHours': '1',
                          'totalHours': '1',
                          'status': 'F',
                          'attachedFile': _tempCommentAttachedFile != null ? Map<String, dynamic>.from(_tempCommentAttachedFile!) : null,
                        });
                        _tempCommentController.clear();
                        _tempCommentAttachedFile = null;
                      });
                    },
                    icon: const Icon(Icons.add_comment, size: 16, color: Colors.white),
                    label: const Text(
                      'Ajouter',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F1B80),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Liste des commentaires existants
        Expanded(
          child: _comments.isEmpty
              ? const Center(child: Text('Aucun commentaire ajouté'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _comments.length,
                  itemBuilder: (context, index) {
                    final comm = _comments[index];
                    final attached = comm['attachedFile'] as Map<String, dynamic>?;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => _showCommentDetailsModal(comm),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.comment, color: Color(0xFF0F1B80), size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Par : ${comm['employee'] ?? '-'}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      setState(() {
                                        final removed = _comments.removeAt(index);
                                        if (removed['pk'] != null) {
                                          _deletedComments.add(removed['pk'] as int);
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                comm['description'] ?? '',
                                style: const TextStyle(fontSize: 14, color: Colors.black87),
                              ),
                              if (attached != null) ...[
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8EDFF),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFF0F1B80).withAlpha(50)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.attach_file, size: 16, color: Color(0xFF0F1B80)),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              attached['nom']?.toString().isNotEmpty == true
                                                  ? attached['nom'].toString()
                                                  : 'Document joint',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF0F1B80),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if ((attached['type'] ?? '').toString().isNotEmpty)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              margin: const EdgeInsets.only(left: 4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF0F1B80),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                attached['type'].toString().toUpperCase(),
                                                style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                        ],
                                      ),
                                      if ((attached['description'] ?? '').toString().isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Description : ${attached['description']}',
                                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                                        ),
                                      ],
                                      if ((attached['categorie'] ?? '').toString().isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Catégorie : ${attached['categorie']}',
                                          style: const TextStyle(fontSize: 11, color: Colors.black54),
                                        ),
                                      ],
                                      if ((attached['url'] ?? '').toString().isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'URL : ${attached['url']}',
                                          style: const TextStyle(fontSize: 11, color: Colors.blueAccent),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// Affiche la modale des détails d'un commentaire en lecture seule
  void _showCommentDetailsModal(Map<String, dynamic> comm) {
    final author = comm['employee']?.toString() ?? 'supervisor';
    final text = comm['description']?.toString() ?? '';
    final dateStr = comm['startDate']?.toString() ?? '';
    final attached = comm['attachedFile'] as Map<String, dynamic>?;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Row(
                children: [
                  Icon(Icons.comment, color: Color(0xFF0F1B80), size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Détails du commentaire',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F1B80),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.account_circle, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            'Auteur : $author',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const Spacer(),
                          const Icon(Icons.access_time, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            dateStr.isNotEmpty ? dateStr : '-',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Observation / Rapport :',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF2B1D4C),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          text.isNotEmpty ? text : 'Aucun texte saisi',
                          style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
                        ),
                      ),
                      if (attached != null) ...[
                        const SizedBox(height: 14),
                        const Text(
                          'Fichier lié / Pièce jointe :',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF2B1D4C),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8EDFF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF0F1B80).withAlpha(40)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.attach_file, color: Color(0xFF0F1B80), size: 18),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      attached['nom'] ?? 'Document',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Color(0xFF0F1B80),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if ((attached['description'] ?? '').toString().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Description : ${attached['description']}',
                                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                                ),
                              ],
                              if ((attached['type'] ?? '').toString().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Type : ${attached['type']}',
                                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                                ),
                              ],
                              if ((attached['categorie'] ?? '').toString().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Catégorie : ${attached['categorie']}',
                                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                                ),
                              ],
                              if (attached['isImprimable'] == true || attached['isImprimable']?.toString().toLowerCase() == 'true') ...[
                                const SizedBox(height: 4),
                                const Row(
                                  children: [
                                    Icon(Icons.check_circle, size: 14, color: Colors.green),
                                    SizedBox(width: 4),
                                    Text('Imprimable', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ],
                              if ((attached['dateCreation'] ?? '').toString().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Date création : ${attached['dateCreation']}',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                              if ((attached['url'] ?? '').toString().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'URL : ${attached['url']}',
                                  style: const TextStyle(fontSize: 11, color: Colors.blueAccent),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F1B80),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Fermer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Onglet 4: Main d'œuvre (Aligné rigoureusement avec Coswin 8i Capture 1)
  Widget _buildMainsOeuvreTab(ResponsiveSpacing spacing) {
    return Column(
      children: [
        Container(
          color: Colors.grey[100],
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Ligne 1: Code Employé (Sélection) et Description de l'employé (Grisâtre/Auto)
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _tempWfEmployeeController,
                      decoration: InputDecoration(
                        labelText: 'Employé *',
                        hintText: 'Code',
                        isDense: true,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF0F1B80)),
                          tooltip: 'Choisir un intervenant',
                          onPressed: () {
                            final sups = _supervisors.isNotEmpty ? _supervisors : _extractSelectionItems('supervisors');
                            final allItems = sups.isNotEmpty ? sups : [
                              _GenericSelectionItem(code: '6073', description: 'Technicien Référent (6073)'),
                              _GenericSelectionItem(code: '5893', description: 'Mbaye NIANG (5893)'),
                              _GenericSelectionItem(code: '6062', description: 'Agent 6062 (6062)'),
                              _GenericSelectionItem(code: '5286', description: 'ERIC DASYLVA CARDOZO (5286)'),
                              _GenericSelectionItem(code: '6732', description: 'Mouhamadou Mansour KEBE (6732)'),
                              _GenericSelectionItem(code: 'EXTERNE', description: 'Prestataire Externe (EXTERNE)'),
                            ];
                            _showGenericSelector(
                              title: 'Choisir un Intervenant',
                              items: allItems,
                              onSelected: (val) {
                                final match = allItems.firstWhere(
                                  (it) => it.code == val,
                                  orElse: () => _GenericSelectionItem(code: val, description: val),
                                );
                                String cleanName = match.description;
                                if (cleanName.contains('(')) {
                                  cleanName = cleanName.split('(')[0].trim();
                                }
                                setState(() {
                                  _tempWfEmployeeController.text = val;
                                  _tempWfDescriptionController.text = cleanName.isNotEmpty ? cleanName : val;
                                  // Auto-projection de la ressource métier (ELEC pour 5893, RDEF par défaut)
                                  if (val == '5893') {
                                    _tempWfResourceController.text = 'ELEC';
                                  } else {
                                    _tempWfResourceController.text = 'RDEF';
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEEEEE),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: TextFormField(
                        controller: _tempWfDescriptionController,
                        readOnly: true,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Description (Auto)',
                          isDense: true,
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Ligne 2: Ressource métier (Grisâtre/Auto-héritée) et État OT de l'employé
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEEEEE),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: TextFormField(
                        controller: _tempWfResourceController,
                        readOnly: true,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Ressource (Auto)',
                          isDense: true,
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _tempWfStatus,
                      isDense: true,
                      isExpanded: true, // ✅ évite le RenderFlex overflow à 147px
                      decoration: const InputDecoration(
                        labelText: 'État',
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'AV', child: Text('AV - En cours', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 'F',  child: Text('F - Clôturé',   overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 'EC', child: Text('EC - En cours',  overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: (val) => setState(() => _tempWfStatus = val ?? 'AV'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Ligne 3: Dates de début et de fin
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _tempWfStartDateController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Date de début',
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
                        labelText: 'Date de fin',
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
              // Ligne 4: Heures réalisées et bouton Ajouter
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _tempWfActualHoursController,
                      decoration: const InputDecoration(
                        labelText: 'Réalisées *',
                        isDense: true,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEEEEE),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: TextFormField(
                        controller: _tempWfTotalHoursController,
                        readOnly: true,
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade800, fontWeight: FontWeight.w500),
                        decoration: const InputDecoration(
                          labelText: 'Planifiées (0,00)',
                          isDense: true,
                          border: InputBorder.none,
                        ),
                      ),
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
                          'resource': _tempWfResourceController.text.trim().isNotEmpty
                              ? _tempWfResourceController.text.trim()
                              : 'RDEF',
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
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFF0F1B80),
                          child: Icon(Icons.person, color: Colors.white, size: 20),
                        ),
                        title: Text(
                          '${wf['description']} (${wf['employee']})',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEEEEE),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.grey.shade400),
                                  ),
                                  child: Text(
                                    'Ressource : ${wf['resource'] ?? 'RDEF'}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F1B80).withAlpha(20),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'État : ${wf['status'] ?? 'AV'}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F1B80)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${wf['startDate']} ➔ ${wf['endDate']} (${wf['actualHours']}h réalisées)',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
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

  /// Onglet 5: Matériel (Sous-onglets Pièces et Moyens / Véhicules - Aligné Coswin 8i Web)
  Widget _buildMaterielTab(ResponsiveSpacing spacing) {
    return Column(
      children: [
        // Sélecteur de sous-onglet Matériel (Pièces vs Moyens/Véhicules)
        Container(
          color: Colors.grey[200],
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _materielSubTabIndex = 0),
                  icon: const Icon(Icons.settings, size: 14),
                  label: Text(
                    'PIÈCES (${_parts.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _materielSubTabIndex == 0 ? const Color(0xFF0F1B80) : Colors.white,
                    foregroundColor: _materielSubTabIndex == 0 ? Colors.white : const Color(0xFF0F1B80),
                    elevation: _materielSubTabIndex == 0 ? 2 : 0,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _materielSubTabIndex = 1),
                  icon: const Icon(Icons.commute, size: 14),
                  label: Text(
                    'MOYENS (${_facilities.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _materielSubTabIndex == 1 ? const Color(0xFF0F1B80) : Colors.white,
                    foregroundColor: _materielSubTabIndex == 1 ? Colors.white : const Color(0xFF0F1B80),
                    elevation: _materielSubTabIndex == 1 ? 2 : 0,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _materielSubTabIndex = 2),
                  icon: const Icon(Icons.handyman, size: 14),
                  label: Text(
                    'SERVICES (${_services.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _materielSubTabIndex == 2 ? const Color(0xFF0F1B80) : Colors.white,
                    foregroundColor: _materielSubTabIndex == 2 ? Colors.white : const Color(0xFF0F1B80),
                    elevation: _materielSubTabIndex == 2 ? 2 : 0,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Contenu du sous-onglet sélectionné
        if (_materielSubTabIndex == 0) ...[
          // === SOUS-ONGLET PIÈCES ===
          Container(
            color: Colors.grey[100],
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Ligne 1: Code Article (Jaune requis) et Description Article (Grisâtre/Auto-récupérée)
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFF99),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: TextFormField(
                          controller: _tempPartCodeController,
                          decoration: InputDecoration(
                            labelText: 'Article *',
                            isDense: true,
                            border: InputBorder.none,
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF0F1B80)),
                              tooltip: 'Choisir une référence article',
                              onPressed: () {
                                _showGenericSelector(
                                  title: 'Choisir un Article / Pièce',
                                  items: _standardParts,
                                  onSelected: (code) {
                                    final match = _standardParts.firstWhere(
                                      (p) => p.code == code,
                                      orElse: () => _GenericSelectionItem(code: code, description: code),
                                    );
                                    setState(() {
                                      _tempPartCodeController.text = match.code;
                                      _tempPartArticleController.text = match.description;
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEEEEE),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: TextFormField(
                          controller: _tempPartArticleController,
                          readOnly: true,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Description Article (Auto)',
                            isDense: true,
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Ligne 2: Quantité planifiée (Jaune requis) et Quantité utilisée
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFF99),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: TextFormField(
                          controller: _tempPartPlannedQtyController,
                          decoration: const InputDecoration(
                            labelText: 'Quantité planifiée *',
                            isDense: true,
                            border: InputBorder.none,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _tempPartQtyController,
                        decoration: const InputDecoration(
                          labelText: 'Quantité utilisée *',
                          isDense: true,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        final pcode = _tempPartCodeController.text.trim();
                        final pdesc = _tempPartArticleController.text.trim();
                        final qty = double.tryParse(_tempPartQtyController.text.trim()) ?? 1.0;
                        final plannedQty = double.tryParse(_tempPartPlannedQtyController.text.trim()) ?? 0.0;
                        if (pcode.isEmpty) return;
                        setState(() {
                          _parts.add({
                            'partCode': pcode,
                            'article': pdesc.isNotEmpty ? pdesc : 'Article $pcode',
                            'plannedQty': plannedQty,
                            'qtyUsed': qty,
                          });
                          _tempPartCodeController.clear();
                          _tempPartArticleController.clear();
                          _tempPartPlannedQtyController.text = '0.00';
                          _tempPartQtyController.text = '1.00';
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
                          title: Text(
                            '${part['article']} (${part['partCode']})',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('Planifiée : ${part['plannedQty'] ?? '0.00'}  |  Utilisée : ${part['qtyUsed'] ?? '1.00'}'),
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
        ] else if (_materielSubTabIndex == 1) ...[
          // === SOUS-ONGLET MOYENS / VÉHICULES ===
          Container(
            color: Colors.grey[100],
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Ligne 1: Moyen (Jaune requis) et Description Moyen (Auto)
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFF99),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: TextFormField(
                          controller: _tempFacMoyenController,
                          decoration: InputDecoration(
                            labelText: 'Moyen / Type *',
                            isDense: true,
                            border: InputBorder.none,
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF0F1B80)),
                              tooltip: 'Choisir un moyen',
                              onPressed: () {
                                _showGenericSelector(
                                  title: 'Choisir un Moyen / Véhicule',
                                  items: _standardFacilities,
                                  onSelected: (code) {
                                    final match = _standardFacilities.firstWhere(
                                      (p) => p.code == code,
                                      orElse: () => _GenericSelectionItem(code: code, description: code),
                                    );
                                    setState(() {
                                      _tempFacMoyenController.text = match.code;
                                      _tempFacMoyenDescController.text = match.description;
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEEEEE),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: TextFormField(
                          controller: _tempFacMoyenDescController,
                          readOnly: true,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Désignation (Auto)',
                            isDense: true,
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Ligne 2: Équipement / Immatriculation et Temps utilisé (heures)
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _tempFacEquipementController,
                        decoration: const InputDecoration(
                          labelText: 'Équipement / Immat (ex: AA-555-BA)',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _tempFacDurationController,
                        decoration: const InputDecoration(
                          labelText: 'Heures',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        final moyen = _tempFacMoyenController.text.trim();
                        final moyenDesc = _tempFacMoyenDescController.text.trim();
                        final eq = _tempFacEquipementController.text.trim();
                        final dur = double.tryParse(_tempFacDurationController.text.trim()) ?? 1.0;
                        if (moyen.isEmpty) return;
                        setState(() {
                          _facilities.add({
                            'moyen': moyen,
                            'moyenDesc': moyenDesc.isNotEmpty ? moyenDesc : moyen,
                            'equipement': eq.isNotEmpty ? eq : moyen,
                            'duration': dur,
                          });
                          _tempFacMoyenController.clear();
                          _tempFacMoyenDescController.clear();
                          _tempFacEquipementController.clear();
                          _tempFacDurationController.text = '1.0';
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
            child: _facilities.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.commute, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Aucun moyen / véhicule utilisé', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _facilities.length,
                    itemBuilder: (context, index) {
                      final fac = _facilities[index];
                      final moyenTitle = fac['moyenDesc'] != null && fac['moyenDesc'].toString().isNotEmpty
                          ? '${fac['moyen']} - ${fac['moyenDesc']}'
                          : '${fac['moyen']}';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.directions_car, color: Color(0xFF0F1B80)),
                          title: Text(
                            moyenTitle,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('Équipement : ${fac['equipement'] ?? '-'}  |  Temps : ${fac['duration'] ?? 1.0} h'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                final removed = _facilities.removeAt(index);
                                if (removed['pk'] != null) {
                                  _deletedFacilities.add(removed['pk'] as int);
                                }
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ] else if (_materielSubTabIndex == 2) ...[
          // === SOUS-ONGLET SERVICES (Prestations de service - Aligné Coswin 8i) ===
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
            color: Colors.grey[100],
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ligne 1: Origine / Approvisionnement (0. Stock)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: const Row(
                        children: [
                          Text('0. Stock', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Icon(Icons.arrow_drop_down, size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Ligne 2: Article / Service (Jaune requis) et Désignation (Auto)
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFF99),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: TextFormField(
                          controller: _tempServiceArticleController,
                          decoration: InputDecoration(
                            labelText: 'Article *',
                            isDense: true,
                            border: InputBorder.none,
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF0F1B80)),
                              tooltip: 'Choisir une prestation / service',
                              onPressed: () {
                                _showGenericSelector(
                                  title: 'Choisir une Prestation / Service',
                                  items: _standardServices,
                                  onSelected: (code) {
                                    final match = _standardServices.firstWhere(
                                      (s) => s.code == code,
                                      orElse: () => _GenericSelectionItem(code: code, description: code),
                                    );
                                    setState(() {
                                      _tempServiceArticleController.text = match.code;
                                      _tempServiceDescController.text = match.description;
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEEEEE),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: TextFormField(
                          controller: _tempServiceDescController,
                          decoration: const InputDecoration(
                            labelText: 'Désignation (Auto)',
                            isDense: true,
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Onglet horizontal intérieur 'DÉTAILS' (Capture Coswin)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xFF0F1B80), width: 2.5)),
                  ),
                  child: const Text(
                    'DÉTAILS',
                    style: TextStyle(color: Color(0xFF0F1B80), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 10),

                // Sous-Détails Ligne 1: Quantité planifiée (jaune requis), Unité, Coût matériel
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFF99),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: TextFormField(
                          controller: _tempServicePlannedQtyController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Quantité planifiée *',
                            isDense: true,
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _tempServiceUnitController,
                        decoration: const InputDecoration(
                          labelText: 'Unité',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _tempServiceCostController,
                        decoration: const InputDecoration(
                          labelText: 'Coût matériel',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Sous-Détails Ligne 2: Quantité consommée et Type de remplacement (Radio)
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _tempServiceUsedQtyController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Quantité consommée',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          const Text('Type: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          Radio<String>(
                            value: '0. Systématique',
                            groupValue: _tempServiceReplacementType,
                            onChanged: (val) => setState(() => _tempServiceReplacementType = val!),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          const Text('0. Syst.', style: TextStyle(fontSize: 11)),
                          Radio<String>(
                            value: '1. Conditionnel',
                            groupValue: _tempServiceReplacementType,
                            onChanged: (val) => setState(() => _tempServiceReplacementType = val!),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          const Text('1. Cond.', style: TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Sous-Détails Ligne 3: Compteur et MàJ directe relevé
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _tempServiceCompteurController,
                        decoration: const InputDecoration(
                          labelText: 'Compteur',
                          isDense: true,
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.arrow_drop_down, color: Color(0xFF0F1B80)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('MàJ directe relevé', style: TextStyle(fontSize: 11)),
                        value: _tempServiceMajDirecte,
                        onChanged: (val) => setState(() => _tempServiceMajDirecte = val ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                  ],
                ),

                // Sous-Détails Ligne 4: N° de séquence, Action et Consommation PR sans BS + Bouton Ajouter
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _tempServiceSeqController,
                        decoration: const InputDecoration(
                          labelText: 'N° séq.',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _tempServiceActionController,
                        decoration: InputDecoration(
                          labelText: 'Action',
                          isDense: true,
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF0F1B80)),
                            onPressed: () {
                              _showGenericSelector(
                                title: 'Choisir une Action Coswin',
                                items: _standardActions,
                                onSelected: (code) {
                                  setState(() {
                                    _tempServiceActionController.text = code;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('PR sans BS', style: TextStyle(fontSize: 11)),
                        value: _tempServiceSansBS,
                        onChanged: (val) => setState(() => _tempServiceSansBS = val ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final article = _tempServiceArticleController.text.trim();
                        final desc = _tempServiceDescController.text.trim();
                        final planText = _tempServicePlannedQtyController.text.trim().replaceAll(',', '.');
                        final consText = _tempServiceUsedQtyController.text.trim().replaceAll(',', '.');
                        final plan = double.tryParse(planText) ?? 0.0;
                        final cons = double.tryParse(consText) ?? 0.0;
                        final unit = _tempServiceUnitController.text.trim().isEmpty ? 'U' : _tempServiceUnitController.text.trim();
                        final cost = _tempServiceCostController.text.trim();
                        final seq = _tempServiceSeqController.text.trim();
                        final compteur = _tempServiceCompteurController.text.trim();
                        final action = _tempServiceActionController.text.trim();

                        if (article.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Veuillez saisir un article / prestation.')),
                          );
                          return;
                        }

                        setState(() {
                          _services.add({
                            'pk': null,
                            'article': article,
                            'description': desc.isNotEmpty ? desc : article,
                            'serviceCode': article,
                            'plannedQty': plan,
                            'usedQty': cons,
                            'unit': unit,
                            'cost': cost,
                            'sequence': seq,
                            'compteur': compteur,
                            'action': action,
                            'replacementType': _tempServiceReplacementType,
                            'majDirecte': _tempServiceMajDirecte,
                            'sansBS': _tempServiceSansBS,
                          });
                          _tempServiceArticleController.clear();
                          _tempServiceDescController.clear();
                          _tempServicePlannedQtyController.text = '0.00';
                          _tempServiceUsedQtyController.text = '0.00';
                          _tempServiceUnitController.text = 'U';
                          _tempServiceCostController.clear();
                          _tempServiceSeqController.clear();
                          _tempServiceCompteurController.clear();
                          _tempServiceActionController.clear();
                          _tempServiceMajDirecte = false;
                          _tempServiceSansBS = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F1B80),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
                  _services.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.handyman, size: 48, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Aucun service / prestation externe', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: _services.length,
                          itemBuilder: (context, index) {
                            final srv = _services[index];
                            final unit = srv['unit'] ?? 'U';
                            final title = srv['description'] != null && srv['description'].toString().isNotEmpty
                                ? '${srv['article']} - ${srv['description']}'
                                : '${srv['article']}';
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const Icon(Icons.handyman, color: Color(0xFF0F1B80)),
                                title: Text(
                                  title,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  'Planifié : ${srv['plannedQty'] ?? 0.0} $unit  |  Consommé : ${srv['usedQty'] ?? 0.0} $unit  |  Type : ${srv['replacementType'] ?? 'Syst.'}',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      final removed = _services.removeAt(index);
                                      if (removed['pk'] != null) {
                                        _deletedServices.add(removed['pk'] as int);
                                      }
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ),
        ],
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
                      decoration: InputDecoration(
                        labelText: 'Nom Attribut *',
                        isDense: true,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF0F1B80)),
                          tooltip: 'Choisir une caractéristique Coswin',
                          onPressed: () {
                            _showGenericSelector(
                              title: 'Choisir une Caractéristique Coswin',
                              items: _standardAttributes,
                              onSelected: (code) {
                                final match = _standardAttributes.firstWhere(
                                  (a) => a.code == code,
                                  orElse: () => _GenericSelectionItem(code: code, description: code),
                                );
                                setState(() {
                                  _tempAttrNameController.text = match.code;
                                  _tempAttrDescController.text = match.description;
                                  if (match.description.contains('[') && match.description.contains(']')) {
                                    final u = match.description.split('[').last.split(']').first.trim();
                                    if (u.isNotEmpty) _tempAttrUnitController.text = u;
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
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
    bool isGreyedOut = false,
    int? maxLength,
    Widget? suffixIcon,
    VoidCallback? onTap,
  }) {
    final effectiveReadOnly = readOnly || isGreyedOut || onTap != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFF0F1B80),
            fontSize: 12,
            fontWeight: isGreyedOut ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: isGreyedOut
              ? BoxDecoration(
                  color: const Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade400),
                )
              : null,
          padding: isGreyedOut ? const EdgeInsets.symmetric(horizontal: 10) : EdgeInsets.zero,
          child: TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            readOnly: effectiveReadOnly,
            onTap: onTap,
            maxLength: maxLength,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isGreyedOut ? FontWeight.w600 : FontWeight.normal,
              color: isGreyedOut
                  ? const Color(0xFF2B1D4C)
                  : (effectiveReadOnly ? Colors.grey.shade700 : Colors.black),
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              counterText: '', // Hide character counter for cleaner look
              suffixIcon: suffixIcon,
              suffixIconConstraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              border: isGreyedOut
                  ? InputBorder.none
                  : const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFCBD5E1)),
                    ),
              enabledBorder: isGreyedOut
                  ? InputBorder.none
                  : const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFCBD5E1)),
                    ),
              focusedBorder: isGreyedOut
                  ? InputBorder.none
                  : const UnderlineInputBorder(
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
                    // DRY: Les onglets 3-5 n'ont pas besoin de KeepAlive car leurs données
                    // sont stockées dans _workforce, _parts, _attributes (pas de perte de données)
                    // + réduit la pression mémoire sur les petits appareils (Pixel 3a)
                    _buildMainsOeuvreTab(spacing),
                    _buildMaterielTab(spacing),
                    _buildAttributesTab(spacing),
                  ],
                )),
      bottomNavigationBar: Builder(
        builder: (context) {
          final bottomInset = MediaQuery.of(context).viewPadding.bottom > 0
              ? MediaQuery.of(context).viewPadding.bottom
              : MediaQuery.of(context).padding.bottom;
          return Container(
            color: Colors.white,
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 10,
              bottom: bottomInset + 14,
            ),
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
          );
        },
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
  final Function(String, String) onSelected;
  final EquipmentService equipmentService;

  const _EquipmentSelectionModal({
    Key? key,
    required this.entity,
    required this.zone,
    required this.onSelected,
    required this.equipmentService,
  }) : super(key: key);

  @override
  State<_EquipmentSelectionModal> createState() => _EquipmentSelectionModalState();
}

class _EquipmentSelectionModalState extends State<_EquipmentSelectionModal> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<_GenericSelectionItem> _equipments = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadEquipments(page: 1);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && !_isLoadingMore && _hasMore) {
        _loadEquipments(page: _currentPage + 1);
      }
    }
  }

  Future<void> _loadEquipments({int page = 1}) async {
    if (page == 1) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final entityToUse = widget.entity.trim().isNotEmpty && widget.entity.trim().toUpperCase() != 'REFORME'
          ? widget.entity.trim()
          : 'SENELEC';

      final query = _searchController.text.trim();

      final response = await widget.equipmentService.getEquipments(
        entity: entityToUse,
        zone: widget.zone.isNotEmpty ? widget.zone : null,
        search: query.isNotEmpty ? query : null,
        page: page,
        pageSize: 30,
      );

      List<Equipment> eqList = response.items;

      // Si l'entité ne retourne aucun équipement, basculer sur SENELEC
      if (eqList.isEmpty && entityToUse != 'SENELEC' && page == 1) {
        final fallbackResponse = await widget.equipmentService.getEquipments(
          entity: 'SENELEC',
          search: query.isNotEmpty ? query : null,
          page: 1,
          pageSize: 30,
        );
        eqList = fallbackResponse.items;
      }

      final List<_GenericSelectionItem> items = eqList.map((eq) =>
        _GenericSelectionItem(
          code: eq.code,
          description: eq.description.isNotEmpty ? eq.description : eq.code,
        )
      ).toList();

      if (mounted) {
        setState(() {
          if (page == 1) {
            _equipments = items;
          } else {
            _equipments.addAll(items);
          }
          _currentPage = page;
          _hasMore = items.length >= 30;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (page == 1) {
            _errorMessage = e.toString().replaceFirst('Exception: ', '');
          }
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                widget.entity.isNotEmpty
                    ? 'Choisir un équipement (${widget.entity})'
                    : 'Choisir un équipement',
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
            onSubmitted: (_) => _loadEquipments(page: 1),
            decoration: InputDecoration(
              hintText: 'Rechercher par code ou description...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF0F1B80)),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search, color: Color(0xFF0F1B80)),
                tooltip: 'Rechercher',
                onPressed: () => _loadEquipments(page: 1),
              ),
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
                    : _equipments.isEmpty
                        ? const Center(child: Text('Aucun équipement trouvé'))
                        : ListView.separated(
                            controller: _scrollController,
                            itemCount: _equipments.length + (_isLoadingMore ? 1 : 0),
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              if (index == _equipments.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F1B80)),
                                      ),
                                    ),
                                  ),
                                );
                              }
                              final eq = _equipments[index];
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
                                  widget.onSelected(eq.code, eq.description);
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
