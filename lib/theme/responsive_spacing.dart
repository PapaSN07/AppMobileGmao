import 'package:flutter/material.dart';
import 'package:appmobilegmao/utils/responsive.dart';

/// Classe pour gérer les espacements de manière responsive
class ResponsiveSpacing {
  final BuildContext context;
  late final Responsive _responsive;

  ResponsiveSpacing(this.context) {
    _responsive = Responsive(context);
  }

  /// Espacements standards
  double get tiny => _responsive.spacing(4);
  double get small => _responsive.spacing(8);
  double get medium => _responsive.spacing(16);
  double get large => _responsive.spacing(24);
  double get xlarge => _responsive.spacing(32);
  double get xxlarge => _responsive.spacing(48);

  /// Padding symétrique horizontal
  EdgeInsets get horizontalPadding => EdgeInsets.symmetric(horizontal: medium);

  /// Padding symétrique vertical
  EdgeInsets get verticalPadding => EdgeInsets.symmetric(vertical: medium);

  /// Padding global
  EdgeInsets get allPadding => EdgeInsets.all(medium);

  /// Padding personnalisé responsive
  EdgeInsets custom({
    double? all,
    double? horizontal,
    double? vertical,
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    if (all != null) {
      return EdgeInsets.all(_responsive.spacing(all));
    }
    if (horizontal != null || vertical != null) {
      return EdgeInsets.symmetric(
        horizontal: horizontal != null ? _responsive.spacing(horizontal) : 0,
        vertical: vertical != null ? _responsive.spacing(vertical) : 0,
      );
    }
    return EdgeInsets.only(
      left: _responsive.spacing(left ?? 0),
      top: _responsive.spacing(top ?? 0),
      right: _responsive.spacing(right ?? 0),
      bottom: _responsive.spacing(bottom ?? 0),
    );
  }

  /// Helper statique
  static ResponsiveSpacing of(BuildContext context) =>
      ResponsiveSpacing(context);
}

/// Extension pour faciliter l'utilisation
extension ResponsiveSpacingExtension on BuildContext {
  ResponsiveSpacing get spacing => ResponsiveSpacing(this);
}
