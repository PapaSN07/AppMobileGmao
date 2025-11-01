import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:appmobilegmao/utils/responsive.dart';
import 'package:appmobilegmao/theme/responsive_spacing.dart';

abstract class Tools extends StatelessWidget {
  const Tools({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }

  static Widget buildVerticalDivider(BuildContext context) {
    final spacing = ResponsiveSpacing.of(context);

    return Container(
      height: spacing.xlarge, // ✅ Hauteur responsive (au lieu de 40)
      width: 1,
      color: const Color.fromRGBO(144, 144, 144, 0.3),
      margin:
          spacing
              .horizontalPadding, // ✅ Margin responsive (au lieu de horizontal: 8)
    );
  }

  static Widget buildStatCard(
    BuildContext context,
    String value,
    String label,
  ) {
    final responsive = Responsive.of(context);
    final spacing = ResponsiveSpacing.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: AppTheme.fontMontserrat,
            fontWeight: FontWeight.bold,
            color: AppTheme.secondaryColor,
            fontSize: responsive.sp(16), // ✅ Texte responsive
          ),
        ),
        SizedBox(
          height: spacing.tiny,
        ), // ✅ Espacement responsive (au lieu de 4)
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.fontRoboto,
            fontWeight: FontWeight.normal,
            color: AppTheme.secondaryColor,
            fontSize: responsive.sp(14), // ✅ Texte responsive
          ),
        ),
      ],
    );
  }

  static Widget buildTextField({
    required BuildContext context,
    required String label,
    required String msgError,
    FocusNode? focusNode,
    TextEditingController? controller,
    bool isRequired = false, // ✅ NOUVEAU: Paramètre pour rendre optionnel
  }) {
    final responsive = Responsive.of(context);

    return TextFormField(
      focusNode: focusNode,
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: AppTheme.secondaryColor,
          fontFamily: AppTheme.fontMontserrat,
          fontWeight: FontWeight.w600,
          fontSize: responsive.sp(14), // ✅ Texte responsive (ajouté)
        ),
        border: const UnderlineInputBorder(),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.thirdColor),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.secondaryColor, width: 2.0),
        ),
      ),
      // ✅ MODIFIÉ: Validation conditionnelle selon isRequired
      validator:
          isRequired
              ? (value) {
                if (value == null || value.isEmpty) {
                  return msgError;
                }
                return null;
              }
              : null, // ✅ Pas de validation si non requis
    );
  }

  static Widget buildText(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final responsive = Responsive.of(context);
    final spacing = ResponsiveSpacing.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: spacing.tiny,
        ), // ✅ Espacement responsive (au lieu de 5)
        Text(
          label,
          style: TextStyle(
            color: AppTheme.secondaryColor,
            fontFamily: AppTheme.fontMontserrat,
            fontWeight: FontWeight.w600,
            fontSize: responsive.sp(12), // ✅ Texte responsive
          ),
        ),
        SizedBox(
          height: spacing.tiny,
        ), // ✅ Espacement responsive (au lieu de 2)
        Text(
          value.isNotEmpty ? value : '------',
          style: TextStyle(
            color:
                value.isNotEmpty
                    ? AppTheme.secondaryColor
                    : AppTheme.thirdColor,
            fontFamily: AppTheme.fontMontserrat,
            fontWeight: FontWeight.normal,
            fontSize: responsive.sp(16), // ✅ Texte responsive
          ),
        ),
        SizedBox(
          height: spacing.small,
        ), // ✅ Espacement responsive (au lieu de 8)
        Container(
          height: 1,
          width: double.infinity,
          color: AppTheme.thirdColor,
        ),
      ],
    );
  }

  static Widget buildFieldset(BuildContext context, String title) {
    final responsive = Responsive.of(context);
    final spacing = ResponsiveSpacing.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: AppTheme.fontMontserrat,
            fontWeight: FontWeight.bold,
            color: AppTheme.secondaryColor,
            fontSize: responsive.sp(18), // ✅ Texte responsive
          ),
        ),
        SizedBox(width: spacing.tiny), // ✅ Espacement responsive (au lieu de 5)
        Expanded(
          child: Container(
            height: 1,
            width: double.infinity,
            color: AppTheme.thirdColor,
            margin: EdgeInsets.only(
              top: spacing.medium,
            ), // ✅ Margin responsive (au lieu de top: 10)
          ),
        ),
      ],
    );
  }
}
