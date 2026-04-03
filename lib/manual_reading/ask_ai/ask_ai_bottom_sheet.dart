import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:biblio/core/services/ai_service.dart';
import 'package:biblio/core/models/book_model.dart';

/// Bottom sheet with free-form AI chat + shortcut chips + Snap & Ask
/// for the physical book reading session.
class AskAiBottomSheet extends StatefulWidget {
  final Book book;

  const AskAiBottomSheet({super.key, required this.book});

  @override
  State<AskAiBottomSheet> createState() => _AskAiBottomSheetState();
}

class _AskAiBottomSheetState extends State<AskAiBottomSheet> {
  final _aiService = AiService();
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();

  final List<Map<String, String>> _messages = [];
  bool _isThinking = false;

  // For Snap & Ask — stores image bytes of the last snapped passage
  Uint8List? _snappedImageBytes;
  String? _lastImageAnalysis;

  String _userName = 'You';
  String _userAvatarUrl = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _textController.addListener(() => setState(() {}));
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 300), _scrollToBottom);
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final metadata = user.userMetadata;
        String? fullName = metadata?['full_name'] ?? metadata?['display_name'];
        String? avatarUrl = metadata?['avatar_url'];

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
          } catch (_) {}
        }

        if (mounted) {
          setState(() {
            if (fullName != null && fullName.trim().isNotEmpty) {
              _userName = fullName.trim().split(' ').first;
            }
            _userAvatarUrl = avatarUrl ?? '';
          });
        }
      }
    } catch (_) {}
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isThinking) return;

    _focusNode.unfocus();
    final question = text.trim();
    _textController.clear();

    setState(() {
      _messages.add({'type': 'question', 'content': question});
      _isThinking = true;
    });

    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);

    try {
      final conversationHistory = _messages
          .where((m) => m['type'] != 'error')
          .map((m) => '${m['type'] == 'question' ? 'Q' : 'A'}: ${m['content']}')
          .join('\n');

      String answer;

      // If we have a snapped image and this is a follow-up about it
      if (_snappedImageBytes != null && _lastImageAnalysis != null) {
        answer = await _aiService.askPassageFollowUp(
          imageBytes: _snappedImageBytes!,
          bookTitle: widget.book.title,
          previousAnalysis: _lastImageAnalysis!,
          question: question,
          conversationHistory: conversationHistory,
        );
      } else {
        answer = await _aiService.askBookQuestion(
          bookTitle: widget.book.title,
          question: question,
          conversationHistory: conversationHistory,
        );
      }

      if (mounted) {
        setState(() {
          _messages.add({'type': 'answer', 'content': answer});
          _isThinking = false;
        });
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({
            'type': 'error',
            'content': e.toString().replaceFirst('Exception: ', ''),
          });
          _isThinking = false;
        });
      }
    }
  }

  Future<void> _snapAndAsk() async {
    HapticFeedback.lightImpact();

    // Open camera — reuse the same pattern as scan quote
    final imagePath = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const _SnapAskCameraScreen(),
      ),
    );

    if (imagePath == null || !mounted) return;

    // Read image bytes
    final file = File(imagePath);
    final bytes = await file.readAsBytes();

    setState(() {
      _snappedImageBytes = bytes;
      _messages.add({'type': 'image', 'content': imagePath});
      _isThinking = true;
    });

    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);

    try {
      final analysis = await _aiService.analyzePassagePhoto(
        imageBytes: bytes,
        bookTitle: widget.book.title,
      );

      if (mounted) {
        setState(() {
          _lastImageAnalysis = analysis;
          _messages.add({'type': 'answer', 'content': analysis});
          _isThinking = false;
        });
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({
            'type': 'error',
            'content': e.toString().replaceFirst('Exception: ', ''),
          });
          _isThinking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFCF9F5),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Color(0x33D97757), blurRadius: 20, spreadRadius: 5),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ──
          _buildHeader(),

          // ── Messages / Empty state ──
          Flexible(
            child:
                _messages.isEmpty
                    ? _buildEmptyState()
                    : _buildMessageList(bottomPadding),
          ),

          // ── Thinking indicator ──
          if (_isThinking) _buildThinkingIndicator(),

          // ── Input field ──
          _buildInputBar(bottomPadding),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final padH = (20 * scale).clamp(16.0, 20.0);

    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: padH),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE8E0D4))),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFD97757).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Color(0xFFD97757),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Biblio AI',
                  style: TextStyle(
                    fontFamily: 'SF-UI-Display',
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: Color(0xFF3D2008),
                  ),
                ),
                Text(
                  'Reading "${widget.book.title}"',
                  style: const TextStyle(
                    fontFamily: 'SF-UI-Display',
                    fontSize: 12,
                    color: Color(0xFF8A8A8A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Snap & Ask button
          GestureDetector(
            onTap: _isThinking ? null : _snapAndAsk,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF8B4513).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Color(0xFF8B4513),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final titleSize = (20 * scale).clamp(16.0, 20.0);
    final padH = (20 * scale).clamp(16.0, 20.0);
    final padV = (24 * scale).clamp(18.0, 24.0);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome text
          Text(
            'How can I help with your reading?',
            style: TextStyle(
              fontFamily: 'SF-UI-Display',
              fontSize: titleSize,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF3D2008),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ask anything about the book, or snap a photo of a passage for instant analysis.',
            style: TextStyle(
              fontFamily: 'SF-UI-Display',
              fontSize: 14,
              color: Color(0xFF8A8A8A),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // Snap & Ask card
          GestureDetector(
            onTap: _snapAndAsk,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF8B4513).withValues(alpha: 0.08),
                    const Color(0xFFD97757).withValues(alpha: 0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF8B4513).withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B4513).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Color(0xFF8B4513),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Snap & Ask',
                          style: TextStyle(
                            fontFamily: 'SF-UI-Display',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF3D2008),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Take a photo of a passage for instant AI analysis',
                          style: TextStyle(
                            fontFamily: 'SF-UI-Display',
                            fontSize: 12,
                            color: Color(0xFF8A8A8A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Color(0xFF8A8A8A),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(double bottomPadding) {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding + 16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final type = msg['type']!;

        if (type == 'image') {
          return _buildImageMessage(msg['content']!);
        }

        return _buildChatBubble(msg);
      },
    );
  }

  Widget _buildImageMessage(String imagePath) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserAvatar(),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName,
                  style: const TextStyle(
                    fontFamily: 'SF-UI-Display',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8A8A8A),
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(imagePath),
                    width: 200,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Analyzing this passage...',
                  style: TextStyle(
                    fontFamily: 'SF-UI-Display',
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF8A8A8A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(Map<String, String> message) {
    final isQuestion = message['type'] == 'question';
    final isError = message['type'] == 'error';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          if (isQuestion)
            _buildUserAvatar()
          else
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color:
                    isError
                        ? Colors.red.withValues(alpha: 0.1)
                        : const Color(0xFFD97757).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isError ? Icons.error_outline : Icons.auto_awesome,
                size: 18,
                color: isError ? Colors.red : const Color(0xFFD97757),
              ),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isQuestion ? _userName : (isError ? 'Error' : 'Biblio AI'),
                  style: const TextStyle(
                    fontFamily: 'SF-UI-Display',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8A8A8A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message['content']!,
                  style: TextStyle(
                    fontFamily: 'SF-UI-Display',
                    fontSize: 15,
                    height: 1.5,
                    color:
                        isError ? Colors.red.shade700 : const Color(0xFF3D2008),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar() {
    if (_userAvatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 16,
        backgroundImage: NetworkImage(_userAvatarUrl),
        backgroundColor: const Color(0xFFD97757).withValues(alpha: 0.1),
      );
    }
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFFD97757).withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.person, size: 18, color: Color(0xFFD97757)),
    );
  }

  Widget _buildThinkingIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFD97757).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 18,
              color: Color(0xFFD97757),
            ),
          ),
          const SizedBox(width: 10),
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Color(0xFFD97757)),
              strokeWidth: 2,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Thinking...',
            style: TextStyle(
              fontFamily: 'SF-UI-Display',
              fontSize: 14,
              color: Color(0xFF8A8A8A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(double bottomPadding) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        14,
        10,
        14,
        10 + MediaQuery.of(context).padding.bottom + bottomPadding,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFCF9F5),
        border: Border(top: BorderSide(color: Color(0xFFE8E0D4))),
      ),
      child: Row(
        children: [
          // Snap & Ask quick button
          GestureDetector(
            onTap: _isThinking ? null : _snapAndAsk,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF8B4513).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.camera_alt_rounded,
                color:
                    _isThinking
                        ? Colors.grey.shade400
                        : const Color(0xFF8B4513),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Text input
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE8E0D4)),
              ),
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                style: const TextStyle(
                  fontFamily: 'SF-UI-Display',
                  fontSize: 15,
                  color: Color(0xFF3D2008),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (v) => _sendMessage(v),
                decoration: const InputDecoration(
                  hintText: 'Ask about this book...',
                  hintStyle: TextStyle(
                    fontFamily: 'SF-UI-Display',
                    fontSize: 15,
                    color: Color(0xFFB5A89A),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send button
          GestureDetector(
            onTap:
                _isThinking || _textController.text.trim().isEmpty
                    ? null
                    : () => _sendMessage(_textController.text),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color:
                    _isThinking || _textController.text.trim().isEmpty
                        ? Colors.grey.shade300
                        : const Color(0xFFD97757),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_upward_rounded,
                color:
                    _isThinking || _textController.text.trim().isEmpty
                        ? Colors.grey.shade500
                        : Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Snap & Ask Camera (minimal — reuses same UX pattern)
// ─────────────────────────────────────────────────────

class _SnapAskCameraScreen extends StatefulWidget {
  const _SnapAskCameraScreen();

  @override
  State<_SnapAskCameraScreen> createState() => _SnapAskCameraScreenState();
}

class _SnapAskCameraScreenState extends State<_SnapAskCameraScreen> {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isCapturing = false;
  FlashMode _flashMode = FlashMode.off;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  Future<void> _capture() async {
    if (_isCapturing ||
        _controller == null ||
        !_controller!.value.isInitialized)
      return;
    HapticFeedback.mediumImpact();
    setState(() => _isCapturing = true);

    try {
      final file = await _controller!.takePicture();
      if (mounted) Navigator.pop(context, file.path);
    } catch (e) {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFD97A73)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: CameraPreview(_controller!)),

          // Top bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                const Text(
                  'Snap & Ask',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'SF-UI-Display',
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _flashMode =
                          _flashMode == FlashMode.off
                              ? FlashMode.torch
                              : FlashMode.off;
                    });
                    _controller?.setFlashMode(_flashMode);
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                    child: Icon(
                      _flashMode == FlashMode.off
                          ? Icons.flash_off
                          : Icons.flash_on,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Instruction
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).size.height * 0.20,
            child: const Text(
              'Take a photo of the passage you want explained',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'SF-UI-Display',
              ),
            ),
          ),

          // Capture button
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom + 40,
            child: Center(
              child: GestureDetector(
                onTap: _isCapturing ? null : _capture,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isCapturing ? Colors.grey : Colors.white,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                      width: 4,
                    ),
                  ),
                  child:
                      _isCapturing
                          ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black54,
                            ),
                          )
                          : const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.black87,
                            size: 32,
                          ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
