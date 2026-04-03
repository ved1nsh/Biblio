import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ColorsTab extends StatefulWidget {
  final Color backgroundColor;
  final Color textColor;
  final String fontFamily;
  final ValueChanged<Color> onBackgroundColorChanged;
  final ValueChanged<Color> onTextColorChanged;
  final Function(Color bg, Color text, String font, {String cardTheme})
  onThemeSelected;

  const ColorsTab({
    super.key,
    required this.backgroundColor,
    required this.textColor,
    required this.fontFamily,
    required this.onBackgroundColorChanged,
    required this.onTextColorChanged,
    required this.onThemeSelected,
  });

  @override
  State<ColorsTab> createState() => _ColorsTabState();
}

class _ColorsTabState extends State<ColorsTab> {
  static const Color _believerBg = Color(0xFFFF2D37);
  static const Color _believerText = Colors.black;

  final ScrollController _bgScrollController = ScrollController();
  final ScrollController _textScrollController = ScrollController();
  final ScrollController _themeScrollController = ScrollController();

  double _bgScrollProgress = 0.0;
  double _textScrollProgress = 0.0;
  double _themeScrollProgress = 0.0;

  static const List<Color> _backgroundColors = [
    Color(0xFFF5E6D3),
    Color(0xFFE8D5C4),
    Color(0xFFD4C5E2),
    Color(0xFFFFB6C1),
    Color(0xFFE0E0E0),
    Color(0xFFB8E6E6),
    Color(0xFFFFE4B5),
    Colors.white,
    Color(0xFF1C1C1E),
    Color(0xFF2D2D2D),
  ];

  static const List<Color> _fontColors = [
    Colors.black,
    Color(0xFF333333),
    Color(0xFF666666),
    Colors.white,
    Color(0xFFD97757),
    Color(0xFF5B4A9E),
    Color(0xFF2E7D6B),
    Color(0xFFC62828),
  ];

  @override
  void initState() {
    super.initState();
    _bgScrollController.addListener(_updateBgScrollProgress);
    _textScrollController.addListener(_updateTextScrollProgress);
    _themeScrollController.addListener(_updateThemeScrollProgress);
  }

  @override
  void dispose() {
    _bgScrollController.dispose();
    _textScrollController.dispose();
    _themeScrollController.dispose();
    super.dispose();
  }

  void _updateBgScrollProgress() {
    if (_bgScrollController.hasClients) {
      final maxScroll = _bgScrollController.position.maxScrollExtent;
      final currentScroll = _bgScrollController.offset;
      setState(() {
        _bgScrollProgress = maxScroll > 0 ? (currentScroll / maxScroll) : 0;
      });
    }
  }

  void _updateTextScrollProgress() {
    if (_textScrollController.hasClients) {
      final maxScroll = _textScrollController.position.maxScrollExtent;
      final currentScroll = _textScrollController.offset;
      setState(() {
        _textScrollProgress = maxScroll > 0 ? (currentScroll / maxScroll) : 0;
      });
    }
  }

  void _updateThemeScrollProgress() {
    if (_themeScrollController.hasClients) {
      final maxScroll = _themeScrollController.position.maxScrollExtent;
      final currentScroll = _themeScrollController.offset;
      setState(() {
        _themeScrollProgress = maxScroll > 0 ? (currentScroll / maxScroll) : 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        (20 * scale).clamp(16.0, 20.0),
        16,
        (20 * scale).clamp(16.0, 20.0),
        8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('BACKGROUND', scale),
          const SizedBox(height: 10),
          SizedBox(
            height: (52 * scale).roundToDouble(),
            child: ListView.separated(
              controller: _bgScrollController,
              scrollDirection: Axis.horizontal,
              itemCount: _backgroundColors.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final color = _backgroundColors[index];
                final isSelected = widget.backgroundColor == color;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.onBackgroundColorChanged(color);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: (52 * scale).roundToDouble(),
                    height: (52 * scale).roundToDouble(),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isSelected
                                ? const Color(0xFFD97757)
                                : Colors.grey.shade300,
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                    child:
                        isSelected
                            ? Icon(
                              Icons.check,
                              color:
                                  _isLightColor(color)
                                      ? Colors.black
                                      : Colors.white,
                              size: (20 * scale).roundToDouble(),
                            )
                            : null,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          _buildScrollIndicator(_bgScrollProgress, scale),

          const SizedBox(height: 24),

          _sectionLabel('TEXT COLOR', scale),
          const SizedBox(height: 10),
          SizedBox(
            height: (52 * scale).roundToDouble(),
            child: ListView.separated(
              controller: _textScrollController,
              scrollDirection: Axis.horizontal,
              itemCount: _fontColors.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final color = _fontColors[index];
                final isSelected = widget.textColor == color;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.onTextColorChanged(color);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: (52 * scale).roundToDouble(),
                    height: (52 * scale).roundToDouble(),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            isSelected
                                ? const Color(0xFFD97757)
                                : Colors.grey.shade300,
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                    child:
                        isSelected
                            ? Icon(
                              Icons.check,
                              color:
                                  _isLightColor(color)
                                      ? Colors.black
                                      : Colors.white,
                              size: (20 * scale).roundToDouble(),
                            )
                            : null,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          _buildScrollIndicator(_textScrollProgress, scale),

          const SizedBox(height: 24),

          _sectionLabel('THEMES', scale),
          const SizedBox(height: 10),
          SizedBox(
            height: (80 * scale).roundToDouble(),
            child: ListView(
              controller: _themeScrollController,
              scrollDirection: Axis.horizontal,
              children: [
                _buildThemePreset(
                  name: 'Classic',
                  bg: const Color(0xFFF5E6D3),
                  text: Colors.black,
                  font: 'Palatino',
                  scale: scale,
                ),
                const SizedBox(width: 10),
                _buildThemePreset(
                  name: 'Dark',
                  bg: const Color(0xFF1C1C1E),
                  text: Colors.white,
                  font: 'NeueMontreal',
                  scale: scale,
                ),
                const SizedBox(width: 10),
                _buildThemePreset(
                  name: 'Lavender',
                  bg: const Color(0xFFD4C5E2),
                  text: const Color(0xFF333333),
                  font: 'Larken',
                  scale: scale,
                ),
                const SizedBox(width: 10),
                _buildThemePreset(
                  name: 'Minimal',
                  bg: Colors.white,
                  text: Colors.black,
                  font: 'Literata',
                  scale: scale,
                ),
                const SizedBox(width: 10),
                _buildThemePreset(
                  name: 'Warm',
                  bg: const Color(0xFFFFE4B5),
                  text: const Color(0xFFC62828),
                  font: 'Raleway',
                  scale: scale,
                ),
                const SizedBox(width: 10),
                _buildBelieverThemePreset(scale),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _buildScrollIndicator(_themeScrollProgress, scale),
        ],
      ),
    );
  }

  Widget _buildScrollIndicator(double progress, double scale) {
    return Center(
      child: Container(
        width: (120 * scale).roundToDouble(),
        height: (3 * scale).clamp(2.0, 4.0),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(2),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate indicator width (30% of track)
            final indicatorWidth = constraints.maxWidth * 0.3;
            // Calculate max travel distance (track width - indicator width)
            final maxTravel = constraints.maxWidth - indicatorWidth;
            // Calculate current position
            final position = progress * maxTravel;

            return Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 150),
                  left: position,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: indicatorWidth,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97757),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildThemePreset({
    required String name,
    required Color bg,
    required Color text,
    required String font,
    required double scale,
  }) {
    final isSelected =
        widget.backgroundColor == bg &&
        widget.textColor == text &&
        widget.fontFamily == font;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onThemeSelected(bg, text, font, cardTheme: 'default');
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: (100 * scale).roundToDouble(),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFFD97757) : Colors.grey.shade300,
            width: isSelected ? 3 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Aa',
              style: TextStyle(
                fontFamily: font,
                fontSize: (22 * scale).clamp(18.0, 22.0),
                color: text,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: TextStyle(
                fontFamily: 'SF-UI-Display',
                fontSize: (10 * scale).clamp(9.0, 10.0),
                color: text.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBelieverThemePreset(double scale) {
    final isSelected =
        widget.backgroundColor == _believerBg &&
        widget.textColor == _believerText;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onThemeSelected(
          _believerBg,
          _believerText,
          'NeueMontreal',
          cardTheme: 'believer',
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: (130 * scale).roundToDouble(),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _believerBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFFD97757) : Colors.grey.shade300,
            width: isSelected ? 3 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: (16 * scale).roundToDouble(),
                  height: (16 * scale).roundToDouble(),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0B253A), Color(0xFF111111)],
                    ),
                  ),
                  child: Icon(
                    Icons.menu_book_rounded,
                    size: (10 * scale).roundToDouble(),
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Believer\nImagine Dragons',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'SF-UI-Display',
                      fontSize: (7 * scale).clamp(6.0, 7.0),
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              'Biblio',
              style: TextStyle(
                fontFamily: 'SF-UI-Display',
                fontSize: (9 * scale).clamp(8.0, 9.0),
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isLightColor(Color color) {
    return color.computeLuminance() > 0.5;
  }

  Widget _sectionLabel(String text, double scale) {
    return Text(
      text,
      style: TextStyle(
        fontSize: (11 * scale).clamp(9.0, 11.0),
        fontWeight: FontWeight.w600,
        fontFamily: 'SF-UI-Display',
        color: Colors.grey.shade500,
        letterSpacing: 0.8,
      ),
    );
  }
}
