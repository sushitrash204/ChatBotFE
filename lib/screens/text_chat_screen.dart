import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/message.dart';
import '../models/conversation.dart';
import '../services/chat_service.dart';
import '../services/conversation_service.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'login_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:lamp_flutter_app/l10n/app_localizations.dart';
import 'settings_screen.dart';

class TextChatScreen extends StatefulWidget {
  const TextChatScreen({super.key});

  @override
  State<TextChatScreen> createState() => _TextChatScreenState();
}

class _TextChatScreenState extends State<TextChatScreen> with TickerProviderStateMixin {
  // Service Instances
  final ChatService _chatService = ChatService();
  final ConversationService _conversationService = ConversationService();

  // Controllers & Keys
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // State Variables
  List<Conversation> _conversations = [];
  List<Message> _messages = [];
  String? _currentConversationId;
  String _systemPrompt = ''; 
  bool _showPersonality = false; 
  bool _isLoading = false;
  bool _isLoggedIn = false;

  // Animation Controller
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    // Setup listener for AuthProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.addListener(_onAuthChanged);
      _onAuthChanged(); // Run initial check
    });

    // Shimmer controller for login button
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  void dispose() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.removeListener(_onAuthChanged);
    _shimmerController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --- LOGIC: Auth Change ---
  void _onAuthChanged() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    setState(() => _isLoggedIn = authProvider.isLoggedIn);

    if (_isLoggedIn) {
      _loadConversations();
    } else {
      // Clear data on logout
      setState(() {
        _conversations.clear();
        _messages.clear();
        _currentConversationId = null;
      });
    }
  }

  // --- LOGIC: Load Conversations ---
  Future<void> _loadConversations() async {
    try {
      print('DEBUG: Loading conversation list...');
      final conversations = await _conversationService.getConversations();
      
      if (!mounted) return;

      setState(() {
        _conversations = conversations;
      });
      print('DEBUG: Loaded ${_conversations.length} conversations');

    } catch (e) {
      print('ERROR loading conversations: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Failed to load history: $e')),
        );
      }
    }
  }

  // --- LOGIC: Select Conversation ---
  void _selectConversation(String conversationId) {
    if (_currentConversationId == conversationId) return;
    
    setState(() {
      _currentConversationId = conversationId;
      _messages.clear(); // Clear old messages
    });
    
    _loadMessages(conversationId);
  }

  // --- LOGIC: Load Messages (History) ---
  Future<void> _loadMessages(String conversationId) async {
    try {
      setState(() => _isLoading = true);
      print('DEBUG: Loading messages for $conversationId...');
      
      final messages = await _conversationService.getConversationMessages(conversationId);
      
      if (!mounted) return;
      
      if (_currentConversationId == conversationId) {
         setState(() {
           _messages = messages;
           _isLoading = false;
         });
         _scrollToBottom();
         print('DEBUG: Loaded ${messages.length} messages.');
      }
    } catch (e) {
      print('ERROR loading messages: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading chat: $e')),
        );
      }
    }
  }

  // --- LOGIC: OCR (Image to Text) ---
  Future<void> _pickImageAndExtractText() async {
    final picker = ImagePicker();
    final currentTheme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;

    // Show dialog to choose Camera or Gallery
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: currentTheme.backgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt, color: currentTheme.primaryColor),
              title: Text('Camera', style: TextStyle(color: currentTheme.textColor)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: currentTheme.accentColor),
              title: Text('Gallery', style: TextStyle(color: currentTheme.textColor)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile == null) return;

      setState(() => _isLoading = true);

      final inputImage = InputImage.fromFilePath(pickedFile.path);
      final textRecognizer = TextRecognizer();
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      String extractedText = recognizedText.text.trim();
      await textRecognizer.close();

      if (extractedText.isEmpty) {
        extractedText = "[No text detected in image]";
      } else {
        extractedText = "[OCR Text]:\n$extractedText";
      }

      // Fill controller with extracted text so user can edit before sending
      _controller.text = extractedText;
      
      setState(() => _isLoading = false);
      
    } catch (e) {
      print('OCR Error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to read image: $e')),
        );
      }
    }
  }

  // --- LOGIC: Send Message ---
  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    // Optimistic Update
    setState(() {
      _messages.add(Message(role: 'user', text: text));
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      // 1. Create Conversation if Needed
      if (_currentConversationId == null) {
        final title = text.length > 30 ? text.substring(0, 30) : text;
        final newId = await _conversationService.createConversation(title);
        
        if (newId != null) {
          setState(() => _currentConversationId = newId);
          // Refresh list silently
          _conversationService.getConversations().then((list) {
            if (mounted) setState(() => _conversations = list);
          });
        }
      }

      // 2. Send Message to Backend
      final responseText = await _chatService.sendTextMessage(
        text, 
        _messages,
        conversationId: _currentConversationId,
        systemPrompt: _systemPrompt,
      );

      if (mounted) {
        setState(() {
          _messages.add(Message(role: 'model', text: responseText));
          _isLoading = false;
        });
        _scrollToBottom();
      }

    } catch (e) {
      print('ERROR sending message: $e');
      if (mounted) {
        setState(() {
          _messages.add(Message(role: 'model', text: 'Error: $e'));
          _isLoading = false;
        });
      }
    }
  }

  // --- LOGIC: New Chat ---
  void _newChat() {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(context); // Close drawer
    }
    setState(() {
      _currentConversationId = null;
      _messages.clear();
    });
  }
  
  // --- LOGIC: Delete Conversation ---
  Future<void> _deleteConversation(String id) async {
      try {
          await _conversationService.deleteConversation(id);
          setState(() {
              _conversations.removeWhere((c) => c.id == id);
              if (_currentConversationId == id) {
                  _newChat();
              }
          });
      } catch (e) {
          // ignore error
      }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoggedIn = authProvider.isLoggedIn;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.currentTheme;

    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      backgroundColor: currentTheme.backgroundColor,
      appBar: AppBar(
        title: Text(l10n.appTitle, style: TextStyle(fontWeight: FontWeight.w600, color: currentTheme.textColor)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: isLoggedIn ? IconButton(
            icon: const Icon(Icons.menu_rounded), 
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ) : null,
        actions: [
          // Personality Toggle with simple glow effect
          IconButton(
            icon: Icon(
                Icons.psychology, 
                color: _showPersonality ? currentTheme.primaryColor : currentTheme.secondaryTextColor
            ),
            onPressed: () => setState(() => _showPersonality = !_showPersonality),
            tooltip: 'AI Personality',
          ),
          if (isLoggedIn)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: _newChat,
              tooltip: l10n.newChat,
            ),
          if (isLoggedIn)
             Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                  onPressed: () { 
                      authProvider.logout(); 
                      _newChat(); 
                  },
                ),
             )
          else 
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: _buildGradientLoginButton(),
            )
        ],
      ),
      drawer: isLoggedIn ? _buildDrawer() : null,
      body: SafeArea(
        child: Column(
          children: [
            // Animated Personality Input
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Container(
                height: _showPersonality ? null : 0,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: currentTheme.cardColor,
                  border: Border(bottom: BorderSide(color: currentTheme.textColor.withOpacity(0.1)))
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("🤖 System Personality", style: TextStyle(color: currentTheme.primaryColor, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      style: TextStyle(color: currentTheme.textColor),
                      decoration: InputDecoration(
                        hintText: "E.g., You are a helpful coding assistant...",
                        hintStyle: TextStyle(color: currentTheme.secondaryTextColor),
                        filled: true,
                        fillColor: currentTheme.backgroundColor.withOpacity(0.5),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: currentTheme.secondaryTextColor.withOpacity(0.1))),
                        contentPadding: const EdgeInsets.all(12)
                      ),
                      onChanged: (val) => _systemPrompt = val,
                    )
                  ]
                ),
              ),
            ),

            // Chat List
            Expanded(
              child: _isLoading && _messages.isEmpty
                ? Center(child: CircularProgressIndicator(color: currentTheme.primaryColor))
                : _buildMessageList(),
            ),
          
            if (_isLoading)
              const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: 20, bottom: 10),
                  child: TypingIndicator(),
                )
              ),

            // Input Area
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    final l10n = AppLocalizations.of(context)!;
    final currentTheme = Provider.of<ThemeProvider>(context).currentTheme;
    return Drawer(
      backgroundColor: currentTheme.backgroundColor,
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
                gradient: currentTheme.gradient,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/logo_no_background.png', height: 60),
                const SizedBox(height: 10),
                Text(l10n.history, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.add_circle, color: currentTheme.primaryColor),
            title: Text(l10n.newChat, style: TextStyle(color: currentTheme.textColor, fontWeight: FontWeight.bold)),
            onTap: _newChat,
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _conversations.length,
              itemBuilder: (ctx, i) {
                final c = _conversations[i];
                final isSelected = c.id == _currentConversationId;
                return ListTile(
                  selected: isSelected,
                  selectedTileColor: currentTheme.primaryColor.withOpacity(0.15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Icon(Icons.chat_bubble_outline, color: isSelected ? currentTheme.primaryColor : currentTheme.secondaryTextColor),
                  title: Text(c.title, style: TextStyle(color: isSelected ? currentTheme.textColor : currentTheme.secondaryTextColor, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
                  onTap: () {
                     Navigator.pop(ctx); 
                     _selectConversation(c.id);
                  },
                  trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                      onPressed: () => _deleteConversation(c.id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // REPLACED: Updated Message List with Animation Wrapper
  Widget _buildMessageList() {
    final currentTheme = Provider.of<ThemeProvider>(context).currentTheme;
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline_rounded, size: 80, color: currentTheme.secondaryTextColor.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              'Start a conversation',
              style: TextStyle(color: currentTheme.secondaryTextColor, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isUser = msg.role == 'user';
        return AnimatedMessageBubble(
            key: ValueKey(msg.timestamp.toString() + index.toString()), 
            message: msg, 
            isUser: isUser
        );
      },
    );
  }

  // REPLACED: Modern Input Area
  Widget _buildInputArea() {
    final l10n = AppLocalizations.of(context)!;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.currentTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: currentTheme.backgroundColor,
        boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(currentTheme.isDark ? 0.3 : 0.1), blurRadius: 15, offset: const Offset(0, -5))
        ]
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: currentTheme.cardColor,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: currentTheme.secondaryTextColor.withOpacity(0.1))
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.camera_alt_rounded, color: currentTheme.secondaryTextColor),
                    onPressed: _pickImageAndExtractText,
                    tooltip: 'Scan Image (OCR)',
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: TextStyle(color: currentTheme.textColor),
                      decoration: InputDecoration(
                        hintText: l10n.typeAMessage,
                        hintStyle: TextStyle(color: currentTheme.secondaryTextColor),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                      ),
                      minLines: 1,
                      maxLines: 4,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: currentTheme.gradient,
                boxShadow: [BoxShadow(color: currentTheme.primaryColor.withOpacity(0.3), blurRadius: 8, spreadRadius: 1)]
            ),
            child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white),
                onPressed: _sendMessage,
            ),
          )
        ],
      ),
    );
  }

  // Gradient Login Button (Standardized)
  Widget _buildGradientLoginButton() {
    final currentTheme = Provider.of<ThemeProvider>(context).currentTheme;
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
}

// --- ANIMATION CLASSES ---

class AnimatedMessageBubble extends StatefulWidget {
  final Message message;
  final bool isUser;

  const AnimatedMessageBubble({super.key, required this.message, required this.isUser});

  @override
  State<AnimatedMessageBubble> createState() => _AnimatedMessageBubbleState();
}

class _AnimatedMessageBubbleState extends State<AnimatedMessageBubble> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 500),
        vsync: this,
    );
    
    _offsetAnimation = Tween<Offset>(
        begin: const Offset(0, 0.5), 
        end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart));

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.currentTheme;
    return SlideTransition(
      position: _offsetAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Align(
                alignment: widget.isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        gradient: widget.isUser 
                            ? currentTheme.gradient
                            : null,
                        color: widget.isUser ? null : currentTheme.cardColor, // AI Bg
                        borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20),
                            topRight: const Radius.circular(20),
                            bottomLeft: widget.isUser ? const Radius.circular(20) : const Radius.circular(5),
                            bottomRight: widget.isUser ? const Radius.circular(5) : const Radius.circular(20),
                        ),
                        boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(currentTheme.isDark ? 0.1 : 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2)
                            )
                        ]
                    ),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                             // Role Label
                            Text(
                                widget.isUser ? l10n.you : l10n.assistant,
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: widget.isUser ? Colors.white.withOpacity(0.8) : currentTheme.primaryColor.withOpacity(0.8),
                                    letterSpacing: 0.5
                                ),
                            ),
                            const SizedBox(height: 4),
                            // Message Content
                            Text(
                                widget.message.text,
                                style: TextStyle(
                                    color: widget.isUser ? Colors.white : currentTheme.textColor, 
                                    fontSize: 15, 
                                    height: 1.4
                                ),
                            ),
                        ]
                    ),
                ),
            )
        ),
      ),
    );
  }
}

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = Provider.of<ThemeProvider>(context).currentTheme;
    final l10n = AppLocalizations.of(context)!;
      return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
              color: currentTheme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: currentTheme.secondaryTextColor.withOpacity(0.1))
          ),
          child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                  return FadeTransition(
                      opacity: CurvedAnimation(parent: _controller, curve: Interval(index * 0.2, 0.6 + index * 0.2, curve: Curves.easeInOut)),
                      child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          width: 8, height: 8,
                          decoration: BoxDecoration(color: currentTheme.primaryColor, shape: BoxShape.circle),
                      ),
                  );
              }),
          ),
      );
  }
}
