import 'dart:io';
import 'package:flutter/material.dart';

/// Editable text screen shown after OCR extraction.
/// Lets the user correct any misread words before opening the styling dialog.
/// Returns the edited text, or null if the user cancels.
class ScanQuoteEditScreen extends StatefulWidget {
  final String ocrText;
  final String imagePath;

  const ScanQuoteEditScreen({
    super.key,
    required this.ocrText,
    required this.imagePath,
  });

  @override
  State<ScanQuoteEditScreen> createState() => _ScanQuoteEditScreenState();
}

class _ScanQuoteEditScreenState extends State<ScanQuoteEditScreen> {
  late final TextEditingController _controller;
  bool _imageExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.ocrText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _proceed() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter some text before continuing.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    Navigator.pop(context, text);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final titleSize = (20 * scale).clamp(16.0, 20.0);
    final padH = (20 * scale).clamp(16.0, 20.0);

    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F5),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    onPressed: () => Navigator.pop(context, null),
                    color: Colors.black87,
                  ),
                  Expanded(
                    child: Text(
                      'Edit Extracted Text',
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'SF-UI-Display',
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  // Proceed button in header
                  FilledButton(
                    onPressed: _proceed,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFD97A73),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Style it →',
                      style: TextStyle(
                        fontFamily: 'SF-UI-Display',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // ── OCR Hint ──
            Padding(
              padding: EdgeInsets.symmetric(horizontal: padH),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFD97A73).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.edit_note_rounded,
                      size: 18,
                      color: Color(0xFFD97A73),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'OCR may have misread some words. Fix anything before styling.',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'SF-UI-Display',
                          color: Color(0xFFD97A73),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // ── Scanned image (collapsible reference) ──
            Padding(
              padding: EdgeInsets.symmetric(horizontal: padH),
              child: GestureDetector(
                onTap: () => setState(() => _imageExpanded = !_imageExpanded),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.black.withOpacity(0.1)),
                  ),
                  height: _imageExpanded ? 200 : 52,
                  child: Stack(
                    children: [
                      if (_imageExpanded)
                        Positioned.fill(
                          child: Image.file(
                            File(widget.imagePath),
                            fit: BoxFit.cover,
                          ),
                        ),
                      // Collapsed bar
                      if (!_imageExpanded)
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              Icon(
                                Icons.image_rounded,
                                size: 18,
                                color: Colors.black.withOpacity(0.4),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Tap to show scanned image',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontFamily: 'SF-UI-Display',
                                  color: Colors.black45,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.expand_more,
                                color: Colors.black.withOpacity(0.3),
                              ),
                            ],
                          ),
                        ),
                      // Expanded overlay bar
                      if (_imageExpanded)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            color: Colors.black.withOpacity(0.45),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  'Scanned image',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontFamily: 'SF-UI-Display',
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.expand_less,
                                  color: Colors.white.withOpacity(0.8),
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Editable text field ──
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: padH),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black.withOpacity(0.08)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: TextField(
                      controller: _controller,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: const TextStyle(
                        fontSize: 17,
                        fontFamily: 'SF-UI-Display',
                        color: Colors.black87,
                        height: 1.6,
                      ),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.all(20),
                        border: InputBorder.none,
                        hintText: 'Edit the extracted text here...',
                        hintStyle: TextStyle(
                          color: Colors.black26,
                          fontFamily: 'SF-UI-Display',
                          fontSize: 17,
                        ),
                      ),
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Bottom action ──
            Padding(
              padding: EdgeInsets.fromLTRB(
                padH,
                0,
                padH,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _proceed,
                  icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: const Text(
                    'Style this quote',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'SF-UI-Display',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFD97A73),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
