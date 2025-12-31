// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'AI 助手';

  @override
  String get settings => '设置';

  @override
  String get appTheme => '应用主题';

  @override
  String get accountSecurity => '账户安全';

  @override
  String get oldPassword => '旧密码';

  @override
  String get newPassword => '新密码';

  @override
  String get confirmNewPassword => '确认新密码';

  @override
  String get changePassword => '更改密码';

  @override
  String get passwordMismatch => '新密码不匹配';

  @override
  String get fillAllFields => '请填写所有密码字段';

  @override
  String get loginToManageProfile => '请登录以管理安全';

  @override
  String get language => '语言';

  @override
  String get voice => '声音';

  @override
  String get newChat => '新聊天';

  @override
  String get logout => '登出';

  @override
  String get login => '登录';

  @override
  String get success => '成功';

  @override
  String get error => '错误';

  @override
  String get typeAMessage => '输入消息...';

  @override
  String get history => '历史';

  @override
  String get deleteConversation => '删除对话';

  @override
  String get confirmDelete => '您确定要删除此对话吗？';

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get tapToStart => '点击开始';

  @override
  String get holdToSpeak => '按住说话';

  @override
  String get listening => '正在倾听...';

  @override
  String get processing => '正在处理...';

  @override
  String get you => '您';

  @override
  String get assistant => 'AI 助手';

  @override
  String get conversationReset => '对话重置。我该如何帮助您？';

  @override
  String get historyCleared => '对话历史已清除';

  @override
  String get micPermissionDenied => '麦克风权限被拒绝';

  @override
  String get thinking => '思考中...';

  @override
  String get noSpeechDetected => '未检测到语音';

  @override
  String uploading(Object fileName) {
    return '正在上传 $fileName...';
  }

  @override
  String get speechServiceNotReady => '语音服务未就绪。请重试。';

  @override
  String get speechRecognitionFailed => '启动语音识别失败';

  @override
  String get releaseToSend => 'Release to Send';

  @override
  String get translate => 'Translate';

  @override
  String get text => 'Text';

  @override
  String get image => 'Image';

  @override
  String get enterTextToTranslate => 'Enter text to translate...';

  @override
  String get translation => 'Translation';

  @override
  String get scanAnother => 'Scan Another';

  @override
  String get detectedText => 'Detected Text';

  @override
  String get cameraNotAvailable => 'Camera not available';

  @override
  String get checkPermissions => 'Check permissions or use Gallery';

  @override
  String get openGalleryInstead => 'Open Gallery Instead';

  @override
  String get from => 'From:';

  @override
  String get to => 'To:';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get loginToAccount => 'Login to your account';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get needAccount => 'Need an account? Register';

  @override
  String get createAccount => 'Create Account';

  @override
  String get joinCommunity => 'Join our AI Community';

  @override
  String get username => 'Username';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get register => 'Register';

  @override
  String get alreadyHaveAccount => 'Already have an account? Login';

  @override
  String get loginSuccessful => 'Login successful';

  @override
  String get loginFailed => 'Login failed';

  @override
  String get registrationSuccessful => 'Registration successful';

  @override
  String get registrationFailed => 'Registration failed';

  @override
  String get invalidLogin => 'Invalid username or password';

  @override
  String get skipLogin => 'Skip (use without login)';

  @override
  String get pleaseFillAllFields => 'Please fill all fields';

  @override
  String get registrationSuccessMessage =>
      'Registration successful! Please login.';

  @override
  String get settingsTab => 'Settings';
}
