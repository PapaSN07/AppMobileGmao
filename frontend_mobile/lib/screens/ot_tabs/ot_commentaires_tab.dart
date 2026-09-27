import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:appmobilegmao/services/ot_service.dart';
import 'package:appmobilegmao/models/attached_file_note.dart';
import 'package:appmobilegmao/widgets/attachment_warning.dart';

/// Onglet "Commentaires" - Affiche les commentaires et les pièces jointes
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage des commentaires et pièces jointes
class CommentairesTab extends StatefulWidget {
  final String otCode;
  final OTService otService;

  const CommentairesTab({super.key, required this.otCode, required this.otService});

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
      return const Center(child: CircularProgressIndicator(color: AppTheme.senelecReflexBlue));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text('Erreur: $_error', style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadComments,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.senelecReflexBlue, foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Text(
                'Commentaires / Rapports',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.senelecReflexBlue,
                  fontSize: 17,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Actualiser depuis Coswin',
                icon: const Icon(Icons.refresh, color: AppTheme.senelecReflexBlue, size: 22),
                onPressed: _loadComments,
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
                      Icon(Icons.comment_bank, size: 64, color: AppTheme.senelecReflexBlue),
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
                        'Commentaire sans texte';
                    final author = fb['wodoCreationUser']?.toString() ??
                        fb['wodoUser']?.toString() ??
                        fb['author']?.toString() ??
                        fb['woefEmployee']?.toString() ??
                        'Agent';
                    final docType = fb['wodoType']?.toString() ?? fb['type']?.toString() ?? '';
                    final dateStr = _formatDate(fb['wodoCreationDate'] ?? fb['woefStartDate'] ?? fb['createdAt']);

                    // Détection des pièces jointes dans le texte
                    final attachedData = (fb['attachedFile'] as Map<String, dynamic>?) ?? AttachedFileNote.parse(rawCommentText);
                    final mainComment = AttachedFileNote.stripFrom(rawCommentText);

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
                                  const Icon(Icons.account_circle, color: AppTheme.senelecReflexBlue, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      author,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.senelecIndigo),
                                    ),
                                  ),
                                  if (docType.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppTheme.senelecReflexBlue.withAlpha(20),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        docType,
                                        style: const TextStyle(color: AppTheme.senelecReflexBlue, fontSize: 11, fontWeight: FontWeight.bold),
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
                                    border: Border.all(color: AppTheme.senelecReflexBlue.withAlpha(50)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.attach_file, size: 16, color: AppTheme.senelecReflexBlue),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              attachedData['nom']?.toString().isNotEmpty == true
                                                  ? attachedData['nom'].toString()
                                                  : 'Document joint',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.senelecReflexBlue,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if ((attachedData['type'] ?? '').toString().isNotEmpty)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              margin: const EdgeInsets.only(left: 4),
                                              decoration: BoxDecoration(
                                                color: AppTheme.senelecReflexBlue,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                attachedData['type'].toString().toUpperCase(),
                                                style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const AttachmentNotSentWarning(),
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
        'Commentaire sans texte';
    final author = fb['wodoCreationUser']?.toString() ??
        fb['wodoUser']?.toString() ??
        fb['author']?.toString() ??
        fb['woefEmployee']?.toString() ??
        'Agent';
    final docType = fb['wodoType']?.toString() ?? fb['type']?.toString() ?? '';
    final dateStr = _formatDate(fb['wodoCreationDate'] ?? fb['woefStartDate'] ?? fb['createdAt']);

    final attachedData = (fb['attachedFile'] as Map<String, dynamic>?) ?? AttachedFileNote.parse(rawCommentText);
    final mainComment = AttachedFileNote.stripFrom(rawCommentText);

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
                  const Icon(Icons.comment, color: AppTheme.senelecReflexBlue, size: 22),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Détails du commentaire',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.senelecReflexBlue,
                      ),
                    ),
                  ),
                  if (docType.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.senelecReflexBlue.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        docType,
                        style: const TextStyle(
                          color: AppTheme.senelecReflexBlue,
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
                          color: AppTheme.senelecIndigo,
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
                            color: AppTheme.senelecIndigo,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8EDFF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.senelecReflexBlue.withAlpha(40)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.attach_file, color: AppTheme.senelecReflexBlue, size: 18),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      attachedData['nom']?.toString().isNotEmpty == true
                                          ? attachedData['nom'].toString()
                                          : 'Document',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: AppTheme.senelecReflexBlue,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const AttachmentNotSentWarning(),
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
                    backgroundColor: AppTheme.senelecReflexBlue,
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

  /// Date Coswin (ISO 8601, UTC) affichée en heure locale : jj/mm/aaaa hh:mm.
  String _formatDate(dynamic raw) {
    final d = DateTime.tryParse(raw?.toString() ?? '')?.toLocal();
    if (d == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }
}
