import 'package:flutter/material.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/utils/responsive.dart';
import 'package:appmobilegmao/theme/responsive_spacing.dart';
import 'package:appmobilegmao/screens/fichier_lie_screen.dart';
import 'package:appmobilegmao/services/ot_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  static Map<String, dynamic>? _parseAttachedFileFromComment(String rawText) {
    if (!rawText.contains('📎 [Fichier joint:')) return null;
    final startIdx = rawText.indexOf('📎 [Fichier joint:');
    final endIdx = rawText.indexOf(']', startIdx);
    final content = endIdx != -1
        ? rawText.substring(startIdx + '📎 [Fichier joint:'.length, endIdx).trim()
        : rawText.substring(startIdx + '📎 [Fichier joint:'.length).trim();

    if (!content.contains('|')) {
      return {'nom': content.isNotEmpty ? content : 'Document'};
    }
    final map = <String, dynamic>{};
    final tokens = content.split('|');
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
    return map;
  }

  static String _extractCleanCommentText(String rawText) {
    if (!rawText.contains('📎 [Fichier joint:')) return rawText.trim();
    final parts = rawText.split('📎 [Fichier joint:');
    return parts[0].trim();
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
            children: [
              const Text(
                'Commentaires / Rapports',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F1B80),
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _comments.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.comment_bank, size: 64, color: Color(0xFF0F1B80)),
                      SizedBox(height: 16),
                      Text('Aucun commentaire pour cet OT', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    MediaQuery.of(context).viewPadding.bottom > 0
                        ? MediaQuery.of(context).viewPadding.bottom + 16
                        : 24,
                  ),
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

                    // Détection des pièces jointes dans le texte
                    final attachedData = (fb['attachedFile'] as Map<String, dynamic>?) ?? _parseAttachedFileFromComment(rawCommentText);
                    final mainComment = _extractCleanCommentText(rawCommentText);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => _showCommentDetails(fb),
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
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                mainComment.isNotEmpty ? mainComment : 'Compte-rendu d\'intervention',
                                style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.3),
                              ),
                              if (attachedData != null) ...[
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
                                              attachedData['nom']?.toString().isNotEmpty == true
                                                  ? attachedData['nom'].toString()
                                                  : 'Document joint',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF0F1B80),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if ((attachedData['type'] ?? '').toString().isNotEmpty)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              margin: const EdgeInsets.only(left: 4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF0F1B80),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                attachedData['type'].toString().toUpperCase(),
                                                style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                        ],
                                      ),
                                      if ((attachedData['description'] ?? '').toString().isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Description : ${attachedData['description']}',
                                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                                        ),
                                      ],
                                      if ((attachedData['categorie'] ?? '').toString().isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Catégorie : ${attachedData['categorie']}',
                                          style: const TextStyle(fontSize: 11, color: Colors.black54),
                                        ),
                                      ],
                                      if ((attachedData['url'] ?? '').toString().isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'URL : ${attachedData['url']}',
                                          style: const TextStyle(fontSize: 11, color: Colors.blueAccent),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
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
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showCommentDetails(Map<String, dynamic> fb) {
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

    final attachedData = (fb['attachedFile'] as Map<String, dynamic>?) ?? _parseAttachedFileFromComment(rawCommentText);
    final mainComment = _extractCleanCommentText(rawCommentText);

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
              Row(
                children: [
                  const Icon(Icons.comment, color: Color(0xFF0F1B80), size: 22),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Détails du commentaire',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F1B80),
                      ),
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
                        style: const TextStyle(
                          color: Color(0xFF0F1B80),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
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
                          mainComment.isNotEmpty ? mainComment : 'Aucun texte saisi',
                          style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
                        ),
                      ),
                      if (attachedData != null) ...[
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
                                      attachedData['nom']?.toString().isNotEmpty == true
                                          ? attachedData['nom'].toString()
                                          : 'Document',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Color(0xFF0F1B80),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if ((attachedData['description'] ?? '').toString().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Description : ${attachedData['description']}',
                                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                                ),
                              ],
                              if ((attachedData['type'] ?? '').toString().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Type : ${attachedData['type']}',
                                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                                ),
                              ],
                              if ((attachedData['categorie'] ?? '').toString().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Catégorie : ${attachedData['categorie']}',
                                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                                ),
                              ],
                              if (attachedData['isImprimable'] == true || attachedData['isImprimable']?.toString().toLowerCase() == 'true') ...[
                                const SizedBox(height: 4),
                                const Row(
                                  children: [
                                    Icon(Icons.check_circle, size: 14, color: Colors.green),
                                    SizedBox(width: 4),
                                    Text('Imprimable', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ],
                              if ((attachedData['dateCreation'] ?? '').toString().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Date création : ${attachedData['dateCreation']}',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                              if ((attachedData['url'] ?? '').toString().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'URL : ${attachedData['url']}',
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
