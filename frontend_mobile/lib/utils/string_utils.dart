class StringUtils {
  /// Parse un username et retourne un Map avec prénom, nom et initiales
  static Map<String, String> parseUserName(String? username) {
    String nom = '';
    String prenom = '';
    String initiales = '?';

    if (username != null && username.isNotEmpty) {
      // Diviser par point, espace, underscore ou tiret
      final parts = username.split(RegExp(r'[.\s_-]+'));

      if (parts.length >= 2) {
        prenom = parts.first;
        nom = parts.last;
      } else if (parts.length == 1) {
        prenom = parts.first;
        nom = parts.first;
      }

      // Générer les initiales
      if (prenom.isNotEmpty && nom.isNotEmpty) {
        initiales = "${prenom[0].toUpperCase()}${nom[0].toUpperCase()}";
      } else if (prenom.isNotEmpty) {
        initiales = prenom[0].toUpperCase();
      } else if (nom.isNotEmpty) {
        initiales = nom[0].toUpperCase();
      }
    }

    return {'prenom': prenom, 'nom': nom, 'initiales': initiales};
  }

  /// Capitalise la première lettre d'une chaîne
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Capitalise chaque mot d'une chaîne
  static String capitalizeWords(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) => capitalize(word)).join(' ');
  }
}
