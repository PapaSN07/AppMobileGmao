/// Une entrée du champ Commentaire de Coswin.
class CoswinComment {
  final String author;

  /// Date telle qu'écrite par Coswin (« 31-03-2026 07:30:55 »), vide si absente.
  final String date;
  final String text;

  const CoswinComment({required this.author, required this.date, required this.text});

  /// Date convertie (heure locale de saisie), ou null si illisible.
  DateTime? get dateTime {
    final m = RegExp(r'^(\d{2})-(\d{2})-(\d{4}) (\d{2}):(\d{2})(?::(\d{2}))?').firstMatch(date.trim());
    if (m == null) return null;
    int g(int i) => int.parse(m.group(i) ?? '0');
    return DateTime(g(3), g(2), g(1), g(4), g(5), g(6));
  }
}

/// Champ Commentaire d'un OT Coswin (`wowoFeedbackNote`).
///
/// Coswin y garde un historique en HTML, le plus récent en premier :
/// `<b>#[auteur] - jj-mm-aaaa hh:mm:ss</b><br>texte<br><br>` (certaines entrées
/// utilisent `<span style="font-weight: bold;">` au lieu de `<b>`).
class CoswinCommentLog {
  CoswinCommentLog._();

  static final RegExp _header = RegExp(r'#\[([^\]]*)\]\s*-\s*([^<,]*)([^<]*)');

  /// Entrées du champ, dans l'ordre de Coswin (la plus récente d'abord).
  /// Un texte sans en-tête « #[auteur] » donne une seule entrée sans auteur.
  static List<CoswinComment> parse(String? html) {
    final source = (html ?? '').trim();
    if (source.isEmpty) return const [];

    final headers = _header.allMatches(source).toList();
    if (headers.isEmpty) {
      final text = toPlainText(source);
      return text.isEmpty ? const [] : [CoswinComment(author: '', date: '', text: text)];
    }

    final entries = <CoswinComment>[];
    for (var i = 0; i < headers.length; i++) {
      final h = headers[i];
      final bodyEnd = i + 1 < headers.length ? headers[i + 1].start : source.length;
      final text = toPlainText(source.substring(h.end, bodyEnd));
      entries.add(CoswinComment(
        author: _decodeEntities(h.group(1) ?? '').trim(),
        date: (h.group(2) ?? '').trim(),
        text: text,
      ));
    }
    return entries;
  }

  /// Ajoute une entrée en tête du champ, au format utilisé par Coswin.
  static String prepend(String? html, {required String author, required String text, DateTime? now}) {
    final t = now ?? DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    final date = '${two(t.day)}-${two(t.month)}-${t.year} ${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
    final body = _escape(text.trim()).replaceAll('\n', '<br>');
    final entry = '<b>#[${_escape(author)}] - $date</b><br>$body<br><br>';
    final existing = (html ?? '').trim();
    return existing.isEmpty ? entry : '$entry$existing';
  }

  /// HTML Coswin → texte lisible (retours à la ligne conservés).
  static String toPlainText(String html) {
    var s = html
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</?(div|p)[^>]*>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), '');
    s = _decodeEntities(s);
    return s
        .split('\n')
        .map((l) => l.trimRight())
        .join('\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  static String _decodeEntities(String s) => s
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAllMapped(RegExp(r'&#(\d+);'), (m) => String.fromCharCode(int.parse(m.group(1)!)))
      .replaceAll('&amp;', '&');

  static String _escape(String s) =>
      s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
}
