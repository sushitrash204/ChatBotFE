class VoiceOption {
  final String name;
  final String description;
  final String icon;

  const VoiceOption({required this.name, required this.description, required this.icon});
}

class LanguageOption {
  final String code;
  final String locale;
  final String flag;
  final String name;

  const LanguageOption({required this.code, required this.locale, required this.flag, required this.name});
}

class VoiceConfig {
  static const List<VoiceOption> voices = [
    VoiceOption(name: 'Puck', description: 'Energetic Male', icon: '🧚'), 
    VoiceOption(name: 'Kore', description: 'Soothing Female', icon: '👩'), 
    VoiceOption(name: 'Fenrir', description: 'Strong Male', icon: '🐺'), 
    VoiceOption(name: 'Aoede', description: 'Elegant Female', icon: '🎵'), 
  ];

  static const List<LanguageOption> languages = [
    LanguageOption(code: 'vi', locale: 'vi-VN', flag: '🇻🇳', name: 'Vietnamese'),
    LanguageOption(code: 'en', locale: 'en-US', flag: '🇺🇸', name: 'English'),
    LanguageOption(code: 'ja', locale: 'ja-JP', flag: '🇯🇵', name: 'Japanese'),
    LanguageOption(code: 'ko', locale: 'ko-KR', flag: '🇰🇷', name: 'Korean'),
    LanguageOption(code: 'zh', locale: 'zh-CN', flag: '🇨🇳', name: 'Chinese'),
  ];
}
