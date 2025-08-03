import 'package:appmobilegmao/services/hive_service.dart';
import 'package:flutter/material.dart';
import 'package:appmobilegmao/services/auth_service.dart';
import 'package:appmobilegmao/screens/auth/login_screen.dart';
import 'package:appmobilegmao/theme/app_theme.dart';

class LogoutButton extends StatelessWidget {
  final bool showIcon;
  final String? customText;

  const LogoutButton({super.key, this.showIcon = true, this.customText});

  Future<void> _handleLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Déconnexion'),
            content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Déconnecter'),
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
              content: Text('Erreur lors de la déconnexion: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _handleLogout(context),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon) ...[
              Icon(Icons.logout, color: AppTheme.secondaryColor, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              customText ?? 'Déconnexion',
              style: TextStyle(
                color: AppTheme.secondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
