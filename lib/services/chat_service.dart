import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/message.dart';

class ChatService {
  // Send text message to API
  Future<String> sendTextMessage(
    String message,
    List<Message> history, {
    String systemPrompt = '',
    String? conversationId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.chatTextUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': message,
          'history': history.map((m) => m.toJson()).toList(),
          'system_prompt': systemPrompt,
          if (conversationId != null) 'conversation_id': conversationId,
        }),
      );

      print('📥 [ChatService] Response received: ${response.statusCode}');
      print('📝 [ChatService] Body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['text'] ?? 'No response';
      } else {
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Send voice message (audio bytes)
  Future<Map<String, dynamic>> sendVoiceMessage(
    String message,
    List<Message> history, {
    String voice = 'Charon',
    String language = 'vi',
    String? voiceBase64,
    String mimeType = 'audio/wav',
  }) async {
    try {
      print('🚀 [ChatService] Calling POST ${ApiConfig.chatUrl}...');
      final response = await http.post(
        Uri.parse(ApiConfig.chatUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': message,
          'voice': voice,
          'language': language,
          'history': history.map((m) => m.toJson()).toList(),
          if (voiceBase64 != null) 'audio': voiceBase64,
          'mime_type': mimeType,
        }),
      ).timeout(const Duration(seconds: 30));
      
      print('📥 [ChatService] Response received: ${response.statusCode}');
      print('📝 [ChatService] Body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'text': data['text'],
          'audio': data['audio'], // base64 encoded WAV
        };
      } else {
        throw Exception('Failed to send voice: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
