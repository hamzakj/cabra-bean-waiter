import 'package:flutter/material.dart';
import '../database/db_helper.dart';

class LocaleProvider with ChangeNotifier {
  Locale _locale = const Locale('ar');

  Locale get locale => _locale;
  String get langCode => _locale.languageCode;
  bool get isArabic => _locale.languageCode == 'ar';

  LocaleProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final saved = await DBHelper.instance.getSetting('language', defaultValue: 'ar');
    _locale = Locale(saved);
    notifyListeners();
  }

  Future<void> setLocale(String langCode) async {
    if (_locale.languageCode == langCode) return;
    _locale = Locale(langCode);
    await DBHelper.instance.setSetting('language', langCode);
    notifyListeners();
  }

  void toggleLocale() {
    final next = isArabic ? 'en' : 'ar';
    setLocale(next);
  }
}
