import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData buildTheme(Locale locale) {
    String fontFamily;

    switch (locale.languageCode) {
      case 'fa': // Dari
      case 'ps': // Pashto
        fontFamily = 'NotoNaskhArabic';
        break;
      case 'en':
      default:
        fontFamily = 'Roboto';
    }

    return ThemeData(
        fontFamily: fontFamily,
        textTheme: ThemeData
            .light()
            .textTheme
            .apply(
            fontFamily: fontFamily
        ),
        primarySwatch: Colors.blue,
        useMaterial3: true
    );
  }
}