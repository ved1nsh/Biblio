import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/services/xp_service.dart';
import 'reading_goal_screen.dart';

class UsernameSetupScreen extends ConsumerStatefulWidget {
  const UsernameSetupScreen({super.key});

  @override
  ConsumerState<UsernameSetupScreen> createState() =>
      _UsernameSetupScreenState();
}

class _UsernameSetupScreenState extends ConsumerState<UsernameSetupScreen>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _xpService = XpService();

  String? _errorText;
  bool _isChecking = false;
  bool _isAvailable = false;
  bool _isClaiming = false;
  Timer? _debounceTimer;

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

    // Auto-focus after build
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

  void _onTextChanged() {
    final text = _controller.text.trim();
    _debounceTimer?.cancel();

    setState(() {
      _isAvailable = false;
      _errorText = null;
    });

    // Validate locally first
    if (text.isEmpty) {
      setState(() => _errorText = null);
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

    // Debounce the availability check
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

  Future<void> _onContinue() async {
    final text = _controller.text.trim();
    if (text.isEmpty || !_isAvailable || _isClaiming) return;

    setState(() => _isClaiming = true);
    HapticFeedback.mediumImpact();

    final success = await _xpService.claimUsername(text);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const ReadingGoalScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder:
              (_, animation, __, child) =>
                  FadeTransition(opacity: animation, child: child),
        ),
      );
    } else {
      setState(() {
        _isClaiming = false;
        _isAvailable = false;
        _errorText = 'Username was just taken. Try another.';
      });
      _shakeController.forward(from: 0);
      HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = _controller.text.trim();
    final bool canContinue = text.length >= 3 && _isAvailable && !_isClaiming;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EF),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 24.h),

                // ── Back button ──
                GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.06),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      size: 20.sp,
                      color: Colors.black87,
                    ),
                  ),
                ),

                SizedBox(height: 36.h),

                // ── Greeting ──
                Text(
                  'Hi, $_displayName',
                  style: TextStyle(
                    fontFamily: 'NeueMontreal',
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 8.h),

                // ── Question ──
                Text(
                  'Pick a username',
                  style: TextStyle(
                    fontFamily: 'NeueMontreal',
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w400,
                    color: Colors.black54,
                    height: 1.3,
                  ),
                ),

                SizedBox(height: 32.h),

                // ── Username input field ──
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
                      horizontal: 20.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color:
                            _errorText != null
                                ? Colors.red.withOpacity(0.5)
                                : _isAvailable
                                ? Colors.green.withOpacity(0.5)
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
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.black38,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            style: TextStyle(
                              fontFamily: 'NeueMontreal',
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            decoration: InputDecoration(
                              hintText: 'ved1nsh',
                              hintStyle: TextStyle(
                                fontFamily: 'NeueMontreal',
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w400,
                                color: Colors.black26,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 14.h,
                              ),
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[a-zA-Z0-9_.]'),
                              ),
                              LengthLimitingTextInputFormatter(20),
                            ],
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _onContinue(),
                          ),
                        ),
                        // Status indicator
                        if (_isChecking)
                          SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black38,
                            ),
                          )
                        else if (_isAvailable && text.isNotEmpty)
                          Icon(
                            Icons.check_circle_rounded,
                            size: 22.sp,
                            color: Colors.green,
                          )
                        else if (_errorText != null && text.isNotEmpty)
                          Icon(
                            Icons.error_rounded,
                            size: 22.sp,
                            color: Colors.red.withOpacity(0.7),
                          ),
                      ],
                    ),
                  ),
                ),

                // ── Error / helper text ──
                SizedBox(height: 10.h),
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
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w400,
                                color: Colors.red.shade400,
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
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w400,
                                color: Colors.black26,
                                height: 1.4,
                              ),
                            ),
                          ),
                ),

                const Spacer(),

                // ── Continue button ──
                Padding(
                  padding: EdgeInsets.only(bottom: 40.h),
                  child: GestureDetector(
                    onTap: canContinue ? _onContinue : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      width: double.infinity,
                      height: 56.h,
                      decoration: BoxDecoration(
                        color:
                            canContinue
                                ? Colors.black
                                : Colors.black.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(100.r),
                      ),
                      child: Center(
                        child:
                            _isClaiming
                                ? SizedBox(
                                  width: 22.w,
                                  height: 22.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Continue',
                                      style: TextStyle(
                                        fontFamily: 'NeueMontreal',
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            canContinue
                                                ? Colors.white
                                                : Colors.black26,
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 18.sp,
                                      color:
                                          canContinue
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
