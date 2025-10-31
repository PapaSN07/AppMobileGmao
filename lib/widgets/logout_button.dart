import 'package:appmobilegmao/services/hive_service.dart';
import 'package:flutter/material.dart';
import 'package:appmobilegmao/services/auth_service.dart';
import 'package:appmobilegmao/screens/auth/login_screen.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/utils/responsive.dart';
import 'package:appmobilegmao/theme/responsive_spacing.dart';

class LogoutButton extends StatelessWidget {
  final bool showIcon;
  final String? customText;

  const LogoutButton({super.key, this.showIcon = true, this.customText});

  Future<void> _handleLogout(BuildContext context) async {
    final responsive = context.responsive;
    final spacing = context.spacing;

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Déconnexion',
              style: TextStyle(
                fontFamily: AppTheme.fontMontserrat,
                fontSize: responsive.sp(20),
              ), // ✅ Titre responsive
            ),
            content: Text(
              'Êtes-vous sûr de vouloir vous déconnecter ?',
              style: TextStyle(
                fontFamily: AppTheme.fontRoboto,
                fontSize: responsive.sp(14),
              ), // ✅ Contenu responsive
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Annuler',
                  style: TextStyle(
                    fontFamily: AppTheme.fontMontserrat,
                    fontSize: responsive.sp(14),
                  ), // ✅ Bouton responsive
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: spacing.custom(
                    horizontal: 16,
                    vertical: 8,
                  ), // ✅ Padding responsive
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      responsive.spacing(8),
                    ), // ✅ Border radius responsive
                  ),
                ),
                child: Text(
                  'Déconnecter',
                  style: TextStyle(
                    fontFamily: AppTheme.fontMontserrat,
                    fontSize: responsive.sp(14),
                  ), // ✅ Bouton responsive
                ),
              ),
            ],
          ),
    );

    if (shouldLogout == true && context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final authService = AuthService();
        final user = HiveService.getCurrentUser();
        await authService.logout(user!.username);

        if (context.mounted) {
          Navigator.of(context).pop(); // Fermer le dialog de chargement

          Navigator.of(context).pushAndRemoveUntil(
            PageRouteBuilder(
              pageBuilder:
                  (context, animation, secondaryAnimation) =>
                      const LoginScreen(),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 300),
            ),
            (route) => false,
          );
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.of(context).pop(); // Fermer le dialog de chargement

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Erreur lors de la déconnexion: $e',
                style: TextStyle(
                  fontFamily: AppTheme.fontRoboto,
                  fontSize: responsive.sp(14),
                ), // ✅ SnackBar responsive
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final spacing = context.spacing;

    return InkWell(
      onTap: () => _handleLogout(context),
      borderRadius: BorderRadius.circular(
        responsive.spacing(8),
      ), // ✅ Border radius responsive
      child: Padding(
        padding: spacing.custom(
          horizontal: 12,
          vertical: 8,
        ), // ✅ Padding responsive
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon) ...[
              Icon(
                Icons.logout,
                color: AppTheme.secondaryColor,
                size: responsive.iconSize(20), // ✅ Icône responsive
              ),
              SizedBox(width: spacing.small), // ✅ Espacement responsive
            ],
            Text(
              customText ?? 'Déconnexion',
              style: TextStyle(
                color: AppTheme.secondaryColor,
                fontWeight: FontWeight.w500,
                fontSize: responsive.sp(14), // ✅ Texte responsive
              ),
            ),
          ],
        ),
      ),
    );
  }
}
