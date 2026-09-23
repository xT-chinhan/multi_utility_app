import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../../services/mlkit_translation_service.dart';

class RealtimeCameraView extends StatefulWidget {
  const RealtimeCameraView({super.key});

  @override
  State<RealtimeCameraView> createState() => _RealtimeCameraViewState();
}

class _RealtimeCameraViewState extends State<RealtimeCameraView> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInit = false;
  bool _isBusy = false;
  String _detectedText = '';
  String _translatedText = '';
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _controller = CameraController(
          _cameras![0],
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await _controller!.initialize();
        if (mounted) {
          setState(() {
            _isInit = true;
          });
          _startContinuousScanning();
        }
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  void _startContinuousScanning() async {
    while (mounted && _controller != null && _controller!.value.isInitialized) {
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) break;
      if (!_isBusy) {
        await _captureAndProcessFrame();
      }
    }
  }

  Future<void> _captureAndProcessFrame() async {
    if (_controller == null || !_controller!.value.isInitialized || _isBusy) return;
    _isBusy = true;

    try {
      final xfile = await _controller!.takePicture();
      final inputImage = InputImage.fromFilePath(xfile.path);
      final recognized = await _textRecognizer.processImage(inputImage);

      // Clean up temporary frame file
      try {
        await File(xfile.path).delete();
      } catch (_) {}

      final extracted = recognized.text.trim();
      if (extracted.isNotEmpty && extracted != _detectedText && mounted) {
        setState(() {
          _detectedText = extracted;
        });

        final trans = await MlkitTranslationService.instance.translate(extracted);
        if (mounted) {
          setState(() {
            _translatedText = trans;
          });
        }
      }
    } catch (e) {
      debugPrint('Frame processing error: $e');
    } finally {
      _isBusy = false;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInit || _controller == null || !_controller!.value.isInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Đang khởi động Camera máy ảo...'),
          ],
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera Viewport
        CameraPreview(_controller!),

        // Viewfinder Target Frame
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            height: 220,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.amberAccent, width: 2.5),
              borderRadius: BorderRadius.circular(16),
              color: Colors.black.withAlpha(25),
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'HƯỚNG CAMERA VÀO VĂN BẢN ĐỂ DỊCH REALTIME',
                  style: TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ),

        // Realtime Translation Result Overlay
        Positioned(
          bottom: 20,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(220),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.greenAccent.shade400, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'KẾT QUẢ DỊCH REALTIME (ML KIT):',
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _detectedText.isEmpty
                      ? 'Đang quét văn bản trước ống kính...'
                      : '📝 Gốc: $_detectedText',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  _translatedText.isEmpty
                      ? '⚡ Bản dịch sẽ xuất hiện ngay tức thì...'
                      : '🌐 Dịch: $_translatedText',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
