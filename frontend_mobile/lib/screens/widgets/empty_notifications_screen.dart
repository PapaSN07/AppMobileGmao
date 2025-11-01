import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class EmptyNotificationsScreen extends StatefulWidget {
  const EmptyNotificationsScreen({super.key, this.onRefresh});

  final Future<void> Function()? onRefresh; // ✅ Changer en Future pour async

  @override
  State<EmptyNotificationsScreen> createState() =>
      _EmptyNotificationsScreenState();
}

class _EmptyNotificationsScreenState extends State<EmptyNotificationsScreen> {
  bool _isLoading = false;

  Future<void> _handleRefresh() async {
    if (widget.onRefresh == null || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      await widget.onRefresh!();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Spacer(flex: 2),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: SvgPicture.asset(
                    'assets/images/empty_notifications.svg',
                    fit: BoxFit.scaleDown,
                  ),
                ),
              ),
              const Spacer(flex: 2),
              ErrorInfo(
                title: "Aucune notification",
                description:
                    "Il semble que vous n'ayez aucune notification pour le moment. Nous vous informerons lorsqu'il y aura du nouveau.",
                btnText: "Vérifier à nouveau",
                press: _handleRefresh,
                isLoading: _isLoading, // ✅ Passer l'état de chargement
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ErrorInfo extends StatelessWidget {
  const ErrorInfo({
    super.key,
    required this.title,
    required this.description,
    this.button,
    this.btnText,
    required this.press,
    this.isLoading = false, // ✅ Ajouter un paramètre isLoading
  });

  final String title;
  final String description;
  final Widget? button;
  final String? btnText;
  final VoidCallback press;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        alignment: Alignment.center,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.secondaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.thirdColor),
            ),
            const SizedBox(height: 16 * 2.5),
            button ??
                ElevatedButton(
                  onPressed:
                      isLoading ? null : press, // ✅ Désactiver si en chargement
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    backgroundColor: AppTheme.secondaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppTheme.thirdColor30, // ✅ Couleur désactivée
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                  ),
                  child:
                      isLoading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : Text(btnText ?? "Réessayer".toUpperCase()),
                ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
