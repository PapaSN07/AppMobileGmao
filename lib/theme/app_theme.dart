import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color.fromRGBO(255, 255, 255, 1);
  static const Color primaryColor75 = Color.fromRGBO(255, 255, 255, 0.75);
  static const Color primaryColor15 = Color.fromRGBO(255, 255, 255, 0.15);
  static const Color secondaryColor = Color.fromRGBO(1, 92, 192, 1);
  static const Color thirdColor = Color.fromRGBO(144, 144, 144, 1);
  static const Color blurColor = Color.fromRGBO(196, 196, 196, 0.25);

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
}
