import 'package:flutter/material.dart';

/// Classe utilitaire pour gérer le responsive design
/// Amélioration: scaling basé sur une `designWidth` pour conserver les
/// proportions sur petits écrans sans casser les layouts existants.
class Responsive {
  final BuildContext context;
  static const double _designWidth = 375.0; // largeur de référence du design

  Responsive(this.context);

  /// Largeur et hauteur de l'écran
  double get width => MediaQuery.of(context).size.width;
  double get height => MediaQuery.of(context).size.height;

  /// Facteur de scale basé sur la largeur par rapport au design
  double get _scale => (width / _designWidth).clamp(0.7, 1.2);

  /// Détecteurs d'appareil
  bool get isMobile => width < 600;
  bool get isTablet => width >= 600 && width < 1024;
  bool get isDesktop => width >= 1024;

  /// Taille responsive basée sur un pourcentage de la largeur
  double wp(double percentage) => width * (percentage / 100);

  /// Taille responsive basée sur un pourcentage de la hauteur
  double hp(double percentage) => height * (percentage / 100);

  /// Taille de texte responsive: applique le scale et clamp pour éviter
  /// textes trop petits ou énormes sur écrans extrêmes.
  double sp(double size) {
    final scaled = size * _scale;
    return scaled.clamp((size * 0.8), (size * 1.25));
  }

  /// Padding/Margin responsive (utilise le scale pour réduire sur petits écrans)
  double spacing(double baseSize) => (baseSize * _scale).clamp(2.0, baseSize * 1.6);

  /// Taille d'icône responsive
  double iconSize(double baseSize) => (baseSize * _scale).clamp(10.0, baseSize * 1.6);

  /// Largeur maximale pour le contenu (évite l'étirement sur grands écrans)
  double get maxContentWidth {
    if (isMobile) return width;
    if (isTablet) return 800;
    return 1200;
  }

  /// Helper pour obtenir une instance Responsive
  static Responsive of(BuildContext context) => Responsive(context);
}

/// Extension pour faciliter l'utilisation
extension ResponsiveExtension on BuildContext {
  Responsive get responsive => Responsive(this);
}
