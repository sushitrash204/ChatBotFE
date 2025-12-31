import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lamp_flutter_app/l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _changePassword(AppLocalizations l10n) async {
    final oldPass = _oldPasswordController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.fillAllFields)),
      );
      return;
    }

    if (newPass != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.passwordMismatch),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final result = await _authService.changePassword(oldPass, newPass);
    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? (result['success'] ? l10n.success : l10n.error)),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
        ),
      );
      if (result['success']) {
        _oldPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentTheme = themeProvider.currentTheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: currentTheme.backgroundColor,
      appBar: AppBar(
        title: Text(l10n.settings, style: TextStyle(fontWeight: FontWeight.bold, color: currentTheme.textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: currentTheme.textColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Image.asset('assets/images/logo_no_background.png', height: 80),
                  const SizedBox(height: 10),
                  Text('ParrotAI', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: currentTheme.textColor)),
                ],
              ),
            ),
            const SizedBox(height: 30),
            // LANGUAGE SELECTION
            Text(
              l10n.language,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: currentTheme.textColor.withOpacity(0.7)),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: currentTheme.cardColor,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: currentTheme.textColor.withOpacity(0.05)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: localeProvider.locale.languageCode,
                  dropdownColor: currentTheme.cardColor,
                  isExpanded: true,
                  items: localeProvider.supportedLanguages.map((lang) {
                    return DropdownMenuItem<String>(
                      value: lang['code'],
                      child: Text(lang['name'], style: TextStyle(color: currentTheme.textColor)),
                    );
                  }).toList(),
                  onChanged: (code) {
                    if (code != null) localeProvider.setLocale(Locale(code));
                  },
                ),
              ),
            ),

            const SizedBox(height: 30),

            // THEME SELECTION
            Text(
              l10n.appTheme,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: currentTheme.textColor.withOpacity(0.7)),
            ),
            const SizedBox(height: 15),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: themeProvider.themes.length,
                itemBuilder: (context, index) {
                  final theme = themeProvider.themes[index];
                  final isSelected = themeProvider.currentThemeIndex == index;
                  return GestureDetector(
                    onTap: () => themeProvider.setTheme(index),
                    child: Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 15),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: isSelected ? theme.accentColor : Colors.white10,
                          width: 2,
                        ),
                        gradient: theme.gradient,
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Text(
                              theme.name.split(' ').first,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Positioned(
                              top: 5,
                              right: 5,
                              child: Icon(Icons.check_circle, color: Colors.white, size: 20),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 40),

            // PASSWORD CHANGE (Only if logged in)
            if (authProvider.isLoggedIn) ...[
              Text(
                l10n.accountSecurity,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: currentTheme.textColor.withOpacity(0.7)),
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: currentTheme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: currentTheme.textColor.withOpacity(0.05)),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _oldPasswordController,
                      obscureText: true,
                      style: TextStyle(color: currentTheme.textColor),
                      decoration: InputDecoration(
                        labelText: l10n.oldPassword,
                        labelStyle: TextStyle(color: currentTheme.secondaryTextColor),
                        prefixIcon: Icon(Icons.lock_outline, color: currentTheme.secondaryTextColor),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: currentTheme.textColor.withOpacity(0.1))),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _newPasswordController,
                      obscureText: true,
                      style: TextStyle(color: currentTheme.textColor),
                      decoration: InputDecoration(
                        labelText: l10n.newPassword,
                        labelStyle: TextStyle(color: currentTheme.secondaryTextColor),
                        prefixIcon: Icon(Icons.lock_reset, color: currentTheme.secondaryTextColor),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: currentTheme.textColor.withOpacity(0.1))),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      style: TextStyle(color: currentTheme.textColor),
                      decoration: InputDecoration(
                        labelText: l10n.confirmNewPassword,
                        labelStyle: TextStyle(color: currentTheme.secondaryTextColor),
                        prefixIcon: Icon(Icons.verified_user_outlined, color: currentTheme.secondaryTextColor),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: currentTheme.textColor.withOpacity(0.1))),
                      ),
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () => _changePassword(l10n),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: currentTheme.primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                l10n.changePassword,
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Center(
                child: Column(
                  children: [
                    Icon(Icons.info_outline, color: currentTheme.secondaryTextColor.withOpacity(0.3), size: 50),
                    const SizedBox(height: 10),
                    Text(
                      l10n.loginToManageProfile,
                      style: TextStyle(color: currentTheme.secondaryTextColor.withOpacity(0.3)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
