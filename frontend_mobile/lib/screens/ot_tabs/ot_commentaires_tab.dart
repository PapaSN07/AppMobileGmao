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
import 'package:image_picker/image_picker.dart';

/// Onglet "Commentaires" - Affiche les commentaires et les pièces jointes
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage des commentaires et pièces jointes
class CommentairesTab extends StatefulWidget {
  final String otCode;
  final OTService otService;

  const CommentairesTab({Key? key, required this.otCode, required this.otService}) : super(key: key);

  @override
  State<CommentairesTab> createState() => CommentairesTabState();
}

class CommentairesTabState extends State<CommentairesTab> {
  List<dynamic> _comments = [];
  bool _isLoading = true;
  String? _error;
  final ImagePicker _picker = ImagePicker();

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
    XFile? selectedFile;

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
              title: const Text('Ajouter un compte-rendu / fichier'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: contentController,
                        decoration: const InputDecoration(
                          labelText: 'Commentaire / Rapport *',
                          hintText: 'Description du travail effectué...',
                        ),
                        maxLines: 2,
                        validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: authorController,
                        decoration: const InputDecoration(labelText: 'Auteur / Code Employé *'),
                        validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                      ),
                      const SizedBox(height: 12),
                      
                      // 📎 Section Pièce Jointe / Fichier
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '📎 Pièce jointe / Photo',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            if (selectedFile == null) ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () async {
                                        try {
                                          final f = await _picker.pickImage(source: ImageSource.camera);
                                          if (f != null) {
                                            setDialogState(() => selectedFile = f);
                                          }
                                        } catch (e) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Erreur caméra: $e')),
                                          );
                                        }
                                      },
                                      icon: const Icon(Icons.camera_alt, size: 16),
                                      label: const Text('Photo', style: TextStyle(fontSize: 12)),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFF0F1B80),
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () async {
                                        try {
                                          final f = await _picker.pickImage(source: ImageSource.gallery);
                                          if (f != null) {
                                            setDialogState(() => selectedFile = f);
                                          }
                                        } catch (e) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Erreur galerie: $e')),
                                          );
                                        }
                                      },
                                      icon: const Icon(Icons.photo_library, size: 16),
                                      label: const Text('Galerie/Fichier', style: TextStyle(fontSize: 12)),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFF0F1B80),
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF0F1B80).withAlpha(50)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.attach_file, color: Color(0xFF0F1B80), size: 18),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        selectedFile!.name,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, color: Colors.red, size: 18),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => setDialogState(() => selectedFile = null),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),
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
                        String commentBody = contentController.text.trim();
                        if (selectedFile != null) {
                          commentBody += "\n📎 [Fichier joint: ${selectedFile!.name}]";
                        }

                        await widget.otService.createDocument(widget.otCode, {
                          "woefEmployee": authorController.text.trim(),
                          "reemDescription": "Intervenant",
                          "woefUserStatus": commentBody,
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
              ElevatedButton.icon(
                onPressed: _showAddDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Ajouter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F1B80),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _comments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.comment_bank, size: 64, color: Color(0xFF0F1B80)),
                      const SizedBox(height: 16),
                      const Text('Aucun commentaire pour cet OT', style: TextStyle(fontSize: 16, color: Colors.grey)),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _showAddDialog,
                        icon: const Icon(Icons.add, color: Color(0xFF0F1B80)),
                        label: const Text('Ajouter un premier compte-rendu', style: TextStyle(color: Color(0xFF0F1B80))),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _comments.length,
                  itemBuilder: (context, index) {
                    final fb = _comments[index];
                    final rawCommentText = fb['wodoComment']?.toString() ??
                        fb['wodoDescription']?.toString() ??
                        fb['wodoText']?.toString() ??
                        fb['comment']?.toString() ??
                        fb['reemDescription']?.toString() ??
                        fb['woefUserStatus']?.toString() ??
                        'Commentaire sans texte';
                    final author = fb['wodoCreationUser']?.toString() ??
                        fb['wodoUser']?.toString() ??
                        fb['author']?.toString() ??
                        fb['woefEmployee']?.toString() ??
                        'Agent';
                    final docType = fb['wodoType']?.toString() ?? fb['type']?.toString() ?? '';
                    final dateStr = _formatDate(fb['wodoCreationDate'] ?? fb['woefStartDate'] ?? fb['createdAt']);
                    final pk = (fb['pkComment'] ?? fb['pkEmployeeFeedback'] ?? 0) as int;

                    // Détection des pièces jointes dans le texte
                    String mainComment = rawCommentText;
                    String? attachedFileName;
                    if (rawCommentText.contains('📎 [Fichier joint:')) {
                      final parts = rawCommentText.split('📎 [Fichier joint:');
                      mainComment = parts[0].trim();
                      if (parts.length > 1) {
                        attachedFileName = parts[1].replaceAll(']', '').trim();
                      }
                    }

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
                                if (pk > 0)
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                                    onSelected: (val) {
                                      if (val == 'edit') {
                                        _showEditDialog(fb);
                                      } else if (val == 'delete') {
                                        _confirmDelete(pk);
                                      }
                                    },
                                    itemBuilder: (ctx) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit, size: 16, color: Colors.blue),
                                            SizedBox(width: 8),
                                            Text('Modifier'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete, size: 16, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Supprimer'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              mainComment.isNotEmpty ? mainComment : 'Compte-rendu d\'intervention',
                              style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.3),
                            ),
                            if (attachedFileName != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F1B80).withAlpha(15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF0F1B80).withAlpha(40)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.attach_file, size: 14, color: Color(0xFF0F1B80)),
                                    const SizedBox(width: 4),
                                    Text(
                                      attachedFileName,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF0F1B80),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
