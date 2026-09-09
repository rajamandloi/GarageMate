import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final ImagePicker _picker = ImagePicker();

  final TextRecognizer _textRecognizer =
      TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  bool _isProcessing = false;

  String _status =
      'Number plate ki clear photo lein';

  Future<void> _scanNumberPlate() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _status = 'Camera open ho rahi hai...';
    });

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
      );

      if (!mounted) return;

      if (image == null) {
        setState(() {
          _isProcessing = false;
          _status = 'Photo cancel kar di gayi';
        });
        return;
      }

      setState(() {
        _status = 'Number plate read ho rahi hai...';
      });

      final inputImage =
          InputImage.fromFilePath(image.path);

      final recognizedText =
          await _textRecognizer.processImage(
        inputImage,
      );

      final plate =
          _extractRegistrationNumber(
        recognizedText.text,
      );

      if (!mounted) return;

      if (plate != null) {
        Navigator.pop(context, plate);
        return;
      }

      setState(() {
        _isProcessing = false;
        _status =
            'Number plate read nahi hui.\n'
            'Plate ko clear aur paas se capture karein.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isProcessing = false;
        _status =
            'Scan failed. Dobara try karein.';
      });
    }
  }

  String? _extractRegistrationNumber(String text) {
    if (text.trim().isEmpty) {
      return null;
    }

    final normalized = text
        .toUpperCase()
        .replaceAll(
          RegExp(r'[^A-Z0-9]'),
          '',
        );

    final pattern = RegExp(
      r'[A-Z]{2}[0-9]{1,2}[A-Z]{1,3}[0-9]{3,4}',
    );

    final match = pattern.firstMatch(normalized);

    if (match != null) {
      return match.group(0);
    }

    return null;
  }

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Scan Vehicle Number',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: Colors.black,
            child: Center(
              child: Icon(
                Icons.directions_car_rounded,
                size: 110,
                color: Colors.white24,
              ),
            ),
          ),

          Center(
            child: Container(
              width: 330,
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                borderRadius:
                    BorderRadius.circular(16),
              ),
            ),
          ),

          Positioned(
            left: 20,
            right: 20,
            bottom: 120,
            child: Container(
              padding:
                  const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius:
                    BorderRadius.circular(16),
              ),
              child: Text(
                _status,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          Positioned(
            left: 20,
            right: 20,
            bottom: 35,
            child: FilledButton.icon(
              onPressed: _isProcessing
                  ? null
                  : _scanNumberPlate,
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
                    : 'Scan Number Plate',
              ),
            ),
          ),
        ],
      ),
    );
  }
}