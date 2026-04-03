import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/services/notebook_service.dart';
import '../controllers/epub_theme_controller.dart';
import 'tabs/font_size_tab.dart';
import 'tabs/layout_tab.dart';
import 'tabs/colors_tab.dart';
import 'tabs/metadata_tab.dart';

class SaveQuoteDialog extends StatefulWidget {
  final String quoteText;
  final String bookTitle;
  final String authorName;
  final String? pageNumber;
  final String? chapterName;
  final EpubThemeController themeController;
  final VoidCallback onSave;

  // Edit mode fields
  final bool editMode;
  final String? quoteId;
  final String? bookId;
  final String? bookCoverUrl;
  final String? initialFontFamily;
  final double? initialFontSize;
  final bool? initialIsBold;
  final bool? initialIsItalic;
  final String? initialTextAlign;
  final double? initialLineHeight;
  final double? initialLetterSpacing;
  final String? initialBackgroundColor;
  final String? initialTextColor;
  final bool? initialShowAuthor;
  final bool? initialShowBookTitle;
  final bool? initialShowUsername;
  final double? initialAspectRatio;
  final String? initialCardAlignment;
  final String? initialMetadataAlign;
  final String? initialCardTheme;
  final double? initialMetadataFontSize;

  const SaveQuoteDialog({
    super.key,
    required this.quoteText,
    required this.bookTitle,
    this.authorName = '',
    this.pageNumber,
    this.chapterName,
    required this.themeController,
    required this.onSave,
    this.editMode = false,
    this.quoteId,
    this.bookId,
    this.bookCoverUrl,
    this.initialFontFamily,
    this.initialFontSize,
    this.initialIsBold,
    this.initialIsItalic,
    this.initialTextAlign,
    this.initialLineHeight,
    this.initialLetterSpacing,
    this.initialBackgroundColor,
    this.initialTextColor,
    this.initialShowAuthor,
    this.initialShowBookTitle,
    this.initialShowUsername,
    this.initialAspectRatio,
    this.initialCardAlignment,
    this.initialMetadataAlign,
    this.initialCardTheme,
    this.initialMetadataFontSize,
  });

  @override
  State<SaveQuoteDialog> createState() => _SaveQuoteDialogState();
}

class _SaveQuoteDialogState extends State<SaveQuoteDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _textController;
  final GlobalKey _captureKey = GlobalKey();
  final NotebookService _notebookService = NotebookService();

  // ── Tab 1: Font ──
  late String _fontFamily;
  late double _fontSize;
  late bool _isBold;
  late bool _isItalic;
  double _aspectRatio = 1.0;

  // ── Tab 2: Layout ──
  Alignment _cardAlignment = Alignment.center;
  late TextAlign _textAlign;
  late double _lineHeight;
  late double _letterSpacing;

  // ── Tab 3: Colors ──
  late Color _backgroundColor;
  late Color _textColor;

  // ── Tab 4: Metadata ──
  late bool _showBookTitle;
  late bool _showAuthor;
  late bool _showUsername;
  late Alignment _metadataAlign;
  late String _cardTheme;
  late double _metadataFontSize;

  String _username = 'reader';
  bool _isSaving = false;

  Color _hexToColor(String hex) {
    final clean = hex.replaceAll('#', '');
    if (clean.length == 6) {
      return Color(int.parse('FF$clean', radix: 16));
    } else if (clean.length == 8) {
      return Color(int.parse(clean, radix: 16));
    }
    return const Color(0xFFF5E6D3);
  }

  TextAlign _textAlignFromString(String value) {
    switch (value) {
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      case 'justify':
        return TextAlign.justify;
      default:
        return TextAlign.left;
    }
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  Future<void> _fetchUsername() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final response =
          await Supabase.instance.client
              .from('user_profiles')
              .select('username')
              .eq('user_id', user.id)
              .maybeSingle();

      if (response != null && response['username'] != null) {
        final fetchedName = response['username'].toString().trim();
        if (fetchedName.isNotEmpty) {
          setState(() {
            _username =
                fetchedName.startsWith('@')
                    ? fetchedName.substring(1)
                    : fetchedName;
          });
        }
      }
    } catch (_) {
      // Keep default fallback
    }
  }

  String _textAlignToString(TextAlign align) {
    switch (align) {
      case TextAlign.center:
        return 'center';
      case TextAlign.right:
        return 'right';
      case TextAlign.justify:
        return 'justify';
      default:
        return 'left';
    }
  }

  Alignment _alignmentFromString(String value) {
    switch (value) {
      case 'topLeft':
        return Alignment.topLeft;
      case 'topCenter':
        return Alignment.topCenter;
      case 'topRight':
        return Alignment.topRight;
      case 'centerLeft':
        return Alignment.centerLeft;
      case 'center':
        return Alignment.center;
      case 'centerRight':
        return Alignment.centerRight;
      case 'bottomLeft':
        return Alignment.bottomLeft;
      case 'bottomCenter':
        return Alignment.bottomCenter;
      case 'bottomRight':
        return Alignment.bottomRight;
      default:
        return Alignment.center;
    }
  }

  String _alignmentToString(Alignment alignment) {
    if (alignment == Alignment.topLeft) return 'topLeft';
    if (alignment == Alignment.topCenter) return 'topCenter';
    if (alignment == Alignment.topRight) return 'topRight';
    if (alignment == Alignment.centerLeft) return 'centerLeft';
    if (alignment == Alignment.center) return 'center';
    if (alignment == Alignment.centerRight) return 'centerRight';
    if (alignment == Alignment.bottomLeft) return 'bottomLeft';
    if (alignment == Alignment.bottomCenter) return 'bottomCenter';
    if (alignment == Alignment.bottomRight) return 'bottomRight';
    return 'center';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Initialize with edit values or defaults
    _fontFamily = widget.initialFontFamily ?? 'NeueMontreal';
    _fontSize = widget.initialFontSize ?? 24.0;
    _isBold = widget.initialIsBold ?? false;
    _isItalic = widget.initialIsItalic ?? false;
    _textAlign = _textAlignFromString(widget.initialTextAlign ?? 'left');
    _cardAlignment = _alignmentFromString(
      widget.initialCardAlignment ?? 'center',
    );
    _lineHeight = widget.initialLineHeight ?? 1.5;
    _letterSpacing = widget.initialLetterSpacing ?? 0.0;
    _backgroundColor = _hexToColor(widget.initialBackgroundColor ?? '#F5E6D3');
    _textColor = _hexToColor(widget.initialTextColor ?? '#000000');
    _showAuthor = widget.initialShowAuthor ?? true;
    _showBookTitle = widget.initialShowBookTitle ?? true;
    _showUsername = widget.initialShowUsername ?? false;
    _metadataAlign = _alignmentFromString(
      widget.initialMetadataAlign ?? 'bottomLeft',
    );
    _aspectRatio = widget.initialAspectRatio ?? 1.0;
    _cardTheme = widget.initialCardTheme ?? 'default';
    _metadataFontSize = widget.initialMetadataFontSize ?? 10.0;

    _textController = TextEditingController(
      text: '\u201C${widget.quoteText}\u201D',
    );

    _fetchUsername();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────
  // SAVE / UPDATE TO SUPABASE
  // ──────────────────────────────────────────────

  Future<void> _saveOrUpdateQuote() async {
    setState(() => _isSaving = true);

    try {
      bool success;

      if (widget.editMode && widget.quoteId != null) {
        // Update existing quote
        success = await _notebookService.updateQuote(
          quoteId: widget.quoteId!,
          quoteText: _textController.text,
          bookTitle: widget.bookTitle,
          authorName: widget.authorName,
          fontFamily: _fontFamily,
          fontSize: _fontSize,
          isBold: _isBold,
          isItalic: _isItalic,
          textAlign: _textAlignToString(_textAlign),
          cardAlignment: _alignmentToString(_cardAlignment),
          metadataAlign: _alignmentToString(_metadataAlign),
          lineHeight: _lineHeight,
          letterSpacing: _letterSpacing,
          backgroundColor: _colorToHex(_backgroundColor),
          textColor: _colorToHex(_textColor),
          showAuthor: _showAuthor,
          showBookTitle: _showBookTitle,
          showUsername: _showUsername,
          aspectRatio: _aspectRatio,
          bookId: widget.bookId,
          cardTheme: _cardTheme,
          bookCoverUrl: widget.bookCoverUrl,
        );
      } else {
        // Save new quote
        success = await _notebookService.saveQuote(
          bookId: widget.bookId ?? 'unknown',
          quoteText: _textController.text,
          bookTitle: widget.bookTitle,
          authorName: widget.authorName,
          fontFamily: _fontFamily,
          fontSize: _fontSize,
          isBold: _isBold,
          isItalic: _isItalic,
          textAlign: _textAlignToString(_textAlign),
          cardAlignment: _alignmentToString(_cardAlignment),
          metadataAlign: _alignmentToString(_metadataAlign),
          lineHeight: _lineHeight,
          letterSpacing: _letterSpacing,
          backgroundColor: _colorToHex(_backgroundColor),
          textColor: _colorToHex(_textColor),
          showAuthor: _showAuthor,
          showBookTitle: _showBookTitle,
          showUsername: _showUsername,
          aspectRatio: _aspectRatio,
          cardTheme: _cardTheme,
          bookCoverUrl: widget.bookCoverUrl,
        );
      }

      if (success && mounted) {
        widget.onSave();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.editMode ? 'Quote updated!' : 'Quote saved to notebook!',
              style: const TextStyle(fontFamily: 'SF-UI-Display'),
            ),
            backgroundColor: const Color(0xFFD97757),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to save/update: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: const ui.Color.fromARGB(255, 64, 61, 60),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ──────────────────────────────────────────────
  // CAPTURE & SAVE TO GALLERY
  // ──────────────────────────────────────────────

  Future<void> _saveToGallery() async {
    setState(() => _isSaving = true);
    try {
      final boundary =
          _captureKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();

      await ImageGallerySaverPlus.saveImage(
        Uint8List.fromList(pngBytes),
        quality: 100,
        name: 'biblio_quote_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Quote saved to gallery!',
              style: TextStyle(fontFamily: 'SF-UI-Display'),
            ),
            backgroundColor: const Color(0xFFD97757),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to save: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ──────────────────────────────────────────────
  // SHARE QUOTE IMAGE
  // ──────────────────────────────────────────────

  Future<void> _shareQuoteImage() async {
    try {
      await WidgetsBinding.instance.endOfFrame;

      final boundary =
          _captureKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('Preview not ready');

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Image bytes are null');

      final bytes = byteData.buffer.asUint8List();

      final box = context.findRenderObject() as RenderBox?;
      final origin =
          box != null ? (box.localToGlobal(Offset.zero) & box.size) : null;

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              bytes,
              mimeType: 'image/png',
              name: 'biblio_quote_${DateTime.now().millisecondsSinceEpoch}.png',
            ),
          ],
          text: 'Shared from Biblio',
          sharePositionOrigin: origin,
        ),
      );
    } catch (e) {
      debugPrint('❌ Failed to share: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to share quote'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ──────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);

    final bottomSheetHeight = MediaQuery.of(context).size.height * 0.48;

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.6),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: Container(color: Colors.transparent),
            ),

            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: Colors.white70,
                      size: (28 * scale).roundToDouble(),
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              top: 52,
              left: 16,
              right: 16,
              bottom: bottomSheetHeight + 8,
              child: Center(child: _buildPreviewCard()),
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomSheet(bottomSheetHeight, scale),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // PREVIEW CARD
  // ──────────────────────────────────────────────

  Widget _buildPreviewCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;

        double cardWidth = 400;
        double cardHeight = 400 / _aspectRatio;

        final scaleW = availableWidth / cardWidth;
        final scaleH = availableHeight / cardHeight;
        final s = scaleW < scaleH ? scaleW : scaleH;

        if (s < 1.0) {
          cardWidth *= s;
          cardHeight *= s;
        }

        return GestureDetector(
          onTap: () => _showEnlargedCard(),
          child: RepaintBoundary(
            key: _captureKey,
            child: _buildCardVisual(cardWidth, cardHeight),
          ),
        );
      },
    );
  }

  Widget _buildCardVisual(double cardWidth, double cardHeight) {
    final isBelieverTheme = _isBelieverTheme();
    // Scale all internal measurements proportionally so the preview,
    // enlarged view, and captured export all look identical.
    final cs = cardWidth / 400.0;
    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(28 * cs),
          child: Stack(
            children: [
              // Quote text positioned by cardAlignment
              Padding(
                padding: EdgeInsets.only(
                  top: isBelieverTheme ? 54 * cs : 0,
                  bottom: isBelieverTheme ? 40 * cs : 0,
                ),
                child: Align(
                  alignment: _cardAlignment,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight:
                          cardHeight - (isBelieverTheme ? 180 * cs : 120 * cs),
                    ),
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: _getColumnAlignment(),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _textController.text,
                            textAlign: _textAlign,
                            style: TextStyle(
                              fontFamily: _fontFamily,
                              fontSize: _fontSize * cs,
                              fontWeight:
                                  _isBold ? FontWeight.bold : FontWeight.normal,
                              fontStyle:
                                  _isItalic
                                      ? FontStyle.italic
                                      : FontStyle.normal,
                              color: _textColor,
                              height: _lineHeight,
                              letterSpacing: _letterSpacing * cs,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Metadata positioned independently
              if (!isBelieverTheme &&
                  (_showBookTitle || _showAuthor || _showUsername))
                Align(
                  alignment: _metadataAlign,
                  child: _buildMetadataSection(cs),
                ),

              if (isBelieverTheme)
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: _buildBelieverTopBand(cs),
                ),

              if (isBelieverTheme)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _BelieverBottomBand(
                    metadataFontSize: _metadataFontSize * cs,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEnlargedCard() {
    final size = MediaQuery.of(context).size;
    final maxW = size.width - 48.0;
    double cardW = maxW;
    double cardH = maxW / _aspectRatio;

    final maxH = size.height - 120.0;
    if (cardH > maxH) {
      cardH = maxH;
      cardW = maxH * _aspectRatio;
    }

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder:
          (ctx) => GestureDetector(
            onTap: () => Navigator.pop(ctx),
            behavior: HitTestBehavior.opaque,
            child: Center(child: _buildCardVisual(cardW, cardH)),
          ),
    );
  }

  CrossAxisAlignment _getColumnAlignment() {
    if (_textAlign == TextAlign.left) return CrossAxisAlignment.start;
    if (_textAlign == TextAlign.right) return CrossAxisAlignment.end;
    return CrossAxisAlignment.center;
  }

  bool _isBelieverTheme() {
    return _cardTheme == 'believer';
  }

  Widget _buildBelieverTopBand(double cs) {
    final scale = (_metadataFontSize * cs) / 10.0;

    return Row(
      children: [
        Container(
          width: 40 * scale,
          height: 40 * scale,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10 * scale),
            gradient:
                widget.bookCoverUrl == null
                    ? const LinearGradient(
                      colors: [Color(0xFF0B253A), Color(0xFF111111)],
                    )
                    : null,
          ),
          clipBehavior: Clip.antiAlias,
          child:
              widget.bookCoverUrl != null
                  ? Image.network(
                    widget.bookCoverUrl!,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, __, ___) => Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF0B253A), Color(0xFF111111)],
                            ),
                          ),
                          child: Icon(
                            Icons.menu_book_rounded,
                            size: 22 * scale,
                            color: Colors.white,
                          ),
                        ),
                  )
                  : Icon(
                    Icons.menu_book_rounded,
                    size: 22 * scale,
                    color: Colors.white,
                  ),
        ),
        SizedBox(width: 10 * scale),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.bookTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'SF-UI-Display',
                  fontSize: 15 * scale,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                  decoration: TextDecoration.none,
                ),
              ),
              if (widget.authorName.isNotEmpty)
                Text(
                  widget.authorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'SF-UI-Display',
                    fontSize: 12 * scale,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    decoration: TextDecoration.none,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataSection(double cs) {
    final hasBookAndAuthor =
        _showBookTitle &&
        _showAuthor &&
        widget.bookTitle.isNotEmpty &&
        widget.authorName.isNotEmpty;
    final hasOnlyBook =
        _showBookTitle && widget.bookTitle.isNotEmpty && !hasBookAndAuthor;
    final hasOnlyAuthor =
        _showAuthor && widget.authorName.isNotEmpty && !hasBookAndAuthor;

    final metadataTextAlign =
        _metadataAlign.x < 0
            ? TextAlign.left
            : _metadataAlign.x > 0
            ? TextAlign.right
            : TextAlign.center;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          _metadataAlign.x < 0
              ? CrossAxisAlignment.start
              : _metadataAlign.x > 0
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.center,
      children: [
        if (hasBookAndAuthor)
          RichText(
            textAlign: metadataTextAlign,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: TextStyle(
                fontSize: _metadataFontSize * cs,
                fontFamily: 'SF-UI-Display',
                color: _textColor.withValues(alpha: 0.6),
                letterSpacing: 0.2,
                decoration: TextDecoration.none,
              ),
              children: [
                const TextSpan(text: 'In '),
                TextSpan(
                  text: widget.bookTitle,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
                const TextSpan(text: ', by '),
                TextSpan(
                  text: widget.authorName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        if (hasOnlyBook)
          Text(
            widget.bookTitle,
            textAlign: metadataTextAlign,
            style: TextStyle(
              fontSize: _metadataFontSize * cs,
              fontFamily: 'SF-UI-Display',
              fontStyle: FontStyle.italic,
              color: _textColor.withValues(alpha: 0.6),
              letterSpacing: 0.2,
              decoration: TextDecoration.none,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        if (hasOnlyAuthor)
          Text(
            '— ${widget.authorName}',
            textAlign: metadataTextAlign,
            style: TextStyle(
              fontSize: _metadataFontSize * cs,
              fontFamily: 'SF-UI-Display',
              fontWeight: FontWeight.w600,
              color: _textColor.withValues(alpha: 0.6),
              letterSpacing: 0.2,
              decoration: TextDecoration.none,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        if (_showUsername) ...[
          if (_showBookTitle || _showAuthor) const SizedBox(height: 2),
          Text(
            '@$_username',
            textAlign: metadataTextAlign,
            style: TextStyle(
              fontSize: (_metadataFontSize - 1) * cs,
              fontFamily: 'SF-UI-Display',
              fontWeight: FontWeight.w500,
              color: _textColor.withValues(alpha: 0.45),
              letterSpacing: 0.3,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ],
    );
  }

  // ──────────────────────────────────────────────
  // BOTTOM SHEET
  // ──────────────────────────────────────────────

  Widget _buildBottomSheet(double height, double scale) {
    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: (40 * scale).roundToDouble(),
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          TabBar(
            controller: _tabController,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey.shade400,
            indicatorColor: const Color(0xFFD97757),
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: TextStyle(
              fontFamily: 'SF-UI-Display',
              fontWeight: FontWeight.w600,
              fontSize: (13 * scale).clamp(10.0, 13.0),
            ),
            unselectedLabelStyle: TextStyle(
              fontFamily: 'SF-UI-Display',
              fontWeight: FontWeight.w400,
              fontSize: (13 * scale).clamp(10.0, 13.0),
            ),
            tabs: const [
              Tab(text: 'Font & Size'),
              Tab(text: 'Layout'),
              Tab(text: 'Colors'),
              Tab(text: 'Metadata'),
            ],
          ),

          Divider(height: 1, color: Colors.grey.shade200),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                FontSizeTab(
                  fontFamily: _fontFamily,
                  fontSize: _fontSize,
                  isBold: _isBold,
                  isItalic: _isItalic,
                  aspectRatio: _aspectRatio,
                  onFontFamilyChanged:
                      (value) => setState(() => _fontFamily = value),
                  onFontSizeChanged:
                      (value) => setState(() => _fontSize = value),
                  onBoldChanged: (value) => setState(() => _isBold = value),
                  onItalicChanged: (value) => setState(() => _isItalic = value),
                  onAspectRatioChanged:
                      (value) => setState(() => _aspectRatio = value),
                ),
                LayoutTab(
                  cardAlignment: _cardAlignment,
                  textAlign: _textAlign,
                  lineHeight: _lineHeight,
                  letterSpacing: _letterSpacing,
                  onCardAlignmentChanged: (alignment, textAlign) {
                    setState(() {
                      _cardAlignment = alignment;
                      _textAlign = textAlign;
                    });
                  },
                  onLineHeightChanged:
                      (value) => setState(() => _lineHeight = value),
                  onLetterSpacingChanged:
                      (value) => setState(() => _letterSpacing = value),
                ),
                ColorsTab(
                  backgroundColor: _backgroundColor,
                  textColor: _textColor,
                  fontFamily: _fontFamily,
                  onBackgroundColorChanged:
                      (value) => setState(() => _backgroundColor = value),
                  onTextColorChanged:
                      (value) => setState(() => _textColor = value),
                  onThemeSelected: (
                    bg,
                    text,
                    font, {
                    String cardTheme = 'default',
                  }) {
                    setState(() {
                      _backgroundColor = bg;
                      _textColor = text;
                      _fontFamily = font;
                      _cardTheme = cardTheme;
                    });
                  },
                ),
                MetadataTab(
                  showAuthor: _showAuthor,
                  showBookTitle: _showBookTitle,
                  showUsername: _showUsername,
                  authorName: widget.authorName,
                  username: _username,
                  metadataAlign: _metadataAlign,
                  metadataFontSize: _metadataFontSize,
                  hideToggles: _cardTheme == 'believer',
                  onShowAuthorChanged:
                      (value) => setState(() => _showAuthor = value),
                  onShowBookTitleChanged:
                      (value) => setState(() => _showBookTitle = value),
                  onShowUsernameChanged:
                      (value) => setState(() => _showUsername = value),
                  onMetadataAlignChanged:
                      (value) => setState(() => _metadataAlign = value),
                  onMetadataFontSizeChanged:
                      (value) => setState(() => _metadataFontSize = value),
                ),
              ],
            ),
          ),

          _buildBottomActions(scale),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // BOTTOM ACTIONS
  // ──────────────────────────────────────────────

  Widget _buildBottomActions(double scale) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        (20 * scale).clamp(16.0, 20.0),
        12,
        (20 * scale).clamp(16.0, 20.0),
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed:
                  _isSaving
                      ? null
                      : () {
                        HapticFeedback.mediumImpact();
                        _saveOrUpdateQuote();
                      },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97757),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: Icon(
                widget.editMode
                    ? Icons.check_rounded
                    : Icons.bookmark_add_rounded,
                size: (20 * scale).roundToDouble(),
              ),
              label: Text(
                widget.editMode ? 'Update Quote' : 'Save to Notebook',
                style: TextStyle(
                  fontSize: (14 * scale).clamp(11.0, 14.0),
                  fontWeight: FontWeight.w600,
                  fontFamily: 'SF-UI-Display',
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _actionIcon(
            icon: Icons.share_rounded,
            onTap:
                _isSaving
                    ? null
                    : () {
                      HapticFeedback.lightImpact();
                      _shareQuoteImage();
                    },
            scale: scale,
          ),
          const SizedBox(width: 8),
          _actionIcon(
            icon: Icons.save_alt_rounded,
            onTap: _isSaving ? null : _saveToGallery,
            isLoading: _isSaving,
            scale: scale,
          ),
        ],
      ),
    );
  }

  Widget _actionIcon({
    required IconData icon,
    VoidCallback? onTap,
    bool isLoading = false,
    required double scale,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: (48 * scale).roundToDouble(),
        height: (48 * scale).roundToDouble(),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child:
            isLoading
                ? Padding(
                  padding: EdgeInsets.all(14 * scale),
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFD97757),
                  ),
                )
                : Icon(
                  icon,
                  size: (22 * scale).roundToDouble(),
                  color: Colors.black54,
                ),
      ),
    );
  }
}

class _BelieverBottomBand extends StatelessWidget {
  final double metadataFontSize;
  const _BelieverBottomBand({required this.metadataFontSize});

  @override
  Widget build(BuildContext context) {
    // scale factor based on 10 as default:
    final scale = metadataFontSize / 10.0;

    return Row(
      children: [
        Icon(Icons.menu_book_rounded, size: 22 * scale, color: Colors.black),
        SizedBox(width: 6 * scale),
        Text(
          'Biblio',
          style: TextStyle(
            fontFamily: 'SF-UI-Display',
            fontSize: 20 * scale,
            fontWeight: FontWeight.w800,
            color: Colors.black,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }
}
