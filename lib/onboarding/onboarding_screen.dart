import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'final_onboarding_screen.dart';
import 'models/feature_card_model.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  int get _totalPages => 1 + featureCards.length;

  @override
  void initState() {
    super.initState();
    // viewportFraction < 1.0 lets the next card peek in from the right
    _pageController = PageController(viewportFraction: 0.88);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _navigateToFeatures() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const FinalOnboardingScreen(),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _goToNextPage() {
    if (_currentPage < _totalPages - 1) {
      HapticFeedback.lightImpact();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final headerHeight = (56 * scale).clamp(48.0, 56.0);
    final headerFontSize = (16 * scale).clamp(13.0, 16.0);
    final pageHeight = (560 * scale).clamp(470.0, 560.0);
    final cardHorizontalPad = (6 * scale).clamp(4.0, 6.0);
    final reserveBottomSpace = (80 * scale).clamp(64.0, 80.0);
    final bottomOffset = (24 * scale).clamp(20.0, 24.0);
    final actionHeight = (48 * scale).clamp(42.0, 48.0);
    final getStartedPadH = (32 * scale).clamp(24.0, 32.0);
    final getStartedFont = (16 * scale).clamp(14.0, 16.0);
    final skipWidth = (100 * scale).clamp(84.0, 100.0);
    final skipFont = (14 * scale).clamp(12.0, 14.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // ── Header: "Welcome to Biblio" ──
                SizedBox(
                  height: headerHeight,
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: _currentPage > 0 ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        'Welcome to Biblio',
                        style: TextStyle(
                          fontFamily: 'StackSansNotch',
                          fontSize: headerFontSize,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Swipeable pages centered vertically ──
                Expanded(
                  child: Center(
                    child: SizedBox(
                      height: pageHeight,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _totalPages,
                        onPageChanged: (index) {
                          setState(() => _currentPage = index);
                        },
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: cardHorizontalPad,
                              ),
                              child: _IntroPage(onFinished: _goToNextPage),
                            );
                          }
                          final cardIndex = index - 1;
                          final card = featureCards[cardIndex];
                          final isLast = cardIndex == featureCards.length - 1;
                          return Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: cardHorizontalPad,
                            ),
                            child: _FeatureCardPage(
                              card: card,
                              isLast: isLast,
                              onGetStarted: _navigateToFeatures,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // Reserve space so cards don't sit behind the bottom button
                SizedBox(height: reserveBottomSpace),
              ],
            ),

            // ── Bottom Action Area pinned to screen bottom ──
            Positioned(
              bottom: bottomOffset,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  height: actionHeight,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child:
                        _currentPage == _totalPages - 1
                            ? Padding(
                              key: const ValueKey('get_started'),
                              padding: EdgeInsets.symmetric(
                                horizontal: getStartedPadH,
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  _navigateToFeatures();
                                },
                                child: Container(
                                  width: double.infinity,
                                  height: actionHeight,
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Get Started',
                                    style: TextStyle(
                                      fontFamily: 'NeueMontreal',
                                      fontSize: getStartedFont,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            : GestureDetector(
                              key: const ValueKey('skip'),
                              onTap: () {
                                HapticFeedback.lightImpact();
                                _navigateToFeatures();
                              },
                              child: Container(
                                alignment: Alignment.center,
                                width: skipWidth,
                                child: Text(
                                  'Skip',
                                  style: TextStyle(
                                    fontFamily: 'NeueMontreal',
                                    fontSize: skipFont,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black38,
                                  ),
                                ),
                              ),
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

// ──────────────────────────────────────────────
// Feature Card Page (colored card with content)
// ──────────────────────────────────────────────
class _FeatureCardPage extends StatelessWidget {
  final FeatureCard card;
  final bool isLast;
  final VoidCallback onGetStarted;

  const _FeatureCardPage({
    required this.card,
    required this.isLast,
    required this.onGetStarted,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final cardMarginV = (12 * scale).clamp(10.0, 12.0);
    final titlePadH = (24 * scale).clamp(18.0, 24.0);
    final titlePadTop = (28 * scale).clamp(22.0, 28.0);
    final subtitleGap = (10 * scale).clamp(8.0, 10.0);
    final subtitlePadH = (12 * scale).clamp(8.0, 12.0);
    final imagePadH = (20 * scale).clamp(16.0, 20.0);
    final imagePadTop = (22 * scale).clamp(18.0, 22.0);
    final titleSize = (20 * scale).clamp(16.0, 20.0);
    final subtitleSize = (12.5 * scale).clamp(11.0, 12.5);

    return Container(
      margin: EdgeInsets.symmetric(vertical: cardMarginV),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: card.cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          // ── Title & Subtitle ──
          Padding(
            padding: EdgeInsets.fromLTRB(titlePadH, titlePadTop, titlePadH, 0),
            child: Column(
              children: [
                Text(
                  card.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'NeueMontreal',
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: subtitleGap),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: subtitlePadH),
                  child: Text(
                    card.subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'NeueMontreal',
                      fontSize: subtitleSize,
                      fontWeight: FontWeight.w400,
                      color: Colors.white70,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Image ──
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                imagePadH,
                imagePadTop,
                imagePadH,
                0,
              ),
              child: Image.asset(
                card.imagePath,
                fit: BoxFit.contain,
                alignment: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Intro page with typewriter animation
// ──────────────────────────────────────────────
class _IntroPage extends StatefulWidget {
  final VoidCallback onFinished;
  const _IntroPage({required this.onFinished});

  @override
  State<_IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<_IntroPage> {
  static const _headline = 'Welcome to Biblio —';
  static const _segments = [
    'a smarter way to read,\nunderstand,\nand stay consistent with\nyour books.',
    'Powered by AI.\nDesigned for real readers.',
  ];

  int _charCount = 0;
  int _segmentIndex = 0;
  final List<String> _done = [];
  bool _cursorVisible = true;

  Timer? _typingTimer;
  Timer? _cursorTimer;

  static const _charDelay = Duration(milliseconds: 38);
  static const _pauseBetween = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _startCursorBlink();
    _typeNextChar();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _cursorTimer?.cancel();
    super.dispose();
  }

  void _startCursorBlink() {
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 530), (_) {
      if (mounted) setState(() => _cursorVisible = !_cursorVisible);
    });
  }

  void _typeNextChar() {
    if (_segmentIndex >= _segments.length) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) widget.onFinished();
      });
      return;
    }
    final current = _segments[_segmentIndex];

    _typingTimer = Timer(_charDelay, () {
      if (!mounted) return;
      setState(() => _charCount++);

      if (_charCount < current.length) {
        _typeNextChar();
      } else {
        _typingTimer = Timer(_pauseBetween, () {
          if (!mounted) return;
          setState(() {
            _done.add(current);
            _segmentIndex++;
            _charCount = 0;
          });
          _typeNextChar();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final horizontalPadding = (28 * scale).clamp(20.0, 28.0);
    final verticalPadding = (20 * scale).clamp(16.0, 20.0);
    final headlineGap = (18 * scale).clamp(14.0, 18.0);
    final bodyGap = (28 * scale).clamp(20.0, 28.0);
    final String currentVisible =
        _segmentIndex < _segments.length
            ? _segments[_segmentIndex].substring(0, _charCount)
            : '';
    final String cursor = _cursorVisible ? '|' : ' ';
    final firstBlock =
        _done.isNotEmpty
            ? _done[0] + (_segmentIndex == 0 ? '$currentVisible$cursor' : '')
            : '$currentVisible$cursor';
    final secondBlock =
        _done.length >= 2
            ? _done[1] + (_segmentIndex == 1 ? '$currentVisible$cursor' : '')
            : _done.length >= 1
            ? '$currentVisible$cursor'
            : '';

    TextStyle mainStyle() => TextStyle(
      fontFamily: 'NeueMontreal',
      fontSize: (25 * scale).clamp(20.0, 25.0),
      fontWeight: FontWeight.w700,
      color: Colors.black87,
      height: 1.35,
    );
    TextStyle subStyle() => TextStyle(
      fontFamily: 'NeueMontreal',
      fontSize: (20 * scale).clamp(16.0, 20.0),
      fontWeight: FontWeight.w700,
      color: Colors.black87,
      height: 1.35,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: Center(
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _headline,
                    textAlign: TextAlign.left,
                    style: mainStyle(),
                  ),
                  SizedBox(height: headlineGap),
                  Stack(
                    alignment: Alignment.topLeft,
                    children: [
                      IgnorePointer(
                        child: Opacity(
                          opacity: 0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _segments[0],
                                textAlign: TextAlign.left,
                                style: subStyle(),
                              ),
                              SizedBox(height: bodyGap),
                              Text(
                                _segments[1],
                                textAlign: TextAlign.left,
                                style: subStyle(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            firstBlock,
                            textAlign: TextAlign.left,
                            style: subStyle(),
                          ),
                          if (_done.length >= 1 || _segmentIndex >= 1) ...[
                            SizedBox(height: bodyGap),
                            Text(
                              secondBlock,
                              textAlign: TextAlign.left,
                              style: subStyle(),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
