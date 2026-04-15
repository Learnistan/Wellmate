import 'package:flutter/material.dart';
import 'colors.dart';

class AppTextStyles {
  static const title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static TextStyle semiBold(Locale locale) {
    final isRTL = locale.languageCode == 'fa' || locale.languageCode == 'ps';

    return TextStyle(
      fontFamily: isRTL ? 'Vazirmatn' : 'Yaldevi',
      fontWeight: FontWeight.w600,
      fontSize: 16,
    );
  }
}