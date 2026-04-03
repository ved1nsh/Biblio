// Builds custom CSS for the reader based on theme and font settings.

import 'package:biblio/epub_viewer/controllers/epub_theme_controller.dart';
import 'package:flutter/material.dart';

class EpubCssBuilder {
  static String buildReaderCss({
    required EpubThemeController theme,
    required String selectedFont,
    required String? fontBase64,
  }) {
    if (fontBase64 == null || fontBase64.isEmpty) {
      return '';
    }

    final textHex =
        '#${theme.textColor.value.toRadixString(16).padLeft(8, '0').substring(2)}';
    final bgHex =
        '#${theme.backgroundColor.value.toRadixString(16).padLeft(8, '0').substring(2)}';

    final alignCss = () {
      switch (theme.textAlign) {
        case TextAlign.left:
          return 'left';
        case TextAlign.right:
          return 'right';
        case TextAlign.center:
          return 'center';
        case TextAlign.justify:
          return 'justify';
        default:
          return 'left';
      }
    }();

    final fontFace = """
@font-face {
  font-family: "$selectedFont";
  src: url(data:font/ttf;base64,$fontBase64);
}
""";

    return """
$fontFace
body {
  font-family: "$selectedFont", serif !important;
  font-size: ${theme.fontSize}px !important;
  color: $textHex !important;
  background-color: $bgHex !important;
  line-height: ${theme.lineHeight} !important;
  letter-spacing: ${theme.letterSpacing}px !important;
  text-align: $alignCss !important;
}
p, div, span, h1, h2, h3, h4, h5, h6 {
  color: inherit !important;
  font-family: inherit !important;
  line-height: inherit !important;
  text-align: inherit !important;
  background-color: transparent !important;
}
""";
  }
}
