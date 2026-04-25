import 'package:flutter/material.dart';
import 'colors.dart';
import 'appFonts.dart';

class AppTextStyles {
  static const title = TextStyle(
    fontSize: 20,
  //  fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static TextStyle semiBold(Locale locale) {
    final isRTL = locale.languageCode == 'fa' || locale.languageCode == 'ps';

    return TextStyle(
      fontFamily: isRTL ? AppFonts.dari : AppFonts.english,
      fontWeight: FontWeight.w600,
      fontSize: 16,
      color: AppColors.textPrimary
    );
  }

  static TextStyle introTitle(Locale locale) {
    final isRTL = locale.languageCode == 'fa' || locale.languageCode == 'ps';

    return TextStyle(
      fontFamily: isRTL ? AppFonts.dari : AppFonts.english,
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
    );
  }

  static TextStyle introDesc(Locale locale) {
    final isRTL = locale.languageCode == 'fa' || locale.languageCode == 'ps';

    return TextStyle(
      fontFamily: isRTL ? AppFonts.dari : AppFonts.english,
      fontSize: 20,
      fontWeight: FontWeight.normal,
      color: AppColors.textSecondary,
    );
  }
}