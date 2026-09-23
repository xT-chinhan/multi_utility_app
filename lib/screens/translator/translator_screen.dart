import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../services/mlkit_ocr_service.dart';
import '../../services/mlkit_translation_service.dart';
import '../../theme/app_theme.dart';
import 'widgets/realtime_camera_view.dart';

class TranslatorScreen extends StatefulWidget {
  const TranslatorScreen({super.key});

  @override
  State<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends State<TranslatorScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Text & Voice Tab State
  final TextEditingController _textInputController = TextEditingController();
  String _translatedResult = '';
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isSpeechListening = false;
  bool _isTranslating = false;

  // Image OCR Tab State
  File? _selectedImage;
  String _extractedOcrText = '';
  String _translatedOcrResult = '';
  bool _isOcrScanning = false;

  final List<Map<String, dynamic>> _supportedLanguages = [
    {'lang': TranslateLanguage.vietnamese, 'name': 'Tiếng Việt', 'flag': '🇻🇳'},
    {'lang': TranslateLanguage.english, 'name': 'English', 'flag': '🇺🇸'},
    {'lang': TranslateLanguage.french, 'name': 'Français', 'flag': '🇫🇷'},
    {'lang': TranslateLanguage.japanese, 'name': '日本語', 'flag': '🇯🇵'},
    {'lang': TranslateLanguage.korean, 'name': '한국어', 'flag': '🇰🇷'},
    {'lang': TranslateLanguage.chinese, 'name': '中文', 'flag': '🇨🇳'},
  ];

  late TranslateLanguage _sourceLang;
  late TranslateLanguage _targetLang;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _sourceLang = TranslateLanguage.vietnamese;
    _targetLang = TranslateLanguage.english;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textInputController.dispose();
    super.dispose();
  }

  // --- TAB 1: TEXT & VOICE TRANSLATION (7đ & 9đ) ---
  Future<void> _performTextTranslation() async {
    final text = _textInputController.text.trim();
    if (text.isEmpty) {
      _showToast('Vui lòng nhập văn bản cần dịch!');
      return;
    }

    setState(() => _isTranslating = true);
    MlkitTranslationService.instance.setLanguagePair(
      source: _sourceLang,
      target: _targetLang,
    );

    final res = await MlkitTranslationService.instance.translate(text);
    if (mounted) {
      setState(() {
        _translatedResult = res;
        _isTranslating = false;
      });
    }
  }

  Future<void> _startVoiceToTranslate() async {
    final available = await _speech.initialize();
    if (!available) {
      _showToast('Không thể kết nối dịch vụ Speech-to-Text.');
      return;
    }

    setState(() => _isSpeechListening = true);

    final localeId = _sourceLang == TranslateLanguage.vietnamese ? 'vi_VN' : 'en_US';

    await _speech.listen(
      listenOptions: stt.SpeechListenOptions(
        localeId: localeId,
        listenFor: const Duration(seconds: 8),
        pauseFor: const Duration(seconds: 3),
      ),
      onResult: (result) async {
        _textInputController.text = result.recognizedWords;
        if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
          setState(() => _isSpeechListening = false);
          await _performTextTranslation();
        }
      },
    );
  }

  Future<void> _stopVoice() async {
    await _speech.stop();
    setState(() => _isSpeechListening = false);
    if (_textInputController.text.trim().isNotEmpty) {
      await _performTextTranslation();
    }
  }

  // --- TAB 2: IMAGE OCR TRANSLATION (10đ) ---
  Future<void> _pickAndTranslateImage(ImageSource source) async {
    setState(() => _isOcrScanning = true);
    final ocrRes = await MlkitOcrService.instance.scanImage(source);

    if (ocrRes == null) {
      setState(() => _isOcrScanning = false);
      return;
    }

    setState(() {
      _selectedImage = ocrRes.imageFile;
      _extractedOcrText = ocrRes.text.trim();
    });

    if (_extractedOcrText.isEmpty) {
      setState(() {
        _translatedOcrResult = 'Không tìm thấy chữ trong bức ảnh này.';
        _isOcrScanning = false;
      });
      return;
    }

    MlkitTranslationService.instance.setLanguagePair(
      source: _sourceLang,
      target: _targetLang,
    );

    final trans = await MlkitTranslationService.instance.translate(_extractedOcrText);
    if (mounted) {
      setState(() {
        _translatedOcrResult = trans;
        _isOcrScanning = false;
      });
    }
  }

  void _swapLanguages() {
    setState(() {
      final temp = _sourceLang;
      _sourceLang = _targetLang;
      _targetLang = temp;
    });
    if (_textInputController.text.isNotEmpty) {
      _performTextTranslation();
    }
  }

  void _showToast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Google ML Kit Dịch Thuật'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryBlue,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.translate_rounded), text: 'Text & Voice\n(7đ - 9đ)'),
            Tab(icon: Icon(Icons.document_scanner_rounded), text: 'Ảnh Chụp\n(10đ)'),
            Tab(icon: Icon(Icons.videocam_rounded), text: 'Realtime\n(Điểm +)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTextAndVoiceTab(isDark),
          _buildImageOcrTab(isDark),
          const RealtimeCameraView(),
        ],
      ),
    );
  }

  // --- WIDGET TAB 1: TEXT & VOICE ---
  Widget _buildTextAndVoiceTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Language selector bar
          _buildLanguageSelectorBar(isDark),

          const SizedBox(height: 16),

          // Input Text Card (Requirement: Dịch text 7đ)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Nhập văn bản nguồn:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      if (_textInputController.text.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _textInputController.clear();
                              _translatedResult = '';
                            });
                          },
                          child: const Icon(Icons.clear_rounded, size: 20, color: Colors.grey),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _textInputController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Nhập nội dung cần dịch hoặc bấm Micro bên dưới...',
                      border: InputBorder.none,
                    ),
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Voice to Text Button (Requirement: Dịch từ giọng nói 9đ)
                      ElevatedButton.icon(
                        onPressed: _isSpeechListening ? _stopVoice : _startVoiceToTranslate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isSpeechListening ? Colors.redAccent : Colors.amber.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: Icon(_isSpeechListening ? Icons.stop_rounded : Icons.mic_rounded, size: 18),
                        label: Text(_isSpeechListening ? 'Đang nghe...' : 'Nói để dịch (9đ)'),
                      ),

                      // Manual Translate Button (Requirement: Dịch text 7đ)
                      ElevatedButton.icon(
                        onPressed: _isTranslating ? null : _performTextTranslation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: _isTranslating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.arrow_forward_rounded, size: 18),
                        label: const Text('Dịch (7đ)'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Output Result Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            color: isDark ? Colors.grey.shade900 : Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Bản dịch (Google ML Kit):',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_translatedResult.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          tooltip: 'Sao chép',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _translatedResult));
                            _showToast('Đã sao chép bản dịch vào bộ nhớ tạm!');
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _translatedResult.isEmpty
                        ? 'Kết quả dịch on-device sẽ hiển thị tại đây...'
                        : _translatedResult,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: _translatedResult.isEmpty ? FontWeight.normal : FontWeight.bold,
                      color: _translatedResult.isEmpty ? Colors.grey : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET TAB 2: IMAGE OCR TRANSLATION (10đ) ---
  Widget _buildImageOcrTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner 10đ
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.purple.withAlpha(80)),
            ),
            child: const Row(
              children: [
                Icon(Icons.camera_alt_rounded, color: Colors.purple),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Yêu Cầu 4 (10đ): Trích xuất chữ bằng ML Kit OCR từ Camera/Thư viện và dịch tự động',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.purple),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Two Action Buttons: Camera & Gallery
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isOcrScanning ? null : () => _pickAndTranslateImage(ImageSource.camera),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.photo_camera_rounded),
                  label: const Text('Chụp Ảnh (10đ)', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isOcrScanning ? null : () => _pickAndTranslateImage(ImageSource.gallery),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.photo_library_rounded),
                  label: const Text('Chọn Thư Viện', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (_isOcrScanning)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Đang quét chữ và dịch bằng Google ML Kit...'),
                  ],
                ),
              ),
            )
          else ...[
            // Image Preview if captured
            if (_selectedImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 200,
                  width: double.infinity,
                  color: Colors.black12,
                  child: Image.file(_selectedImage!, fit: BoxFit.contain),
                ),
              ),

            const SizedBox(height: 16),

            // Extracted OCR text
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.text_snippet_rounded, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Văn bản trích xuất từ ảnh (ML Kit OCR):',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _extractedOcrText.isEmpty ? '(Chưa có ảnh nào được quét)' : _extractedOcrText,
                      style: TextStyle(
                        fontStyle: _extractedOcrText.isEmpty ? FontStyle.italic : FontStyle.normal,
                        color: _extractedOcrText.isEmpty ? Colors.grey : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Translated OCR result
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: isDark ? Colors.grey.shade900 : Colors.purple.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.g_translate_rounded, color: Colors.purple),
                        SizedBox(width: 8),
                        Text(
                          'Bản dịch ML Kit từ ảnh chụp:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _translatedOcrResult.isEmpty ? '(Kết quả dịch sẽ hiện tại đây)' : _translatedOcrResult,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: _translatedOcrResult.isEmpty ? Colors.grey : Colors.purple.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- LANGUAGE SELECTOR BAR ---
  Widget _buildLanguageSelectorBar(bool isDark) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Source Language Dropdown
            DropdownButton<TranslateLanguage>(
              value: _sourceLang,
              underline: const SizedBox.shrink(),
              items: _supportedLanguages.map((item) {
                return DropdownMenuItem<TranslateLanguage>(
                  value: item['lang'] as TranslateLanguage,
                  child: Text('${item['flag']} ${item['name']}'),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _sourceLang = val);
              },
            ),

            // Swap Button
            IconButton(
              icon: const Icon(Icons.swap_horiz_rounded, color: AppTheme.primaryBlue),
              onPressed: _swapLanguages,
            ),

            // Target Language Dropdown
            DropdownButton<TranslateLanguage>(
              value: _targetLang,
              underline: const SizedBox.shrink(),
              items: _supportedLanguages.map((item) {
                return DropdownMenuItem<TranslateLanguage>(
                  value: item['lang'] as TranslateLanguage,
                  child: Text('${item['flag']} ${item['name']}'),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _targetLang = val);
              },
            ),
          ],
        ),
      ),
    );
  }
}
