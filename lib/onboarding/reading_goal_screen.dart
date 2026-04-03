import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/services/xp_service.dart';
import '../Homescreen/homepage.dart';

class ReadingGoalScreen extends StatefulWidget {
  const ReadingGoalScreen({super.key});

  @override
  State<ReadingGoalScreen> createState() => _ReadingGoalScreenState();
}

class _ReadingGoalScreenState extends State<ReadingGoalScreen> {
  final _xpService = XpService();
  int _presetIndex = 3; // default 30 min
  bool _isSaving = false;

  static const List<int> _presets = [10, 15, 20, 30, 45, 60];

  int get _selectedMinutes => _presets[_presetIndex];

  String get _firstName {
    final user = Supabase.instance.client.auth.currentUser;
    final fullName = user?.userMetadata?['full_name'] as String? ?? 'Reader';
    return fullName.split(' ').first;
  }

  String get _goalLabel {
    if (_selectedMinutes < 15) return 'Casual';
    if (_selectedMinutes < 25) return 'Regular';
    if (_selectedMinutes < 40) return 'Committed';
    if (_selectedMinutes < 55) return 'Avid';
    return 'Bookworm';
  }

  String get _goalEmoji {
    if (_selectedMinutes < 15) return '☕';
    if (_selectedMinutes < 25) return '📖';
    if (_selectedMinutes < 40) return '🔥';
    if (_selectedMinutes < 55) return '⚡';
    return '🏆';
  }

  void _incrementPreset() {
    if (_presetIndex < _presets.length - 1) {
      HapticFeedback.selectionClick();
      setState(() => _presetIndex++);
    }
  }

  void _decrementPreset() {
    if (_presetIndex > 0) {
      HapticFeedback.selectionClick();
      setState(() => _presetIndex--);
    }
  }

  Future<void> _onContinue() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    await _xpService.updateDailyReadingGoal(_selectedMinutes);

    if (!mounted) return;

    // Show the "You're all set" dialog
    await _showSuccessDialog();
  }

  Future<void> _showSuccessDialog() async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, animation, _, __) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );
        return ScaleTransition(
          scale: curvedAnimation,
          child: FadeTransition(
            opacity: animation,
            child: _SuccessDialogContent(
              goalMinutes: _selectedMinutes,
              goalLabel: _goalLabel,
              goalEmoji: _goalEmoji,
              onDone: () {
                Navigator.of(ctx).pop(); // close dialog
                _goToHome();
              },
            ),
          ),
        );
      },
    );
  }

  void _goToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const Homepage(),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder:
            (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final headingSize = 34.sp.clamp(24.0, 36.0);
    final subtitleSize = 14.sp.clamp(12.0, 15.0);
    final numberSize = 80.sp.clamp(56.0, 80.0);
    final emojiSize = 48.sp.clamp(36.0, 48.0);
    final labelSize = 16.sp.clamp(13.0, 16.0);
    final minDaySize = 18.sp.clamp(14.0, 18.0);
    final arrowSize = 36.sp.clamp(28.0, 36.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EF),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            children: [
              // ── Scrollable content (fills screen, scrolls on small phones) ──
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Heading section ──
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 50.h),
                                Text(
                                  'Alright $_firstName,',
                                  style: TextStyle(
                                    fontFamily: 'NeueMontreal',
                                    fontSize: headingSize,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                    height: 1.2,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  "It's time to set your daily reading goal",
                                  style: TextStyle(
                                    fontFamily: 'NeueMontreal',
                                    fontSize: headingSize,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black38,
                                    height: 1.2,
                                  ),
                                ),
                                SizedBox(height: 10.h),
                                Text(
                                  'You can always change this later.',
                                  style: TextStyle(
                                    fontFamily: 'NeueMontreal',
                                    fontSize: subtitleSize,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.black26,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),

                            // ── Goal picker (centered via spaceBetween) ──
                            Center(
                              child: GestureDetector(
                                onHorizontalDragEnd: (details) {
                                  if (details.primaryVelocity == null) return;
                                  if (details.primaryVelocity! < -100) {
                                    _incrementPreset();
                                  } else if (details.primaryVelocity! > 100) {
                                    _decrementPreset();
                                  }
                                },
                                behavior: HitTestBehavior.opaque,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      child: Text(
                                        _goalEmoji,
                                        key: ValueKey(_goalEmoji),
                                        style: TextStyle(fontSize: emojiSize),
                                      ),
                                    ),
                                    SizedBox(height: 8.h),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        GestureDetector(
                                          onTap: _decrementPreset,
                                          behavior: HitTestBehavior.opaque,
                                          child: Padding(
                                            padding: EdgeInsets.all(8.w),
                                            child: AnimatedOpacity(
                                              opacity:
                                                  _presetIndex > 0
                                                      ? 0.25
                                                      : 0.08,
                                              duration: const Duration(
                                                milliseconds: 200,
                                              ),
                                              child: Icon(
                                                Icons.chevron_left_rounded,
                                                size: arrowSize,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 140.w,
                                          child: TweenAnimationBuilder<double>(
                                            tween: Tween(
                                              begin:
                                                  _selectedMinutes.toDouble(),
                                              end: _selectedMinutes.toDouble(),
                                            ),
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            builder: (context, value, child) {
                                              return Text(
                                                '${value.round()}',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontFamily: 'NeueMontreal',
                                                  fontSize: numberSize,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.black87,
                                                  height: 1,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: _incrementPreset,
                                          behavior: HitTestBehavior.opaque,
                                          child: Padding(
                                            padding: EdgeInsets.all(8.w),
                                            child: AnimatedOpacity(
                                              opacity:
                                                  _presetIndex <
                                                          _presets.length - 1
                                                      ? 0.25
                                                      : 0.08,
                                              duration: const Duration(
                                                milliseconds: 200,
                                              ),
                                              child: Icon(
                                                Icons.chevron_right_rounded,
                                                size: arrowSize,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      'min / day',
                                      style: TextStyle(
                                        fontFamily: 'NeueMontreal',
                                        fontSize: minDaySize,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.black38,
                                      ),
                                    ),
                                    SizedBox(height: 6.h),
                                    AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      child: Text(
                                        _goalLabel,
                                        key: ValueKey(_goalLabel),
                                        style: TextStyle(
                                          fontFamily: 'NeueMontreal',
                                          fontSize: labelSize,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF191B46),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Bottom spacer (balances spaceBetween)
                            SizedBox(height: 16.h),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // ── Continue button (pinned at bottom) ──
              Padding(
                padding: EdgeInsets.only(top: 16.h, bottom: 32.h),
                child: GestureDetector(
                  onTap: _isSaving ? null : _onContinue,
                  child: Container(
                    width: double.infinity,
                    height: 62.h,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(100.r),
                    ),
                    child: Center(
                      child:
                          _isSaving
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
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 18.sp,
                                    color: Colors.white,
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
    );
  }
}

// ──────────────────────────────────────────────
// Success dialog content
// ──────────────────────────────────────────────
class _SuccessDialogContent extends StatefulWidget {
  final int goalMinutes;
  final String goalLabel;
  final String goalEmoji;
  final VoidCallback onDone;

  const _SuccessDialogContent({
    required this.goalMinutes,
    required this.goalLabel,
    required this.goalEmoji,
    required this.onDone,
  });

  @override
  State<_SuccessDialogContent> createState() => _SuccessDialogContentState();
}

class _SuccessDialogContentState extends State<_SuccessDialogContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _checkController;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _checkAnimation = CurvedAnimation(
      parent: _checkController,
      curve: Curves.elasticOut,
    );

    // Start the check animation after a small delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _checkController.forward();
    });
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 40.w),
          padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 36.h),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F3EF),
            borderRadius: BorderRadius.circular(28.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Animated check circle ──
              ScaleTransition(
                scale: _checkAnimation,
                child: Container(
                  width: 72.w,
                  height: 72.w,
                  decoration: const BoxDecoration(
                    color: Color(0xFF191B46),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 36.sp,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 24.h),

              Text(
                'You\'re all set!',
                style: TextStyle(
                  fontFamily: 'NeueMontreal',
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 10.h),

              Text(
                '${widget.goalEmoji} ${widget.goalMinutes} min/day — ${widget.goalLabel} reader',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'NeueMontreal',
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w400,
                  color: Colors.black45,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Let\'s start reading.',
                style: TextStyle(
                  fontFamily: 'NeueMontreal',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic,
                  color: Colors.black38,
                ),
              ),

              SizedBox(height: 28.h),

              // ── Let's go button ──
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  widget.onDone();
                },
                child: Container(
                  width: double.infinity,
                  height: 52.h,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(100.r),
                  ),
                  child: Center(
                    child: Text(
                      'Let\'s go',
                      style: TextStyle(
                        fontFamily: 'NeueMontreal',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
