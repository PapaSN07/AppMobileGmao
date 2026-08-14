import 'package:flutter/material.dart';
import 'package:appmobilegmao/models/work_request.dart';

/// =====================================================================
/// DETAIL DI (Demandes d'Intervention) - SAUVEGARDE DU CODE D'ORIGINE
/// Pour réactiver l'écran de détail d'origine, supprimez les commentaires /* ... */
/// =====================================================================

class DIDetailScreen extends StatefulWidget {
  final WorkRequest request;

  const DIDetailScreen({super.key, required this.request});

  @override
  State<DIDetailScreen> createState() => _DIDetailScreenState();
}

class _DIDetailScreenState extends State<DIDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Détails DI ${widget.request.dinqCode}'),
        backgroundColor: const Color(0xFF0F1B80),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.info_outline, size: 64, color: Color(0xFF0F1B80)),
              const SizedBox(height: 16),
              Text(
                "Détails de la DI ${widget.request.dinqCode}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Code d'origine sauvegardé en commentaire pour le développeur du module.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* =====================================================================
CODE D'ORIGINE COMPLET DE DI_DETAIL_SCREEN (CONSERVÉ EN BACKUP) :
======================================================================== */
/*
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/utils/responsive.dart';
import 'package:appmobilegmao/theme/responsive_spacing.dart';

  late TabController _tabController;
  final int _currentBottomIndex = 3; // Index 3 is DI in MainScreen

  @override
  void initState() {
    super.initState();
    // 7 tabs to match Coswin 8 screenshots
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onBottomNavTapped(int index) {
    if (index == _currentBottomIndex) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => MainScreen(initialIndex: index)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final spacing = context.spacing;

    // Get color according to Priority
    Color priorityColor = Colors.grey;
    if (widget.request.dinqPriority == 'URGENT') {
      priorityColor = const Color(0xFFEF4444);
    } else if (widget.request.dinqPriority == 'NORMAL') {
      priorityColor = const Color(0xFFF59E0B);
    } else if (widget.request.dinqPriority == 'DEPL_SUPPORT') {
      priorityColor = const Color(0xFF3B82F6);
    }

    // Get color according to Status
    Color statusBg = const Color(0xFFFEF3C7);
    Color statusText = const Color(0xFFD97706);
    if (widget.request.dinqUserStatus.contains('OT créé')) {
      statusBg = const Color(0xFFDCFCE7);
      statusText = const Color(0xFF15803D);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        backgroundColor: Colors.white,
        iconColor: const Color(0xFF2B1D4C),
        title: 'DI ${widget.request.dinqCode}',
        // The tab bar is placed inside the AppBar bottom area
        bottom: CustomTabBar(
          tabController: _tabController,
          tabLabels: const [
            'Problème',
            'Plus',
            'Diagnostic',
            'Combiné',
            'Remarque OT',
            'Hist. États',
            'Répartitions',
          ],
        ),
      ),
      body: Column(
        children: [
          // 📌 Persistent Header Card showing general fields above tabs (just like Coswin 8!)
          Container(
            width: double.infinity,
            margin: spacing.custom(horizontal: 16, top: 12, bottom: 4),
            padding: spacing.custom(all: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.request.dinqCode,
                      style: TextStyle(
                        fontFamily: AppTheme.fontMontserrat,
                        fontWeight: FontWeight.bold,
                        fontSize: responsive.sp(15),
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.request.dinqUserStatus,
                            style: TextStyle(
                              color: statusText,
                              fontWeight: FontWeight.bold,
                              fontSize: responsive.sp(11),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (widget.request.dinqPriority != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: priorityColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              widget.request.dinqPriority!,
                              style: TextStyle(
                                color: priorityColor,
                                fontWeight: FontWeight.bold,
                                fontSize: responsive.sp(11),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 16),
                Text(
                  widget.request.dinqEquipmentDescription,
                  style: TextStyle(
                    fontFamily: AppTheme.fontRoboto,
                    fontWeight: FontWeight.w600,
                    fontSize: responsive.sp(12),
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Éqpt: ${widget.request.dinqEquipment}',
                      style: TextStyle(
                        fontFamily: AppTheme.fontRoboto,
                        fontSize: responsive.sp(11),
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      'Demandeur: ${widget.request.dinqSupervisor ?? "6795"}',
                      style: TextStyle(
                        fontFamily: AppTheme.fontRoboto,
                        fontSize: responsive.sp(11),
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 🗂️ Tab Contents
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ProblemeTab(request: widget.request),
                _PlusTab(request: widget.request),
                _DiagnosticTab(request: widget.request),
                _CombineTab(request: widget.request),
                _RemarqueOtTab(request: widget.request),
                _HistEtatsTab(request: widget.request),
                _RepartitionsTab(request: widget.request),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentBottomIndex,
        onTap: _onBottomNavTapped,
      ),
    );
  }
}

// 🗂️ TAB 1: PROBLEME
class _ProblemeTab extends StatelessWidget {
  final WorkRequest request;

  const _ProblemeTab({required this.request});

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final spacing = context.spacing;

    return ListView(
      padding: spacing.custom(all: 16),
      children: [
        Container(
          padding: spacing.custom(all: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Description de l\'anomalie / panne',
                style: TextStyle(
                  fontFamily: AppTheme.fontMontserrat,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondaryColor,
                  fontSize: responsive.sp(14),
                ),
              ),
              const Divider(height: 24),
              Text(
                request.dinqDescription,
                style: TextStyle(
                  fontFamily: AppTheme.fontRoboto,
                  fontSize: responsive.sp(13),
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: spacing.medium),

        Container(
          padding: spacing.custom(all: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pièces Jointes & Documents',
                style: TextStyle(
                  fontFamily: AppTheme.fontMontserrat,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondaryColor,
                  fontSize: responsive.sp(14),
                ),
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  ),
                  SizedBox(width: spacing.medium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RAPPORT_ULTRASON_VISITE.pdf',
                          style: TextStyle(
                            fontFamily: AppTheme.fontRoboto,
                            fontWeight: FontWeight.bold,
                            fontSize: responsive.sp(12),
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '2.4 MB • Modifié le 28/07/2026',
                          style: TextStyle(
                            fontFamily: AppTheme.fontRoboto,
                            fontSize: responsive.sp(11),
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.download, color: Colors.grey),
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// 🗂️ TAB 2: PLUS
class _PlusTab extends StatelessWidget {
  final WorkRequest request;

  const _PlusTab({required this.request});

  String _formatShortDate(String? dateStr, String defaultValue) {
    if (dateStr == null || dateStr.isEmpty) return defaultValue;
    if (dateStr.length < 10) return dateStr;
    return dateStr.substring(0, 10);
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return ListView(
      padding: spacing.custom(all: 16),
      children: [
        _buildInfoCard(context, 'Planification & Dates', [
          _buildFieldRow('Date début prévue', _formatShortDate(request.dateDebut, '24/07/2026')),
          _buildFieldRow('Date fin prévue', _formatShortDate(request.dateFin, '24/07/2026')),
          _buildFieldRow('Date création', _formatShortDate(request.dinqAskDate, '24/07/2026')),
        ]),
        SizedBox(height: spacing.medium),
        _buildInfoCard(context, 'Localisation & Réalisation', [
          _buildFieldRow('Zone géographique', request.dinqZone ?? 'DAKAR'),
          _buildFieldRow('Centre de charges', request.dinqCostcentre ?? 'DD303'),
          _buildFieldRow('Entité de réalisation', request.dinqActionEntity ?? 'SERVICE DE DISTRIBUTION DAKAR VILLE'),
          _buildFieldRow('Entité demanderesse', request.dinqRequestEntity ?? 'SERVICE DE DISTRIBUTION DAKAR VILLE'),
        ]),
        SizedBox(height: spacing.medium),
        _buildInfoCard(context, 'Notifications', [
          _buildFieldRow('Mails à notifier', request.mailsToNotify ?? 'NÉANT'),
        ]),
      ],
    );
  }
}

// 🗂️ TAB 3: DIAGNOSTIC
class _DiagnosticTab extends StatelessWidget {
  final WorkRequest request;

  const _DiagnosticTab({required this.request});

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final spacing = context.spacing;

    final Map<String, String> diagnostics = {
      'Symptôme': 'DECHARGE PARTIELLE SUR CELLULE',
      'Défaut': 'ECHAUFFEMENT / EFFET CORONA',
      'Cause': 'USURE NATURELLE / ISOLEMENT DÉGRADÉ',
      'Remède': 'REMPLACEMENT DES COMPOSANTS & NETTOYAGE',
    };

    return ListView(
      padding: spacing.custom(all: 16),
      children: [
        Container(
          padding: spacing.custom(all: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Arbre Diagnostic',
                style: TextStyle(
                  fontFamily: AppTheme.fontMontserrat,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondaryColor,
                  fontSize: responsive.sp(14),
                ),
              ),
              const Divider(height: 24),
              ...diagnostics.entries.map((entry) {
                return Padding(
                  padding: spacing.custom(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: TextStyle(
                          fontFamily: AppTheme.fontMontserrat,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.thirdColor,
                          fontSize: responsive.sp(12),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: spacing.custom(all: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            fontFamily: AppTheme.fontRoboto,
                            fontSize: responsive.sp(13),
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

// 🗂️ TAB 4: COMBINE
class _CombineTab extends StatelessWidget {
  final WorkRequest request;

  const _CombineTab({required this.request});

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final spacing = context.spacing;

    return Center(
      child: Padding(
        padding: spacing.custom(all: 20),
        child: Text(
          'Aucune demande d\'intervention combinée.',
          style: TextStyle(
            fontFamily: AppTheme.fontRoboto,
            fontSize: responsive.sp(14),
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// 🗂️ TAB 5: REMARQUE DE L'OT
class _RemarqueOtTab extends StatelessWidget {
  final WorkRequest request;

  const _RemarqueOtTab({required this.request});

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final spacing = context.spacing;

    return ListView(
      padding: spacing.custom(all: 16),
      children: [
        Container(
          padding: spacing.custom(all: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Remarque de l\'OT',
                style: TextStyle(
                  fontFamily: AppTheme.fontMontserrat,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondaryColor,
                  fontSize: responsive.sp(14),
                ),
              ),
              const Divider(height: 24),
              TextField(
                maxLines: 6,
                readOnly: true,
                decoration: InputDecoration(
                  hintText: 'Aucune remarque rédigée pour le moment.',
                  fillColor: const Color(0xFFF8FAFC),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
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

// 🗂️ TAB 6: HISTORIQUE DES ETATS
class _HistEtatsTab extends StatelessWidget {
  final WorkRequest request;

  const _HistEtatsTab({required this.request});

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final spacing = context.spacing;

    return ListView(
      padding: spacing.custom(all: 16),
      children: [
        Container(
          padding: spacing.custom(all: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Historique des États',
                style: TextStyle(
                  fontFamily: AppTheme.fontMontserrat,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondaryColor,
                  fontSize: responsive.sp(14),
                ),
              ),
              const Divider(height: 24),
              _buildTimelineItem(responsive, '24/07/2026 13:41', '0. Créée', 'papamadou.mbaye'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(Responsive responsive, String date, String status, String user) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            const Icon(Icons.circle, color: AppTheme.secondaryColor, size: 14),
            Container(width: 2, height: 40, color: Colors.grey[300]),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                status,
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondaryColor),
              ),
              const SizedBox(height: 2),
              Text(
                'Le $date par $user',
                style: TextStyle(color: Colors.grey[600], fontSize: responsive.sp(11)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// 🗂️ TAB 7: REPARTITIONS
class _RepartitionsTab extends StatelessWidget {
  final WorkRequest request;

  const _RepartitionsTab({required this.request});

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final spacing = context.spacing;

    return Center(
      child: Padding(
        padding: spacing.custom(all: 20),
        child: Text(
          'Aucune répartition sur cette DI.',
          style: TextStyle(
            fontFamily: AppTheme.fontRoboto,
            fontSize: responsive.sp(14),
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}

// 🛠️ HELPERS
Widget _buildInfoCard(BuildContext context, String title, List<Widget> children) {
  final responsive = context.responsive;
  final spacing = context.spacing;

  return Container(
    padding: spacing.custom(all: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: AppTheme.fontMontserrat,
            fontWeight: FontWeight.bold,
            color: AppTheme.secondaryColor,
            fontSize: responsive.sp(14),
          ),
        ),
        const Divider(height: 24),
        ...children,
      ],
    ),
  );
}

Widget _buildFieldRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
            ),
          ),
        ),
      ],
    ),
  );
}
*/

