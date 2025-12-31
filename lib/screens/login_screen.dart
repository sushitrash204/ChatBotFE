import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'package:lamp_flutter_app/l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isRegisterMode = false;

  void _submit() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseFillAllFields)),
      );
      return;
    }

    setState(() => _isLoading = true);

    if (_isRegisterMode) {
      // Register (doesn't update global state, just registers)
      final result = await _authService.register(username, password);
      setState(() => _isLoading = false);
      
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.registrationSuccessMessage)),
        );
        setState(() => _isRegisterMode = false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      }
    } else {
      // Login using AuthProvider
      try {
        final success = await Provider.of<AuthProvider>(context, listen: false)
            .login(username, password);
        
        setState(() => _isLoading = false);

        if (success) {
          if (mounted) {
            Navigator.pop(context, true);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.invalidLogin)),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = Provider.of<ThemeProvider>(context).currentTheme;
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: currentTheme.backgroundColor,
      appBar: AppBar(
        title: Text(_isRegisterMode ? l10n.register : l10n.login, style: TextStyle(color: currentTheme.textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: currentTheme.textColor),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo/Title
              Image.asset(
                'assets/images/logo_no_background.png',
                height: 120,
              ),
              const SizedBox(height: 16),
              Text(
                'ParrotAI',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: currentTheme.textColor,
                ),
              ),
              const SizedBox(height: 48),

              // Username field
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: l10n.username,
                  labelStyle: TextStyle(color: currentTheme.secondaryTextColor),
                  filled: true,
                  fillColor: currentTheme.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: currentTheme.textColor.withOpacity(0.1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: currentTheme.textColor.withOpacity(0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: currentTheme.primaryColor),
                  ),
                ),
                style: TextStyle(color: currentTheme.textColor),
              ),
              const SizedBox(height: 16),

              // Password field
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.password,
                  labelStyle: TextStyle(color: currentTheme.secondaryTextColor),
                  filled: true,
                  fillColor: currentTheme.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: currentTheme.textColor.withOpacity(0.1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: currentTheme.textColor.withOpacity(0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: currentTheme.primaryColor),
                  ),
                ),
                style: TextStyle(color: currentTheme.textColor),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: currentTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _isRegisterMode ? l10n.register : l10n.login,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Toggle register/login
              TextButton(
                onPressed: () {
                  setState(() => _isRegisterMode = !_isRegisterMode);
                },
                child: Text(
                  _isRegisterMode
                      ? l10n.alreadyHaveAccount
                      : l10n.needAccount,
                  style: TextStyle(color: currentTheme.primaryColor),
                ),
              ),

              const SizedBox(height: 16),

              // Skip button
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  l10n.skipLogin,
                  style: TextStyle(color: currentTheme.secondaryTextColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
