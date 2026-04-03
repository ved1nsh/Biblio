import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MetadataTab extends StatelessWidget {
  final bool showAuthor;
  final bool showBookTitle;
  final bool showUsername;
  final String authorName;
  final String username;
  final Alignment metadataAlign;
  final double metadataFontSize;
  final bool hideToggles;
  final ValueChanged<bool> onShowAuthorChanged;
  final ValueChanged<bool> onShowBookTitleChanged;
  final ValueChanged<bool> onShowUsernameChanged;
  final ValueChanged<Alignment> onMetadataAlignChanged;
  final ValueChanged<double> onMetadataFontSizeChanged;

  const MetadataTab({
    super.key,
    required this.showAuthor,
    required this.showBookTitle,
    required this.showUsername,
    required this.authorName,
    required this.username,
    required this.metadataAlign,
    required this.metadataFontSize,
    this.hideToggles = false,
    required this.onShowAuthorChanged,
    required this.onShowBookTitleChanged,
    required this.onShowUsernameChanged,
    required this.onMetadataAlignChanged,
    required this.onMetadataFontSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);

    return SingleChildScrollView(
      padding: EdgeInsets.all((20 * scale).clamp(16.0, 20.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!hideToggles) ...[
            Text(
              'Show On Card',
              style: TextStyle(
                fontFamily: 'SF-UI-Display',
                fontSize: (16 * scale).clamp(14.0, 16.0),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),

            // Show Author Toggle
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: SwitchListTile(
                value: showAuthor,
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  onShowAuthorChanged(value);
                },
                title: Text(
                  'Author Name',
                  style: TextStyle(
                    fontFamily: 'SF-UI-Display',
                    fontSize: (14 * scale).clamp(12.0, 14.0),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Show $authorName',
                  style: TextStyle(
                    fontFamily: 'SF-UI-Display',
                    fontSize: (12 * scale).clamp(10.0, 12.0),
                    color: Colors.grey.shade600,
                  ),
                ),
                activeThumbColor: const Color(0xFFD97757),
              ),
            ),

            const SizedBox(height: 12),

            // Show Book Title Toggle
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: SwitchListTile(
                value: showBookTitle,
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  onShowBookTitleChanged(value);
                },
                title: Text(
                  'Book Title',
                  style: TextStyle(
                    fontFamily: 'SF-UI-Display',
                    fontSize: (14 * scale).clamp(12.0, 14.0),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Show book title',
                  style: TextStyle(
                    fontFamily: 'SF-UI-Display',
                    fontSize: (12 * scale).clamp(10.0, 12.0),
                    color: Colors.grey.shade600,
                  ),
                ),
                activeThumbColor: const Color(0xFFD97757),
              ),
            ),

            const SizedBox(height: 12),

            // Show Username Toggle
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: SwitchListTile(
                value: showUsername,
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  onShowUsernameChanged(value);
                },
                title: Text(
                  'Username',
                  style: TextStyle(
                    fontFamily: 'SF-UI-Display',
                    fontSize: (14 * scale).clamp(12.0, 14.0),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Show @$username',
                  style: TextStyle(
                    fontFamily: 'SF-UI-Display',
                    fontSize: (12 * scale).clamp(10.0, 12.0),
                    color: Colors.grey.shade600,
                  ),
                ),
                activeThumbColor: const Color(0xFFD97757),
              ),
            ),

            const SizedBox(height: 24),
          ],

          if (hideToggles) ...[
            Text(
              'Believer Layout',
              style: TextStyle(
                fontFamily: 'SF-UI-Display',
                fontSize: (14 * scale).clamp(12.0, 14.0),
                fontWeight: FontWeight.w600,
                color: const Color(0xFFFF2D37),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Metadata toggles are managed by the theme',
              style: TextStyle(
                fontFamily: 'SF-UI-Display',
                fontSize: (12 * scale).clamp(10.0, 12.0),
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 24),
          ],

          _sectionLabel(
            'METADATA SIZE  ·  ${metadataFontSize.toInt()}px',
            scale,
          ),
          SliderTheme(
            data: _sliderTheme(context),
            child: Slider(
              value: metadataFontSize,
              min: 2,
              max: 20,
              divisions: 14,
              onChanged: onMetadataFontSizeChanged,
            ),
          ),
          const SizedBox(height: 20),

          // Metadata Position Grid
          if (!hideToggles) ...[
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
          ],
        ],
      ),
    );
  }

  Widget _buildPositionDot(Alignment alignment, double scale) {
    final isSelected = metadataAlign == alignment;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onMetadataAlignChanged(alignment);
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
