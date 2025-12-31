import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/voice_chat_screen.dart';
import 'screens/text_chat_screen.dart';
import 'screens/translate_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'screens/settings_screen.dart';
import 'package:lamp_flutter_app/l10n/app_localizations.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: const LampApp(),
    ),
  );
}

class LampApp extends StatelessWidget {
  const LampApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final currentTheme = themeProvider.currentTheme;

    return MaterialApp(
      title: 'BotCuaThuy',
      debugShowCheckedModeBanner: false,
      locale: localeProvider.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        brightness: currentTheme.isDark ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: currentTheme.backgroundColor,
        primaryColor: currentTheme.primaryColor,
        canvasColor: currentTheme.backgroundColor,
        colorScheme: currentTheme.isDark 
          ? ColorScheme.dark(
              primary: currentTheme.primaryColor,
              secondary: currentTheme.accentColor,
              surface: currentTheme.cardColor,
            )
          : ColorScheme.light(
              primary: currentTheme.primaryColor,
              secondary: currentTheme.accentColor,
              surface: currentTheme.cardColor,
            ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: currentTheme.textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: currentTheme.textColor),
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: currentTheme.textColor),
          bodyMedium: TextStyle(color: currentTheme.textColor),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          VoiceChatScreen(),
          TextChatScreen(),
          TranslateScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Provider.of<ThemeProvider>(context).currentTheme.cardColor,
        selectedItemColor: Provider.of<ThemeProvider>(context).currentTheme.primaryColor,
        unselectedItemColor: Provider.of<ThemeProvider>(context).currentTheme.secondaryTextColor,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.mic),
            label: l10n.voice,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.chat),
            label: l10n.text,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.translate),
            label: l10n.translate,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: l10n.settingsTab,
          ),
        ],
      ),
    );
  }
}
