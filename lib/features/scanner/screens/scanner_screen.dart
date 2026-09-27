import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final ImagePicker _picker = ImagePicker();

  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  bool _isProcessing = false;
  int _attemptCount = 0;

  String _status = 'Number plate की clear photo लें';

  // ============================================================
  // SCAN FROM CAMERA
  // ============================================================

  Future<void> _scanFromCamera() async {
    if (_isProcessing) return;

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
        maxWidth: 1920,
      );

      if (image == null) return;

      await _processImage(image.path);
    } catch (e) {
      _showError('Camera खोलने में समस्या: $e');
    }
  }

  // ============================================================
  // SCAN FROM GALLERY
  // ============================================================

  Future<void> _scanFromGallery() async {
    if (_isProcessing) return;

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
        maxWidth: 1920,
      );

      if (image == null) return;

      await _processImage(image.path);
    } catch (e) {
      _showError('Gallery खोलने में समस्या: $e');
    }
  }

  // ============================================================
  // PROCESS IMAGE
  // ============================================================

  Future<void> _processImage(String imagePath) async {
    setState(() {
      _isProcessing = true;
      _status = 'Photo process हो रही है...';
    });

    try {
      setState(() {
        _status = 'Image enhance हो रही है...';
      });

      final enhancedPath = await _enhanceImage(imagePath);

      setState(() {
        _status = 'Number plate पढ़ रहे हैं...';
      });

      String? plate = await _tryExtractPlate(enhancedPath);

      if (plate == null && enhancedPath != imagePath) {
        setState(() {
          _status = 'दूसरी बार try कर रहे हैं...';
        });

        plate = await _tryExtractPlate(imagePath);
      }

      if (!mounted) return;

      if (plate != null) {
        Navigator.pop(context, plate);
        return;
      }

      _attemptCount++;

      setState(() {
        _isProcessing = false;

        if (_attemptCount >= 3) {
          _status =
              'Number plate नहीं मिली।\n\n'
              'Manual entry करें या नई photo लें।';
        } else {
          _status =
              'Number plate साफ नहीं दिख रही।\n\n'
              '• Plate frame के अंदर लें\n'
              '• अच्छी रोशनी में लें\n'
              '• पास से लें (1-2 feet)\n'
              '• सीधा angle रखें';
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isProcessing = false;
        _status = 'Error: $e';
      });
    }
  }

  // ============================================================
  // ENHANCE IMAGE
  // ============================================================

  Future<String> _enhanceImage(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();

      img.Image? original = img.decodeImage(bytes);

      if (original == null) return imagePath;

      if (original.width > 1600) {
        original = img.copyResize(
          original,
          width: 1600,
        );
      }

      final gray = img.grayscale(original);

      final contrasted = img.adjustColor(
        gray,
        contrast: 1.3,
      );

      final sharpened = img.convolution(
        contrasted,
        filter: [
          0, -1, 0,
          -1, 5, -1,
          0, -1, 0,
        ],
      );

      final tempDir = Directory.systemTemp;
      final tempFile = File(
        '${tempDir.path}/enhanced_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      await tempFile.writeAsBytes(
        img.encodeJpg(sharpened, quality: 95),
      );

      return tempFile.path;
    } catch (e) {
      return imagePath;
    }
  }

  // ============================================================
  // TRY EXTRACT PLATE
  // ============================================================

  Future<String?> _tryExtractPlate(String imagePath) async {
    try {
      final inputImage =
          InputImage.fromFilePath(imagePath);

      final recognizedText =
          await _textRecognizer.processImage(inputImage);

      final rawText = recognizedText.text;

      if (rawText.trim().isEmpty) return null;

      return _parsePlate(rawText);
    } catch (e) {
      return null;
    }
  }

  // ============================================================
  // PARSE PLATE
  // ============================================================

  String? _parsePlate(String rawText) {
    final normalized = rawText
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final compact = normalized.replaceAll(' ', '');

    final patterns = [
      RegExp(r'([A-Z]{2})(\d{2})([A-Z]{1,3})(\d{4})'),
      RegExp(r'([A-Z]{2})(\d{2})([A-Z]{1,3})(\d{3})'),
      RegExp(r'([A-Z]{2})(\d{2})(\d{4})'),
      RegExp(r'(BH)(\d{2})([A-Z]{1,3})(\d{4})'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(compact);

      if (match != null) {
        final plate = match.group(0)!;

        if (_isValidStateCode(plate.substring(0, 2))) {
          return plate;
        }
      }
    }

    final fuzzy = compact
        .replaceAll('O', '0')
        .replaceAll('I', '1')
        .replaceAll('S', '5')
        .replaceAll('B', '8')
        .replaceAll('Z', '2')
        .replaceAll('G', '6')
        .replaceAll('Q', '0')
        .replaceAll('D', '0');

    for (final pattern in patterns) {
      final match = pattern.firstMatch(fuzzy);

      if (match != null) {
        final plate = match.group(0)!;

        if (_isValidStateCode(plate.substring(0, 2))) {
          return plate;
        }
      }
    }

    final parts = normalized.split(' ');

    for (int i = 0; i < parts.length; i++) {
      for (int len = 2; len <= 4; len++) {
        if (i + len > parts.length) break;

        final combined =
            parts.sublist(i, i + len).join('');

        for (final pattern in patterns) {
          final match = pattern.firstMatch(combined);

          if (match != null) {
            final plate = match.group(0)!;

            if (_isValidStateCode(plate.substring(0, 2))) {
              return plate;
            }
          }
        }
      }
    }

    return null;
  }

  // ============================================================
  // VALIDATE STATE CODE
  // ============================================================

  bool _isValidStateCode(String code) {
    const validStates = {
      'AN', 'AP', 'AR', 'AS', 'BR', 'CH', 'CG', 'DD',
      'DL', 'DN', 'GA', 'GJ', 'HR', 'HP', 'JK', 'JH',
      'KA', 'KL', 'LA', 'LD', 'MH', 'ML', 'MN', 'MP',
      'MZ', 'NL', 'OD', 'OR', 'PB', 'PY', 'RJ', 'SK',
      'TN', 'TS', 'TR', 'UK', 'UA', 'UP', 'WB', 'BH',
    };

    return validStates.contains(code);
  }

  // ============================================================
  // MANUAL ENTRY
  // ============================================================

  Future<void> _showManualEntry() async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Enter Number Plate',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Type the vehicle number manually:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization:
                    TextCapitalization.characters,
                maxLength: 10,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
                decoration: const InputDecoration(
                  hintText: 'MP09AB1234',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final text = controller.text
                    .toUpperCase()
                    .replaceAll(
                      RegExp(r'[^A-Z0-9]'),
                      '',
                    );

                if (text.length >= 6) {
                  Navigator.pop(dialogContext, text);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result != null && mounted) {
      Navigator.pop(context, result);
    }
  }

  // ============================================================
  // SHOW ERROR
  // ============================================================

  void _showError(String message) {
    if (!mounted) return;

    setState(() {
      _isProcessing = false;
      _status = message;
    });
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final showManualOption = _attemptCount >= 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Scan Vehicle Number',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: Colors.black,
            child: const Center(
              child: Icon(
                Icons.directions_car_rounded,
                size: 110,
                color: Colors.white24,
              ),
            ),
          ),

          if (!_isProcessing)
            Center(
              child: Container(
                width: 330,
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),

          Positioned(
            left: 20,
            right: 20,
            bottom: 200,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isProcessing)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  Text(
                    _status,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            left: 20,
            right: 20,
            bottom: 35,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showManualOption && !_isProcessing) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _showManualEntry,
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text(
                        'Enter Manually',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(
                          color: Colors.white54,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed:
                        _isProcessing ? null : _scanFromCamera,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.document_scanner_rounded,
                          ),
                    label: Text(
                      _isProcessing
                          ? 'Reading...'
                          : 'Scan with Camera',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed:
                        _isProcessing ? null : _scanFromGallery,
                    icon: const Icon(Icons.photo_library_rounded),
                    label: const Text(
                      'Upload from Gallery',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(
                        color: Colors.white70,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}