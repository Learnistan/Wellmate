import 'package:flutter/material.dart';

/// Colors for Majlis, built on the WellMate palette (core/theme/colors.dart,
/// wellmate.app) plus jewel tones taken from Afghan tilework and carpets.
class MajlisColors {
  static const cream = Color(0xFFFFFBF6);
  static const paper = Color(0xFFFFFFFF);
  static const blush = Color(0xFFF6E9E4);
  static const sand = Color(0xFFF6EDE6);
  static const rose = Color(0xFFC17A82);
  static const roseDeep = Color(0xFF9E626A);
  static const roseText = Color(0xFF9A5C64);
  static const rosewater = Color(0xFFEBD7D6);
  static const plum = Color(0xFF6E4A55);
  static const night = Color(0xFF2E1F26);
  static const ink = Color(0xFF2A211E);
  static const muted = Color(0xFF74675E);
  static const faint = Color(0xFFB3A69C);
  static const line = Color(0xFFEFE4DA);
  static const saffron = Color(0xFFC8893A);
  static const saffronSoft = Color(0xFFFBF0DD);
  static const gold = Color(0xFFD9B26F);
  static const goldSoft = Color(0xFFF3E3C3);
  static const goldLine = Color(0xFFC7A86E);
  static const live = Color(0xFFD9475C);
}

/// One jewel tone: a deep color, a mid tone and a light wash.
class MajlisJewel {
  final Color deep;
  final Color mid;
  final Color light;
  const MajlisJewel(this.deep, this.mid, this.light);
}

class MajlisJewels {
  static const lapis = MajlisJewel(Color(0xFF2F4F7A), Color(0xFF7E9CC4), Color(0xFFE6ECF4));
  static const turquoise = MajlisJewel(Color(0xFF2B6E6B), Color(0xFF79B4AE), Color(0xFFDFEFED));
  static const saffron = MajlisJewel(Color(0xFFA0631D), Color(0xFFE2B26A), Color(0xFFF8EDDC));
  static const pomegranate = MajlisJewel(Color(0xFF953344), Color(0xFFD98A96), Color(0xFFF7E3E5));
  static const plum = MajlisJewel(Color(0xFF6E4A55), Color(0xFFB48E9A), Color(0xFFF1E7EA));
  static const sage = MajlisJewel(Color(0xFF4F6B4A), Color(0xFFA2BB9A), Color(0xFFE7EFE4));
  static const rose = MajlisJewel(Color(0xFF9E5B65), Color(0xFFDDA2A8), Color(0xFFF7E9E7));
  static const walnut = MajlisJewel(Color(0xFF74553C), Color(0xFFC4A383), Color(0xFFF2EAE1));

  static const all = [lapis, turquoise, saffron, pomegranate, plum, sage, rose, walnut];
}

class MajlisText {
  static const _fallback = ['Vazirmatn'];

  /// True while the app shows Dari or Pashto. Arabic-script letters join, so
  /// letter spacing must stay at 0 and lines need a little more height.
  static bool arabicScript = false;

  static void setLanguage(String code) => arabicScript = code == 'fa' || code == 'ps';

  static double _h(double h) => arabicScript ? (h < 1.5 ? 1.5 : h) : h;

  /// How much the phone's text-size setting grows body text. Measured at a
  /// body size because Android 14+ grows large sizes less than small ones.
  static double grow(BuildContext context) => MediaQuery.textScalerOf(context).scale(14) / 14;
  static double _s(double s) => arabicScript ? 0 : s;

  /// Headings use the app's English font (Yaldevi) and fall back to
  /// Vazirmatn for Dari and Pashto.
  static TextStyle head(
    double size, {
    Color color = MajlisColors.ink,
    FontWeight weight = FontWeight.w600,
    double height = 1.15,
    double spacing = -0.2,
  }) =>
      TextStyle(
        fontFamily: arabicScript ? 'Vazirmatn' : 'Yaldevi',
        fontFamilyFallback: _fallback,
        fontSize: arabicScript ? size * 0.9 : size,
        fontWeight: weight,
        color: color,
        height: _h(height),
        letterSpacing: _s(spacing),
      );

  static TextStyle body(
    double size, {
    Color color = MajlisColors.ink,
    FontWeight weight = FontWeight.w400,
    double height = 1.35,
  }) =>
      TextStyle(
        fontFamily: arabicScript ? 'Vazirmatn' : null,
        fontFamilyFallback: _fallback,
        fontSize: arabicScript ? size * 0.95 : size,
        fontWeight: weight,
        color: color,
        height: _h(height),
      );

  /// Small label, e.g. "ON THE CARPET".
  static TextStyle eyebrow({Color color = MajlisColors.muted}) => TextStyle(
        fontFamily: arabicScript ? 'Vazirmatn' : null,
        fontFamilyFallback: _fallback,
        fontSize: arabicScript ? 12 : 11,
        fontWeight: FontWeight.w700,
        letterSpacing: arabicScript ? 0 : 1.2,
        color: color,
        height: arabicScript ? 1.5 : 1.2,
      );

  /// Uppercase only where the script has case.
  static String caps(String text) => arabicScript ? text : text.toUpperCase();
}
