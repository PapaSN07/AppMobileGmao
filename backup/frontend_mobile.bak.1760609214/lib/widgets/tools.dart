import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:flutter/material.dart';

abstract class Tools extends StatelessWidget {
  const Tools({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }

  static Widget buildVerticalDivider() {
    return Container(
      height: 40,
      width: 1,
      color: const Color.fromRGBO(144, 144, 144, 0.3),
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  static buildStatCard(String value, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: AppTheme.fontMontserrat,
            fontWeight: FontWeight.bold,
            color: AppTheme.secondaryColor,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.fontRoboto,
            fontWeight: FontWeight.normal,
            color: AppTheme.secondaryColor,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  static Widget buildTextField({
    required String label,
    required String msgError,
    FocusNode? focusNode,
    TextEditingController? controller,
    bool isRequired = false, // ✅ NOUVEAU: Paramètre pour rendre optionnel
  }) {
    return TextFormField(
      focusNode: focusNode,
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: AppTheme.secondaryColor,
          fontFamily: AppTheme.fontMontserrat,
          fontWeight: FontWeight.w600,
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

  static Widget buildText({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.secondaryColor,
            fontFamily: AppTheme.fontMontserrat,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value.isNotEmpty ? value : '------',
          style: TextStyle(
            color:
                value.isNotEmpty
                    ? AppTheme.secondaryColor
                    : AppTheme.thirdColor,
            fontFamily: AppTheme.fontMontserrat,
            fontWeight: FontWeight.normal,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 1,
          width: double.infinity,
          color: AppTheme.thirdColor,
        ),
      ],
    );
  }

  static Widget buildFieldset(String title) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: AppTheme.fontMontserrat,
            fontWeight: FontWeight.bold,
            color: AppTheme.secondaryColor,
            fontSize: 18,
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Container(
            height: 1,
            width: double.infinity,
            color: AppTheme.thirdColor,
            margin: const EdgeInsets.only(top: 10),
          ),
        ),
      ],
    );
  }
}