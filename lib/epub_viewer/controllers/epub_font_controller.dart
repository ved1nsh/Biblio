import 'dart:convert';
import 'package:flutter/services.dart';

class EpubFontController {
  final Map<String, String> _fontMap = {};

  static const Map<String, String> fontAssets = {
    'Bookerly': 'assets/fonts/Bookerly Light.ttf',
    'Merriweather': 'assets/fonts/Merriweather_24pt-Light.ttf',
    'Baskerville': 'assets/fonts/Baskervville-Regular.ttf',
    'Palatino': 'assets/fonts/palr45w.ttf',
    'Literata': 'assets/fonts/Literata-Light.ttf',
  };

  String? getFontBase64(String fontFamily) => _fontMap[fontFamily];

  Future<void> loadFont(String fontFamily) async {
    final assetPath = fontAssets[fontFamily];
    if (assetPath == null) return;

    if (_fontMap.containsKey(fontFamily)) return;

    final data = await rootBundle.load(assetPath);
    final base64Font = base64Encode(data.buffer.asUint8List());
    _fontMap[fontFamily] = base64Font;
  }
}
