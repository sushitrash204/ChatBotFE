class ApiConfig {
  // IMPORTANT: Change this to your computer's IP address
  // For web (Chrome): use localhost or 127.0.0.1
  // For mobile: use your computer's IP (run 'ipconfig' to find it)
  static const String baseUrl = 'https://chatbotbe-sjk6.onrender.com'; // Live Render backend
  
  // API Endpoints
  static const String apiChat = '/api/chat';
  static const String apiChatText = '/api/chat-text';
  static const String apiTranslate = '/api/translate';
  static const String apiOcr = '/api/ocr';
  static const String apiConversations = '/api/conversations';
  static const String apiChatHistory = '/api/history'; // Corrected from /api/chat-history
  static const String login = '/login';
  static const String register = '/register';
  static const String logout = '/logout';
  
  // Full URLs
  static String get chatUrl => '$baseUrl$apiChat';
  static String get chatTextUrl => '$baseUrl$apiChatText';
  static String get translateUrl => '$baseUrl$apiTranslate';
  static String get ocrUrl => '$baseUrl$apiOcr';
  static String get conversationsUrl => '$baseUrl$apiConversations';
  static String get chatHistoryUrl => '$baseUrl$apiChatHistory';
  static String get loginUrl => '$baseUrl$login';
  static String get registerUrl => '$baseUrl$register';
  static String get logoutUrl => '$baseUrl$logout';
}
