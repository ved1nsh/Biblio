import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/epub_theme_controller.dart';

class EpubFontSettingsSheet extends StatefulWidget {
  final EpubThemeController themeController;

  const EpubFontSettingsSheet({super.key, required this.themeController});

  @override
  State<EpubFontSettingsSheet> createState() => _EpubFontSettingsSheetState();
}

class _EpubFontSettingsSheetState extends State<EpubFontSettingsSheet>
    with SingleTickerProviderStateMixin {
  static const String _uiFont = 'SF-UI-Display-Medium';
  static const double _largeFontWarningThreshold = 30.0;
  static const Color _warningColor = Color(0xFFD64545);

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);

    return ListenableBuilder(
      listenable: widget.themeController,
      builder: (context, child) {
        final sheetBg = widget.themeController.sheetBackgroundColor;
        final textColor = widget.themeController.textColor;
        final cardColor = widget.themeController.stepperBackgroundColor;
        final bottomPadding = MediaQuery.of(context).padding.bottom;

        final sheetHeight = (MediaQuery.of(context).size.height * 0.55).clamp(
          300.0,
          double.infinity,
        );
        final handleWidth = (70 * scale).clamp(50.0, 70.0);
        final handleHeight = (5 * scale).clamp(4.0, 5.0);
        final handleTopMargin = (12 * scale).clamp(8.0, 12.0);
        final tabHeight = (44 * scale).roundToDouble().clamp(36.0, 44.0);
        final tabMargin = (20 * scale).clamp(16.0, 20.0);
        final tabIconSize = (16 * scale).clamp(12.0, 16.0);
        final tabFontSize = (13 * scale).clamp(11.0, 13.0);
        final tabRadius = (14 * scale).clamp(10.0, 14.0);
        final contentPaddingH = (24 * scale).clamp(16.0, 24.0);
        final contentPaddingV = (20 * scale).clamp(16.0, 20.0);
        final sectionMarginV = (28 * scale).clamp(20.0, 28.0);
        final sectionMarginV2 = (16 * scale).clamp(12.0, 16.0);
        final fontItemSize = (90 * scale).roundToDouble().clamp(70.0, 90.0);
        final fontItemSpacing = (12 * scale).clamp(8.0, 12.0);
        final fontItemRadius = (16 * scale).clamp(12.0, 16.0);
        final fontLabelFontSize = (12 * scale).clamp(10.0, 12.0);
        final fontPreviewSize = (24 * scale).clamp(20.0, 24.0);
        final alignmentGridSpacing = (12 * scale).clamp(8.0, 12.0);
        final alignmentItemRadius = (18 * scale).clamp(14.0, 18.0);
        final previewPadding = (20 * scale).clamp(16.0, 20.0);
        final previewRadius = (20 * scale).clamp(16.0, 20.0);
        final previewFontSize = (15 * scale).clamp(12.0, 15.0);

        return SizedBox(
          height: sheetHeight,
          child: Container(
            decoration: BoxDecoration(
              color: sheetBg,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // ── Handle ──
                _buildHandle(
                  textColor,
                  handleWidth,
                  handleHeight,
                  handleTopMargin,
                ),
                SizedBox(height: (8 * scale).clamp(6.0, 8.0)),

                // ── Tab Bar ──
                _buildTabBar(
                  textColor,
                  sheetBg,
                  tabMargin,
                  tabHeight,
                  tabIconSize,
                  tabFontSize,
                  tabRadius,
                  scale,
                ),

                Divider(height: 1, color: textColor.withValues(alpha: 0.08)),

                // ── Tab Pages ──
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildFontPage(
                        textColor,
                        cardColor,
                        contentPaddingH,
                        contentPaddingV,
                        sectionMarginV,
                        sectionMarginV2,
                        fontItemSize,
                        fontItemSpacing,
                        fontItemRadius,
                        fontPreviewSize,
                        fontLabelFontSize,
                        scale,
                      ),
                      _buildAlignmentPage(
                        textColor,
                        cardColor,
                        sheetBg,
                        contentPaddingH,
                        contentPaddingV,
                        sectionMarginV,
                        sectionMarginV2,
                        alignmentGridSpacing,
                        alignmentItemRadius,
                        previewPadding,
                        previewRadius,
                        previewFontSize,
                      ),
                      _buildSpacingPage(
                        textColor,
                        cardColor,
                        contentPaddingH,
                        contentPaddingV,
                        sectionMarginV,
                        sectionMarginV2,
                        previewPadding,
                        previewRadius,
                        previewFontSize,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: bottomPadding + (8 * scale).clamp(6.0, 8.0)),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // HANDLE
  // ─────────────────────────────────────────────

  Widget _buildHandle(
    Color textColor,
    double width,
    double height,
    double topMargin,
  ) {
    return Center(
      child: Container(
        width: width,
        height: height,
        margin: EdgeInsets.only(top: topMargin),
        decoration: BoxDecoration(
          color: textColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TAB BAR
  // ─────────────────────────────────────────────

  Widget _buildTabBar(
    Color textColor,
    Color sheetBg,
    double margin,
    double tabHeight,
    double iconSize,
    double fontSize,
    double radius,
    double scale,
  ) {
    final tabs = [
      {'label': 'Font', 'icon': Icons.text_fields_rounded},
      {'label': 'Alignment', 'icon': Icons.format_align_left_rounded},
      {'label': 'Spacing', 'icon': Icons.format_line_spacing_rounded},
    ];

    return Container(
      margin: EdgeInsets.fromLTRB(
        margin,
        (10 * scale).clamp(8.0, 10.0),
        margin,
        0,
      ),
      decoration: BoxDecoration(
        color: textColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: sheetBg,
          borderRadius: BorderRadius.circular(radius - 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelPadding: EdgeInsets.zero,
        tabs:
            tabs.map((tab) {
              return Tab(
                height: tabHeight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(tab['icon'] as IconData, size: iconSize),
                    SizedBox(width: (6 * scale).clamp(4.0, 6.0)),
                    Text(
                      tab['label'] as String,
                      style: TextStyle(
                        fontFamily: _uiFont,
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        labelColor: textColor,
        unselectedLabelColor: textColor.withValues(alpha: 0.45),
        onTap: (_) => HapticFeedback.selectionClick(),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // PAGE 1: FONT
  // ─────────────────────────────────────────────

  Widget _buildFontPage(
    Color textColor,
    Color cardColor,
    double padH,
    double padV,
    double sectionMargin,
    double sectionMargin2,
    double fontItemSize,
    double fontItemSpacing,
    double fontItemRadius,
    double fontPreviewSize,
    double fontLabelSize,
    double scale,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(padH, padV, padH, padV),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            'Select Font',
            textColor.withValues(alpha: 0.5),
            (13 * scale).clamp(11.0, 13.0),
          ),
          SizedBox(height: sectionMargin2),
          _buildFontSelector(
            textColor,
            cardColor,
            fontItemSize,
            fontItemSpacing,
            fontItemRadius,
            fontPreviewSize,
            fontLabelSize,
            scale,
          ),
          SizedBox(height: sectionMargin),
          _buildSectionTitle(
            'Appearance',
            textColor.withValues(alpha: 0.5),
            (13 * scale).clamp(11.0, 13.0),
          ),
          SizedBox(height: sectionMargin2),
          _buildAppearanceCard(textColor, cardColor),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // PAGE 2: ALIGNMENT
  // ─────────────────────────────────────────────

  Widget _buildAlignmentPage(
    Color textColor,
    Color cardColor,
    Color sheetBg,
    double padH,
    double padV,
    double sectionMargin,
    double sectionMargin2,
    double gridSpacing,
    double itemRadius,
    double previewPad,
    double previewRadius,
    double previewFontSize,
  ) {
    final scale = (MediaQuery.sizeOf(context).width / 393).clamp(0.85, 1.0);

    final items = [
      {
        'label': 'Default',
        'value': TextAlign.left,
        'icon': Icons.format_align_left_rounded,
      },
      {
        'label': 'Justify',
        'value': TextAlign.justify,
        'icon': Icons.format_align_justify_rounded,
      },
      {
        'label': 'Center',
        'value': TextAlign.center,
        'icon': Icons.format_align_center_rounded,
      },
      {
        'label': 'Right',
        'value': TextAlign.right,
        'icon': Icons.format_align_right_rounded,
      },
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        padH,
        (28 * scale).clamp(20.0, 28.0),
        padH,
        padV,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            'Text Alignment',
            textColor.withValues(alpha: 0.5),
            (13 * scale).clamp(11.0, 13.0),
          ),
          SizedBox(height: (20 * scale).clamp(16.0, 20.0)),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: gridSpacing,
            mainAxisSpacing: gridSpacing,
            childAspectRatio: 2.5,
            children:
                items.map((item) {
                  final align = item['value'] as TextAlign;
                  final isSelected = widget.themeController.textAlign == align;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      widget.themeController.setTextAlign(align);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? textColor.withValues(alpha: 0.12)
                                : cardColor,
                        borderRadius: BorderRadius.circular(itemRadius),
                        border: Border.all(
                          color: isSelected ? textColor : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            item['icon'] as IconData,
                            size: (20 * scale).clamp(16.0, 20.0),
                            color: textColor,
                          ),
                          SizedBox(width: (10 * scale).clamp(8.0, 10.0)),
                          Text(
                            item['label'] as String,
                            style: TextStyle(
                              fontFamily: _uiFont,
                              fontSize: (14 * scale).clamp(12.0, 14.0),
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
          SizedBox(height: sectionMargin),
          _buildSectionTitle(
            'Preview',
            textColor.withValues(alpha: 0.5),
            (13 * scale).clamp(11.0, 13.0),
          ),
          SizedBox(height: (14 * scale).clamp(11.0, 14.0)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(previewPad),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(previewRadius),
            ),
            child: Text(
              'The best books are those that tell you what you already know.',
              textAlign: widget.themeController.textAlign,
              style: TextStyle(
                fontFamily: widget.themeController.fontFamily,
                fontSize: previewFontSize,
                color: textColor,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // PAGE 3: SPACING
  // ─────────────────────────────────────────────

  Widget _buildSpacingPage(
    Color textColor,
    Color cardColor,
    double padH,
    double padV,
    double sectionMargin,
    double sectionMargin2,
    double previewPad,
    double previewRadius,
    double previewFontSize,
  ) {
    final scale = (MediaQuery.sizeOf(context).width / 393).clamp(0.85, 1.0);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        padH,
        (28 * scale).clamp(20.0, 28.0),
        padH,
        padV,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            'Spacing',
            textColor.withValues(alpha: 0.5),
            (13 * scale).clamp(11.0, 13.0),
          ),
          SizedBox(height: sectionMargin2),
          _buildSpacingCard(textColor, cardColor),
          SizedBox(height: sectionMargin),
          _buildSectionTitle(
            'Preview',
            textColor.withValues(alpha: 0.5),
            (13 * scale).clamp(11.0, 13.0),
          ),
          SizedBox(height: (14 * scale).clamp(11.0, 14.0)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(previewPad),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(previewRadius),
            ),
            child: Text(
              'The best books are those that tell you what you already know.\n\nA reader lives a thousand lives.',
              style: TextStyle(
                fontFamily: widget.themeController.fontFamily,
                fontSize: previewFontSize,
                color: textColor,
                height: widget.themeController.lineHeight,
                letterSpacing: widget.themeController.letterSpacing,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String text, Color color, double fontSize) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: _uiFont,
        fontSize: fontSize,
        color: color,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildFontSelector(
    Color textColor,
    Color cardColor,
    double itemSize,
    double spacing,
    double radius,
    double previewSize,
    double labelSize,
    double scale,
  ) {
    final fonts = widget.themeController.availableFonts;
    return SizedBox(
      height: itemSize,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: fonts.length,
        separatorBuilder: (_, __) => SizedBox(width: spacing),
        itemBuilder: (context, index) {
          final fontName = fonts[index];
          final isSelected = widget.themeController.fontFamily == fontName;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              widget.themeController.setFontFamily(fontName);
            },
            child: Container(
              width: itemSize,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(radius),
                border:
                    isSelected ? Border.all(color: textColor, width: 2) : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Aa',
                    style: TextStyle(
                      fontFamily: fontName,
                      fontSize: previewSize,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: (8 * scale).clamp(6.0, 8.0)),
                  Text(
                    fontName,
                    style: TextStyle(
                      fontFamily: _uiFont,
                      fontSize: labelSize,
                      color: textColor.withValues(alpha: 0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppearanceCard(Color textColor, Color cardColor) {
    final scale = (MediaQuery.sizeOf(context).width / 393).clamp(0.85, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular((24 * scale).clamp(18.0, 24.0)),
      ),
      padding: EdgeInsets.all((20 * scale).clamp(16.0, 20.0)),
      child: Column(
        children: [
          _buildTextSizeRow(textColor),
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: (20 * scale).clamp(16.0, 20.0),
            ),
            child: Divider(
              color: widget.themeController.dividerColor,
              height: 1,
            ),
          ),
          _buildThemeSelector(),
        ],
      ),
    );
  }

  Widget _buildTextSizeRow(Color textColor) {
    final scale = (MediaQuery.sizeOf(context).width / 393).clamp(0.85, 1.0);
    final value = widget.themeController.fontSize.clamp(12.0, 40.0);
    final showLargeFontWarning = value >= _largeFontWarningThreshold;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Text Size',
              style: TextStyle(
                fontFamily: _uiFont,
                color: textColor,
                fontSize: (16 * scale).clamp(14.0, 16.0),
                fontWeight: FontWeight.w500,
              ),
            ),
            if (showLargeFontWarning) ...[
              SizedBox(width: (8 * scale).clamp(6.0, 8.0)),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _showLargeFontWarningDialog,
                child: Padding(
                  padding: EdgeInsets.all((2 * scale).clamp(2.0, 4.0)),
                  child: Icon(
                    Icons.priority_high_rounded,
                    color: _warningColor,
                    size: (18 * scale).clamp(16.0, 18.0),
                  ),
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: (12 * scale).clamp(10.0, 12.0)),
        Row(
          children: [
            _buildStepButton(
              icon: Icons.remove,
              onTap:
                  () => widget.themeController.setFontSize(
                    (value - 1).clamp(12.0, 40.0),
                  ),
              textColor: textColor,
            ),
            SizedBox(width: (8 * scale).clamp(6.0, 8.0)),
            Expanded(
              child: Slider(
                value: value,
                min: 12,
                max: 40,
                divisions: 28,
                onChanged: (v) => widget.themeController.setFontSize(v),
              ),
            ),
            SizedBox(width: (8 * scale).clamp(6.0, 8.0)),
            _buildStepButton(
              icon: Icons.add,
              onTap:
                  () => widget.themeController.setFontSize(
                    (value + 1).clamp(12.0, 40.0),
                  ),
              textColor: textColor,
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showLargeFontWarningDialog() {
    final textColor = widget.themeController.textColor;
    final sheetBg = widget.themeController.sheetBackgroundColor;

    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: sheetBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 8),
          contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          title: Row(
            children: [
              const Icon(Icons.priority_high_rounded, color: _warningColor),
              const SizedBox(width: 8),
              Text(
                'Large Text Warning',
                style: TextStyle(
                  fontFamily: _uiFont,
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Text(
            'Very large text sizes can cause text selection to break in the EPUB viewer.',
            style: TextStyle(
              fontFamily: _uiFont,
              color: textColor.withValues(alpha: 0.8),
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: TextStyle(
                  fontFamily: _uiFont,
                  color: _warningColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStepperRow({
    required String label,
    required String value,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
    required Color textColor,
  }) {
    final scale = (MediaQuery.sizeOf(context).width / 393).clamp(0.85, 1.0);

    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: _uiFont,
            color: textColor,
            fontSize: (16 * scale).clamp(14.0, 16.0),
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        _buildStepButton(
          icon: Icons.remove,
          onTap: onDecrement,
          textColor: textColor,
        ),
        SizedBox(
          width: (50 * scale).clamp(40.0, 50.0),
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: _uiFont,
              color: textColor,
              fontSize: (16 * scale).clamp(14.0, 16.0),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _buildStepButton(
          icon: Icons.add,
          onTap: onIncrement,
          textColor: textColor,
        ),
      ],
    );
  }

  Widget _buildStepButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color textColor,
  }) {
    final scale = (MediaQuery.sizeOf(context).width / 393).clamp(0.85, 1.0);
    final size = (32 * scale).roundToDouble().clamp(26.0, 32.0);
    final iconSize = (18 * scale).clamp(14.0, 18.0);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: textColor.withValues(alpha: 0.05),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: iconSize, color: textColor),
      ),
    );
  }

  Widget _buildThemeSelector() {
    final scale = (MediaQuery.sizeOf(context).width / 393).clamp(0.85, 1.0);
    final themes = widget.themeController.availableThemes;
    final itemSize = (90 * scale).roundToDouble().clamp(70.0, 90.0);
    final spacing = (12 * scale).clamp(8.0, 12.0);
    final radius = (16 * scale).clamp(12.0, 16.0);

    const selectedBorderColor = Color(0xFFD97757);
    const unselectedBorderColor = Color(0xFFD8D2CB);
    const previewTextColor = Color(0xFF2D2D2D);
    const labelTextColor = Color(0xFF6E655D);

    const fixedThemePreviewColors = <String, Color>{
      'default': Color(0xFFF5E6D3),
      'sepia': Color(0xFFF1E7D0),
      'night': Color(0xFF232328),
      'sage': Color(0xFFE2E9DD),
      'ocean': Color(0xFFDDEAF2),
      'amber': Color(0xFFF3E6CC),
    };

    Color previewBgForTheme(String id, Color fallback) {
      return fixedThemePreviewColors[id.toLowerCase()] ?? fallback;
    }

    return SizedBox(
      height: itemSize,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: themes.length,
        separatorBuilder: (_, __) => SizedBox(width: spacing),
        itemBuilder: (context, index) {
          final theme = themes[index];
          final isSelected = widget.themeController.currentTheme.id == theme.id;
          final previewBg = previewBgForTheme(theme.id, theme.backgroundColor);
          final previewFg =
              previewBg.computeLuminance() < 0.45
                  ? Colors.white
                  : previewTextColor;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              widget.themeController.setTheme(theme);
            },
            child: Container(
              width: itemSize,
              decoration: BoxDecoration(
                color: previewBg,
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(
                  color:
                      isSelected ? selectedBorderColor : unselectedBorderColor,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow:
                    isSelected
                        ? [
                          BoxShadow(
                            color: selectedBorderColor.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                        : [],
              ),
              padding: EdgeInsets.symmetric(
                vertical: (12 * scale).clamp(10.0, 12.0),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Aa',
                    style: TextStyle(
                      fontFamily: _uiFont,
                      fontSize: (24 * scale).clamp(20.0, 24.0),
                      color: previewFg,
                    ),
                  ),
                  Text(
                    theme.name,
                    style: TextStyle(
                      fontFamily: _uiFont,
                      fontSize: (12 * scale).clamp(10.0, 12.0),
                      color: labelTextColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSpacingCard(Color textColor, Color cardColor) {
    final scale = (MediaQuery.sizeOf(context).width / 393).clamp(0.85, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: widget.themeController.stepperBackgroundColor,
        borderRadius: BorderRadius.circular((24 * scale).clamp(18.0, 24.0)),
      ),
      padding: EdgeInsets.all((20 * scale).clamp(16.0, 20.0)),
      child: Column(
        children: [
          _buildStepperRow(
            label: 'Line Height',
            value: widget.themeController.lineHeight.toStringAsFixed(2),
            onDecrement: () {
              final newValue = (widget.themeController.lineHeight - 0.1).clamp(
                1.0,
                2.5,
              );
              widget.themeController.setLineHeight(newValue);
            },
            onIncrement: () {
              final newValue = (widget.themeController.lineHeight + 0.1).clamp(
                1.0,
                2.5,
              );
              widget.themeController.setLineHeight(newValue);
            },
            textColor: textColor,
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: (20 * scale).clamp(16.0, 20.0),
            ),
            child: Divider(
              color: widget.themeController.dividerColor,
              height: 1,
            ),
          ),
          _buildStepperRow(
            label: 'Letter Spacing',
            value: widget.themeController.letterSpacing.toStringAsFixed(2),
            onDecrement: () {
              final newValue = (widget.themeController.letterSpacing - 0.2)
                  .clamp(-2.0, 5.0);
              widget.themeController.setLetterSpacing(newValue);
            },
            onIncrement: () {
              final newValue = (widget.themeController.letterSpacing + 0.2)
                  .clamp(-2.0, 5.0);
              widget.themeController.setLetterSpacing(newValue);
            },
            textColor: textColor,
          ),
        ],
      ),
    );
  }
}
