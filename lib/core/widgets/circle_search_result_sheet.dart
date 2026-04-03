import 'dart:typed_data';

import 'package:biblio/core/services/ai_service.dart';
import 'package:flutter/material.dart';

/// Bottom sheet that displays the AI analysis of a circle-to-search image crop.
/// Mirrors the visual style of [AiDefinitionSheet].
class CircleSearchResultSheet extends StatefulWidget {
  final Uint8List imageBytes;
  final String bookTitle;
  final bool isDarkMode;

  const CircleSearchResultSheet({
    super.key,
    required this.imageBytes,
    required this.bookTitle,
    required this.isDarkMode,
  });

  @override
  State<CircleSearchResultSheet> createState() =>
      _CircleSearchResultSheetState();
}

class _CircleSearchResultSheetState extends State<CircleSearchResultSheet> {
  bool _isLoading = true;
  String? _analysisResult;
  String? _errorMessage;

  final TextEditingController _questionController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  bool _isAskingFollowUp = false;
  final List<Map<String, String>> _conversation = [];

  @override
  void initState() {
    super.initState();
    _analyzeImage();

    _questionController.addListener(() {
      setState(() {});
    });

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _questionController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _analyzeImage() async {
    try {
      final result = await AiService().analyzeImage(
        imageBytes: widget.imageBytes,
        bookTitle: widget.bookTitle,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _analysisResult = result;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _askFollowUp() async {
    final question = _questionController.text.trim();
    if (question.isEmpty || _isAskingFollowUp) return;

    _focusNode.unfocus();

    setState(() {
      _conversation.add({'type': 'question', 'content': question});
      _isAskingFollowUp = true;
    });

    _questionController.clear();

    _scrollToBottom();

    try {
      final conversationHistory = _conversation
          .where((msg) => msg['type'] != 'error')
          .map(
            (msg) =>
                '${msg['type'] == 'question' ? 'Q' : 'A'}: ${msg['content']}',
          )
          .join('\n');

      final result = await AiService().askImageFollowUp(
        imageBytes: widget.imageBytes,
        bookTitle: widget.bookTitle,
        previousAnalysis: _analysisResult ?? '',
        question: question,
        conversationHistory: conversationHistory,
      );

      if (mounted) {
        setState(() {
          _conversation.add({'type': 'answer', 'content': result});
          _isAskingFollowUp = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _conversation.add({
            'type': 'error',
            'content': e.toString().replaceFirst('Exception: ', ''),
          });
          _isAskingFollowUp = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Colors ──
  Color get _bgColor =>
      widget.isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
  Color get _textColor => widget.isDarkMode ? Colors.white : Colors.black87;
  Color get _secondaryText =>
      widget.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;
  Color get _dividerColor =>
      widget.isDarkMode ? Colors.white10 : Colors.black12;
  Color get _inputBg =>
      widget.isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFF8F4F0);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final contentPadH = (24 * scale).clamp(16.0, 24.0);
    final contentPadTop = (20 * scale).clamp(16.0, 20.0);
    final contentBottomPad = (80 * scale).clamp(64.0, 80.0);
    final imageMaxHeight = (160 * scale).clamp(136.0, 160.0);
    final inputButtonSize = (40 * scale).clamp(34.0, 40.0);
    final inputTextSize = (15 * scale).clamp(12.0, 15.0);
    final headerTitleSize = (16 * scale).clamp(13.0, 16.0);
    final sectionTitleSize = (13 * scale).clamp(11.0, 13.0);
    final bodySize = (15 * scale).clamp(12.0, 15.0);
    final convoGap = (28 * scale).clamp(20.0, 28.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFFD97757,
            ).withValues(alpha: widget.isDarkMode ? 0.1 : 0.2),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ──
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: _dividerColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, color: Color(0xFFD97757), size: 20),
                SizedBox(width: 8),
                Text(
                  "Biblio AI",
                  style: TextStyle(
                    fontFamily: 'SF-UI-Display',
                    fontWeight: FontWeight.w600,
                    fontSize: headerTitleSize,
                    color: Color(0xFFD97757),
                  ),
                ),
              ],
            ),
          ),

          // ── Content ──
          Flexible(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(
                contentPadH,
                contentPadTop,
                contentPadH,
                bottomPadding + contentBottomPad,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Show the captured image as a small preview
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      constraints: BoxConstraints(maxHeight: imageMaxHeight),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color:
                            widget.isDarkMode
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Image.memory(
                        widget.imageBytes,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (_isLoading)
                    _buildLoading()
                  else if (_errorMessage != null)
                    _buildError()
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Analysis label
                        Text(
                          'Analysis',
                          style: TextStyle(
                            fontFamily: 'SF-UI-Display',
                            fontSize: sectionTitleSize,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFD97757),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          _analysisResult ?? '',
                          style: TextStyle(
                            fontFamily: 'SF-UI-Display',
                            fontSize: bodySize,
                            fontWeight: FontWeight.w400,
                            color: _textColor,
                            height: 1.6,
                          ),
                        ),

                        // Conversation history
                        if (_conversation.isNotEmpty) ...[
                          SizedBox(height: convoGap),
                          ..._conversation.map(
                            (msg) => _buildConversationMessage(msg),
                          ),
                        ],

                        if (_isAskingFollowUp) ...[
                          const SizedBox(height: 16),
                          _buildFollowUpLoading(),
                        ],
                      ],
                    ),
                ],
              ),
            ),
          ),

          // ── Input field ──
          if (!_isLoading && _errorMessage == null)
            Container(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                12 + MediaQuery.of(context).padding.bottom + bottomPadding,
              ),
              decoration: BoxDecoration(
                color: _bgColor,
                border: Border(top: BorderSide(color: _dividerColor, width: 1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: _inputBg,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _questionController,
                        focusNode: _focusNode,
                        style: TextStyle(
                          fontFamily: 'SF-UI-Display',
                          fontSize: inputTextSize,
                          color: _textColor,
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _askFollowUp(),
                        decoration: InputDecoration(
                          hintText: 'Ask about this...',
                          hintStyle: TextStyle(
                            fontFamily: 'SF-UI-Display',
                            fontSize: inputTextSize,
                            color: _secondaryText,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap:
                        _isAskingFollowUp ||
                                _questionController.text.trim().isEmpty
                            ? null
                            : _askFollowUp,
                    child: Container(
                      width: inputButtonSize,
                      height: inputButtonSize,
                      decoration: BoxDecoration(
                        color:
                            _questionController.text.trim().isEmpty ||
                                    _isAskingFollowUp
                                ? Colors.grey.withValues(alpha: 0.3)
                                : const Color(0xFFD97757),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_upward_rounded,
                        color:
                            _questionController.text.trim().isEmpty ||
                                    _isAskingFollowUp
                                ? Colors.grey
                                : Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Loading shimmer ──
  Widget _buildLoading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _shimmerLine(width: 100),
        const SizedBox(height: 12),
        _shimmerLine(),
        const SizedBox(height: 8),
        _shimmerLine(),
        const SizedBox(height: 8),
        _shimmerLine(width: 200),
      ],
    );
  }

  Widget _shimmerLine({double? width}) {
    return Container(
      width: width ?? double.infinity,
      height: 14,
      decoration: BoxDecoration(
        color:
            widget.isDarkMode
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  // ── Error ──
  Widget _buildError() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Something went wrong',
          style: TextStyle(
            fontFamily: 'SF-UI-Display',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _textColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _errorMessage ?? 'Unknown error',
          style: TextStyle(
            fontFamily: 'SF-UI-Display',
            fontSize: 14,
            color: _secondaryText,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // ── Conversation message ──
  Widget _buildConversationMessage(Map<String, String> msg) {
    final isQuestion = msg['type'] == 'question';
    final isError = msg['type'] == 'error';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isQuestion ? 'You' : (isError ? 'Error' : 'Biblio AI'),
            style: TextStyle(
              fontFamily: 'SF-UI-Display',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color:
                  isError
                      ? Colors.redAccent
                      : (isQuestion ? _secondaryText : const Color(0xFFD97757)),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            msg['content'] ?? '',
            style: TextStyle(
              fontFamily: 'SF-UI-Display',
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: isError ? Colors.redAccent : _textColor,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ── Follow-up loading dots ──
  Widget _buildFollowUpLoading() {
    return Row(
      children: [
        Text(
          'Biblio AI',
          style: TextStyle(
            fontFamily: 'SF-UI-Display',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFD97757),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD97757)),
          ),
        ),
      ],
    );
  }
}
