import 'package:flutter/material.dart';
import 'package:appmobilegmao/models/work_order.dart';
import 'package:appmobilegmao/services/ot_service.dart';
import 'package:appmobilegmao/services/api_service.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/theme/responsive_spacing.dart';
import 'package:appmobilegmao/screens/ot_detail_screen.dart';
import 'package:appmobilegmao/models/order.dart';
import 'package:appmobilegmao/utils/responsive.dart';
import 'package:appmobilegmao/widgets/list_item.dart';

/// Écran listant tous les OT avec sélection et détails en bas
/// Design identique à HomeScreen pour cohérence UX
class OTInfoDetailsScreen extends StatefulWidget {
  final String? otNumber;
  final bool showBottomNavigationBar;

  const OTInfoDetailsScreen({
    Key? key,
    this.otNumber,
    this.showBottomNavigationBar = true,
  }) : super(key: key);

  @override
  State<OTInfoDetailsScreen> createState() => _OTInfoDetailsScreenState();
}

class _OTInfoDetailsScreenState extends State<OTInfoDetailsScreen> {
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
  bool _isLoading = true;
  WorkOrder? _selectedWorkOrder;
  List<WorkOrder> _allOrders = [];
  List<WorkOrder> _filteredOrders = [];
  String? _errorMessage;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _otService = OTService(ApiService());
    _loadAllOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Charger tous les OT disponibles
  Future<void> _loadAllOrders() async {
    try {
      final orders = await _otService.getAllOrders();
      setState(() {
        _allOrders = orders;
        _filteredOrders = orders;
        _isLoading = false;

        // Présélectionner le premier OT
        if (orders.isNotEmpty) {
          _selectedWorkOrder = orders.first;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur lors du chargement des OT: $e';
      });
    }
  }

  /// Filtrer les OT par recherche
  void _filterOrders(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredOrders = _allOrders;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredOrders = _allOrders.where((order) {
          return order.wowoCode.toString().toLowerCase().contains(lowerQuery) ||
              order.wowoEquipment.toLowerCase().contains(lowerQuery) ||
              order.wowoEquipmentDescription.toLowerCase().contains(lowerQuery);
        }).toList();
      }
    });
  }

  /// Naviguer vers la page OTDetailScreen
  void _navigateToDetailScreen() {
    if (_selectedWorkOrder == null) return;

    final order = Order(
      id: _selectedWorkOrder!.pkWorkOrder.toString(),
      icon: Icons.assignment,
      code: _selectedWorkOrder!.wowoCode.toString(),
      famille: _selectedWorkOrder!.wowoJobClass,
      zone: _selectedWorkOrder!.wowoZone ?? '',
      entity: _selectedWorkOrder!.wowoActionEntity,
      unite: '',
      centre: _selectedWorkOrder!.wowoCostcentre,
      description: _selectedWorkOrder!.wowoEquipmentDescription,
      // MODIFICATION: Formater le statut en toutes lettres (ex: OUVERT (OUV))
      status: Order.formatStatus(_selectedWorkOrder!.wowoUserStatus, _selectedWorkOrder!.mdusDescription),
      // MODIFICATION: Passer le taux de realisation reel de l'OT
      completionRate: _selectedWorkOrder!.wowoCompletionRate,
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => OTDetailScreen(order: order)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final spacing = context.spacing;

    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      appBar: AppBar(
        title: Text(
          'Ordres de Travail',
          style: TextStyle(
            fontFamily: AppTheme.fontMontserrat,
            fontWeight: FontWeight.bold,
            color: AppTheme.secondaryColor,
            fontSize: responsive.sp(18),
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.secondaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF015CC0)),
            )
          : _errorMessage != null
              ? _buildErrorState(spacing)
              : _allOrders.isEmpty
                  ? _buildEmptyState(spacing)
                  : _buildContent(spacing),
      // Panel détails en bas
      bottomSheet: _selectedWorkOrder != null
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Détails sélectionnés
                  Text(
                    'OT ${_selectedWorkOrder!.wowoCode}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF015CC0),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedWorkOrder!.wowoEquipmentDescription,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),

                  // Bouton Détails
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _navigateToDetailScreen,
                      icon: const Icon(Icons.dashboard),
                      label: const Text('Voir les détails complets'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF015CC0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  /// Afficher l'état d'erreur
  Widget _buildErrorState(ResponsiveSpacing spacing) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 60),
          SizedBox(height: spacing.medium),
          Text(
            'Erreur de chargement',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
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
            onPressed: _loadAllOrders,
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

  /// Afficher l'état vide
  Widget _buildEmptyState(ResponsiveSpacing spacing) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_late, color: Colors.grey, size: 60),
          SizedBox(height: spacing.medium),
          const Text(
            'Aucun OT trouvé',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Afficher le contenu principal
  Widget _buildContent(ResponsiveSpacing spacing) {
    final responsive = context.responsive;

    return Padding(
      padding: spacing.custom(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          // Compteur en haut
          Text(
            '${_filteredOrders.length} Ordres de Travail',
            style: TextStyle(
              fontFamily: AppTheme.fontMontserrat,
              fontWeight: FontWeight.normal,
              color: AppTheme.thirdColor,
              fontSize: responsive.sp(15),
            ),
          ),
          SizedBox(height: spacing.medium),

          // Barre de recherche
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _filterOrders,
              decoration: InputDecoration(
                hintText: 'Rechercher par code, équipement...',
                prefixIcon: Icon(Icons.search, color: AppTheme.thirdColor),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          SizedBox(height: spacing.medium),

          // Liste des OT avec ListItemCustom.order
          Expanded(
            child: _filteredOrders.isEmpty
                ? Center(
                    child: Text(
                      'Aucun OT ne correspond à votre recherche',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = _filteredOrders[index];
                      final isSelected =
                          order.wowoCode.toString() ==
                              _selectedWorkOrder?.wowoCode.toString();

                      final isClosed = _closedStatuses.contains(order.wowoUserStatus.trim().toUpperCase());

                      return Padding(
                        padding: spacing.custom(bottom: 10),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedWorkOrder = order;
                            });
                          },
                          // Utiliser ListItemCustom.order avec les vraies infos de l'OT
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected
                                  ? Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    )
                                  : null,
                            ),
                            child: ListItemCustom.order(
                              id: order.pkWorkOrder.toString(),
                              // Code de l'OT
                              code: order.wowoCode.toString(),
                              // Type d'intervention (classe intervention)
                              famille: order.wowoJobClass,
                              // Zone de l'équipement
                              zone: order.wowoZone ?? '-',
                              // Entité responsable
                              entity: order.wowoActionEntity,
                              // Unité / Coût centre
                              unite: order.wowoCostcentre,
                              // Centre de charges
                              centre: order.wowoCostcentre,
                              // Description complète de l'équipement
                              description: order.wowoEquipmentDescription,
                              status: Order.formatStatus(order.wowoUserStatus, order.mdusDescription),
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
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
