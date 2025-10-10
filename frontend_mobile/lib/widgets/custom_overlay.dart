import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:appmobilegmao/theme/app_theme.dart';

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
    final screenSize = MediaQuery.of(context).size;

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
                width: width ?? screenSize.width * 0.9,
                constraints: BoxConstraints(
                  maxHeight: maxHeight ?? screenSize.height * 0.8,
                  maxWidth: screenSize.width * 0.95,
                ),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor15,
                      blurRadius: 20,
                      offset: const Offset(0, 10),
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
