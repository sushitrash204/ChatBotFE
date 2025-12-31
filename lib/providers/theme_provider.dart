import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  final String name;
  final Color primaryColor;
  final Color accentColor;
  final Color backgroundColor;
  final Color cardColor;
  final Color textColor;
  final Color secondaryTextColor;
  final LinearGradient gradient;
  final bool isDark;

  AppTheme({
    required this.name,
    required this.primaryColor,
    required this.accentColor,
    required this.backgroundColor,
    required this.cardColor,
    required this.textColor,
    required this.secondaryTextColor,
    required this.gradient,
    this.isDark = true,
  });
}

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'selected_theme_index';
  int _currentThemeIndex = 0;

  final List<AppTheme> themes = [
    AppTheme(
      name: 'EchoBlue',
      primaryColor: const Color(0xFF00BFA5), // Deep Teal
      accentColor: const Color(0xFF00E5FF),  // Bright Cyan
      backgroundColor: const Color(0xFFF0F9F9),
      cardColor: Colors.white,
      textColor: const Color(0xFF1D2E2E),
      secondaryTextColor: const Color(0xFF455A64),
      gradient: const LinearGradient(colors: [Color(0xFF00BFA5), Color(0xFF00E5FF)]),
      isDark: false,
    ),
    AppTheme(
      name: 'Classic Midnight',
      primaryColor: const Color(0xFF667EEA),
      accentColor: const Color(0xFF764BA2),
      backgroundColor: const Color(0xFF15161A),
      cardColor: const Color(0xFF2D2F33),
      textColor: Colors.white,
      secondaryTextColor: Colors.white70,
      gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
    ),
    AppTheme(
      name: 'Midnight Blue',
      primaryColor: const Color(0xFF1E3A8A),
      accentColor: const Color(0xFF3B82F6),
      backgroundColor: const Color(0xFF0F172A),
      cardColor: const Color(0xFF1E293B),
      textColor: Colors.white,
      secondaryTextColor: Colors.white70,
      gradient: const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)]),
    ),
    AppTheme(
      name: 'Sunset Red',
      primaryColor: const Color(0xFF7F1D1D),
      accentColor: const Color(0xFFEF4444),
      backgroundColor: const Color(0xFF1A0B0B),
      cardColor: const Color(0xFF271010),
      textColor: Colors.white,
      secondaryTextColor: Colors.white70,
      gradient: const LinearGradient(colors: [Color(0xFF7F1D1D), Color(0xFFEF4444)]),
    ),
    AppTheme(
      name: 'RoseGold',
      primaryColor: const Color(0xFFF06292), // Soft Rose
      accentColor: const Color(0xFFFFB74D),  // Peach Gold
      backgroundColor: const Color(0xFFFFF5F8), // Pale Pink tint
      cardColor: Colors.white,
      textColor: const Color(0xFF4A148C), // Deep Purple text
      secondaryTextColor: const Color(0xFF880E4F),
      gradient: const LinearGradient(colors: [Color(0xFFF06292), Color(0xFFFFB74D)]),
      isDark: false,
    ),
    AppTheme(
      name: 'Arctic White',
      primaryColor: const Color(0xFF607D8B), // Slate Grey
      accentColor: const Color(0xFF81D4FA),  // Sky Blue
      backgroundColor: const Color(0xFFF5F7FA), // Pure clean background
      cardColor: Colors.white,
      textColor: const Color(0xFF263238), // Dark Blue Grey text
      secondaryTextColor: const Color(0xFF546E7A),
      gradient: const LinearGradient(colors: [Color(0xFF607D8B), Color(0xFF81D4FA)]),
      isDark: false,
    ),
  ];

  int get currentThemeIndex => _currentThemeIndex;
  AppTheme get currentTheme => themes[_currentThemeIndex];

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _currentThemeIndex = prefs.getInt(_themeKey) ?? 0;
    notifyListeners();
  }

  Future<void> setTheme(int index) async {
    if (index >= 0 && index < themes.length) {
      _currentThemeIndex = index;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, index);
      notifyListeners();
    }
  }
}
