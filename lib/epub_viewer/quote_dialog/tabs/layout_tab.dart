import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LayoutTab extends StatelessWidget {
  final Alignment cardAlignment;
  final TextAlign textAlign;
  final double lineHeight;
  final double letterSpacing;
  final Function(Alignment, TextAlign) onCardAlignmentChanged;
  final ValueChanged<double> onLineHeightChanged;
  final ValueChanged<double> onLetterSpacingChanged;

  const LayoutTab({
    super.key,
    required this.cardAlignment,
    required this.textAlign,
    required this.lineHeight,
    required this.letterSpacing,
    required this.onCardAlignmentChanged,
    required this.onLineHeightChanged,
    required this.onLetterSpacingChanged,
  });

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
          _sectionLabel('POSITION ON CARD', scale),
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: (160 * scale).roundToDouble(),
              height: (160 * scale).roundToDouble(),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(8),
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                children: [
                  _buildPositionDot(Alignment.topLeft, scale),
                  _buildPositionDot(Alignment.topCenter, scale),
                  _buildPositionDot(Alignment.topRight, scale),
                  _buildPositionDot(Alignment.centerLeft, scale),
                  _buildPositionDot(Alignment.center, scale),
                  _buildPositionDot(Alignment.centerRight, scale),
                  _buildPositionDot(Alignment.bottomLeft, scale),
                  _buildPositionDot(Alignment.bottomCenter, scale),
                  _buildPositionDot(Alignment.bottomRight, scale),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          _sectionLabel(
            'LINE HEIGHT  ·  ${lineHeight.toStringAsFixed(1)}',
            scale,
          ),
          SliderTheme(
            data: _sliderTheme(context),
            child: Slider(
              value: lineHeight,
              min: 1.0,
              max: 2.0,
              divisions: 10,
              onChanged: onLineHeightChanged,
            ),
          ),

          const SizedBox(height: 8),

          _sectionLabel(
            'LETTER SPACING  ·  ${letterSpacing.toStringAsFixed(1)}',
            scale,
          ),
          SliderTheme(
            data: _sliderTheme(context),
            child: Slider(
              value: letterSpacing,
              min: 0.0,
              max: 5.0,
              divisions: 50,
              onChanged: onLetterSpacingChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPositionDot(Alignment alignment, double scale) {
    final isSelected = cardAlignment == alignment;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        TextAlign newTextAlign;
        if (alignment == Alignment.topLeft ||
            alignment == Alignment.centerLeft ||
            alignment == Alignment.bottomLeft) {
          newTextAlign = TextAlign.left;
        } else if (alignment == Alignment.topRight ||
            alignment == Alignment.centerRight ||
            alignment == Alignment.bottomRight) {
          newTextAlign = TextAlign.right;
        } else {
          newTextAlign = TextAlign.center;
        }
        onCardAlignmentChanged(alignment, newTextAlign);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD97757) : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFFD97757) : Colors.grey.shade400,
            width: isSelected ? 2 : 1,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: const Color(0xFFD97757).withValues(alpha: 0.3),
                      blurRadius: 8,
                    ),
                  ]
                  : null,
        ),
        child:
            isSelected
                ? Icon(
                  Icons.circle,
                  size: (12 * scale).roundToDouble(),
                  color: Colors.white,
                )
                : null,
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
