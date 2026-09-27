/// Pièce jointe notée dans le texte d'un compte-rendu Coswin.
///
/// Le fichier lui-même n'est PAS envoyé à Coswin : seules ses informations
/// (nom, type, URL…) sont écrites dans le commentaire, sous la forme
/// `[PJ: Nom: photo.jpg ; Type: JPG ; …]`. L'envoi réel passera par le backend.
class AttachedFileNote {
  AttachedFileNote._();

  static const String _tag = '[PJ:';
  static const String _legacyTag = '📎 [Fichier joint:';

  /// Avertissement affiché partout où une pièce jointe apparaît.
  static const String notSentWarning =
      "Fichier non envoyé à Coswin : seul son nom est noté dans le commentaire.";

  /// Correspondance clé de métadonnée → étiquette dans le texte.
  static const Map<String, String> _labels = {
    'nom': 'Nom',
    'description': 'Desc',
    'type': 'Type',
    'categorie': 'Cat',
    'url': 'URL',
    'dateCreation': 'Date',
    'createur': 'Auteur',
  };

  /// Texte du commentaire suivi de la balise de pièce jointe.
  static String compose(String text, Map<String, dynamic>? attached) {
    final cleanText = text.trim();
    if (attached == null) return cleanText;

    final parts = <String>[
      for (final e in _labels.entries)
        if ((attached[e.key] ?? '').toString().trim().isNotEmpty)
          '${e.value}: ${attached[e.key].toString().trim()}',
      if (attached['isImprimable'] == true || attached['isImprimable']?.toString().toLowerCase() == 'true')
        'Imprimable: Oui',
    ];
    final note = '$_tag ${parts.join(' ; ')}]';
    return cleanText.isEmpty ? note : '$cleanText\n$note';
  }

  static String? _tagIn(String rawText) =>
      rawText.contains(_tag) ? _tag : (rawText.contains(_legacyTag) ? _legacyTag : null);

  /// Métadonnées de la pièce jointe notée dans le texte, ou null s'il n'y en a pas.
  static Map<String, dynamic>? parse(String rawText) {
    final tag = _tagIn(rawText);
    if (tag == null) return null;

    final start = rawText.indexOf(tag) + tag.length;
    final end = rawText.indexOf(']', start);
    final content = (end != -1 ? rawText.substring(start, end) : rawText.substring(start)).trim();

    final map = <String, dynamic>{};
    final delimiter = content.contains(' ; ') ? ' ; ' : '|';
    for (final token in content.split(delimiter)) {
      final t = token.trim();
      if (t.startsWith('Imprimable:')) {
        map['isImprimable'] = t.substring('Imprimable:'.length).trim() == 'Oui';
        continue;
      }
      for (final e in _labels.entries) {
        final prefix = '${e.value}:';
        if (t.startsWith(prefix)) {
          map[e.key] = t.substring(prefix.length).trim();
          break;
        }
      }
    }
    if (map.isEmpty && content.isNotEmpty) map['nom'] = content;
    return map.isNotEmpty ? map : null;
  }

  /// Texte du commentaire sans la balise de pièce jointe.
  static String stripFrom(String rawText) {
    final tag = _tagIn(rawText);
    return (tag == null ? rawText : rawText.split(tag).first).trim();
  }
}
