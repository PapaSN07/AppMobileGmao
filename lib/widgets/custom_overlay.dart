import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/utils/responsive.dart';
import 'package:appmobilegmao/theme/responsive_spacing.dart';

class CustomOverlay extends StatelessWidget {
  final Widget content;
  final VoidCallback onClose;
  final bool isDismissible;
  final double? width;
  final double? maxHeight;

  const CustomOverlay({
    super.key,
    required this.content,
    required this.onClose,
    this.isDismissible = true,
    this.width,
    this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final spacing = context.spacing;

    return GestureDetector(
      onTap: isDismissible ? onClose : null,
      child: Stack(
        children: [
          // Arrière-plan avec effet de flou
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(color: AppTheme.primaryColor15),
            ),
          ),

          // Contenu centré
          Center(
            child: GestureDetector(
              onTap: () {}, // Empêche la fermeture lors du clic sur le contenu
              child: Container(
                width: width ?? responsive.wp(90), // ✅ Largeur responsive
                constraints: BoxConstraints(
                  maxHeight:
                      maxHeight ??
                      responsive.hp(80), // ✅ Hauteur max responsive
                  maxWidth: responsive.wp(95), // ✅ Largeur max responsive
                ),
                margin: EdgeInsets.symmetric(
                  horizontal: spacing.large,
                ), // ✅ Marge responsive
                padding: spacing.allPadding, // ✅ Padding responsive
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor,
                  borderRadius: BorderRadius.circular(
                    responsive.spacing(20),
                  ), // ✅ Border radius responsive
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor15,
                      blurRadius: responsive.spacing(
                        20,
                      ), // ✅ Blur radius responsive
                      offset: Offset(
                        0,
                        responsive.spacing(10),
                      ), // ✅ Offset responsive
                    ),
                  ],
                ),
                child: SingleChildScrollView(child: content),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
