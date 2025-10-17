import 'package:flutter/material.dart';

/// Classe utilitaire pour gérer le responsive design
class Responsive {
  final BuildContext context;

  Responsive(this.context);

  /// Largeur de l'écran
  double get width => MediaQuery.of(context).size.width;

  /// Hauteur de l'écran
  double get height => MediaQuery.of(context).size.height;

  /// Type d'appareil selon la largeur
  bool get isMobile => width < 600;
  bool get isTablet => width >= 600 && width < 1024;
  bool get isDesktop => width >= 1024;

  /// Taille responsive basée sur la largeur
  double wp(double percentage) => width * percentage / 100;

  /// Taille responsive basée sur la hauteur
  double hp(double percentage) => height * percentage / 100;

  /// Taille de texte responsive
  double sp(double size) {
    if (isMobile) return size;
    if (isTablet) return size * 1.2;
    return size * 1.4;
  }

  /// Padding/Margin responsive
  double spacing(double baseSize) {
    if (isMobile) return baseSize;
    if (isTablet) return baseSize * 1.3;
    return baseSize * 1.5;
  }

  /// Taille d'icône responsive
  double iconSize(double baseSize) {
    if (isMobile) return baseSize;
    if (isTablet) return baseSize * 1.2;
    return baseSize * 1.4;
  }

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
