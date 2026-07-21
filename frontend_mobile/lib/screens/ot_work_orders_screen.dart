import 'package:appmobilegmao/models/work_order.dart';
import 'package:appmobilegmao/models/order.dart';
import 'package:appmobilegmao/provider/auth_provider.dart';
import 'package:appmobilegmao/screens/ot_detail_screen.dart';
import 'package:appmobilegmao/screens/ot_create_screen.dart';
import 'package:appmobilegmao/screens/ot_info_details_screen.dart';
import 'package:appmobilegmao/services/api_service.dart';
import 'package:appmobilegmao/services/ot_service.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/theme/responsive_spacing.dart';
import 'package:appmobilegmao/utils/responsive.dart';
import 'package:appmobilegmao/widgets/empty_state.dart';
import 'package:appmobilegmao/widgets/loading_indicator.dart';
import 'package:appmobilegmao/widgets/list_item.dart';
import 'package:appmobilegmao/widgets/tools.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OTWorkOrdersScreen extends StatefulWidget {
  final String? initialService;
  final bool showBottomNavigationBar;
  final bool isTab;

  const OTWorkOrdersScreen({
    super.key,
    this.initialService,
    this.showBottomNavigationBar = false,
    this.isTab = false,
  });

  @override
  State<OTWorkOrdersScreen> createState() => _OTWorkOrdersScreenState();
}

class _OTWorkOrdersScreenState extends State<OTWorkOrdersScreen> {
  static const Set<String> _closedStatuses = {
    'CL',
    'TE',
    'CLOSE',
    'CLOSED',
    'TERMINE',
    'TERMINEE',
    'TERMINATED',
    'FINI',
    'FINISHED',
  };

  late final OTService _otService;
  final TextEditingController _serviceController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  List<WorkOrder> _orders = [];
  bool _isLoading = true;
  bool _hideClosedOrders = true;
  bool _showSearchOptions = false;
  String _selectedService = '';
  String _searchQuery = '';
  String? _errorMessage;
  
  // Variables de pagination
  String? _paginationContext;
  bool _hasMore = false;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _otService = OTService(ApiService());
    _selectedService = widget.initialService?.trim() ?? '';
    _serviceController.text = _selectedService;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrapService();
    });
  }

  @override
  void dispose() {
    _serviceController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _bootstrapService() async {
    if (_selectedService.isEmpty) {
      final authProvider = context.read<AuthProvider>();
      final entity = authProvider.currentUser?.entity.trim() ?? '';
      final group = authProvider.currentUser?.group?.trim() ?? '';
      final fallbackService = entity.isNotEmpty ? entity : group;
      if (fallbackService.isNotEmpty) {
        _selectedService = fallbackService;
        _serviceController.text = fallbackService;
      }
    }

    if (_selectedService.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Service introuvable. Saisis un code service pour charger les OT.';
      });
      return;
    }

    await _loadOrders();
  }

  bool _isOpenOrder(WorkOrder order) {
    final status = order.wowoUserStatus.trim().toUpperCase();
    if (!_hideClosedOrders) {
      return true;
    }
    return !_closedStatuses.contains(status);
  }

  bool _matchesSearch(WorkOrder order) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return true;
    }

    final haystack = [
      order.wowoCode.toString(),
      order.wowoUserStatus,
      order.wowoEquipment,
      order.wowoEquipmentDescription,
      order.wowoJob,
      order.wowoJobType,
      order.wowoJobClass,
      order.wowoRequestEntity,
      order.wowoActionEntity,
      order.wowoSupervisor ?? '',
      order.wowoCostcentre,
    ].join(' ').toLowerCase();

    return haystack.contains(query);
  }

  List<WorkOrder> _applyFilters(List<WorkOrder> source) {
    return source.where(_isOpenOrder).where(_matchesSearch).toList();
  }

  Future<void> _loadOrders() async {
    final service = _serviceController.text.trim();
    if (service.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Le code service est obligatoire.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _paginationContext = null;
      _hasMore = false;
    });

    try {
      final result = await _otService.getOrdersPage(
        scope: 'service',
        requestEntity: service,
        excludeClosed: _hideClosedOrders,
      );

      setState(() {
        _selectedService = service;
        _orders = result.workorders;
        _paginationContext = result.paginationContext;
        _hasMore = result.hasMore;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _orders = [];
        _isLoading = false;
        _errorMessage = e.toString();
        _paginationContext = null;
        _hasMore = false;
      });
    }
  }

  Future<void> _loadMoreOrders() async {
    if (_isLoadingMore || !_hasMore || _paginationContext == null) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final service = _serviceController.text.trim();
      final result = await _otService.getOrdersPage(
        scope: 'service',
        requestEntity: service,
        excludeClosed: _hideClosedOrders,
        paginationContext: _paginationContext,
      );

      setState(() {
        _orders.addAll(result.workorders);
        _paginationContext = result.paginationContext;
        _hasMore = result.hasMore;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement des OT supplémentaires: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openDetails(WorkOrder order) async {
    final uiOrder = Order(
      id: order.pkWorkOrder.toString(),
      icon: Icons.assignment,
      code: order.wowoCode.toString(),
      famille: order.wowoJobType.isNotEmpty
          ? order.wowoJobType
          : (order.wowoJobClass.isNotEmpty ? order.wowoJobClass : '-'),
      zone: order.wowoZone?.isNotEmpty == true ? order.wowoZone! : '-',
      entity: order.wowoRequestEntity.isNotEmpty ? order.wowoRequestEntity : '-',
      unite: order.wowoEquipment.isNotEmpty ? order.wowoEquipment : '-',
      centre: order.wowoCostcentre.isNotEmpty ? order.wowoCostcentre : '-',
      description: order.wowoJob.isNotEmpty
          ? order.wowoJob
          : (order.wowoEquipmentDescription.isNotEmpty ? order.wowoEquipmentDescription : '-'),
      // MODIFICATION: Formater le statut en toutes lettres (ex: OUVERT (OUV))
      status: Order.formatStatus(order.wowoUserStatus, order.mdusDescription),
      // MODIFICATION: Passer le taux de realisation reel de l'OT
      completionRate: order.wowoCompletionRate,
    );

    final refresh = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => OTDetailScreen(order: uiOrder),
      ),
    );

    if (refresh == true) {
      _loadOrders();
    }
  }

  void _showOTActionMenu(WorkOrder order) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'OT N° ${order.wowoCode}',
                style: const TextStyle(
                  fontFamily: AppTheme.fontMontserrat,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.secondaryColor,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Modifier l\'OT'),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OTCreateScreen(orderToEdit: order),
                    ),
                  );
                  if (result == true) {
                    _loadOrders();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Supprimer l\'OT'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteOT(order);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditOTDialog(WorkOrder order) {
    final formKey = GlobalKey<FormState>();
    final jobController = TextEditingController(text: order.wowoJob);
    final eqController = TextEditingController(text: order.wowoEquipment);
    final supervisorController = TextEditingController(text: order.wowoSupervisor ?? '');
    final zoneController = TextEditingController(text: order.wowoZone ?? '');
    final entityController = TextEditingController(text: order.wowoRequestEntity);
    final rateController = TextEditingController(text: order.wowoCompletionRate?.toString() ?? '0');
    final jobClassController = TextEditingController(text: order.wowoJobClass);
    String priority = order.wowoPriority?.trim().toUpperCase() ?? 'URGENT';
    if (!['URGENT', 'MOYEN', 'BAS'].contains(priority)) {
      priority = 'URGENT';
    }
    String status = order.wowoUserStatus.trim().toUpperCase();
    if (!['OUV', 'CR', 'CL', 'TE'].contains(status)) {
      status = 'OUV';
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Modifier l\'OT ${order.wowoCode}'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: jobController,
                        decoration: const InputDecoration(labelText: 'Description / Travail *'),
                        validator: (value) => value == null || value.isEmpty ? 'Ce champ est obligatoire' : null,
                      ),
                      TextFormField(
                        controller: eqController,
                        decoration: const InputDecoration(labelText: 'Équipement *'),
                        validator: (value) => value == null || value.isEmpty ? 'Ce champ est obligatoire' : null,
                      ),
                      TextFormField(
                        controller: supervisorController,
                        decoration: const InputDecoration(labelText: 'Technicien / Superviseur *'),
                        validator: (value) => value == null || value.isEmpty ? 'Ce champ est obligatoire' : null,
                      ),
                      TextFormField(
                        controller: zoneController,
                        decoration: const InputDecoration(labelText: 'Zone'),
                      ),
                      TextFormField(
                        controller: entityController,
                        decoration: const InputDecoration(labelText: 'Entité / Service'),
                      ),
                      TextFormField(
                        controller: rateController,
                        decoration: const InputDecoration(labelText: 'Taux de réalisation (%)'),
                        keyboardType: TextInputType.number,
                      ),
                      TextFormField(
                        controller: jobClassController,
                        decoration: const InputDecoration(labelText: 'Classe de travail'),
                      ),
                      DropdownButtonFormField<String>(
                        value: priority,
                        decoration: const InputDecoration(labelText: 'Priorité'),
                        items: ['URGENT', 'MOYEN', 'BAS'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => priority = val);
                        },
                      ),
                      DropdownButtonFormField<String>(
                        value: status,
                        decoration: const InputDecoration(labelText: 'Statut'),
                        items: [
                          DropdownMenuItem(value: 'OUV', child: const Text('OUVERT (OUV)')),
                          DropdownMenuItem(value: 'CR', child: const Text('CRÉÉ (CR)')),
                          DropdownMenuItem(value: 'TE', child: const Text('RÉALISÉ (TE)')),
                          DropdownMenuItem(value: 'CL', child: const Text('CLÔTURÉ (CL)')),
                        ].toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => status = val);
                        },
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
                      setState(() => _isLoading = true);
                      try {
                        final data = {
                          "wowoUserStatus": status,
                          "wowoEquipment": eqController.text.trim(),
                          "wowoJob": jobController.text.trim(),
                          "wowoJobClass": jobClassController.text.trim(),
                          "wowoPriority": priority,
                          "wowoActionEntity": entityController.text.trim(),
                          "wowoRequestEntity": entityController.text.trim(),
                          "wowoSupervisor": supervisorController.text.trim(),
                          "wowoZone": zoneController.text.trim(),
                          "wowoCompletionRate": double.tryParse(rateController.text.trim()) ?? 0.0,
                        };

                        await _otService.updateOT(order.wowoCode, data);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('OT mis à jour avec succès !')),
                        );
                        _loadOrders();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erreur: $e')),
                        );
                        setState(() => _isLoading = false);
                      }
                    }
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteOT(WorkOrder order) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmation de suppression'),
          content: Text('Voulez-vous vraiment supprimer l\'OT N° ${order.wowoCode} ? Cette action est irréversible.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(context);
                try {
                  await _otService.deleteOT(order.wowoCode);
                  if (mounted) {
                    setState(() {
                      _orders.removeWhere((o) => o.wowoCode == order.wowoCode);
                    });
                    messenger.showSnackBar(
                      const SnackBar(content: Text('OT supprimé avec succès !')),
                    );
                  }
                  _loadOrders();
                } catch (e) {
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Erreur lors de la suppression: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchAndFilters(Responsive responsive, ResponsiveSpacing spacing) {
    return Column(
      children: [
        TextFormField(
          controller: _serviceController,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(color: AppTheme.thirdColor),
          decoration: InputDecoration(
            labelText: 'Filtre service (code service / entité)',
            prefixIcon: IconButton(
              icon: Icon(_showSearchOptions ? Icons.filter_list : Icons.tune),
              onPressed: () => setState(() => _showSearchOptions = !_showSearchOptions),
            ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _loadOrders,
                ),
                if (_serviceController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _serviceController.clear();
                      FocusScope.of(context).unfocus();
                      setState(() {});
                    },
                  ),
              ],
            ),
          ),
          onFieldSubmitted: (_) => _loadOrders(),
          textInputAction: TextInputAction.search,
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: _showSearchOptions ? responsive.spacing(175) : 0,
          child: _showSearchOptions
              ? SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Card(
                    elevation: 0,
                    margin: spacing.custom(top: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: AppTheme.primaryColor20),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: spacing.custom(horizontal: 14, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recherche locale',
                            style: TextStyle(
                              fontFamily: AppTheme.fontMontserrat,
                              fontSize: responsive.sp(14),
                              fontWeight: FontWeight.bold,
                              color: AppTheme.secondaryColor,
                            ),
                          ),
                          SizedBox(height: spacing.tiny),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    labelText: 'Rechercher un OT',
                                    hintText: 'Ex: Numéro OT, équipement...',
                                    prefixIcon: const Icon(Icons.search),
                                    suffixIcon: _searchController.text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear),
                                            onPressed: () {
                                              _searchController.clear();
                                              setState(() {
                                                _searchQuery = '';
                                              });
                                            },
                                          )
                                        : null,
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _searchQuery = value;
                                    });
                                  },
                                  onFieldSubmitted: (value) {
                                    setState(() {
                                      _searchQuery = value;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Masquer les OT terminés',
                              style: TextStyle(
                                fontSize: responsive.sp(14),
                                color: AppTheme.secondaryColor,
                              ),
                            ),
                            value: _hideClosedOrders,
                            activeTrackColor: AppTheme.secondaryColor,
                            onChanged: (value) {
                              setState(() {
                                _hideClosedOrders = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  void _showAddOTDialog() {
    final formKey = GlobalKey<FormState>();
    final codeController = TextEditingController();
    final jobController = TextEditingController();
    final eqController = TextEditingController(text: 'POSTE_A_AGRIK');
    final supervisorController = TextEditingController(text: '5286');
    final jobClassController = TextEditingController(text: 'POSTE');
    final zoneController = TextEditingController(text: 'DAKAR');
    final entityController = TextEditingController(text: _selectedService.isNotEmpty ? _selectedService : 'DTAE');
    final rateController = TextEditingController(text: '0');
    String priority = 'URGENT';
    String status = 'OUV';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Créer un Ordre de Travail (OT)'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: codeController,
                        decoration: const InputDecoration(labelText: 'Code OT (laisser vide pour générer)'),
                        keyboardType: TextInputType.number,
                      ),
                      TextFormField(
                        controller: jobController,
                        decoration: const InputDecoration(labelText: 'Description / Travail *'),
                        validator: (value) => value == null || value.isEmpty ? 'Ce champ est obligatoire' : null,
                      ),
                      TextFormField(
                        controller: eqController,
                        decoration: const InputDecoration(labelText: 'Équipement *'),
                        validator: (value) => value == null || value.isEmpty ? 'Ce champ est obligatoire' : null,
                      ),
                      TextFormField(
                        controller: supervisorController,
                        decoration: const InputDecoration(labelText: 'Technicien / Superviseur *'),
                        validator: (value) => value == null || value.isEmpty ? 'Ce champ est obligatoire' : null,
                      ),
                      TextFormField(
                        controller: zoneController,
                        decoration: const InputDecoration(labelText: 'Zone'),
                      ),
                      TextFormField(
                        controller: entityController,
                        decoration: const InputDecoration(labelText: 'Entité / Service'),
                      ),
                      TextFormField(
                        controller: rateController,
                        decoration: const InputDecoration(labelText: 'Taux de réalisation (%)'),
                        keyboardType: TextInputType.number,
                      ),
                      TextFormField(
                        controller: jobClassController,
                        decoration: const InputDecoration(labelText: 'Classe de travail'),
                      ),
                      DropdownButtonFormField<String>(
                        value: priority,
                        decoration: const InputDecoration(labelText: 'Priorité'),
                        items: ['URGENT', 'MOYEN', 'BAS'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => priority = val);
                        },
                      ),
                      DropdownButtonFormField<String>(
                        value: status,
                        decoration: const InputDecoration(labelText: 'Statut de départ'),
                        items: [
                          DropdownMenuItem(value: 'OUV', child: const Text('OUVERT (OUV)')),
                          DropdownMenuItem(value: 'CR', child: const Text('CRÉÉ (CR)')),
                        ].toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => status = val);
                        },
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
                      setState(() => _isLoading = true);
                      try {
                        final authProvider = context.read<AuthProvider>();
                        final currentUser = authProvider.currentUser;
                        final currentService = entityController.text.trim();

                        final data = {
                          "wowoUserStatus": status,
                          "wowoEquipment": eqController.text.trim(),
                          "wowoJob": jobController.text.trim(),
                          "wowoJobType": "CORR",
                          "wowoJobClass": jobClassController.text.trim(),
                          "wowoPriority": priority,
                          "wowoActionEntity": currentService,
                          "wowoRequestEntity": currentService,
                          "wowoSupervisor": supervisorController.text.trim(),
                          "wowoCostcentre": "DD304",
                          "wowoZone": zoneController.text.trim(),
                          "wowoFunction": "UMP-PG",
                          "wowoEquipmentDescription": "Équipement de test créé par mobile",
                          "wowoCompletionRate": double.tryParse(rateController.text.trim()) ?? 0.0,
                        };

                        if (codeController.text.trim().isNotEmpty) {
                          data["wowoCode"] = int.parse(codeController.text.trim());
                        }

                        await _otService.createOT(data);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('OT créé avec succès en base locale !')),
                        );
                        _loadOrders();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erreur: $e')),
                        );
                        setState(() => _isLoading = false);
                      }
                    }
                  },
                  child: const Text('Créer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final spacing = context.spacing;
    final visibleOrders = _applyFilters(_orders);

    final mainContent = Stack(
      children: [
        Positioned(
          top: responsive.spacing(120),
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: spacing.custom(horizontal: 16),
            child: Column(
              children: [
                _buildSearchAndFilters(responsive, spacing),
                SizedBox(height: spacing.medium),
                Expanded(
                  child: _isLoading
                      ? const LoadingIndicator()
                      : _errorMessage != null
                          ? EmptyState(
                              title: 'Impossible de charger les OT',
                              message: _errorMessage!,
                              icon: Icons.work_history,
                              onRetry: _loadOrders,
                              retryButtonText: 'Réessayer',
                            )
                          : visibleOrders.isEmpty
                              ? const EmptyState(
                                  title: 'Aucun OT trouvé',
                                  message: 'Aucun OT ouvert ne correspond à ce service.',
                                  icon: Icons.assignment_late,
                                )
                              : ListView.separated(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  itemCount: visibleOrders.length + (_hasMore ? 1 : 0),
                                  separatorBuilder: (_, __) => SizedBox(height: spacing.small),
                                  itemBuilder: (context, index) {
                                    if (index == visibleOrders.length) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                                        child: Center(
                                          child: _isLoadingMore
                                              ? const CircularProgressIndicator()
                                              : ElevatedButton.icon(
                                                  onPressed: _loadMoreOrders,
                                                  icon: const Icon(Icons.add),
                                                  label: const Text("Charger plus d'OT"),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: AppTheme.secondaryColor,
                                                    foregroundColor: Colors.white,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 24,
                                                      vertical: 12,
                                                    ),
                                                  ),
                                                ),
                                        ),
                                      );
                                    }

                                    final order = visibleOrders[index];
                                    final isClosed = _closedStatuses.contains(order.wowoUserStatus.trim().toUpperCase());
                                    return ListItemCustom.order(
                                      code: order.wowoCode.toString(),
                                      famille: order.wowoJobType.isNotEmpty
                                          ? order.wowoJobType
                                          : (order.wowoJobClass.isNotEmpty ? order.wowoJobClass : '-'),
                                      zone: order.wowoZone?.isNotEmpty == true ? order.wowoZone! : '-',
                                      entity: order.wowoRequestEntity.isNotEmpty ? order.wowoRequestEntity : '-',
                                      unite: order.wowoEquipment.isNotEmpty ? order.wowoEquipment : '-',
                                      centre: order.wowoCostcentre.isNotEmpty ? order.wowoCostcentre : '-',
                                      description: order.wowoJob.isNotEmpty
                                          ? order.wowoJob
                                          : (order.wowoEquipmentDescription.isNotEmpty ? order.wowoEquipmentDescription : '-'),
                                      status: Order.formatStatus(order.wowoUserStatus, order.mdusDescription),
                                      onDetailsTap: () => _openDetails(order),
                                      trailing: PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert, color: AppTheme.primaryColor),
                                        onSelected: (value) async {
                                          if (value == 'edit') {
                                            final result = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => OTCreateScreen(orderToEdit: order),
                                              ),
                                            );
                                            if (result == true) {
                                              _loadOrders();
                                            }
                                          } else if (value == 'delete') {
                                            _confirmDeleteOT(order);
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                Icon(Icons.edit_outlined, color: Color(0xFF015CC0), size: 20),
                                                SizedBox(width: 10),
                                                Text('Modifier', style: TextStyle(color: Color(0xFF015CC0), fontWeight: FontWeight.w600, fontSize: 14)),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                                SizedBox(width: 10),
                                                Text('Supprimer', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 14)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      statusBadge: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isClosed ? Colors.red.shade50 : Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          order.wowoUserStatus.isEmpty ? 'INCONNU' : order.wowoUserStatus,
                                          style: TextStyle(
                                            color: isClosed ? Colors.red.shade700 : Colors.green.shade700,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(color: AppTheme.secondaryColor, height: 70),
        ),
        Positioned(
          top: responsive.spacing(20),
          left: 20,
          right: 20,
          child: Container(
            constraints: BoxConstraints(
              minHeight: responsive.spacing(84),
            ),
            padding: spacing.custom(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(responsive.spacing(20)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.boxShadowColor,
                  blurRadius: responsive.spacing(10),
                  offset: Offset(0, responsive.spacing(5)),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Tools.buildStatCard(
                    context,
                    _selectedService.isEmpty ? 'Non défini' : _selectedService,
                    'Service',
                  ),
                ),
                Tools.buildVerticalDivider(context),
                Expanded(
                  child: Tools.buildStatCard(
                    context,
                    visibleOrders.length.toString(),
                    visibleOrders.length > 1 ? 'OTs ouverts' : 'OT ouvert',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    if (widget.isTab) {
      return Scaffold(
        backgroundColor: AppTheme.primaryColor,
        body: mainContent,
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OTCreateScreen()),
            );
            if (result == true) {
              _loadOrders();
            }
          },
          backgroundColor: AppTheme.secondaryColor,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      );
    } else {
      return Scaffold(
        backgroundColor: AppTheme.primaryColor,
        appBar: AppBar(
          title: const Text('OT par service'),
          backgroundColor: AppTheme.secondaryColor,
          foregroundColor: Colors.white,
        ),
        body: SafeArea(
          child: mainContent,
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OTCreateScreen()),
            );
            if (result == true) {
              _loadOrders();
            }
          },
          backgroundColor: AppTheme.secondaryColor,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      );
    }
  }
}