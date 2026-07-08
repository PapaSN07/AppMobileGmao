import 'package:appmobilegmao/models/work_order.dart';
import 'package:appmobilegmao/models/order.dart';
import 'package:appmobilegmao/provider/auth_provider.dart';
import 'package:appmobilegmao/screens/ot_detail_screen.dart';
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
    });

    try {
      final orders = await _otService.getAllOrders(
        scope: 'service',
        requestEntity: service,
        excludeClosed: _hideClosedOrders,
      );

      setState(() {
        _selectedService = service;
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _orders = [];
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _openDetails(WorkOrder order) {
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
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OTDetailScreen(order: uiOrder),
      ),
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
                              _loadOrders();
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
                              : RefreshIndicator(
                                  onRefresh: _loadOrders,
                                  child: ListView.separated(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    itemCount: visibleOrders.length,
                                    separatorBuilder: (_, __) => SizedBox(height: spacing.small),
                                    itemBuilder: (context, index) {
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
                                        onDetailsTap: () => _openDetails(order),
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
      );
    }
  }
}