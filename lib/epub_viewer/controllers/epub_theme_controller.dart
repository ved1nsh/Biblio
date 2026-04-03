import 'package:flutter/material.dart';

class ReaderThemeConfig {
  final String id;
  final String name;
  final Color backgroundColor;
  final Color textColor;
  final bool isDark;

  const ReaderThemeConfig({
    required this.id,
    required this.name,
    required this.backgroundColor,
    required this.textColor,
    required this.isDark,
  });
}

class EpubThemeController extends ChangeNotifier {
  // --- THEME DATA ---
  static const List<ReaderThemeConfig> _themes = [
    ReaderThemeConfig(
      id: 'day',
      name: 'Day',
      backgroundColor: Color(0xFFFFFFFF),
      textColor: Color(0xFF121212),
      isDark: false,
    ),
    ReaderThemeConfig(
      id: 'paper',
      name: 'Paper',
      backgroundColor: Color(0xFFFAF8F1),
      textColor: Color(0xFF333333),
      isDark: false,
    ),
    ReaderThemeConfig(
      id: 'night',
      name: 'Night',
      backgroundColor: Color(0xFF1C1C1E),
      textColor: Color(0xFFEBEBF5),
      isDark: true,
    ),
    ReaderThemeConfig(
      id: 'true_dark',
      name: 'True Dark',
      backgroundColor: Color(0xFF000000),
      textColor: Color.fromARGB(255, 255, 255, 255),
      isDark: true,
    ),
  ];

  ReaderThemeConfig _currentTheme = _themes[0]; // Default = Day

  // --- Font settings (keep defaults) ---
  double _fontSize = 16;
  Color _fontColor = Colors.black;
  String _fontFamily = 'Bookerly';
  TextAlign _textAlign = TextAlign.left;
  double _lineHeight = 1.5;
  double _letterSpacing = 0.0;

  // --- Theme getters ---
  List<ReaderThemeConfig> get availableThemes => _themes;
  ReaderThemeConfig get currentTheme => _currentTheme;

  bool get isDarkMode => _currentTheme.isDark;

  Color get backgroundColor => _currentTheme.backgroundColor;
  Color get textColor => _currentTheme.textColor;
  Color get fontColor => _fontColor;

  // --- Exposed UI colors ---
  Color get sheetBackgroundColor =>
      _currentTheme.backgroundColor; // follows theme

  Color get handleColor => isDarkMode ? Colors.white24 : Colors.black26;

  Color get buttonBackgroundColor =>
      isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFF5F6F2);

  Color get buttonIconColor => isDarkMode ? Colors.white : Colors.black87;

  Color get sheetGradientStart =>
      isDarkMode ? const Color(0xFF000000) : const Color(0xFFFFFFFF);

  Color get dividerColor => isDarkMode ? Colors.white10 : Colors.black12;

  Color get stepperBackgroundColor =>
      isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFF5F6F2);

  // --- Font getters ---
  double get fontSize => _fontSize;
  String get fontFamily => _fontFamily;
  TextAlign get textAlign => _textAlign;
  double get lineHeight => _lineHeight;
  double get letterSpacing => _letterSpacing;

  List<String> get availableFonts => const [
    'Bookerly',
    'Merriweather',
    'Baskerville',
    'Palatino',
    'Literata',
  ];

  // --- Actions ---
  void setTheme(ReaderThemeConfig theme) {
    _currentTheme = theme;
    notifyListeners();
  }

  void toggleDarkMode() {
    _currentTheme = isDarkMode ? _themes[0] : _themes[2];
    notifyListeners();
  }

  void setFontSize(double value) {
    _fontSize = value;
    notifyListeners();
  }

  void setFontColor(Color color) {
    _fontColor = color;
    notifyListeners();
  }

  void setFontFamily(String family) {
    _fontFamily = family;
    notifyListeners();
  }

  void setTextAlign(TextAlign align) {
    _textAlign = align;
    notifyListeners();
  }

  void setLineHeight(double value) {
    _lineHeight = value.clamp(1.0, 4.0);
    notifyListeners();
  }

  void setLetterSpacing(double value) {
    _letterSpacing = value.clamp(-2.0, 10.0);
    notifyListeners();
  }

  void adjustLineHeight(double delta) {
    final newValue = double.parse((_lineHeight + delta).toStringAsFixed(1));
    setLineHeight(newValue);
  }

  void adjustLetterSpacing(double delta) {
    final newValue = double.parse((_letterSpacing + delta).toStringAsFixed(1));
    setLetterSpacing(newValue);
  }
}
