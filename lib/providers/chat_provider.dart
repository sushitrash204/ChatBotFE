import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/voice_config.dart';

class ChatProvider with ChangeNotifier {
  String _selectedVoice = 'Puck';
  String _selectedLanguageCode = 'vi';

  ChatProvider() {
    _loadSettings();
  }

  String get selectedVoice => _selectedVoice;
  String get selectedLanguageCode => _selectedLanguageCode;

  LanguageOption get currentLanguage => 
      VoiceConfig.languages.firstWhere((l) => l.code == _selectedLanguageCode, 
      orElse: () => VoiceConfig.languages.first);

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedVoice = prefs.getString('selectedVoice') ?? 'Puck';
    _selectedLanguageCode = prefs.getString('selectedLanguageCode') ?? 'vi';
    notifyListeners();
  }

  Future<void> setVoice(String voice) async {
    _selectedVoice = voice;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedVoice', voice);
    notifyListeners();
  }

  Future<void> setLanguage(String langCode) async {
    _selectedLanguageCode = langCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedLanguageCode', langCode);
    notifyListeners();
  }
}
