import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Performs text recognition (OCR) on an image file using Google ML Kit.
class OcrService {
  /// Recognizes text from the given image file path.
  /// Returns the recognized text as a single string, or null if recognition fails.
  static Future<String?> recognizeText(String imagePath) async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await textRecognizer.processImage(inputImage);

      if (recognizedText.text.trim().isEmpty) {
        debugPrint('⚠️ OCR: No text found in image');
        return null;
      }

      debugPrint('✅ OCR: Recognized ${recognizedText.text.length} characters');
      return recognizedText.text.trim();
    } catch (e) {
      debugPrint('❌ OCR Error: $e');
      return null;
    } finally {
      textRecognizer.close();
    }
  }
}
