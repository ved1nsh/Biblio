import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FontSizeTab extends StatelessWidget {
  final String fontFamily;
  final double fontSize;
  final bool isBold;
  final bool isItalic;
  final double aspectRatio;
  final ValueChanged<String> onFontFamilyChanged;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<bool> onBoldChanged;
  final ValueChanged<bool> onItalicChanged;
  final ValueChanged<double> onAspectRatioChanged;

  const FontSizeTab({
    super.key,
    required this.fontFamily,
    required this.fontSize,
    required this.isBold,
    required this.isItalic,
    required this.aspectRatio,
    required this.onFontFamilyChanged,
    required this.onFontSizeChanged,
    required this.onBoldChanged,
    required this.onItalicChanged,
    required this.onAspectRatioChanged,
  });

  static const List<String> _fontFamilies = [
    'NeueMontreal',
    'Palatino',
    'Literata',
    'Larken',
    'Raleway',
  ];

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
          _sectionLabel('FONT FAMILY', scale),
          const SizedBox(height: 10),
          SizedBox(
            height: (78 * scale).roundToDouble(),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _fontFamilies.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final font = _fontFamilies[index];
                final isSelected = fontFamily == font;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onFontFamilyChanged(font);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: (72 * scale).roundToDouble(),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.black : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
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
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            font,
                            style: TextStyle(
                              fontFamily: 'SF-UI-Display',
                              fontSize: (8 * scale).clamp(7.0, 8.0),
                              color:
                                  isSelected ? Colors.white60 : Colors.black45,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('SIZE  ·  ${fontSize.toInt()}px', scale),
                    SliderTheme(
                      data: _sliderTheme(context),
                      child: Slider(
                        value: fontSize,
                        min: 2,
                        max: 40,
                        divisions: 28,
                        onChanged: onFontSizeChanged,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildToggle(
                'B',
                isBold,
                () => onBoldChanged(!isBold),
                scale: scale,
              ),
              const SizedBox(width: 8),
              _buildToggle(
                'I',
                isItalic,
                () => onItalicChanged(!isItalic),
                italic: true,
                scale: scale,
              ),
            ],
          ),

          const SizedBox(height: 20),

          _sectionLabel('ASPECT RATIO', scale),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildRatioButton(
                label: '1:1',
                subtitle: 'Square',
                ratio: 1.0,
                icon: Icons.crop_square_rounded,
                scale: scale,
              ),
              const SizedBox(width: 12),
              _buildRatioButton(
                label: '4:5',
                subtitle: 'Portrait',
                ratio: 0.8,
                icon: Icons.crop_portrait_rounded,
                scale: scale,
              ),
              const SizedBox(width: 12),
              _buildRatioButton(
                label: '9:16',
                subtitle: 'Story',
                ratio: 0.5625,
                icon: Icons.smartphone_rounded,
                scale: scale,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatioButton({
    required String label,
    required String subtitle,
    required double ratio,
    required IconData icon,
    required double scale,
  }) {
    final isSelected = aspectRatio == ratio;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onAspectRatioChanged(ratio);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? Colors.black : Colors.grey.shade300,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: (24 * scale).roundToDouble(),
                color: isSelected ? Colors.white : Colors.black54,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'SF-UI-Display',
                  fontSize: (13 * scale).clamp(11.0, 13.0),
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : Colors.black,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: 'SF-UI-Display',
                  fontSize: (9 * scale).clamp(8.0, 9.0),
                  color: isSelected ? Colors.white60 : Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  Widget _buildToggle(
    String label,
    bool isActive,
    VoidCallback onTap, {
    bool italic = false,
    required double scale,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: (48 * scale).roundToDouble(),
        height: (48 * scale).roundToDouble(),
        decoration: BoxDecoration(
          color: isActive ? Colors.black : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? Colors.black : Colors.grey.shade300,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: (18 * scale).clamp(15.0, 18.0),
            fontWeight: FontWeight.bold,
            fontStyle: italic ? FontStyle.italic : FontStyle.normal,
            fontFamily: 'SF-UI-Display',
            color: isActive ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  SliderThemeData _sliderTheme(BuildContext context) {
    return SliderThemeData(
      activeTrackColor: const Color(0xFFD97757),
      inactiveTrackColor: Colors.grey.shade300,
      thumbColor: const Color(0xFFD97757),
      overlayColor: const Color(0xFFD97757).withValues(alpha: .15),
      trackHeight: 3,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
    );
  }
}
