import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale;

  LocaleProvider(this._locale);

  Locale get locale => _locale;

  Future<void> changeLocale(String languageCode) async {
    _locale = Locale(languageCode);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', languageCode);

    notifyListeners();
  }
}