import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart'; // Import Camera
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../services/translate_service.dart';
import '../services/auth_service.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'package:lamp_flutter_app/l10n/app_localizations.dart';
import 'login_screen.dart';

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> with WidgetsBindingObserver, TickerProviderStateMixin {
  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _ocrController = TextEditingController();
  final TranslateService _translateService = TranslateService();
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();
  
  // Camera State
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  int _selectedCameraIndex = 0;

  String _sourceLang = 'auto';
  String _targetLang = 'vi';
  bool _isLoading = false;
  bool _isLoggedIn = false;

  // Animation Controller
  late AnimationController _shimmerController;
  int _currentTab = 0; // 0 = Text, 1 = Image

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLogin();
    _initCameras(); // Init cameras early

    // Shimmer controller for login button
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _shimmerController.dispose();
    _cameraController?.dispose();
    _sourceController.dispose();
    _targetController.dispose();
    _ocrController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-initialize camera on resume if needed (mostly for mobile)
    final CameraController? cameraController = _cameraController;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera(_cameras![_selectedCameraIndex]);
    }
  }

  Future<void> _initCameras() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        // Default to the first camera
        _selectedCameraIndex = 0; 
      } else {
        print('No cameras found');
        if (mounted) setState(() => _isCameraInitialized = false); // Ensure UI updates
      }
    } catch (e) {
      print('Camera init error: $e');
      if (mounted) setState(() => _isCameraInitialized = false);
    }
  }

  Future<void> _initCamera(CameraDescription cameraDescription) async {
    final CameraController cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
    );

    _cameraController = cameraController;

    try {
      await cameraController.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      print('Camera controller init error: $e');
    }
  }

  Future<void> _checkLogin() async {
    final loggedIn = await _authService.isLoggedIn();
    setState(() => _isLoggedIn = loggedIn);
  }

  void _translateText() async {
    final text = _sourceController.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      final result = await _translateService.translateText(
        text,
        sourceLang: _sourceLang,
        targetLang: _targetLang,
      );
      setState(() {
        _targetController.text = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _targetController.text = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  void _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    await _processImage(image);
  }

  Future<void> _takePointsPicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (_cameraController!.value.isTakingPicture) return;

    try {
      final XFile image = await _cameraController!.takePicture();
      await _processImage(image);
    } catch (e) {
      print('Error taking picture: $e');
    }
  }
  
  void _switchCamera() async {
      if (_cameras == null || _cameras!.isEmpty) return;
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras!.length;
      await _initCamera(_cameras![_selectedCameraIndex]);
  }

  Future<void> _processImage(XFile imageFile) async {
    setState(() => _isLoading = true);

    try {
      // --- CLIENT-SIDE OCR (ML Kit) ---
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final textRecognizer = TextRecognizer();
      
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      final ocrText = recognizedText.text.trim();
      
      textRecognizer.close();
      
      setState(() => _ocrController.text = ocrText.isNotEmpty ? ocrText : AppLocalizations.of(context)!.noSpeechDetected); // Reusing 'No speech detected' as placeholder or add 'No text detected'

      // Auto-translate
      if (ocrText.isNotEmpty) {
        final translated = await _translateService.translateText(
          ocrText,
          targetLang: _targetLang,
        );
        setState(() {
          _targetController.text = translated;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() {
        _ocrController.text = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.currentTheme;
    final isLoggedIn = authProvider.isLoggedIn;

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: currentTheme.backgroundColor,
      appBar: AppBar(
        title: Text(l10n.translate, style: TextStyle(fontWeight: FontWeight.w600, color: currentTheme.textColor)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
             padding: const EdgeInsets.only(right: 8.0),
             child: isLoggedIn 
                ? IconButton(
                    icon: const Icon(Icons.logout_rounded, color: Colors.redAccent), 
                    onPressed: authProvider.logout
                  )
                 : _buildGradientLoginButton()
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Tabs
            Container(
              color: currentTheme.cardColor,
              child: Row(
                children: [
                  Expanded(child: _buildTab(l10n.text, 0)),
                  Expanded(child: _buildTab(l10n.image, 1)),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _currentTab == 0 ? _buildTextTab() : _buildImageTab(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final currentTheme = Provider.of<ThemeProvider>(context).currentTheme;
    final isActive = _currentTab == index;
    return GestureDetector(
      onTap: () {
          setState(() => _currentTab = index);
          // Lazy load camera when switching to Image tab
          if (index == 1 && !_isCameraInitialized && _cameras != null && _cameras!.isNotEmpty) {
              _initCamera(_cameras![_selectedCameraIndex]);
          }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? currentTheme.primaryColor : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isActive ? currentTheme.primaryColor : currentTheme.secondaryTextColor,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildTextTab() {
    final currentTheme = Provider.of<ThemeProvider>(context).currentTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: currentTheme.cardColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: _sourceController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.enterTextToTranslate,
                hintStyle: TextStyle(color: currentTheme.secondaryTextColor),
                border: InputBorder.none,
              ),
              style: TextStyle(color: currentTheme.textColor, fontSize: 16),
              maxLines: 5,
              onChanged: (_) => _translateText(),
            ),
          ),
          const SizedBox(height: 16),
          // Shortened Lang Selectors for brevity (Assume same as before)
           Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               Column(children: [
                   Text(AppLocalizations.of(context)!.from, style: TextStyle(color: currentTheme.secondaryTextColor, fontSize: 12)),
                   DropdownButton<String>(
                     value: _sourceLang,
                     dropdownColor: currentTheme.cardColor,
                     style: TextStyle(color: currentTheme.textColor),
                     items: ['auto', 'vi', 'en', 'ja', 'ko', 'zh-CN'].map((lang) => DropdownMenuItem(value: lang, child: Text(lang))).toList(),
                     onChanged: (val) { setState(() => _sourceLang = val!); _translateText(); },
                   )
               ]),
               const SizedBox(width: 16),
               Icon(Icons.arrow_forward, color: currentTheme.secondaryTextColor),
               const SizedBox(width: 16),
               Column(children: [
                   Text(AppLocalizations.of(context)!.to, style: TextStyle(color: currentTheme.secondaryTextColor, fontSize: 12)),
                   DropdownButton<String>(
                     value: _targetLang,
                     dropdownColor: currentTheme.cardColor,
                     style: TextStyle(color: currentTheme.textColor),
                     items: ['vi', 'en', 'ja', 'ko', 'zh-CN'].map((lang) => DropdownMenuItem(value: lang, child: Text(lang))).toList(),
                     onChanged: (val) { setState(() => _targetLang = val!); _translateText(); },
                   )
               ]),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: currentTheme.cardColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: _targetController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.translation,
                hintStyle: TextStyle(color: currentTheme.secondaryTextColor),
                border: InputBorder.none,
              ),
              style: TextStyle(color: currentTheme.textColor, fontSize: 16),
              maxLines: 5,
              readOnly: true,
            ),
          ),
          if (_isLoading) Padding(padding: const EdgeInsets.all(16), child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildImageTab() {
    final currentTheme = Provider.of<ThemeProvider>(context).currentTheme;
    // 1. Show Result if available (Prioritize this over Camera Init)
    if (_ocrController.text.isNotEmpty) {
        return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
                children: [
                    // Back Button
                    Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                            icon: const Icon(Icons.arrow_back),
                            label: Text(AppLocalizations.of(context)!.scanAnother),
                            onPressed: () {
                                setState(() {
                                    _ocrController.clear();
                                    _targetController.clear();
                                });
                            },
                        )
                    ),
                    const SizedBox(height: 10),
                     Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: currentTheme.cardColor,
                            borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextField(
                            controller: _ocrController,
                            style: TextStyle(color: currentTheme.textColor),
                            maxLines: null,
                            decoration: InputDecoration(labelText: AppLocalizations.of(context)!.detectedText, border: InputBorder.none),
                        ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: currentTheme.cardColor, // Darker for output
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: currentTheme.primaryColor.withOpacity(0.5))
                        ),
                        child: TextField(
                            controller: _targetController,
                            style: TextStyle(color: currentTheme.textColor, fontSize: 16),
                            maxLines: null,
                             decoration: InputDecoration(labelText: AppLocalizations.of(context)!.translation, border: InputBorder.none),
                            readOnly: true,
                        ),
                    ),
                ]
            )
        );
    }

    // 2. Camera Initialization / Fallback
    if (!_isCameraInitialized || _cameraController == null) {
        return Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    if (_isLoading) ...[
                       const CircularProgressIndicator(),
                       const SizedBox(height: 20),
                       Text(AppLocalizations.of(context)!.processing, style: TextStyle(color: currentTheme.textColor)),
                    ] else ...[
                       const Icon(Icons.videocam_off, size: 50, color: Colors.grey),
                       const SizedBox(height: 20),
                       Text(AppLocalizations.of(context)!.cameraNotAvailable, style: const TextStyle(color: Colors.grey)),
                       const SizedBox(height: 10),
                       Text(AppLocalizations.of(context)!.checkPermissions, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                    const SizedBox(height: 30),
                    // Fallback to Gallery if camera fails
                    ElevatedButton.icon(
                        icon: const Icon(Icons.photo_library),
                        label: const Text("Open Gallery Instead"),
                        onPressed: _pickImage,
                        style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            backgroundColor: currentTheme.primaryColor,
                            foregroundColor: Colors.white
                        ),
                    )
                ]
            )
        );
    }
    
    // 3. Live Camera UI
    return Stack(
      children: [
        // Camera Preview (Full Screen)
        SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: CameraPreview(_cameraController!),
        ),

        // Overlay Gradient (Bottom) for contrast
        Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
                height: 150,
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                    )
                ),
            )
        ),
        
        // Controls (Bottom Row)
        Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                    // Left: Gallery
                    IconButton(
                        icon: const Icon(Icons.photo_library, color: Colors.white, size: 30),
                        onPressed: _pickImage,
                        tooltip: 'Gallery',
                    ),

                    // Center: Shutter
                    GestureDetector(
                        onTap: _takePointsPicture,
                        child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 4),
                                color: Colors.transparent,
                            ),
                            child: Container(
                                margin: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                ),
                            ),
                        ),
                    ),

                    // Right: Switch Camera
                    IconButton(
                        icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 30),
                        onPressed: _switchCamera,
                        tooltip: 'Switch Camera',
                    ),
                ],
            )
        ),

        // Loading Overlay
        if (_isLoading)
            Container(
                color: Colors.black54,
                child: Center(child: CircularProgressIndicator()),
            )
      ],
    );
  }

  // Gradient Login Button (Standardized)
  Widget _buildGradientLoginButton() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.currentTheme;
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, _) {
        final val = _shimmerController.value;
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
            child: Text(AppLocalizations.of(context)!.login, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }
}
