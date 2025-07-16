import 'package:appmobilegmao/models/order.dart';
import 'package:flutter/material.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/widgets/custom_overlay.dart';
import 'package:appmobilegmao/widgets/overlay_content.dart';

class WorkOrderItem extends StatelessWidget {
  final Order order;
  final Map<String, String> overlayDetails;
  final String overlayTitle;

  const WorkOrderItem({
    super.key,
    required this.order,
    required this.overlayDetails,
    this.overlayTitle = 'Détails',
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Afficher l'overlay plein écran
        showGeneralDialog(
          context: context,
          barrierDismissible: true,
          barrierLabel:
              MaterialLocalizations.of(context).modalBarrierDismissLabel,
          barrierColor: AppTheme.primaryColor15,
          transitionDuration: Duration(milliseconds: 300),
          pageBuilder: (
            BuildContext buildContext,
            Animation animation,
            Animation secondaryAnimation,
          ) {
            return CustomOverlay(
              onClose: () {
                Navigator.of(context).pop(); // Fermer l'overlay
              },
              content: OverlayContent(
                title: overlayTitle,
                details: overlayDetails,
              ),
            );
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.secondaryColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 56, // Taille du cercle
              height: 56, // Taille du cercle
              decoration: BoxDecoration(
                color:
                    AppTheme.primaryColor, // Couleur de fond du cercle (bleu)
                shape: BoxShape.rectangle, // Forme rectangulaire
                borderRadius: BorderRadius.circular(15), // Coins arrondis
              ),
              child: Icon(
                order.icon, // Icône dynamique
                size: 30, // Taille de l'icône
                color: AppTheme.secondaryColor, // Couleur de l'icône (blanc)
              ),
            ),
            SizedBox(width: 10), // Ajout d'espace entre l'icône et les textes
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        spacing: 5,
                        children: [
                          Text(
                            'Code:',
                            style: TextStyle(
                              fontFamily: AppTheme.fontMontserrat,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                              fontSize: 18,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            order.code,
                            style: TextStyle(
                              fontFamily: AppTheme.fontMontserrat,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                              fontSize: 18,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      Transform(
                        transform: Matrix4.rotationZ(-0.785398),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.arrow_back,
                          size: 24,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        spacing: 5,
                        children: [
                          Text(
                            'Famille:',
                            style: TextStyle(
                              fontFamily: AppTheme.fontRoboto,
                              fontWeight: FontWeight.normal,
                              color: AppTheme.primaryColor,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            order.famille,
                            style: TextStyle(
                              fontFamily: AppTheme.fontRoboto,
                              fontWeight: FontWeight.normal,
                              color: AppTheme.primaryColor,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      Row(
                        spacing: 5,
                        children: [
                          Text(
                            'Zone:',
                            style: TextStyle(
                              fontFamily: AppTheme.fontRoboto,
                              fontWeight: FontWeight.normal,
                              color: AppTheme.primaryColor,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            order.zone,
                            style: TextStyle(
                              fontFamily: AppTheme.fontRoboto,
                              fontWeight: FontWeight.normal,
                              color: AppTheme.primaryColor,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        spacing: 5,
                        children: [
                          Text(
                            'Entité:',
                            style: TextStyle(
                              fontFamily: AppTheme.fontRoboto,
                              fontWeight: FontWeight.normal,
                              color: AppTheme.primaryColor,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            order.entity,
                            style: TextStyle(
                              fontFamily: AppTheme.fontRoboto,
                              fontWeight: FontWeight.normal,
                              color: AppTheme.primaryColor,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      Row(
                        spacing: 5,
                        children: [
                          Text(
                            'Unité:',
                            style: TextStyle(
                              fontFamily: AppTheme.fontRoboto,
                              fontWeight: FontWeight.normal,
                              color: AppTheme.primaryColor,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            order.unite,
                            style: TextStyle(
                              fontFamily: AppTheme.fontRoboto,
                              fontWeight: FontWeight.normal,
                              color: AppTheme.primaryColor,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
