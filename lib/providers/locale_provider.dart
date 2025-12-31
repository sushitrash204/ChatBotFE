import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider with ChangeNotifier {
  static const String _localeKey = 'selected_locale';
  Locale _locale = const Locale('en');

  final List<Map<String, dynamic>> supportedLanguages = [
    {'name': 'English', 'code': 'en'},
    {'name': 'Tiếng Việt', 'code': 'vi'},
    {'name': 'Español', 'code': 'es'},
    {'name': 'Français', 'code': 'fr'},
    {'name': 'Deutsch', 'code': 'de'},
    {'name': '中文', 'code': 'zh'},
  ];

  Locale get locale => _locale;

  LocaleProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    String? languageCode = prefs.getString(_localeKey);
    if (languageCode != null) {
      _locale = Locale(languageCode);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (!supportedLanguages.any((lang) => lang['code'] == locale.languageCode)) return;
    
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
    notifyListeners();
  }
}
