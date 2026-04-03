import 'package:biblio/core/services/ai_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../controllers/epub_theme_controller.dart';

class AiDefinitionSheet extends StatefulWidget {
  final String selectedText;
  final String contextText;
  final String bookTitle;
  final EpubThemeController themeController;

  const AiDefinitionSheet({
    super.key,
    required this.selectedText,
    required this.contextText,
    required this.bookTitle,
    required this.themeController,
  });

  @override
  State<AiDefinitionSheet> createState() => _AiDefinitionSheetState();
}

class _AiDefinitionSheetState extends State<AiDefinitionSheet> {
  bool _isLoading = true;
  String? _definition;
  String? _contextAnalysis;

  final TextEditingController _questionController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  bool _isAskingFollowUp = false;
  final List<Map<String, String>> _conversation = [];

  String _userName = 'You';
  String _userAvatarUrl = '';

  @override
  void initState() {
    super.initState();
    _fetchAiData();
    _loadUserData();

    // Listen to text changes to update button state
    _questionController.addListener(() {
      setState(() {});
    });

    // Listen to keyboard events
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        // Scroll to bottom when keyboard opens
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

  Future<void> _loadUserData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // 1. Try fetching from user_metadata (built-in Supabase Auth)
        final metadata = user.userMetadata;
        String? fullName = metadata?['full_name'] ?? metadata?['display_name'];
        String? avatarUrl = metadata?['avatar_url'];

        // 2. Fallback to your custom database table if metadata is missing
        if (fullName == null || avatarUrl == null) {
          try {
            final response =
                await Supabase.instance.client
                    .from('users')
                    .select('first_name, avatar_url')
                    .eq('id', user.id)
                    .single();
            fullName ??= response['first_name'];
            avatarUrl ??= response['avatar_url'];
          } catch (e) {
            debugPrint('Database fetch fallback failed: $e');
          }
        }

        if (mounted) {
          setState(() {
            // Extract first name from full name
            if (fullName != null && fullName.trim().isNotEmpty) {
              _userName = fullName.trim().split(' ').first;
            } else {
              _userName = 'You';
            }
            _userAvatarUrl = avatarUrl ?? '';
          });
          debugPrint(
            '✅ User Loaded: $_userName | Avatar URL: ${_userAvatarUrl.isNotEmpty}',
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Total failure loading user data: $e');
    }
  }

  Future<void> _fetchAiData() async {
    final service = AiService();

    final result = await service.explainText(
      selectedText: widget.selectedText,
      contextText: widget.contextText,
      bookTitle: widget.bookTitle,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        _definition = result['definition'];
        _contextAnalysis = result['contextAnalysis'];
      });
    }
  }

  Future<void> _askFollowUpQuestion() async {
    final question = _questionController.text.trim();
    if (question.isEmpty || _isAskingFollowUp) return;

    // Collapse keyboard
    _focusNode.unfocus();

    // Add user question to conversation
    setState(() {
      _conversation.add({'type': 'question', 'content': question});
      _isAskingFollowUp = true;
    });

    // Clear input
    _questionController.clear();

    // Scroll to bottom to show new message
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    try {
      final service = AiService();

      // Build conversation context
      final conversationHistory = _conversation
          .where((msg) => msg['type'] != 'error')
          .map(
            (msg) =>
                '${msg['type'] == 'question' ? 'Q' : 'A'}: ${msg['content']}',
          )
          .join('\n');

      final result = await service.askFollowUpQuestion(
        selectedText: widget.selectedText,
        contextText: widget.contextText,
        bookTitle: widget.bookTitle,
        definition: _definition ?? '',
        contextAnalysis: _contextAnalysis ?? '',
        question: question,
        conversationHistory: conversationHistory,
      );

      if (mounted) {
        setState(() {
          _conversation.add({'type': 'answer', 'content': result});
          _isAskingFollowUp = false;
        });

        // Scroll to bottom to show answer
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);

    final theme = widget.themeController;
    final isDark = theme.isDarkMode;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    final headerPadV = (16 * scale).clamp(12.0, 16.0);
    final headerIconSize = (20 * scale).clamp(16.0, 20.0);
    final headerGap = (8 * scale).clamp(6.0, 8.0);
    final headerFontSize = (16 * scale).clamp(13.0, 16.0);
    final contentPadH = (24 * scale).clamp(16.0, 24.0);
    final contentPadT = (24 * scale).clamp(16.0, 24.0);
    final contentPadBottom = (80 * scale).clamp(64.0, 80.0);
    final selectedFontSize = (28 * scale).clamp(22.0, 28.0);
    final sectionGap = (24 * scale).clamp(18.0, 24.0);
    final conversationGap = (32 * scale).clamp(24.0, 32.0);
    final followupGap = (16 * scale).clamp(12.0, 16.0);
    final inputPadH = (16 * scale).clamp(12.0, 16.0);
    final inputPadV = (12 * scale).clamp(10.0, 12.0);
    final questionFontSize = (15 * scale).clamp(13.0, 15.0);
    final questionContentPadH = (20 * scale).clamp(14.0, 20.0);
    final questionContentPadV = (12 * scale).clamp(8.0, 12.0);
    final sendButtonSize = (44 * scale).clamp(36.0, 44.0).roundToDouble();
    final sendIconSize = (20 * scale).clamp(16.0, 20.0).roundToDouble();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFFD97757,
            ).withValues(alpha: isDark ? 0.1 : 0.2),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(vertical: headerPadV),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: const Color(0xFFD97757),
                  size: headerIconSize,
                ),
                SizedBox(width: headerGap),
                Text(
                  "Biblio AI",
                  style: TextStyle(
                    fontFamily: 'SF-UI-Display',
                    fontWeight: FontWeight.w600,
                    fontSize: headerFontSize,
                    color: const Color(0xFFD97757),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Flexible(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(
                contentPadH,
                contentPadT,
                contentPadH,
                bottomPadding + contentPadBottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    widget.selectedText,
                    style: TextStyle(
                      fontFamily: 'SF-UI-Display',
                      fontSize: selectedFontSize,
                      fontWeight: FontWeight.w700,
                      color: theme.textColor,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: sectionGap),

                  if (_isLoading)
                    _buildLoading(isDark, scale)
                  else
                    Column(
                      children: [
                        _buildSection("Definition", _definition!, theme, scale),
                        SizedBox(height: sectionGap),
                        _buildSection(
                          "Contextual Analysis",
                          _contextAnalysis!,
                          theme,
                          scale,
                        ),

                        // Conversation history
                        if (_conversation.isNotEmpty) ...[
                          SizedBox(height: conversationGap),
                          ..._conversation.map(
                            (msg) =>
                                _buildConversationMessage(msg, theme, scale),
                          ),
                        ],

                        // Loading indicator for follow-up
                        if (_isAskingFollowUp) ...[
                          SizedBox(height: followupGap),
                          _buildFollowUpLoading(isDark, scale),
                        ],
                      ],
                    ),
                ],
              ),
            ),
          ),

          // Input field - positioned at bottom
          if (!_isLoading)
            Container(
              padding: EdgeInsets.fromLTRB(
                inputPadH,
                inputPadV,
                inputPadH,
                inputPadV +
                    MediaQuery.of(context).padding.bottom +
                    bottomPadding,
              ),
              decoration: BoxDecoration(
                color: theme.backgroundColor,
                border: Border(
                  top: BorderSide(color: theme.dividerColor, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            isDark
                                ? const Color(0xFF2C2C2E)
                                : const Color(0xFFF8F4F0),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _questionController,
                        focusNode: _focusNode,
                        style: TextStyle(
                          fontFamily: 'SF-UI-Display',
                          fontSize: questionFontSize,
                          color: theme.textColor,
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _askFollowUpQuestion(),
                        decoration: InputDecoration(
                          hintText: 'Ask a follow-up question...',
                          hintStyle: TextStyle(
                            fontFamily: 'SF-UI-Display',
                            fontSize: questionFontSize,
                            color:
                                isDark
                                    ? Colors.grey.shade600
                                    : Colors.grey.shade400,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: questionContentPadH,
                            vertical: questionContentPadV,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: headerGap),
                  GestureDetector(
                    onTap:
                        _isAskingFollowUp ||
                                _questionController.text.trim().isEmpty
                            ? null
                            : _askFollowUpQuestion,
                    child: Container(
                      width: sendButtonSize,
                      height: sendButtonSize,
                      decoration: BoxDecoration(
                        color:
                            _isAskingFollowUp ||
                                    _questionController.text.trim().isEmpty
                                ? (isDark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade300)
                                : const Color(0xFFD97757),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_upward_rounded,
                        color:
                            _isAskingFollowUp ||
                                    _questionController.text.trim().isEmpty
                                ? (isDark
                                    ? Colors.grey.shade600
                                    : Colors.grey.shade500)
                                : Colors.white,
                        size: sendIconSize,
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

  Widget _buildConversationMessage(
    Map<String, String> message,
    EpubThemeController theme,
    double scale,
  ) {
    final isQuestion = message['type'] == 'question';
    final isError = message['type'] == 'error';
    final rowGap = (12 * scale).clamp(8.0, 12.0);
    final bubbleSize = (32 * scale).clamp(28.0, 32.0).roundToDouble();
    final bubbleIcon = (18 * scale).clamp(14.0, 18.0).roundToDouble();
    final nameFont = (12 * scale).clamp(10.0, 12.0);
    final contentFont = (15 * scale).clamp(13.0, 15.0);
    final contentTopGap = (4 * scale).clamp(3.0, 4.0);
    final bottomPad = (16 * scale).clamp(12.0, 16.0);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPad),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Avatar with fallback
          if (isQuestion)
            _userAvatarUrl.isNotEmpty
                ? CircleAvatar(
                  radius: bubbleSize / 2,
                  backgroundImage: NetworkImage(_userAvatarUrl),
                  backgroundColor: const Color(
                    0xFFD97757,
                  ).withValues(alpha: .1),
                )
                : Container(
                  width: bubbleSize,
                  height: bubbleSize,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97757).withValues(alpha: .15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    size: bubbleIcon,
                    color: const Color(0xFFD97757),
                  ),
                )
          else
            Container(
              width: bubbleSize,
              height: bubbleSize,
              decoration: BoxDecoration(
                color:
                    isError
                        ? Colors.red.withValues(alpha: .1)
                        : Colors.blue.withValues(alpha: .1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isError ? Icons.error_outline : Icons.auto_awesome,
                size: bubbleIcon,
                color: isError ? Colors.red : Colors.blue,
              ),
            ),
          SizedBox(width: rowGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isQuestion ? _userName : (isError ? 'Error' : 'Biblio AI'),
                  style: TextStyle(
                    fontFamily: 'SF-UI-Display',
                    fontSize: nameFont,
                    fontWeight: FontWeight.w600,
                    color:
                        theme.isDarkMode
                            ? Colors.grey.shade500
                            : Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: contentTopGap),
                Text(
                  message['content']!,
                  style: TextStyle(
                    fontFamily: 'SF-UI-Display',
                    fontSize: contentFont,
                    height: 1.5,
                    color: theme.textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    String title,
    String content,
    EpubThemeController theme,
    double scale,
  ) {
    final sectionPad = (16 * scale).clamp(12.0, 16.0);
    final titleFont = (11 * scale).clamp(9.0, 11.0);
    final contentFont = (15 * scale).clamp(13.0, 15.0);
    final titleGap = (8 * scale).clamp(6.0, 8.0);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(sectionPad),
      decoration: BoxDecoration(
        color:
            theme.isDarkMode
                ? const Color(0xFF2C2C2E)
                : const Color(0xFFF8F4F0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: titleFont,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color:
                  theme.isDarkMode
                      ? Colors.grey.shade500
                      : const Color(0xFF8A8A8A),
            ),
          ),
          SizedBox(height: titleGap),
          Text(
            content,
            style: TextStyle(
              fontSize: contentFont,
              height: 1.5,
              color: theme.textColor,
              fontFamily: 'SF-UI-Display',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading(bool isDark, double scale) {
    final loadingPadV = (40 * scale).clamp(30.0, 40.0);
    final loadingGap = (16 * scale).clamp(12.0, 16.0);
    final loadingFont = (14 * scale).clamp(12.0, 14.0);

    return Container(
      padding: EdgeInsets.symmetric(vertical: loadingPadV),
      alignment: Alignment.center,
      child: Column(
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Color(0xFFD97757)),
            strokeWidth: 3,
          ),
          SizedBox(height: loadingGap),
          Text(
            "Analyzing meaning & context...",
            style: TextStyle(
              color: isDark ? Colors.grey.shade400 : const Color(0xFF8A8A8A),
              fontSize: loadingFont,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowUpLoading(bool isDark, double scale) {
    final bubbleSize = (32 * scale).clamp(28.0, 32.0).roundToDouble();
    final bubbleIcon = (18 * scale).clamp(14.0, 18.0).roundToDouble();
    final bubbleGap = (12 * scale).clamp(8.0, 12.0);
    final spinnerSize = (20 * scale).clamp(16.0, 20.0).roundToDouble();
    final textGap = (8 * scale).clamp(6.0, 8.0);
    final thinkingFont = (14 * scale).clamp(12.0, 14.0);

    return Row(
      children: [
        Container(
          width: bubbleSize,
          height: bubbleSize,
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.auto_awesome, size: bubbleIcon, color: Colors.blue),
        ),
        SizedBox(width: bubbleGap),
        SizedBox(
          width: spinnerSize,
          height: spinnerSize,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Color(0xFFD97757)),
            strokeWidth: 2,
          ),
        ),
        SizedBox(width: textGap),
        Text(
          "Thinking...",
          style: TextStyle(
            fontFamily: 'SF-UI-Display',
            fontSize: thinkingFont,
            color: isDark ? Colors.grey.shade400 : const Color(0xFF8A8A8A),
          ),
        ),
      ],
    );
  }
}
