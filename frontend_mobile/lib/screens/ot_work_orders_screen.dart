import 'package:appmobilegmao/services/connectivity_service.dart';
import 'dart:async';
import 'package:appmobilegmao/widgets/offline_data_banner.dart';
import 'package:appmobilegmao/models/work_order.dart';
import 'package:appmobilegmao/models/ot_status.dart';
import 'package:appmobilegmao/models/ot_referentials.dart';
import 'package:appmobilegmao/models/order.dart';
import 'package:appmobilegmao/provider/auth_provider.dart';
import 'package:appmobilegmao/screens/ot_detail_screen.dart';
import 'package:appmobilegmao/screens/ot_create_screen.dart';
import 'package:appmobilegmao/services/ot_service.dart';
import 'package:appmobilegmao/services/ot_paginator.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/theme/responsive_spacing.dart';
import 'package:appmobilegmao/utils/responsive.dart';
import 'package:appmobilegmao/widgets/empty_state.dart';
import 'package:appmobilegmao/widgets/loading_indicator.dart';
import 'package:appmobilegmao/widgets/list_item.dart';
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

class _OTWorkOrdersScreenState extends State<OTWorkOrdersScreen>
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true; // Garde la liste en mémoire même quand on change d'onglet

  // Options des filtres Statut / Type (code → libellé), chargées depuis Coswin
  Map<String, String> _statusFilterOptions = {};
  Map<String, String> _typeFilterOptions = {};

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

  // Filtres Statut et Type
  String? _selectedStatus;
  String? _selectedType;
  
  // Pagination multi-années (état porté par OTYearPaginator)
  static const int _targetVisibleCount = 10; // OT visibles à trouver avant d'arrêter la recherche
  static const int _maxWindowsFirstLoad = 8; // fenêtres Coswin (~5 s chacune) au 1er chargement
  static const int _maxWindowsPerClick = 6; // fenêtres Coswin par clic « charger plus »
  late final OTYearPaginator _paginator;
  bool _noOlderFound = false;
  bool _isLoadingMore = false;
  int get _currentYear => _paginator.currentYear;
  bool get _hasMoreInYear => _paginator.hasMoreInYear;
  bool get _canLoadPreviousYear => _paginator.canLoadPreviousYear;

  @override
  void initState() {
    super.initState();
    _otService = context.read<OTService>();
    _paginator = OTYearPaginator(_otService);
    _selectedService = widget.initialService?.trim() ?? '';
    _serviceController.text = _selectedService;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrapService();
    });
    _loadFilterOptions();
    // Retour du réseau : on remplace la liste hors ligne par les vraies données
    _reconnection = ConnectivityService().onReconnected(() {
      if (mounted && (_paginator.offlineSince != null || _errorMessage != null)) {
        _loadOrders(isRefresh: true);
      }
    });
  }

  late final StreamSubscription<bool> _reconnection;

  Future<void> _loadFilterOptions() async {
    final refs = await _otService.getReferentials();
    if (!mounted) return;
    setState(() {
      _statusFilterOptions = OTReferentials.toLabelMap(refs.statuses);
      _typeFilterOptions = OTReferentials.toLabelMap(refs.jobTypes);
    });
  }

  @override
  void dispose() {
    _reconnection.cancel();
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

  bool _isOpenOrder(WorkOrder order) =>
      !_hideClosedOrders || !OTStatus.isClosed(order.wowoUserStatus);

  /// Retourne true si l'OT peut être modifié selon son statut.
  /// Suit le même principe que [_isOpenOrder] (principe DRY/SRP).
  bool _isEditable(WorkOrder order) => OTStatus.isEditable(order.wowoUserStatus);

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
    final filtered = source
        .where(_isOpenOrder)
        .where(_matchesSearch)
        .where(_matchesStatusAndType)
        .toList();
    final seen = <String>{};
    final unique = filtered.where((o) => seen.add(o.wowoCode.toString())).toList();
    unique.sort((a, b) => b.wowoCode.compareTo(a.wowoCode));
    return unique;
  }

  bool _matchesStatusAndType(WorkOrder order) {
    // Filtre par statut
    if (_selectedStatus != null &&
        order.wowoUserStatus.trim().toUpperCase() != _selectedStatus) {
      return false;
    }
    // Filtre par type de travail
    if (_selectedType != null &&
        order.wowoJobType.trim().toUpperCase() != _selectedType) {
      return false;
    }
    return true;
  }

  /// Nombre d'OT de la liste qui seront visibles à l'écran (hors OT fermés masqués).
  int _visibleCount(List<WorkOrder> orders) => orders.where(_isOpenOrder).length;

  Future<void> _loadOrders({bool isRefresh = false}) async {
    final service = _serviceController.text.trim();
    if (service.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Le code service est obligatoire.';
      });
      return;
    }

    // Mettre à jour l'entité active globale réactive dans AuthProvider
    context.read<AuthProvider>().updateActiveEntity(service);

    setState(() {
      // Pull-to-refresh : on garde la liste visible ; 1er chargement : spinner plein écran
      if (!isRefresh) _isLoading = true;
      _errorMessage = null;
      _noOlderFound = false;
    });

    try {
      // Du plus récent au plus ancien, jusqu'à avoir assez d'OT visibles
      final orders = await _paginator.loadFirst(
        requestEntity: service,
        excludeClosed: _hideClosedOrders,
        maxBatches: _maxWindowsFirstLoad,
        stopWhen: (found) => _visibleCount(found) >= _targetVisibleCount,
        // Affichage progressif : la liste apparaît dès la première fenêtre non vide
        onBatch: (found) {
          if (mounted && found.isNotEmpty) {
            setState(() {
              _selectedService = service;
              _orders = List.of(found);
              _isLoading = false;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _selectedService = service;
          _orders = orders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _orders = [];
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _loadMoreOrders() async {
    if (_isLoadingMore) return;
    if (_serviceController.text.trim().isEmpty) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final newlyFound = await _paginator.loadMore(
        knownCodes: _orders.map((o) => o.wowoCode).toSet(),
        maxBatches: _maxWindowsPerClick,
        minNew: _targetVisibleCount,
      );
      if (!mounted) return;

      setState(() {
        _orders.addAll(newlyFound);
        _noOlderFound = newlyFound.isEmpty && _paginator.isExhausted;
        _isLoadingMore = false;
      });

      if (newlyFound.isEmpty && !_noOlderFound) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lot scanné : aucun nouvel OT ouvert dans cette tranche. Cliquez à nouveau pour continuer.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
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
      classe: order.wowoJobClass,
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
      _loadOrders(isRefresh: true);
    }
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
                  _loadOrders(isRefresh: true);
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
          style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            labelText: 'Filtre service (code service / entité)',
            labelStyle: const TextStyle(color: Color(0xFF64748B)),
            prefixIcon: IconButton(
              icon: Icon(
                _showSearchOptions ? Icons.filter_list : Icons.tune,
                color: AppTheme.senelecReflexBlue,
              ),
              onPressed: () => setState(() => _showSearchOptions = !_showSearchOptions),
            ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.search, color: AppTheme.senelecReflexBlue),
                  onPressed: _loadOrders,
                ),
                if (_serviceController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, color: Color(0xFF64748B)),
                    onPressed: () {
                      _serviceController.clear();
                      FocusScope.of(context).unfocus();
                      setState(() {});
                    },
                  ),
              ],
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(responsive.spacing(12)),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(responsive.spacing(12)),
              borderSide: const BorderSide(color: AppTheme.senelecReflexBlue, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(responsive.spacing(12)),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
          onFieldSubmitted: (_) => _loadOrders(),
          textInputAction: TextInputAction.search,
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: _showSearchOptions ? responsive.spacing(380) : 0,
          child: _showSearchOptions
              ? SingleChildScrollView(
                  child: Card(
                    elevation: 0,
                    margin: spacing.custom(top: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: spacing.custom(horizontal: 14, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Recherche locale',
                            style: TextStyle(
                              fontFamily: AppTheme.fontMontserrat,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.senelecIndigo,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _searchController,
                                  style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
                                  decoration: InputDecoration(
                                    labelText: 'Rechercher un OT',
                                    labelStyle: const TextStyle(color: Color(0xFF64748B)),
                                    hintText: 'Ex: Numéro OT, équipement...',
                                    prefixIcon: const Icon(Icons.search, color: AppTheme.senelecReflexBlue),
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(responsive.spacing(10)),
                                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(responsive.spacing(10)),
                                      borderSide: const BorderSide(color: AppTheme.senelecReflexBlue, width: 1.5),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(responsive.spacing(10)),
                                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                    ),
                                    suffixIcon: _searchController.text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear, color: Color(0xFF64748B)),
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
                              _loadOrders();
                            },
                          ),

                          // ── Filtre par Statut ──
                          const SizedBox(height: 4),
                          DropdownButtonFormField<String?>(
                            value: _selectedStatus,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Statut',
                              labelStyle: const TextStyle(color: Color(0xFF64748B)),
                              prefixIcon: const Icon(Icons.flag_outlined, color: AppTheme.senelecReflexBlue, size: 20),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: AppTheme.senelecReflexBlue, width: 1.5),
                              ),
                            ),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('Tous les statuts', style: TextStyle(color: Color(0xFF64748B))),
                              ),
                              ..._statusFilterOptions.entries.map((e) => DropdownMenuItem<String?>(
                                value: e.key,
                                child: Text(e.value),
                              )),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedStatus = value;
                                // Si un statut "clôturé" est choisi, désactiver le masquage automatique
                                if (value != null && OTStatus.isClosed(value)) {
                                  _hideClosedOrders = false;
                                }
                              });
                            },
                          ),

                          // ── Filtre par Type de travail ──
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String?>(
                            value: _selectedType,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Type de travail',
                              labelStyle: const TextStyle(color: Color(0xFF64748B)),
                              prefixIcon: const Icon(Icons.build_outlined, color: AppTheme.senelecReflexBlue, size: 20),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: AppTheme.senelecReflexBlue, width: 1.5),
                              ),
                            ),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('Tous les types', style: TextStyle(color: Color(0xFF64748B))),
                              ),
                              ..._typeFilterOptions.entries.map((e) => DropdownMenuItem<String?>(
                                value: e.key,
                                child: Text(e.value),
                              )),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedType = value;
                              });
                            },
                          ),

                          // ── Bouton Réinitialiser ──
                          const SizedBox(height: 12),
                          if (_selectedStatus != null || _selectedType != null || _searchQuery.isNotEmpty)
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _selectedStatus = null;
                                    _selectedType = null;
                                    _searchQuery = '';
                                    _searchController.clear();
                                    _hideClosedOrders = true;
                                  });
                                  _loadOrders();
                                },
                                icon: const Icon(Icons.refresh, size: 18),
                                label: const Text('Réinitialiser les filtres'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.senelecReflexBlue,
                                  side: const BorderSide(color: AppTheme.senelecReflexBlue),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
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

  @override
  Widget build(BuildContext context) {
    super.build(context); // Requis par AutomaticKeepAliveClientMixin
    final responsive = context.responsive;
    final spacing = context.spacing;
    final visibleOrders = _applyFilters(_orders);

    final mainContent = SafeArea(
      child: Column(
        children: [
          // 📊 En-Tête Supérieur Moderne : Carte de Compteur des OT
          Container(
            margin: spacing.custom(horizontal: 16, vertical: 12),
            padding: spacing.custom(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.senelecIndigo, AppTheme.senelecReflexBlue],
              ),
              borderRadius: BorderRadius.circular(responsive.spacing(16)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.senelecReflexBlue.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.assignment_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${visibleOrders.length} ${_selectedStatus != null || !_hideClosedOrders ? "OT" : (visibleOrders.length > 1 ? "OTs ouverts" : "OT ouvert")}',
                          style: TextStyle(
                            fontFamily: AppTheme.fontMontserrat,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            fontSize: responsive.sp(18),
                          ),
                        ),
                        Text(
                          'Service : ${_selectedService.isEmpty ? "Non défini" : _selectedService}',
                          style: TextStyle(
                            fontFamily: AppTheme.fontRoboto,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: responsive.sp(12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.flash_on_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),

          // 🔍 Barre de Recherche & Filtres
          Padding(
            padding: spacing.custom(horizontal: 16),
            child: _buildSearchAndFilters(responsive, spacing),
          ),

          SizedBox(height: spacing.small),

          if (!_isLoading && _paginator.offlineSince != null)
            Padding(
              padding: spacing.custom(horizontal: 16),
              child: OfflineDataBanner(since: _paginator.offlineSince!),
            ),

          // 📋 Liste des OT
          Expanded(
            child: Padding(
              padding: spacing.custom(horizontal: 16),
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
                          ? SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 32.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      EmptyState(
                                        title: 'Aucun OT trouvé ($_currentYear)',
                                        message: _hideClosedOrders
                                            ? 'Aucun OT ouvert pour ce service en $_currentYear.'
                                            : 'Aucun OT ne correspond aux critères en $_currentYear.',
                                        icon: Icons.assignment_late,
                                      ),
                                      const SizedBox(height: 16),
                                      if (_isLoadingMore)
                                        const Column(
                                          children: [
                                            CircularProgressIndicator(),
                                            SizedBox(height: 8),
                                            Text("Recherche des OT plus anciens..."),
                                          ],
                                        )
                                      else if (_hasMoreInYear || _canLoadPreviousYear)
                                        ElevatedButton.icon(
                                          onPressed: _loadMoreOrders,
                                          icon: const Icon(Icons.history_rounded),
                                          label: Text(
                                            _hasMoreInYear
                                                ? "Chercher la suite des OT ($_currentYear)"
                                                : "Chercher les OT de ${_currentYear - 1}",
                                          ),
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
                                        )
                                      else if (_noOlderFound)
                                        Text(
                                          "Aucun OT plus ancien trouvé",
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 13,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              )
                          : ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: visibleOrders.length +
                                    ((_hasMoreInYear || _canLoadPreviousYear || _noOlderFound) ? 1 : 0),
                                separatorBuilder: (_, __) => SizedBox(height: spacing.small),
                                itemBuilder: (context, index) {
                                  if (index == visibleOrders.length) {
                                    if (_isLoadingMore) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                                        child: Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                  color: AppTheme.senelecReflexBlue,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                "Recherche des OT plus anciens...",
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }

                                    if (_noOlderFound && !_canLoadPreviousYear && !_hasMoreInYear) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                                        child: Center(
                                          child: Text(
                                            "Aucun OT plus ancien trouvé",
                                            style: TextStyle(
                                              color: Colors.grey.shade500,
                                              fontSize: 13,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                      );
                                    }

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                                      child: Center(
                                        child: ElevatedButton.icon(
                                          onPressed: _loadMoreOrders,
                                          icon: const Icon(Icons.history_rounded, size: 18),
                                          label: Text(
                                            _hasMoreInYear
                                                ? "Charger plus d'OT ($_currentYear)"
                                                : "Charger les OT de ${_currentYear - 1}",
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.secondaryColor,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }

                                final order = visibleOrders[index];
                                final isClosed = OTStatus.isClosed(order.wowoUserStatus);
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
                                    icon: const Icon(Icons.more_vert, color: AppTheme.secondaryColor),
                                    onSelected: (value) async {
                                      if (value == 'edit') {
                                        if (!_isEditable(order)) return;
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => OTCreateScreen(orderToEdit: order),
                                          ),
                                        );
                                        if (result == true) {
                                          _loadOrders(isRefresh: true);
                                        }
                                      } else if (value == 'delete') {
                                        _confirmDeleteOT(order);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      if (_isEditable(order))
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit_outlined, color: AppTheme.senelecReflexBlue, size: 20),
                                              SizedBox(width: 10),
                                              Text('Modifier', style: TextStyle(color: AppTheme.senelecReflexBlue, fontWeight: FontWeight.w600, fontSize: 14)),
                                            ],
                                          ),
                                        )
                                      else
                                        PopupMenuItem(
                                          enabled: false,
                                          child: Row(
                                            children: [
                                              const Icon(Icons.lock_outline, color: Colors.grey, size: 20),
                                              const SizedBox(width: 10),
                                              Text('Non modifiable (${order.wowoUserStatus})', style: const TextStyle(color: Colors.grey, fontSize: 14)),
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
          ),
        ],
      ),
    );

    if (widget.isTab) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: mainContent,
        floatingActionButton: FloatingActionButton(
          heroTag: 'ot_tab_fab',
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OTCreateScreen()),
            );
            if (result == true) {
              _loadOrders(isRefresh: true);
            }
          },
          backgroundColor: AppTheme.secondaryColor,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      );
    } else {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('OT par service'),
          backgroundColor: AppTheme.secondaryColor,
          foregroundColor: Colors.white,
        ),
        body: mainContent,
        floatingActionButton: FloatingActionButton(
          heroTag: 'ot_screen_fab',
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OTCreateScreen()),
            );
            if (result == true) {
              _loadOrders(isRefresh: true);
            }
          },
          backgroundColor: AppTheme.secondaryColor,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      );
    }
  }
}