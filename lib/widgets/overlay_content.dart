import 'package:flutter/material.dart';
import 'package:appmobilegmao/theme/app_theme.dart';

class OverlayContent extends StatelessWidget {
  final String title;
  final Map<String, String>
  details; // Détails dynamiques sous forme de clé-valeur

  const OverlayContent({super.key, required this.title, required this.details});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min, // Ajuste la taille du contenu
      children: [
        Row(
          children: [
            SizedBox(
              width: 64, // Largeur fixe
              height: 34, // Hauteur fixe
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Fermer l'overlay
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: EdgeInsets.zero, // Supprime les marges internes
                ),
                child: Icon(
                  Icons.arrow_back,
                  size: 20, // Taille de l'icône
                  color: AppTheme.secondaryColor,
                ),
              ),
            ),
            SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontFamily: AppTheme.fontMontserrat,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: AppTheme.primaryColor,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
        SizedBox(height: 30),
        ...details.entries.map(
          (entry) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.key,
                style: TextStyle(
                  fontFamily: AppTheme.fontMontserrat,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: AppTheme.primaryColor,
                  decoration: TextDecoration.none,
                ),
              ),
              SizedBox(height: 10),
              Text(
                entry.value,
                style: TextStyle(
                  fontFamily: AppTheme.fontRoboto,
                  fontWeight: FontWeight.normal,
                  fontSize: 14,
                  color: AppTheme.primaryColor,
                  decoration: TextDecoration.none,
                ),
              ),
              Divider(
                color: AppTheme.primaryColor15, // Couleur du trait
                thickness: 1, // Épaisseur du trait
                indent: 0, // Espacement à gauche
                endIndent: 0, // Espacement à droite
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }
}
