import 'package:appmobilegmao/provider/auth_provider.dart';
import 'package:appmobilegmao/screens/equipments/history_equipment_screen.dart';
import 'package:appmobilegmao/screens/main_screen.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:appmobilegmao/utils/responsive.dart';
import 'package:appmobilegmao/theme/responsive_spacing.dart';

class UnderMaintenanceScreen extends StatelessWidget {
  const UnderMaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final spacing = context.spacing;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: spacing.allPadding, // ✅ Padding responsive
          child: Column(
            children: [
              const Spacer(flex: 2),
              SizedBox(
                width: responsive.wp(80), // ✅ Largeur responsive
                child: AspectRatio(
                  aspectRatio: 1,
                  child: SvgPicture.asset(
                    'assets/images/under_maintenance.svg',
                    fit: BoxFit.scaleDown,
                  ),
                ),
              ),
              const Spacer(flex: 2),
              ErrorInfo(
                title: "Site en maintenance",
                description:
                    "Nous effectuons actuellement une maintenance planifiée. Veuillez revenir plus tard. Merci de votre patience.",
                // button: you can pass your custom button,
                btnText: "Accueil",
                press: () {
                  if (authProvider.isPrestataire) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const HistoryEquipmentScreen(),
                      ),
                    );
                  } else {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const MainScreen(),
                      ),
                    );
                  }
                },
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
  });

  final String title;
  final String description;
  final Widget? button;
  final String? btnText;
  final VoidCallback press;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final spacing = context.spacing;

    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: responsive.maxContentWidth,
        ), // ✅ Largeur max responsive
        alignment: Alignment.center,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: responsive.sp(24), // ✅ Texte responsive
              ),
            ),
            SizedBox(height: spacing.medium), // ✅ Espacement responsive
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: responsive.sp(14),
              ), // ✅ Texte responsive
            ),
            SizedBox(height: spacing.xlarge), // ✅ Espacement responsive
            button ??
                ElevatedButton(
                  onPressed: press,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(
                      double.infinity,
                      responsive.spacing(48),
                    ), // ✅ Hauteur responsive
                    backgroundColor: AppTheme.secondaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(responsive.spacing(8)),
                      ), // ✅ Border radius responsive
                    ),
                  ),
                  child: Text(btnText ?? "Retry".toUpperCase()),
                ),
            SizedBox(height: spacing.medium), // ✅ Espacement responsive
          ],
        ),
      ),
    );
  }
}
