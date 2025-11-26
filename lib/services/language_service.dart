import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static const String _languageKey = 'app_language';

  /// Get saved locale from SharedPreferences
  Future<Locale?> getSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey);

    if (languageCode == null) {
      return null;
    }

    // Handle Traditional Chinese separately
    if (languageCode == 'zh_TW') {
      return const Locale('zh', 'TW');
    }

    return Locale(languageCode);
  }

  /// Save locale to SharedPreferences
  Future<void> saveLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();

    // Save as 'zh_TW' for Traditional Chinese, otherwise just language code
    final languageCode = locale.countryCode == 'TW'
        ? 'zh_TW'
        : locale.languageCode;

    await prefs.setString(_languageKey, languageCode);
  }

  /// Get list of supported locales
  List<Locale> getSupportedLocales() {
    return const [
      Locale('zh'), // Simplified Chinese
      Locale('zh', 'TW'), // Traditional Chinese
      Locale('en'), // English
    ];
  }

  /// Get display name for a locale
  String getLocaleName(Locale locale) {
    if (locale.languageCode == 'zh' && locale.countryCode == 'TW') {
      return '繁體中文';
    } else if (locale.languageCode == 'zh') {
      return '简体中文';
    } else if (locale.languageCode == 'en') {
      return 'English';
    }
    return locale.languageCode;
  }
}
