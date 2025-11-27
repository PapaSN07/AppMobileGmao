import 'package:flutter/material.dart';
import 'package:appmobilegmao/models/work_order.dart';
import 'package:appmobilegmao/services/ot_service.dart';
import 'package:appmobilegmao/services/api_service.dart';
import 'package:appmobilegmao/theme/responsive_spacing.dart';
import 'package:appmobilegmao/screens/ot_detail_screen.dart';
import 'package:appmobilegmao/widgets/custom_bottom_navigation_bar.dart';
import 'package:appmobilegmao/widgets/custom_app_bar.dart';
import 'package:appmobilegmao/models/order.dart';
import 'package:intl/intl.dart';

/// Écran qui affiche les informations détaillées d'un Ordre de Travail
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage des informations détaillées
/// Principe DRY: Réutilise OTService pour charger les données
class OTInfoDetailsScreen extends StatefulWidget {
  final String? otNumber; // Optionnel : pour charger depuis l'API

  const OTInfoDetailsScreen({Key? key, this.otNumber}) : super(key: key);

  @override
  State<OTInfoDetailsScreen> createState() => _OTInfoDetailsScreenState();
}

class _OTInfoDetailsScreenState extends State<OTInfoDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final OTService _otService;

  int _currentBottomIndex = 2;
  bool _isLoading = true;
  WorkOrder? _workOrder;
  List<WorkOrder> _allOrders = []; // Liste de tous les OT disponibles
  String? _errorMessage;

  // Contrôleurs pour tous les champs du formulaire
  late TextEditingController _numeroOTController;
  late TextEditingController _etatOTController;
  late TextEditingController _etatFullController;
  late TextEditingController _equipementController;
  late TextEditingController _interventionController;
  late TextEditingController _typeInterventionController;
  late TextEditingController _classeInterventionController;
  late TextEditingController _dateDebutPrevuController;
  late TextEditingController _societeController;
  late TextEditingController _chargeDesTravauxController;
  late TextEditingController _superviseurController;
  late TextEditingController _natureDesTravauxController;
  late TextEditingController _centreDeResponsabiliteController;

  @override
  void initState() {
    super.initState();
    _otService = OTService(ApiService());
    _initializeControllers();
    _loadAllOrders(); // Charger la liste des OT d'abord
    _loadOTData();
  }

  /// Initialiser les contrôleurs avec des valeurs vides
  /// Principe DRY: Méthode réutilisable pour l'initialisation
  void _initializeControllers() {
    _numeroOTController = TextEditingController();
    _etatOTController = TextEditingController();
    _etatFullController = TextEditingController();
    _equipementController = TextEditingController();
    _interventionController = TextEditingController();
    _typeInterventionController = TextEditingController();
    _classeInterventionController = TextEditingController();
    _dateDebutPrevuController = TextEditingController();
    _societeController = TextEditingController();
    _chargeDesTravauxController = TextEditingController();
    _superviseurController = TextEditingController();
    _natureDesTravauxController = TextEditingController();
    _centreDeResponsabiliteController = TextEditingController();
  }

  /// Charger tous les OT disponibles pour le dropdown
  Future<void> _loadAllOrders() async {
    try {
      final orders = await _otService.getAllOrders();
      setState(() {
        _allOrders = orders;
      });
    } catch (e) {
      debugPrint('Erreur chargement liste OT: $e');
    }
  }

  /// Charger les données de l'OT depuis l'API ou mock
  /// Principe SOLID: Single Responsibility - Séparation du chargement des données
  Future<void> _loadOTData({String? specificOtNumber}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Charger l'OT (numéro spécifié, widget, ou défaut)
      final otNumber = specificOtNumber ?? widget.otNumber ?? '2025246533';
      final workOrder = await _otService.getOTDetails(otNumber);

      setState(() {
        _workOrder = workOrder;
        _populateFields(workOrder);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Remplir les champs du formulaire avec les données du WorkOrder
  /// Principe DRY: Méthode réutilisable pour la mise à jour des champs
  void _populateFields(WorkOrder workOrder) {
    _numeroOTController.text = workOrder.wowoCode.toString();
    _etatOTController.text = workOrder.wowoUserStatus;
    _etatFullController.text =
        workOrder.mdusDescription ?? workOrder.wowoUserStatus;
    _equipementController.text = workOrder.wowoEquipment;
    _interventionController.text = workOrder.wowoJob;
    _typeInterventionController.text = workOrder.wowoJobType;
    _classeInterventionController.text = workOrder.wowoJobClass;

    // Formater la date si elle existe
    if (workOrder.wowoScheduleDate != null) {
      try {
        final date = DateTime.parse(workOrder.wowoScheduleDate!);
        _dateDebutPrevuController.text = DateFormat('dd/MM/yyyy').format(date);
      } catch (e) {
        _dateDebutPrevuController.text = workOrder.wowoScheduleDate!;
      }
    }

    _societeController.text = workOrder.wowoString4 ?? 'SENELEC';
    _chargeDesTravauxController.text = workOrder.wowoString1 ?? '';
    _superviseurController.text = workOrder.wowoSupervisor ?? '';
    _natureDesTravauxController.text = workOrder.wowoString2 ?? '';
    _centreDeResponsabiliteController.text = workOrder.wowoCostcentre;
  }

  @override
  void dispose() {
    _numeroOTController.dispose();
    _etatOTController.dispose();
    _etatFullController.dispose();
    _equipementController.dispose();
    _interventionController.dispose();
    _typeInterventionController.dispose();
    _classeInterventionController.dispose();
    _dateDebutPrevuController.dispose();
    _societeController.dispose();
    _chargeDesTravauxController.dispose();
    _superviseurController.dispose();
    _natureDesTravauxController.dispose();
    _centreDeResponsabiliteController.dispose();
    super.dispose();
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _currentBottomIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Détails de l\'OT',
        backgroundColor: const Color(0xFF015CC0),
      ),
      body: _buildBody(spacing),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentBottomIndex,
        onTap: _onBottomNavTapped,
      ),
    );
  }

  /// Construire le corps de l'écran selon l'état (chargement, erreur, succès)
  /// Principe SOLID: Single Responsibility - Séparation de la logique d'affichage
  Widget _buildBody(ResponsiveSpacing spacing) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF015CC0)),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            SizedBox(height: spacing.medium),
            Text(
              'Erreur de chargement',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: spacing.small),
            Padding(
              padding: spacing.custom(horizontal: 40),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            SizedBox(height: spacing.large),
            ElevatedButton.icon(
              onPressed: _loadOTData,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF015CC0),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return _buildForm(spacing);
  }

  /// Construire le formulaire avec les champs
  /// Principe DRY: Formulaire réutilisable avec les widgets existants
  Widget _buildForm(ResponsiveSpacing spacing) {
    return SingleChildScrollView(
      padding: spacing.custom(horizontal: 20, vertical: 20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FormField(
              label: 'N° d\'OT',
              controller: _numeroOTController,
              hasDropdown: true,
              onDropdownTap: () => _showOTList(context),
            ),
            SizedBox(height: spacing.large),

            _TwoFieldsRow(
              left: _FormField(
                label: 'État OT',
                controller: _etatOTController,
                hasDropdown: true,
              ),
              right: _FormField(
                label: '',
                controller: _etatFullController,
                displayOnly: true,
              ),
            ),
            SizedBox(height: spacing.large),

            _FormField(
              label: 'Équipement',
              controller: _equipementController,
              hasDropdown: true,
              subtitle: _workOrder?.wowoEquipmentDescription,
            ),
            SizedBox(height: spacing.large),

            _FormField(
              label: 'Intervention',
              controller: _interventionController,
              hasDropdown: true,
              subtitle: _workOrder?.mdjbDescription,
            ),
            SizedBox(height: spacing.large),

            _FormField(
              label: 'Type d\'intervention',
              controller: _typeInterventionController,
              hasDropdown: true,
              subtitle: _workOrder?.wowoJobTypeDescription,
            ),
            SizedBox(height: spacing.large),

            _FormField(
              label: 'Classe d\'intervention',
              controller: _classeInterventionController,
              hasDropdown: true,
              subtitle: _workOrder?.wowoJobClassDescription,
            ),
            SizedBox(height: spacing.large),

            _TwoFieldsRow(
              left: _FormField(
                label: 'Date de début prévu',
                controller: _dateDebutPrevuController,
                isDateField: true,
              ),
              right: _FormField(
                label: 'Société',
                controller: _societeController,
                hasDropdown: true,
              ),
            ),
            SizedBox(height: spacing.large),

            _TwoFieldsRow(
              left: _FormField(
                label: 'Charge des travaux',
                controller: _chargeDesTravauxController,
                hasDropdown: true,
              ),
              right: _FormField(
                label: 'Superviseur',
                controller: _superviseurController,
                hasDropdown: true,
                subtitle: _workOrder?.wowoSupervisorDescription,
              ),
            ),
            SizedBox(height: spacing.large),

            _FormField(
              label: 'Nature des travaux',
              controller: _natureDesTravauxController,
              hasDropdown: true,
            ),
            SizedBox(height: spacing.large),

            _FormField(
              label: 'Centre de responsabilité',
              controller: _centreDeResponsabiliteController,
              hasDropdown: true,
              subtitle: _workOrder?.wowoCostcentreDescription,
            ),
            SizedBox(height: spacing.large),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    _workOrder != null ? () => _navigateToDetails() : null,
                icon: const Icon(Icons.dashboard, color: Colors.white),
                label: const Text(
                  'Détails',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF015CC0),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Afficher la liste des OT disponibles
  void _showOTList(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _primaryBlue,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.list_alt, color: Colors.white),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Sélectionner un OT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // Liste des OT
                Expanded(
                  child:
                      _allOrders.isEmpty
                          ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(color: _primaryBlue),
                                SizedBox(height: 16),
                                Text(
                                  'Chargement des OT...',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                          : ListView.builder(
                            controller: scrollController,
                            itemCount: _allOrders.length,
                            itemBuilder: (context, index) {
                              final order = _allOrders[index];
                              final isSelected =
                                  order.wowoCode.toString() ==
                                  _numeroOTController.text;

                              return ListTile(
                                selected: isSelected,
                                selectedTileColor: _primaryBlue.withOpacity(
                                  0.1,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor:
                                      isSelected ? _primaryBlue : Colors.grey,
                                  child: Text(
                                    order.wowoUserStatus,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  'OT ${order.wowoCode}',
                                  style: TextStyle(
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                    color: isSelected ? _primaryBlue : null,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      order.wowoEquipment,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      order.wowoEquipmentDescription,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                                trailing: Icon(
                                  isSelected
                                      ? Icons.check_circle
                                      : Icons.arrow_forward_ios,
                                  color:
                                      isSelected ? _primaryBlue : Colors.grey,
                                  size: 20,
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  _loadOTData(
                                    specificOtNumber: order.wowoCode.toString(),
                                  );
                                },
                              );
                            },
                          ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Naviguer vers l'écran de détails complets
  /// Principe SOLID: Single Responsibility - Séparation de la navigation
  void _navigateToDetails() {
    if (_workOrder == null) return;

    // Convertir WorkOrder en Order pour la compatibilité avec OTDetailScreen
    final order = Order(
      id: _workOrder!.pkWorkOrder.toString(),
      icon: Icons.work,
      code: _workOrder!.wowoCode.toString(),
      famille: _workOrder!.wowoJobClass,
      zone: _workOrder!.wowoZone ?? '',
      entity: _workOrder!.wowoActionEntity,
      unite: '',
      centre: _workOrder!.wowoCostcentre,
      description: _workOrder!.wowoEquipmentDescription,
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => OTDetailScreen(order: order)),
    );
  }
}

/// Widget qui affiche un champ de formulaire avec ou sans dropdown
const Color _primaryBlue = Color(0xFF015CC0);

TextStyle _labelStyle() {
  return const TextStyle(
    color: _primaryBlue,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.1,
  );
}

TextStyle _valueTextStyle() {
  return const TextStyle(color: Color(0xFF9E9E9E), fontSize: 14, height: 1.2);
}

/// Row réutilisable pour afficher deux champs côte à côte
/// Principe DRY: Widget réutilisable
class _TwoFieldsRow extends StatelessWidget {
  final Widget left;
  final Widget right;

  const _TwoFieldsRow({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return Row(
      children: [
        Expanded(child: left),
        SizedBox(width: spacing.medium),
        Expanded(child: right),
      ],
    );
  }
}

/// Widget formulaire réutilisable
/// Principe SOLID: Single Responsibility
/// Principe DRY: Réutilisable pour tous les champs
class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool hasDropdown;
  final bool isDateField;
  final bool displayOnly;
  final String? subtitle;
  final VoidCallback? onDropdownTap; // Callback personnalisé pour le dropdown

  const _FormField({
    required this.label,
    required this.controller,
    this.hasDropdown = false,
    this.isDateField = false,
    this.displayOnly = false,
    this.subtitle,
    this.onDropdownTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle()),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller,
                      readOnly: isDateField || displayOnly,
                      style: _valueTextStyle(),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 0,
                        ),
                        border: InputBorder.none,
                      ),
                      onTap:
                          (isDateField && !displayOnly)
                              ? () => _selectDate(context)
                              : null,
                    ),
                  ),
                  if (!displayOnly && isDateField)
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: Icon(
                        Icons.calendar_today,
                        color: _primaryBlue,
                        size: 20,
                      ),
                    )
                  else if (!displayOnly && hasDropdown)
                    InkWell(
                      onTap:
                          onDropdownTap ?? () => _showDropdownOptions(context),
                      child: Icon(
                        Icons.arrow_drop_down,
                        color: _primaryBlue,
                        size: 24,
                      ),
                    ),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
              ],
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
              primary: _primaryBlue,
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
                  color: _primaryBlue,
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
