import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('vi'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'ParrotAI'**
  String get appTitle;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @appTheme.
  ///
  /// In en, this message translates to:
  /// **'App Theme'**
  String get appTheme;

  /// No description provided for @accountSecurity.
  ///
  /// In en, this message translates to:
  /// **'Account Security'**
  String get accountSecurity;

  /// No description provided for @oldPassword.
  ///
  /// In en, this message translates to:
  /// **'Old Password'**
  String get oldPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'New passwords do not match'**
  String get passwordMismatch;

  /// No description provided for @fillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all password fields'**
  String get fillAllFields;

  /// No description provided for @loginToManageProfile.
  ///
  /// In en, this message translates to:
  /// **'Please log in to manage security'**
  String get loginToManageProfile;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @voice.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get voice;

  /// No description provided for @newChat.
  ///
  /// In en, this message translates to:
  /// **'New Chat'**
  String get newChat;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @typeAMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeAMessage;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @deleteConversation.
  ///
  /// In en, this message translates to:
  /// **'Delete Conversation'**
  String get deleteConversation;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this conversation?'**
  String get confirmDelete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @tapToStart.
  ///
  /// In en, this message translates to:
  /// **'Tap to start'**
  String get tapToStart;

  /// No description provided for @holdToSpeak.
  ///
  /// In en, this message translates to:
  /// **'Hold to speak'**
  String get holdToSpeak;

  /// No description provided for @listening.
  ///
  /// In en, this message translates to:
  /// **'Listening...'**
  String get listening;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @assistant.
  ///
  /// In en, this message translates to:
  /// **'ParrotAI'**
  String get assistant;

  /// No description provided for @conversationReset.
  ///
  /// In en, this message translates to:
  /// **'Conversation reset. How can I help?'**
  String get conversationReset;

  /// No description provided for @historyCleared.
  ///
  /// In en, this message translates to:
  /// **'Conversation history cleared'**
  String get historyCleared;

  /// No description provided for @micPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission denied'**
  String get micPermissionDenied;

  /// No description provided for @thinking.
  ///
  /// In en, this message translates to:
  /// **'Thinking...'**
  String get thinking;

  /// No description provided for @noSpeechDetected.
  ///
  /// In en, this message translates to:
  /// **'No speech detected'**
  String get noSpeechDetected;

  /// No description provided for @uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading {fileName}...'**
  String uploading(Object fileName);

  /// No description provided for @speechServiceNotReady.
  ///
  /// In en, this message translates to:
  /// **'Speech service not ready. Please try again.'**
  String get speechServiceNotReady;

  /// No description provided for @speechRecognitionFailed.
  ///
  /// In en, this message translates to:
  /// **'Speech recognition failed to start'**
  String get speechRecognitionFailed;

  /// No description provided for @releaseToSend.
  ///
  /// In en, this message translates to:
  /// **'Release to Send'**
  String get releaseToSend;

  /// No description provided for @translate.
  ///
  /// In en, this message translates to:
  /// **'Translate'**
  String get translate;

  /// No description provided for @text.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get text;

  /// No description provided for @image.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get image;

  /// No description provided for @enterTextToTranslate.
  ///
  /// In en, this message translates to:
  /// **'Enter text to translate...'**
  String get enterTextToTranslate;

  /// No description provided for @translation.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get translation;

  /// No description provided for @scanAnother.
  ///
  /// In en, this message translates to:
  /// **'Scan Another'**
  String get scanAnother;

  /// No description provided for @detectedText.
  ///
  /// In en, this message translates to:
  /// **'Detected Text'**
  String get detectedText;

  /// No description provided for @cameraNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Camera not available'**
  String get cameraNotAvailable;

  /// No description provided for @checkPermissions.
  ///
  /// In en, this message translates to:
  /// **'Check permissions or use Gallery'**
  String get checkPermissions;

  /// No description provided for @openGalleryInstead.
  ///
  /// In en, this message translates to:
  /// **'Open Gallery Instead'**
  String get openGalleryInstead;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From:'**
  String get from;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To:'**
  String get to;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @loginToAccount.
  ///
  /// In en, this message translates to:
  /// **'Login to your account'**
  String get loginToAccount;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @needAccount.
  ///
  /// In en, this message translates to:
  /// **'Need an account? Register'**
  String get needAccount;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @joinCommunity.
  ///
  /// In en, this message translates to:
  /// **'Join our AI Community'**
  String get joinCommunity;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get alreadyHaveAccount;

  /// No description provided for @loginSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Login successful'**
  String get loginSuccessful;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginFailed;

  /// No description provided for @registrationSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Registration successful'**
  String get registrationSuccessful;

  /// No description provided for @registrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed'**
  String get registrationFailed;

  /// No description provided for @invalidLogin.
  ///
  /// In en, this message translates to:
  /// **'Invalid username or password'**
  String get invalidLogin;

  /// No description provided for @skipLogin.
  ///
  /// In en, this message translates to:
  /// **'Skip (use without login)'**
  String get skipLogin;

  /// No description provided for @pleaseFillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all fields'**
  String get pleaseFillAllFields;

  /// No description provided for @registrationSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Registration successful! Please login.'**
  String get registrationSuccessMessage;

  /// No description provided for @settingsTab.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTab;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'vi',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
