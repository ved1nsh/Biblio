import 'dart:async';

import 'package:biblio/core/services/xp_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChangeUsernameScreen extends StatefulWidget {
  const ChangeUsernameScreen({super.key});

  @override
  State<ChangeUsernameScreen> createState() => _ChangeUsernameScreenState();
}

class _ChangeUsernameScreenState extends State<ChangeUsernameScreen>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _xpService = XpService();

  String? _errorText;
  bool _isChecking = false;
  bool _isAvailable = false;
  bool _isSaving = false;
  Timer? _debounceTimer;
  String? _currentUsername;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  String get _displayName {
    final user = Supabase.instance.client.auth.currentUser;
    final fullName = user?.userMetadata?['full_name'] as String? ?? 'Reader';
    return fullName.split(' ').first;
  }

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _controller.addListener(_onTextChanged);
    _loadCurrentUsername();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUsername() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response =
          await Supabase.instance.client
              .from('user_profiles')
              .select('username')
              .eq('user_id', userId)
              .maybeSingle();

      final username = response?['username']?.toString().trim();
      if (!mounted) return;

      setState(() {
        _currentUsername = username;
      });

      if (username != null && username.isNotEmpty) {
        _controller.text = username;
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
      }
    } catch (_) {
      // Keep defaults if fetch fails.
    }
  }

  void _onTextChanged() {
    final text = _controller.text.trim();
    _debounceTimer?.cancel();

    setState(() {
      _isAvailable = false;
      _errorText = null;
      _isChecking = false;
    });

    if (text.isEmpty) {
      return;
    }
    if (text.length < 3) {
      setState(() => _errorText = 'At least 3 characters');
      return;
    }
    if (text.length > 20) {
      setState(() => _errorText = 'Max 20 characters');
      return;
    }
    if (!RegExp(r'^[a-zA-Z0-9_.]+$').hasMatch(text)) {
      setState(() => _errorText = 'Only letters, numbers, dots & underscores');
      return;
    }

    if (_currentUsername != null &&
        text.toLowerCase() == _currentUsername!.toLowerCase()) {
      setState(() {
        _isAvailable = true;
        _errorText = 'This is your current username';
      });
      return;
    }

    setState(() => _isChecking = true);
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      final available = await _xpService.isUsernameAvailable(text);
      if (!mounted) return;
      setState(() {
        _isChecking = false;
        _isAvailable = available;
        _errorText = available ? null : 'Username is taken';
      });
    });
  }

  Future<void> _onSave() async {
    final text = _controller.text.trim();
    if (text.isEmpty || !_isAvailable || _isSaving) return;

    if (_currentUsername != null &&
        text.toLowerCase() == _currentUsername!.toLowerCase()) {
      if (mounted) Navigator.of(context).pop(false);
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final success = await _xpService.changeUsername(text);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username updated successfully')),
      );
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _isSaving = false;
        _isAvailable = false;
        _errorText = 'Could not update username. Try again.';
      });
      _shakeController.forward(from: 0);
      HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final text = _controller.text.trim();
    final canSave = text.length >= 3 && _isAvailable && !_isSaving;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EF),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: (32 * scale).clamp(20.0, 32.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: (24 * scale).roundToDouble()),
                GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Container(
                    width: (40 * scale).clamp(34.0, 40.0),
                    height: (40 * scale).clamp(34.0, 40.0),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.06),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      size: (20 * scale).clamp(17.0, 20.0),
                      color: Colors.black87,
                    ),
                  ),
                ),
                SizedBox(height: (36 * scale).clamp(28.0, 36.0)),
                Text(
                  'Hi, $_displayName',
                  style: TextStyle(
                    fontFamily: 'NeueMontreal',
                    fontSize: (28 * scale).clamp(22.0, 28.0),
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: (8 * scale).roundToDouble()),
                Text(
                  'Change your username',
                  style: TextStyle(
                    fontFamily: 'NeueMontreal',
                    fontSize: (20 * scale).clamp(16.0, 20.0),
                    fontWeight: FontWeight.w400,
                    color: Colors.black54,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: (32 * scale).clamp(24.0, 32.0)),
                AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) {
                    final dx =
                        _shakeAnimation.value *
                        8 *
                        ((_shakeController.status == AnimationStatus.forward)
                            ? ((_shakeAnimation.value * 4).toInt().isEven
                                ? 1
                                : -1)
                            : 0);
                    return Transform.translate(
                      offset: Offset(dx, 0),
                      child: child,
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: (20 * scale).clamp(16.0, 20.0),
                      vertical: (4 * scale).roundToDouble(),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            _errorText != null &&
                                    _errorText !=
                                        'This is your current username'
                                ? Colors.red.withValues(alpha: 0.5)
                                : _isAvailable
                                ? Colors.green.withValues(alpha: 0.5)
                                : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '@',
                          style: TextStyle(
                            fontFamily: 'NeueMontreal',
                            fontSize: (18 * scale).clamp(15.0, 18.0),
                            fontWeight: FontWeight.w500,
                            color: Colors.black38,
                          ),
                        ),
                        SizedBox(width: (4 * scale).roundToDouble()),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            style: TextStyle(
                              fontFamily: 'NeueMontreal',
                              fontSize: (18 * scale).clamp(15.0, 18.0),
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            decoration: InputDecoration(
                              hintText: 'new_username',
                              hintStyle: TextStyle(
                                fontFamily: 'NeueMontreal',
                                fontSize: (18 * scale).clamp(15.0, 18.0),
                                fontWeight: FontWeight.w400,
                                color: Colors.black26,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: (14 * scale).clamp(10.0, 14.0),
                              ),
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[a-zA-Z0-9_.]'),
                              ),
                              LengthLimitingTextInputFormatter(20),
                            ],
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _onSave(),
                          ),
                        ),
                        if (_isChecking)
                          SizedBox(
                            width: (20 * scale).clamp(17.0, 20.0),
                            height: (20 * scale).clamp(17.0, 20.0),
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black38,
                            ),
                          )
                        else if (_isAvailable && text.isNotEmpty)
                          Icon(
                            Icons.check_circle_rounded,
                            size: (22 * scale).clamp(18.0, 22.0),
                            color: Colors.green,
                          )
                        else if (_errorText != null && text.isNotEmpty)
                          Icon(
                            Icons.error_rounded,
                            size: (22 * scale).clamp(18.0, 22.0),
                            color:
                                _errorText == 'This is your current username'
                                    ? Colors.orange.withValues(alpha: 0.8)
                                    : Colors.red.withValues(alpha: 0.7),
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: (10 * scale).roundToDouble()),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child:
                      _errorText != null
                          ? Align(
                            alignment: Alignment.centerLeft,
                            key: ValueKey(_errorText),
                            child: Text(
                              _errorText!,
                              style: TextStyle(
                                fontFamily: 'NeueMontreal',
                                fontSize: (13 * scale).clamp(11.0, 13.0),
                                fontWeight: FontWeight.w400,
                                color:
                                    _errorText ==
                                            'This is your current username'
                                        ? Colors.orange.shade600
                                        : Colors.red.shade400,
                                height: 1.4,
                              ),
                            ),
                          )
                          : Align(
                            alignment: Alignment.centerLeft,
                            key: const ValueKey('helper'),
                            child: Text(
                              'Letters, numbers, dots & underscores only',
                              style: TextStyle(
                                fontFamily: 'NeueMontreal',
                                fontSize: (13 * scale).clamp(11.0, 13.0),
                                fontWeight: FontWeight.w400,
                                color: Colors.black26,
                                height: 1.4,
                              ),
                            ),
                          ),
                ),
                const Spacer(),
                Padding(
                  padding: EdgeInsets.only(
                    bottom: (40 * scale).clamp(28.0, 40.0),
                  ),
                  child: GestureDetector(
                    onTap: canSave ? _onSave : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      width: double.infinity,
                      height: (56 * scale).clamp(48.0, 56.0),
                      decoration: BoxDecoration(
                        color:
                            canSave
                                ? Colors.black
                                : Colors.black.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Center(
                        child:
                            _isSaving
                                ? SizedBox(
                                  width: (22 * scale).clamp(18.0, 22.0),
                                  height: (22 * scale).clamp(18.0, 22.0),
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Save username',
                                      style: TextStyle(
                                        fontFamily: 'NeueMontreal',
                                        fontSize: (16 * scale).clamp(
                                          14.0,
                                          16.0,
                                        ),
                                        fontWeight: FontWeight.w600,
                                        color:
                                            canSave
                                                ? Colors.white
                                                : Colors.black26,
                                      ),
                                    ),
                                    SizedBox(
                                      width: (8 * scale).roundToDouble(),
                                    ),
                                    Icon(
                                      Icons.check_rounded,
                                      size: (18 * scale).clamp(15.0, 18.0),
                                      color:
                                          canSave
                                              ? Colors.white
                                              : Colors.black26,
                                    ),
                                  ],
                                ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
