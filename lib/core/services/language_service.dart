import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static const String _keyLanguage = 'app_language';

  // ============================================================
  // SAVE LANGUAGE
  // ============================================================

  static Future<void> saveLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, languageCode);
  }

  // ============================================================
  // LOAD LANGUAGE
  // ============================================================

  static Future<String?> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLanguage);
  }

  // ============================================================
  // CHECK IF LANGUAGE IS SET (first launch)
  // ============================================================

  static Future<bool> hasChosenLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyLanguage);
  }

  // ============================================================
  // CLEAR (for logout if needed)
  // ============================================================

  static Future<void> clearLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLanguage);
  }

  // ============================================================
  // SUPPORTED LOCALES
  // ============================================================

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('hi'),
  ];

  static const Locale fallbackLocale = Locale('en');
}