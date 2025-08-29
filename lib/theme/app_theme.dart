import 'package:flutter/material.dart';

class AppTheme {
  // Couleurs principales existantes
  static const Color primaryColor = Color.fromRGBO(255, 255, 255, 1);
  static const Color primaryColor75 = Color.fromRGBO(255, 255, 255, 0.75);
  static const Color primaryColor50 = Color.fromRGBO(255, 255, 255, 0.5);
  static const Color primaryColor30 = Color.fromRGBO(255, 255, 255, 0.3);
  static const Color primaryColor20 = Color.fromRGBO(255, 255, 255, 0.2);
  static const Color primaryColor15 = Color.fromRGBO(255, 255, 255, 0.15);
  static const Color primaryColor10 = Color.fromRGBO(255, 255, 255, 0.1);
  static const Color secondaryColor = Color.fromRGBO(1, 92, 192, 1);
  static const Color secondaryColor10 = Color.fromRGBO(1, 92, 192, 0.1);
  static const Color secondaryColor20 = Color.fromRGBO(1, 92, 192, 0.2);
  static const Color secondaryColor30 = Color.fromRGBO(1, 92, 192, 0.3);
  static const Color secondaryColor70 = Color.fromRGBO(1, 92, 192, 0.7);
  static const Color secondaryColor80 = Color.fromRGBO(1, 92, 192, 0.8);
  static const Color thirdColor = Color.fromRGBO(144, 144, 144, 1);
  static const Color thirdColor20 = Color.fromRGBO(144, 144, 144, 0.2);
  static const Color thirdColor30 = Color.fromRGBO(144, 144, 144, 0.3);
  static const Color thirdColor50 = Color.fromRGBO(144, 144, 144, 0.5);
  static const Color thirdColor60 = Color.fromRGBO(144, 144, 144, 0.6);
  static const Color blurColor = Color.fromRGBO(196, 196, 196, 0.25);
  static const Color boxShadowColor = Color.fromRGBO(0, 0, 0, 0.25);

  // Nouvelles couleurs pour les notifications
  static const Color successColor = Color(0xFF10B981);
  static const Color successColorDark = Color(0xFF059669);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color errorColorDark = Color(0xFFDC2626);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color warningColorDark = Color(0xFFD97706);
  static const Color infoColor =
      secondaryColor; // Utilise la couleur secondaire existante
  static const Color infoColorDark = Color.fromRGBO(1, 82, 172, 1);

  // Couleurs d'overlay pour les notifications
  static const Color overlayBackgroundColor = Color.fromRGBO(0, 0, 0, 0.3);
  static const Color notificationShadowColor = Color.fromRGBO(0, 0, 0, 0.15);

  // Font styles
  static const String fontMontserrat = 'Montserrat';
  static const String fontRoboto = 'Roboto';

  // Text styles
  static const TextStyle headline1 = TextStyle(
    fontFamily: fontMontserrat,
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: secondaryColor,
  );

  static const TextStyle bodyText1 = TextStyle(
    fontFamily: fontRoboto,
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: thirdColor,
  );

  static const TextStyle bodyText2 = TextStyle(
    fontFamily: fontRoboto,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: thirdColor,
  );

  // Styles pour les notifications
  static const TextStyle notificationTitle = TextStyle(
    fontFamily: fontMontserrat,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    fontSize: 16,
  );

  static const TextStyle notificationMessage = TextStyle(
    fontFamily: fontRoboto,
    fontWeight: FontWeight.normal,
    color: Colors.white,
    fontSize: 14,
  );

  static const TextStyle notificationAction = TextStyle(
    fontFamily: fontMontserrat,
    fontWeight: FontWeight.w600,
    fontSize: 12,
  );
}
