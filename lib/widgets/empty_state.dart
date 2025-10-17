import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/widgets/custom_buttons.dart'; // Ajout de l'import
import 'package:flutter/material.dart';
import 'package:appmobilegmao/utils/responsive.dart';
import 'package:appmobilegmao/theme/responsive_spacing.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onRetry;
  final String? retryButtonText;

  const EmptyState({
    super.key,
    this.title = 'Aucun résultat trouvé',
    this.message = 'Aucun équipement ne correspond à votre recherche.',
    this.icon = Icons.search_off,
    this.onRetry,
    this.retryButtonText = 'Réessayer',
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final spacing = context.spacing;

    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: spacing.custom(all: 32), // ✅ Padding responsive
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icône avec animation
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: responsive.spacing(100), // ✅ Largeur responsive
                      height: responsive.spacing(100), // ✅ Hauteur responsive
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor15,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.thirdColor,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        icon,
                        size: responsive.iconSize(50), // ✅ Icône responsive
                        color: AppTheme.thirdColor,
                      ),
                    ),
                  );
                },
              ),

              SizedBox(height: spacing.large), // ✅ Espacement responsive
              // Titre
              Text(
                title,
                style: TextStyle(
                  fontFamily: AppTheme.fontMontserrat,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondaryColor,
                  fontSize: responsive.sp(20), // ✅ Texte responsive
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: spacing.medium), // ✅ Espacement responsive
              // Message
              Text(
                message,
                style: TextStyle(
                  fontFamily: AppTheme.fontRoboto,
                  fontWeight: FontWeight.normal,
                  color: AppTheme.thirdColor,
                  fontSize: responsive.sp(16), // ✅ Texte responsive
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: spacing.large), // ✅ Espacement responsive
              // Bouton optionnel
              if (onRetry != null)
                PrimaryButton(
                  text: retryButtonText!,
                  onPressed: onRetry,
                  icon: Icons.refresh,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
