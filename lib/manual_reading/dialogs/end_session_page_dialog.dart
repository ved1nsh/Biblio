import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Dialog shown when the user finishes a physical book reading session.
/// Asks which page they read up to so we can update progress.
class EndSessionPageDialog extends StatefulWidget {
  final int currentPage;
  final int totalPages;
  final String duration;

  const EndSessionPageDialog({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.duration,
  });

  @override
  State<EndSessionPageDialog> createState() => _EndSessionPageDialogState();
}

class _EndSessionPageDialogState extends State<EndSessionPageDialog> {
  late final TextEditingController _controller;
  String? _errorText;
  String? _selectedMood;

  final List<Map<String, String>> _moods = [
    {'emoji': '😊', 'label': 'Happy'},
    {'emoji': '😌', 'label': 'Relaxed'},
    {'emoji': '😐', 'label': 'Neutral'},
    {'emoji': '😔', 'label': 'Sad'},
    {'emoji': '😴', 'label': 'Sleepy'},
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _errorText = 'Please enter a page number');
      return;
    }

    final page = int.tryParse(text);
    if (page == null) {
      setState(() => _errorText = 'Enter a valid number');
      return;
    }
    if (page < widget.currentPage) {
      setState(
        () => _errorText = 'Must be at least page ${widget.currentPage}',
      );
      return;
    }
    if (page > widget.totalPages && widget.totalPages > 0) {
      setState(() => _errorText = 'Cannot exceed ${widget.totalPages} pages');
      return;
    }

    Navigator.of(
      context,
    ).pop(EndSessionResult(pageReachedTo: page, moodEmoji: _selectedMood));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: EdgeInsets.all((24 * scale).clamp(16.0, 24.0)),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFF8EFD0),
              const Color(0xFFF8EFD0).withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Text(
              '📚 Great Session!',
              style: TextStyle(
                fontSize: (24 * scale).clamp(20.0, 24.0),
                fontWeight: FontWeight.bold,
                color: Color(0xFF191B46),
                fontFamily: 'SF-UI-Display',
              ),
            ),
            SizedBox(height: (8 * scale).clamp(6.0, 8.0)),
            Text(
              'You read for ${widget.duration}',
              style: TextStyle(
                fontSize: (14 * scale).clamp(12.0, 14.0),
                color: Color(0xFF666666),
                fontFamily: 'SF-UI-Display',
              ),
            ),
            SizedBox(height: (24 * scale).clamp(16.0, 24.0)),

            // Page input card
            Container(
              padding: EdgeInsets.all((20 * scale).clamp(14.0, 20.0)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Which page did you read up to?',
                    style: TextStyle(
                      fontSize: (16 * scale).clamp(14.0, 16.0),
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF191B46),
                      fontFamily: 'SF-UI-Display',
                    ),
                  ),
                  SizedBox(height: (4 * scale).clamp(3.0, 4.0)),
                  Text(
                    'Started at page ${widget.currentPage}${widget.totalPages > 0 ? ' of ${widget.totalPages}' : ''}',
                    style: TextStyle(
                      fontSize: (13 * scale).clamp(11.0, 13.0),
                      color: Color(0xFF888888),
                      fontFamily: 'SF-UI-Display',
                    ),
                  ),
                  SizedBox(height: (16 * scale).clamp(12.0, 16.0)),
                  TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    autofocus: true,
                    style: TextStyle(
                      fontSize: (24 * scale).clamp(20.0, 24.0),
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF191B46),
                      fontFamily: 'SF-UI-Display',
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. ${widget.currentPage + 20}',
                      hintStyle: TextStyle(
                        fontSize: (24 * scale).clamp(20.0, 24.0),
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF191B46).withValues(alpha: 0.25),
                        fontFamily: 'SF-UI-Display',
                      ),
                      errorText: _errorText,
                      prefixIcon: const Icon(
                        Icons.menu_book_rounded,
                        color: Color(0xFFB85C38),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF5F0E8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFFB85C38),
                          width: 2,
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: (16 * scale).clamp(12.0, 16.0),
                        horizontal: (16 * scale).clamp(12.0, 16.0),
                      ),
                    ),
                    onChanged: (_) {
                      if (_errorText != null) {
                        setState(() => _errorText = null);
                      }
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: (24 * scale).clamp(16.0, 24.0)),

            // Mood picker
            Text(
              'How are you feeling?',
              style: TextStyle(
                fontSize: (16 * scale).clamp(14.0, 16.0),
                fontWeight: FontWeight.w600,
                color: Color(0xFF191B46),
                fontFamily: 'SF-UI-Display',
              ),
            ),
            SizedBox(height: (16 * scale).clamp(12.0, 16.0)),

            Wrap(
              spacing: (12 * scale).clamp(8.0, 12.0).toDouble(),
              runSpacing: (12 * scale).clamp(8.0, 12.0).toDouble(),
              alignment: WrapAlignment.center,
              children:
                  _moods.map((mood) {
                    final isSelected = _selectedMood == mood['emoji'];
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedMood = mood['emoji']);
                      },
                      child: Container(
                        width: (56 * scale).clamp(48.0, 56.0),
                        height: (56 * scale).clamp(48.0, 56.0),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? const Color(0xFFB85C38)
                                  : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                isSelected
                                    ? const Color(0xFFB85C38)
                                    : Colors.grey.shade300,
                            width: 2,
                          ),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: const Color(
                                  0xFFB85C38,
                                ).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            mood['emoji']!,
                            style: TextStyle(
                              fontSize: (28 * scale).clamp(24.0, 28.0),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),

            SizedBox(height: (24 * scale).clamp(16.0, 24.0)),

            // Done button
            SizedBox(
              width: double.infinity,
              height: (50 * scale).clamp(42.0, 50.0),
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB85C38),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                child: Text(
                  'Done',
                  style: TextStyle(
                    fontSize: (16 * scale).clamp(14.0, 16.0),
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: 'SF-UI-Display',
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

/// Result from the end session dialog
class EndSessionResult {
  final int pageReachedTo;
  final String? moodEmoji;

  EndSessionResult({required this.pageReachedTo, this.moodEmoji});
}
