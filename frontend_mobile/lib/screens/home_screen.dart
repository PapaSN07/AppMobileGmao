import 'package:appmobilegmao/models/order.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/widgets/list_item.dart';
import 'package:appmobilegmao/screens/ot_work_orders_screen.dart';
import 'package:flutter/material.dart';
import 'package:appmobilegmao/utils/responsive.dart';
import 'package:appmobilegmao/theme/responsive_spacing.dart';
import 'package:provider/provider.dart';
import 'package:appmobilegmao/provider/auth_provider.dart';
import 'package:appmobilegmao/services/ot_service.dart';
import 'package:appmobilegmao/services/api_service.dart';
import 'package:appmobilegmao/models/work_order.dart';
import 'package:appmobilegmao/screens/ot_detail_screen.dart';
import 'package:appmobilegmao/screens/di/di_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedCategory = 'OT';
  late final OTService _otService;
  List<WorkOrder> _otOrders = [];
  bool _isLoadingOT = true;
  String? _errorMessage;

  final List<Order> diOrders = List.generate(
    5,
    (index) => Order(
      id: '$index',
      icon: Icons.build,
      code: '#DI12345$index',
      famille: 'Famille DI $index',
      zone: 'Zone DI $index',
      entity: 'Entité DI $index',
      unite: 'Unité DI $index',
      centre: 'Centre DI $index',
      description: 'Description de la demande d\'intervention DI $index',
      status: 'CREE',
      completionRate: 10.0 * index,
    ),
  );

  @override
  void initState() {
    super.initState();
    _otService = OTService(ApiService());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOTs();
    });
  }

  Future<void> _loadOTs() async {
    if (!mounted) return;
    setState(() {
      _isLoadingOT = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      final entity = user?.entity.trim() ?? '';
      final group = user?.group?.trim() ?? '';
      final fallbackService = entity.isNotEmpty ? entity : group;
      final serviceCode = fallbackService.isNotEmpty ? fallbackService : 'SDDV';

      final result = await _otService.getOrdersPage(
        scope: 'service',
        requestEntity: serviceCode,
        excludeClosed: true,
      );

      if (mounted) {
        setState(() {
          _otOrders = result.workorders;
          _isLoadingOT = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _otOrders = [];
          _isLoadingOT = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Order _convertToOrder(WorkOrder order) {
    return Order(
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
      status: Order.formatStatus(order.wowoUserStatus, order.mdusDescription),
      completionRate: order.wowoCompletionRate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final spacing = context.spacing;
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final username = user?.username ?? 'Utilisateur';
    final capitalizedUsername = username.isNotEmpty 
        ? username[0].toUpperCase() + username.substring(1) 
        : '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bonjour, $capitalizedUsername',
              style: TextStyle(
                fontFamily: AppTheme.fontMontserrat,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF2B1D4C),
                fontSize: responsive.sp(18),
              ),
            ),
            Text(
              'Tableau de bord de maintenance',
              style: TextStyle(
                fontFamily: AppTheme.fontRoboto,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF64748B),
                fontSize: responsive.sp(12),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: false,
      ),
      body: Padding(
        padding: spacing.custom(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📊 Cartes de Raccourcis Supérieures (Stat Cards sans chevauchement)
            Row(
              children: [
                Expanded(child: _buildStatCard(
                  title: 'Ordres de Travail',
                  count: _isLoadingOT ? 0 : _otOrders.length,
                  icon: Icons.assignment_rounded,
                  categoryKey: 'OT',
                  gradientColors: [const Color(0xFF0F1B80), const Color(0xFF2B1D4C)],
                  responsive: responsive,
                  spacing: spacing,
                  onTap: () {
                    setState(() {
                      selectedCategory = 'OT';
                    });
                  },
                  onArrowTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OTWorkOrdersScreen(),
                      ),
                    );
                  },
                )),
                SizedBox(width: spacing.medium),
                Expanded(child: _buildStatCard(
                  title: 'Demandes d\'Intervention',
                  count: diOrders.length,
                  icon: Icons.build_circle_rounded,
                  categoryKey: 'DI',
                  gradientColors: [const Color(0xFF2B1D4C), const Color(0xFF2B1D4C)],
                  responsive: responsive,
                  spacing: spacing,
                  onTap: () {
                    setState(() {
                      selectedCategory = 'DI';
                    });
                  },
                  onArrowTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DiScreen(),
                      ),
                    );
                  },
                )),
              ],
            ),
            SizedBox(height: spacing.large),

            // 🏷️ Titre de Section Dynamique & Badge de Compteur
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedCategory == 'OT'
                      ? 'Ordres de Travail en cours'
                      : 'Demandes d\'Intervention',
                  style: TextStyle(
                    fontFamily: AppTheme.fontMontserrat,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2B1D4C),
                    fontSize: responsive.sp(16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: selectedCategory == 'OT' 
                        ? const Color(0xFF0F1B80).withValues(alpha: 0.1)
                        : const Color(0xFFFFB800).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    selectedCategory == 'OT'
                        ? '${_otOrders.length} OT'
                        : '${diOrders.length} DI',
                    style: TextStyle(
                      fontFamily: AppTheme.fontMontserrat,
                      fontWeight: FontWeight.w700,
                      color: selectedCategory == 'OT'
                          ? const Color(0xFF0F1B80)
                          : const Color(0xFFCC4600),
                      fontSize: responsive.sp(12),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.medium),

            // 📋 Liste Animée des OT / DI
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: selectedCategory == 'OT' && _isLoadingOT
                    ? const Center(
                        child: CircularProgressIndicator(color: Color(0xFF0F1B80)),
                      )
                    : selectedCategory == 'OT' && _errorMessage != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : ListView.builder(
                            key: ValueKey(selectedCategory),
                            padding: EdgeInsets.zero,
                            itemCount: selectedCategory == 'OT'
                                ? _otOrders.length
                                : diOrders.length,
                            itemBuilder: (context, index) {
                              if (selectedCategory == 'OT') {
                                final order = _otOrders[index];
                                return Padding(
                                  padding: spacing.custom(bottom: 12),
                                  child: ListItemCustom.order(
                                    id: order.wowoCode.toString(),
                                    code: '#OT${order.wowoCode}',
                                    famille: order.wowoJobClassDescription ?? order.wowoJobClass,
                                    zone: order.wowoZone ?? '-',
                                    entity: order.wowoActionEntity,
                                    unite: order.wowoRequestEntity,
                                    centre: order.wowoCostcentre,
                                    description: order.mdjbDescription ?? order.wowoEquipmentDescription,
                                    status: order.wowoUserStatus,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => OTDetailScreen(order: _convertToOrder(order)),
                                        ),
                                      );
                                    },
                                    trailing: const SizedBox.shrink(),
                                  ),
                                );
                              } else {
                            final order = diOrders[index];
                            return Padding(
                              padding: spacing.custom(bottom: 12),
                              child: ListItemCustom.order(
                                id: order.id,
                                code: order.code,
                                famille: order.famille,
                                zone: order.zone,
                                entity: order.entity,
                                unite: order.unite,
                                centre: order.centre,
                                description: order.description,
                                trailing: PopupMenuButton<String>(
                                  icon: const Icon(
                                    Icons.more_vert_rounded,
                                    color: Color(0xFF64748B),
                                  ),
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Modifier ${order.code}')),
                                      );
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_outlined, size: 18, color: Color(0xFF0F1B80)),
                                          SizedBox(width: 8),
                                          Text('Modifier'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 💎 Composant de Carte de Statistique Moderne Sans Chevauchement de Texte
  Widget _buildStatCard({
    required String title,
    required int count,
    required IconData icon,
    required String categoryKey,
    required List<Color> gradientColors,
    required Responsive responsive,
    required ResponsiveSpacing spacing,
    required VoidCallback onTap,
    required VoidCallback onArrowTap,
  }) {
    final bool isSelected = selectedCategory == categoryKey;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: spacing.custom(all: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(responsive.spacing(16)),
          border: Border.all(
            color: isSelected ? gradientColors.first : const Color(0xFFE2E8F0),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? gradientColors.first.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: isSelected ? 12 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Ligne supérieure : Icône colorée + Flèche d'action (cliquable séparément)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: responsive.spacing(44),
                  height: responsive.spacing(44),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradientColors),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors.first.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: responsive.iconSize(22),
                    color: Colors.white,
                  ),
                ),
                GestureDetector(
                  onTap: onArrowTap,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: EdgeInsets.all(responsive.spacing(8)),
                    child: Icon(
                      Icons.arrow_outward_rounded,
                      size: responsive.iconSize(20),
                      color: isSelected ? gradientColors.first : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.medium),

            // Compteur & Libellé (Sans aucun chevauchement !)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count en cours',
                  style: TextStyle(
                    fontFamily: AppTheme.fontMontserrat,
                    fontWeight: FontWeight.w800,
                    color: gradientColors.first,
                    fontSize: responsive.sp(16),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.fontRoboto,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF334155),
                    fontSize: responsive.sp(13),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
