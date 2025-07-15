import 'package:flutter/material.dart';
import 'dart:ui'; // Import nécessaire pour ImageFilter
import 'package:appmobilegmao/theme/app_theme.dart';

class CustomOverlay extends StatelessWidget {
  final Widget content; // Contenu à afficher dans l'overlay
  final VoidCallback onClose; // Action pour fermer l'overlay

  const CustomOverlay({super.key, required this.content, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose, // Fermer l'overlay lorsqu'on clique sur l'arrière-plan
      child: Stack(
        children: [
          // Effet de flou sur l'arrière-plan
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 10,
                sigmaY: 10,
              ), // Intensité du flou
              child: Container(
                color: AppTheme.primaryColor15, // Couleur semi-transparente
              ),
            ),
          ),
          // Contenu de l'overlay centré
          Center(
            child: GestureDetector(
              onTap:
                  () {}, // Empêche la fermeture lorsqu'on clique sur le contenu
              child: Container(
                width:
                    MediaQuery.of(context).size.width *
                    0.85, // Largeur relative
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor,
                  borderRadius: BorderRadius.circular(20), // Coins arrondis
                ),
                child: content, // Contenu dynamique
              ),
            ),
          ),
        ],
      ),
    );
  }
}
