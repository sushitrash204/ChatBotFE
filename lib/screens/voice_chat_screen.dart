import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart'; // Audio Recorder & Player
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../config/api_config.dart';

import '../utils/audio_helper.dart';
import '../models/message.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../config/voice_config.dart';
import '../providers/theme_provider.dart';
import 'package:lamp_flutter_app/l10n/app_localizations.dart';
import 'login_screen.dart';
import 'settings_screen.dart';

class VoiceChatScreen extends StatefulWidget {
  final Function(VoidCallback)? onNewChatRequested;

  const VoiceChatScreen({super.key, this.onNewChatRequested});

  @override
  State<VoiceChatScreen> createState() => _VoiceChatScreenState();
}

class _VoiceChatScreenState extends State<VoiceChatScreen> with TickerProviderStateMixin {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final TextEditingController _textController = TextEditingController(); // Manual Input
  final List<Message> _messages = [];
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _sttInitialized = false;

  bool _isRecorderInitialized = false;
  bool _isPlayerInitialized = false;
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _isLoggedIn = false;
  bool _showTextInput = false; // Toggle Text Input
  
  String? _recordingPath;
  String _aiText = ''; 
  final ScrollController _scrollController = ScrollController();

  // --- Animation Controllers ---
  late AnimationController _bgController;
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late AnimationController _shimmerController;
  late AnimationController _rippleController;

  Offset _touchPosition = Offset.zero;
  Color _touchColor = Colors.blue;

  void _newChat() {
    final currentTheme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;
    setState(() {
      _messages.clear();
      _aiText = AppLocalizations.of(context)!.conversationReset;
      _textController.clear();
    });
    
    // Add visual feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.historyCleared, style: TextStyle(color: currentTheme.textColor)),
          duration: const Duration(seconds: 2),
          backgroundColor: currentTheme.cardColor,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _initRecorder();
    _initPlayer();
    _initSTT();
    _checkLogin();
    widget.onNewChatRequested?.call(_newChat);

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );
  }

  void _triggerRipple(Offset position) {
    if (_showTextInput && position.dy > MediaQuery.of(context).size.height - 150) return; // Avoid ripple over text input

    final random = math.Random();
    final currentTheme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;
    setState(() {
      _touchPosition = position;
      _touchColor = random.nextBool() 
          ? currentTheme.primaryColor
          : currentTheme.accentColor;
    });
    _rippleController.forward(from: 0.0);
  }

  Future<void> _checkLogin() async {
    final loggedIn = await _authService.isLoggedIn();
    setState(() => _isLoggedIn = loggedIn);
  }

  Future<void> _initRecorder() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.micPermissionDenied)));
      return;
    }
    await _recorder.openRecorder();
    setState(() => _isRecorderInitialized = true);
  }

  Future<void> _initPlayer() async {
    await _player.openPlayer();
    setState(() => _isPlayerInitialized = true);
  }

  Future<void> _initSTT() async {
    try {
      _sttInitialized = await _speechToText.initialize(
        onStatus: (status) {
          print('STT status: $status');
          if (status == 'done' || status == 'notListening') {
            if (mounted) setState(() => _isRecording = false);
          }
        },
        onError: (e) {
          print('STT error: ${e.errorMsg}');
          if (mounted) setState(() => _aiText = 'STT Error: ${e.errorMsg}');
        },
      );
      print('STT Available: $_sttInitialized');
    } catch (e) {
      print('STT Init Exception: $e');
      _sttInitialized = false;
    }
  }

  Future<void> _startRecording() async {
    if (_isPlaying) await _player.stopPlayer();
    
    try {
      // 1. Re-init only if fundamentally failed before
      if (!_sttInitialized) {
        await _initSTT();
      }

      // 2. Final check
      if (_sttInitialized) {
        setState(() {
          _isRecording = true;
          _aiText = AppLocalizations.of(context)!.listening;
          _textController.clear();
        });
        
        await _speechToText.listen(
          onResult: (result) {
            setState(() {
              _textController.text = result.recognizedWords;
              _aiText = result.recognizedWords;
            });
          },
          localeId: Provider.of<ChatProvider>(context, listen: false).selectedLanguageCode == 'vi' ? 'vi_VN' : 'en_US',
          listenMode: stt.ListenMode.dictation,
          cancelOnError: true,
          partialResults: true,
        );
      } else {
        setState(() => _aiText = AppLocalizations.of(context)!.speechServiceNotReady);
        // Try to trigger init again for next time
        _initSTT();
      }
    } catch (e) {
      print('Start Recording Exception: $e');
      setState(() => _aiText = AppLocalizations.of(context)!.speechRecognitionFailed);
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    
    await _speechToText.stop();
    setState(() => _isRecording = false);
    
    if (_textController.text.isNotEmpty) {
      _sendVoiceMessage(_textController.text);
    } else {
      setState(() => _aiText = AppLocalizations.of(context)!.noSpeechDetected);
    }
  }

  // --- AUDIO UPLOAD FOR DEBUGGING ---
  Future<void> _pickAndSendAudio() async {
    try {
      print('📂 Opening file picker...');
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
        withData: true, // Crucial for Web
      );

      if (result != null && result.files.single.bytes != null) {
        final fileName = result.files.single.name;
        final extension = fileName.split('.').last.toLowerCase();
        
        // Determine MIME
        String mimeType = 'audio/$extension';
        if (extension == 'mp3') mimeType = 'audio/mpeg';
        if (extension == 'm4a') mimeType = 'audio/mp4';
        if (extension == 'wav') mimeType = 'audio/wav';
        if (extension == 'webm') mimeType = 'audio/webm;codecs=opus';
        
        final base64Audio = base64Encode(result.files.single.bytes!);
        
        print('📤 File picked: $fileName (${result.files.single.bytes!.length} bytes)');
        if (mounted) {
           final l10n = AppLocalizations.of(context)!;
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.uploading(fileName))));
           setState(() {
             _isLoading = true;
             _aiText = l10n.uploading(fileName);
           });
        }
        
        await _sendVoiceMessage('User uploaded: $fileName', audioBase64: base64Audio, overrideMime: mimeType);
      } else {
        print('⚠️ No file picked or bytes empty');
      }
    } catch (e) {
      print('❌ Pick Error: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
    }
  }

  // Handle Text/Audio Send
  Future<void> _sendVoiceMessage(String text, {String? audioBase64, String? overrideMime}) async {
    if (text.isEmpty && audioBase64 == null) return;
    
    setState(() {
      _isLoading = true;
      if (text.isNotEmpty) _aiText = AppLocalizations.of(context)!.thinking;
    });
    
    // Clear Input
    if (text.isNotEmpty) _textController.clear();

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final mimeType = overrideMime ?? (kIsWeb ? 'audio/webm' : 'audio/wav'); 

    try {
      print('🌐 Sending Voice Request to: ${_chatService.hashCode} across ${ApiConfig.chatUrl}');
      print('📦 Payload: text length=${text.length}, audio size=${audioBase64?.length ?? 0} chars');
      
      final response = await _chatService.sendVoiceMessage(
        text, // Empty string if audio is used
        _messages,
        voice: chatProvider.selectedVoice,
        language: chatProvider.selectedLanguageCode,
        voiceBase64: audioBase64,
        mimeType: mimeType,
      );
      
      if (!mounted) return;

      setState(() {
        final reply = response['text'] ?? (audioBase64 != null ? '[AI responded with audio - No text transcription]' : 'No response');
        _aiText = reply;
        _messages.add(Message(role: 'user', text: text.isNotEmpty ? text : '🎤 [Audio Message]'));
        _messages.add(Message(role: 'model', text: reply));
        _isLoading = false;
        
        // Auto scroll to bottom
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      });
      
      if (response['audio'] != null) {
        await _playAudioResponse(response['audio']);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _aiText = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _playAudioResponse(String base64Audio) async {
    try {
      final bytes = base64Decode(base64Audio);
      setState(() => _isPlaying = true);
      
      if (kIsWeb) {
        // Use HTML5 Audio for Web (flutter_sound doesn't work well on Web)
        final audioHelper = getAudioHelper();
        await audioHelper.playAudio(bytes);
        
        // Simulating playing state as we don't have easy callback without more complexity
        // but it's better than crashing the build.
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _isPlaying = false);
        });
      } else {
        // Mobile: Use flutter_sound
        if (!_isPlayerInitialized) return;
        final dir = await getTemporaryDirectory();
        final audioPath = '${dir.path}/response_${DateTime.now().millisecondsSinceEpoch}.wav';
        final file = File(audioPath);
        await file.writeAsBytes(bytes);

        await _player.startPlayer(
          fromURI: audioPath,
          whenFinished: () {
            setState(() => _isPlaying = false);
            file.delete();
          },
        );
      }
    } catch (e) {
      setState(() => _isPlaying = false);
      print('Audio Play Error: $e');
    }
  }

  void _toggleTextInput() {
    setState(() => _showTextInput = !_showTextInput);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);
    final isLoggedIn = authProvider.isLoggedIn;
    final l10n = AppLocalizations.of(context)!;

    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.currentTheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l10n.appTitle, style: TextStyle(fontWeight: FontWeight.w600, color: currentTheme.textColor)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: PopupMenuButton<String>(
          icon: Icon(Icons.tune, color: currentTheme.textColor),
          offset: const Offset(0, 40),
          color: currentTheme.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          onSelected: (value) {
            if (value == 'language')  _showLanguageModal(context, chatProvider);
            else if (value == 'voice') _showVoiceModal(context, chatProvider);
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: 'language', 
              child: Text(l10n.language, style: TextStyle(color: currentTheme.textColor))),
            PopupMenuItem(value: 'voice', 
              child: Text(l10n.voice, style: TextStyle(color: currentTheme.textColor))),
          ],
        ),
        actions: [
            IconButton(
                icon: Icon(Icons.refresh_rounded, color: currentTheme.textColor.withOpacity(0.7)),
                tooltip: l10n.newChat,
                onPressed: _newChat,
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: isLoggedIn
                ? IconButton(
                    icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                    onPressed: () async {
                      await authProvider.logout();
                      _newChat();
                    },
                  )
                : _buildGradientLoginButton(),
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(color: currentTheme.backgroundColor),

          AnimatedBuilder(
            animation: _waveController,
            builder: (context, _) => CustomPaint(
              painter: MinimalWavesPainter(
                _waveController.value,
                currentTheme.primaryColor,
                currentTheme.accentColor,
              ),
              size: Size.infinite,
            ),
          ),

          GestureDetector(
            onTapDown: (details) => _triggerRipple(details.localPosition),
            onPanDown: (details) => _triggerRipple(details.localPosition),
            child: Stack(
              children: [
                AnimatedBuilder(
                  animation: _bgController,
                  builder: (context, child) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          stops: const [0.0, 0.5, 1.0],
                          colors: [
                            currentTheme.backgroundColor.withOpacity(0.8),
                            Color.lerp(currentTheme.backgroundColor, currentTheme.cardColor, _bgController.value)!.withOpacity(0.6),
                            currentTheme.backgroundColor.withOpacity(0.8),
                          ],
                        ),
                      ),
                    ),
                ),

                AnimatedBuilder(
                  animation: _rippleController,
                  builder: (context, _) => CustomPaint(
                      painter: TouchRipplePainter(
                        _touchPosition,
                        _rippleController.value,
                        _touchColor,
                      ),
                      child: Container(),
                    ),
                ),

                SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                              // MIC VISUALIZER
                              AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) {
                                  double pulse = (_isRecording || _isPlaying) ? _pulseController.value * 20 : 0;
                                  return Container(
                                    width: 200 + pulse,
                                    height: 200 + pulse,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: (_isRecording || _isPlaying) 
                                        ? currentTheme.gradient
                                        : LinearGradient(colors: [currentTheme.cardColor, currentTheme.backgroundColor]),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (_isRecording || _isPlaying ? currentTheme.primaryColor : Colors.black)
                                              .withOpacity(currentTheme.isDark ? 0.5 : 0.2),
                                          blurRadius: 30 + pulse,
                                          spreadRadius: 5 + (pulse / 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      _isRecording ? Icons.mic : _isPlaying ? Icons.volume_up : Icons.mic_none,
                                      size: 80,
                                      color: (_isRecording || _isPlaying) ? Colors.white : currentTheme.textColor.withOpacity(0.7),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 50),
                              
                              // AI TEXT / STATUS
                              if (_aiText.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 32),
                                  child: Text(_aiText,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: currentTheme.textColor, 
                                          fontSize: 18, 
                                          fontWeight: FontWeight.w500,
                                          fontStyle: _isLoading ? FontStyle.italic : FontStyle.normal,
                                      )),
                                ),
                              
                              if (_isLoading)
                                Padding(
                                  padding: const EdgeInsets.only(top: 20),
                                  child: Column(
                                    children: [
                                      CircularProgressIndicator(color: currentTheme.primaryColor),
                                      const SizedBox(height: 8),
                                      Text(l10n.thinking, style: TextStyle(color: currentTheme.secondaryTextColor, fontSize: 12)),
                                    ],
                                  ),
                                ),
                            ],
                            ),
                          ),
                        ),
                      ),

                      // --- CONTROLS ---
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                                // TEXT INPUT FIELD (Toggleable)
                                if (_showTextInput)
                                    Padding(
                                        padding: const EdgeInsets.only(bottom: 20),
                                        child: Row(
                                            children: [
                                                Expanded(child: TextField(
                                                    controller: _textController,
                                                    style: TextStyle(color: currentTheme.textColor),
                                                    decoration: InputDecoration(
                                                        hintText: l10n.typeAMessage,
                                                        hintStyle: TextStyle(color: currentTheme.secondaryTextColor),
                                                        filled: true,
                                                        fillColor: currentTheme.cardColor,
                                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                                                    ),
                                                    onSubmitted: (val) => _sendVoiceMessage(val),
                                                )),
                                                const SizedBox(width: 8),
                                                IconButton(
                                                    icon: Icon(Icons.send, color: currentTheme.primaryColor),
                                                    onPressed: () => _sendVoiceMessage(_textController.text),
                                                ),
                                            ],
                                        ),
                                    ),

                                // MIC & TEXT TOGGLE
                                Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                        // TEXT TOGGLE BTN
                                        IconButton(
                                            icon: Icon(_showTextInput ? Icons.keyboard_hide : Icons.keyboard, 
                                              color: currentTheme.secondaryTextColor),
                                            onPressed: _toggleTextInput,
                                        ),
                                        const SizedBox(width: 20),

                                        // MIC BUTTON
                                        GestureDetector(
                                          onLongPressStart: (_) => _startRecording(),
                                          onLongPressEnd: (_) => _stopRecording(),
                                          onTap: () {
                                             // Provide feedback for short tap
                                             ScaffoldMessenger.of(context).showSnackBar(
                                               SnackBar(content: Text(l10n.holdToSpeak), duration: const Duration(seconds: 1))
                                             );
                                          },
                                          child: AnimatedScale(
                                            duration: const Duration(milliseconds: 200),
                                            scale: _isRecording ? 1.2 : 1.0,
                                            child: Container(
                                              width: 70,
                                              height: 70,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient: LinearGradient(
                                                  colors: _isRecording
                                                      ? [Colors.red.shade400, Colors.red.shade600]
                                                      : currentTheme.gradient.colors,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: (_isRecording ? Colors.red : currentTheme.primaryColor).withOpacity(0.4),
                                                    blurRadius: 15,
                                                    spreadRadius: 4,
                                                  ),
                                                ],
                                              ),
                                              child: Icon(_isRecording ? Icons.mic : Icons.mic_none, size: 35, color: Colors.white),
                                            ),
                                          ),
                                        ),
                                        
                                        const SizedBox(width: 20),
                                         // UPLOAD BUTTON FOR DEBUGGING
                                         IconButton(
                                            icon: Icon(Icons.upload_file, color: currentTheme.secondaryTextColor),
                                            onPressed: _pickAndSendAudio,
                                         ),
                                    ],
                                ),
                                const SizedBox(height: 10),
                                Text(_isRecording ? l10n.releaseToSend : l10n.holdToSpeak, 
                                  style: TextStyle(color: currentTheme.secondaryTextColor, fontSize: 12)),
                            ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Login Button helper ---
  Widget _buildGradientLoginButton() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.currentTheme;
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, _) {
        final val = _shimmerController.value;
        final l10n = AppLocalizations.of(context)!;
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen())),
          child: Container(
            height: 36, width: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: currentTheme.gradient,
              boxShadow: [BoxShadow(color: Color.lerp(currentTheme.primaryColor, currentTheme.accentColor, val)!.withOpacity(0.5), blurRadius: 10)],
            ),
            alignment: Alignment.center,
            child: Text(l10n.login, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  void _showLanguageModal(BuildContext context, ChatProvider provider) {
    final currentTheme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: currentTheme.backgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.language, style: TextStyle(color: currentTheme.textColor, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: VoiceConfig.languages.length,
                  itemBuilder: (context, index) {
                    final lang = VoiceConfig.languages[index];
                    final isSelected = provider.selectedLanguageCode == lang.code;
                    return ListTile(
                      leading: Text(lang.flag, style: const TextStyle(fontSize: 24)),
                      title: Text(lang.name, style: TextStyle(color: isSelected ? currentTheme.primaryColor : currentTheme.textColor)),
                      trailing: isSelected ? Icon(Icons.check, color: currentTheme.primaryColor) : null,
                      onTap: () {
                        provider.setLanguage(lang.code);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showVoiceModal(BuildContext context, ChatProvider provider) {
    final currentTheme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: currentTheme.backgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.voice, style: TextStyle(color: currentTheme.textColor, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: VoiceConfig.voices.length,
                  itemBuilder: (context, index) {
                    final voice = VoiceConfig.voices[index];
                    final isSelected = provider.selectedVoice == voice.name;
                    return ListTile(
                      leading: Text(voice.icon, style: const TextStyle(fontSize: 24)),
                      title: Text(voice.name, style: TextStyle(color: isSelected ? currentTheme.primaryColor : currentTheme.textColor)),
                      subtitle: Text(voice.description, style: TextStyle(color: currentTheme.secondaryTextColor, fontSize: 12)),
                      trailing: isSelected ? Icon(Icons.check, color: currentTheme.primaryColor) : null,
                      onTap: () {
                        provider.setVoice(voice.name);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _bgController.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    _shimmerController.dispose();
    _rippleController.dispose();
    _recorder.closeRecorder();
    _player.closePlayer();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

// PAINTERS
class TouchRipplePainter extends CustomPainter {
  final Offset position;
  final double opacity;
  final Color baseColor;

  TouchRipplePainter(this.position, this.opacity, this.baseColor);

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0 || opacity >= 0.95) return;
    
    final random = math.Random(baseColor.hashCode);
    
    for (int i = 0; i < 8; i++) {
      final delay = i * 0.12;
      final progress = math.max(0.0, math.min(1.0, opacity - delay));
      
      if (progress <= 0 || progress >= 0.95) continue;

      final maxRadius = math.min(size.width, size.height) * 0.8;
      final radius = 30 + (progress * maxRadius);
      
      final fadeOut = math.pow(1 - progress, 2).toDouble();
      final ringOpacity = fadeOut * 0.35;
      
      final ringColor = baseColor;

      final gradient = RadialGradient(
        colors: [
          ringColor.withOpacity(ringOpacity * 0.25),
          ringColor.withOpacity(ringOpacity * 0.15),
          ringColor.withOpacity(0.0),
        ],
        stops: const [0.85, 0.95, 1.0],
      );

      final rect = Rect.fromCircle(center: position, radius: radius);
      final paint = Paint()..shader = gradient.createShader(rect);
      
      canvas.drawCircle(position, radius, paint);

      final strokePaint = Paint()
        ..color = ringColor.withOpacity(ringOpacity * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 + fadeOut * 1.5;

      canvas.drawCircle(position, radius, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant TouchRipplePainter oldDelegate) =>
      oldDelegate.position != position || 
      oldDelegate.opacity != opacity ||
      oldDelegate.baseColor != baseColor;
}

class MinimalWavesPainter extends CustomPainter {
  final double animationValue;
  final Color primaryColor;
  final Color accentColor;

  MinimalWavesPainter(this.animationValue, this.primaryColor, this.accentColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paintBlue1 = Paint()
      ..color = primaryColor.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final paintBlue2 = Paint()
      ..color = primaryColor.withOpacity(0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final paintBlue3 = Paint()
      ..color = accentColor.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final paintRed1 = Paint()
      ..color = accentColor.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final paintRed2 = Paint()
      ..color = accentColor.withOpacity(0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final pathBlue1 = Path();
    final pathBlue2 = Path();
    final pathBlue3 = Path();
    final pathRed1 = Path();
    final pathRed2 = Path();

    void drawWave(Path path, double phase, double amplitude, double frequency) {
      path.moveTo(0, size.height / 2);
      for (double x = 0; x <= size.width; x++) {
        double y = size.height / 2 +
            math.sin((x / size.width * 2 * math.pi * frequency) + (animationValue * 2 * math.pi) + phase) * amplitude;
        path.lineTo(x, y);
      }
    }

    drawWave(pathBlue1, 0, 30, 1.0);
    drawWave(pathBlue2, math.pi / 4, 25, 1.2);
    drawWave(pathBlue3, math.pi / 2, 20, 1.5);
    drawWave(pathRed1, math.pi, 28, 1.1);
    drawWave(pathRed2, math.pi * 1.5, 22, 1.3);

    canvas.drawPath(pathBlue1, paintBlue1);
    canvas.drawPath(pathBlue2, paintBlue2);
    canvas.drawPath(pathBlue3, paintBlue3);
    canvas.drawPath(pathRed1, paintRed1);
    canvas.drawPath(pathRed2, paintRed2);
  }

  @override
  bool shouldRepaint(covariant MinimalWavesPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}