import 'package:flutter/material.dart';

import '../services/language_service.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');
  bool _isLoading = true;

  Locale get locale => _locale;
  bool get isLoading => _isLoading;

  // ============================================================
  // INIT — load saved language
  // ============================================================

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final saved = await LanguageService.loadLanguage();

      if (saved != null && saved.isNotEmpty) {
        _locale = Locale(saved);
      }
    } catch (_) {
      // fallback to English
      _locale = const Locale('en');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ============================================================
  // CHANGE LANGUAGE
  // ============================================================

  Future<void> changeLanguage(String languageCode) async {
    if (_locale.languageCode == languageCode) return;

    _locale = Locale(languageCode);
    notifyListeners();

    await LanguageService.saveLanguage(languageCode);
  }

  // ============================================================
  // HELPERS
  // ============================================================

  bool get isHindi => _locale.languageCode == 'hi';
  bool get isEnglish => _locale.languageCode == 'en';

  String get currentLanguageName {
    return isHindi ? 'हिंदी' : 'English';
  }
}