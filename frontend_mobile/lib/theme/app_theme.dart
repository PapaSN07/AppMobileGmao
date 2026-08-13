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
  // Senelec Brand Colors (Charte Graphique 2017)
  static const Color senelecReflexBlue = Color(0xFF0F1B80); // Reflex Blue C
  static const Color senelecIndigo = Color(0xFF2B1D4C); // Pantone 2695 C
  static const Color senelecMagenta = Color(0xFFA20067); // Pantone 234 C
  static const Color senelecOrange = Color(0xFFFF5800); // Pantone 021 C
  static const Color senelecTeal = Color(0xFF007A87); // Pantone 7474 C
  static const Color senelecYellow = Color(0xFFFFD100); // Pantone 109 C

  static const Color secondaryColor = senelecReflexBlue;
  static const Color secondaryColor10 = Color(0x1A0F1B80);
  static const Color secondaryColor20 = Color(0x330F1B80);
  static const Color secondaryColor30 = Color(0x4D0F1B80);
  static const Color secondaryColor70 = Color(0xB30F1B80);
  static const Color secondaryColor80 = Color(0xCC0F1B80);
  static const Color thirdColor = Color.fromRGBO(144, 144, 144, 1);
  static const Color thirdColor10 = Color.fromRGBO(144, 144, 144, 0.1);
  static const Color thirdColor20 = Color.fromRGBO(144, 144, 144, 0.2);
  static const Color thirdColor30 = Color.fromRGBO(144, 144, 144, 0.3);
  static const Color thirdColor50 = Color.fromRGBO(144, 144, 144, 0.5);
  static const Color thirdColor60 = Color.fromRGBO(144, 144, 144, 0.6);
  static const Color blurColor = Color.fromRGBO(196, 196, 196, 0.25);
  static const Color boxShadowColor = Color.fromRGBO(0, 0, 0, 0.25);

  // Nouvelles couleurs pour les notifications & statuts
  static const Color successColor = senelecTeal;
  static const Color successColorDark = Color(0xFF005E68);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color errorColorDark = Color(0xFFDC2626);
  static const Color warningColor = senelecOrange;
  static const Color warningColor10 = Color(0x1AFF5800);
  static const Color warningColorDark = Color(0xFFCC4600);
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
