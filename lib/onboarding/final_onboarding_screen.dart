import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/providers/auth_provider.dart';
import 'profile_setup_screen.dart';

class FinalOnboardingScreen extends ConsumerStatefulWidget {
  const FinalOnboardingScreen({super.key});

  @override
  ConsumerState<FinalOnboardingScreen> createState() =>
      _FinalOnboardingScreenState();
}

class _FinalOnboardingScreenState extends ConsumerState<FinalOnboardingScreen> {
  bool _isLoading = false;

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch $url');
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      final user = await authService.signInWithGoogle();
      debugPrint('signInWithGoogle returned: ${user?.email}');

      if (user != null) {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const ProfileSetupScreen(),
            transitionDuration: const Duration(milliseconds: 400),
            transitionsBuilder:
                (_, animation, __, child) =>
                    FadeTransition(opacity: animation, child: child),
          ),
          (_) => false,
        );
        return;
      }
    } catch (e) {
      debugPrint('Sign-in error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign in failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final topGap = (32 * scale).clamp(24.0, 32.0);
    final logoSize = (64 * scale).clamp(48.0, 72.0);
    final subtitleSize = (28 * scale).clamp(24.0, 32.0);
    final logoSubtitleGap = (8 * scale).clamp(6.0, 10.0);
    final headingToCardGap = (24 * scale).clamp(16.0, 32.0);
    final cardPadH = (24 * scale).clamp(16.0, 32.0);
    final cardPadV = (0 * scale).clamp(0.0, 0.0);
    final imagePadH = (24 * scale).clamp(16.0, 32.0);
    final imagePadTop = (24 * scale).clamp(16.0, 32.0);
    final cardToLinksGap = (32 * scale).clamp(24.0, 40.0);
    final linkSize = (16 * scale).clamp(14.0, 18.0);
    final linksToButtonGap = (20 * scale).clamp(16.0, 24.0);
    final buttonPadH = (32 * scale).clamp(24.0, 32.0);
    final buttonHeight = (54 * scale).clamp(48.0, 60.0);
    final loaderSize = (24 * scale).clamp(20.0, 24.0);
    final googleIconSize = (24 * scale).clamp(20.0, 28.0);
    final buttonInnerGap = (12 * scale).clamp(8.0, 16.0);
    final buttonTextSize = (18 * scale).clamp(16.0, 20.0);
    final buttonToTermsGap = (20 * scale).clamp(16.0, 24.0);
    final termsPadH = (24 * scale).clamp(18.0, 32.0);
    final termsSize = (14 * scale).clamp(12.0, 16.0);
    final bottomGap = (40 * scale).clamp(32.0, 48.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EF),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: topGap),

            // ── Header Texts ──
            Text(
              'Biblio',
              style: TextStyle(
                fontFamily: 'StackSansNotch',
                fontSize: logoSize,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                letterSpacing: -1.5,
                height: 1.1,
              ),
            ),
            SizedBox(height: logoSubtitleGap),
            Text(
              'All this and much more',
              style: TextStyle(
                fontFamily: 'StackSansNotch',
                fontSize: subtitleSize,
                fontWeight: FontWeight.w400,
                color: Colors.black,
                letterSpacing: -0.5,
                height: 1.2,
              ),
            ),

            SizedBox(height: headingToCardGap),

            // ── Image Card (flexible — shrinks on small screens) ──
            Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: cardPadH,
                    vertical: cardPadV,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 255, 255, 255),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        imagePadH,
                        imagePadTop,
                        imagePadH,
                        0,
                      ),
                      child: Image.asset(
                        'assets/ob/ob1.png',
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: cardToLinksGap),

            // ── Links ──
            GestureDetector(
              onTap: () => _launchUrl('https://v1-biblio.vercel.app/'),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontFamily: 'NeueMontreal',
                    fontSize: linkSize,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                  children: const [
                    TextSpan(text: 'Visit '),
                    TextSpan(
                      text: 'biblio.com',
                      style: TextStyle(color: Colors.blue),
                    ),
                    TextSpan(text: ' for more features'),
                  ],
                ),
              ),
            ),

            SizedBox(height: linksToButtonGap),

            // ── Google Button ──
            Padding(
              padding: EdgeInsets.symmetric(horizontal: buttonPadH),
              child: GestureDetector(
                onTap: _isLoading ? null : _signInWithGoogle,
                child: Container(
                  width: double.infinity,
                  height: buttonHeight,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child:
                      _isLoading
                          ? Center(
                            child: SizedBox(
                              width: loaderSize,
                              height: loaderSize,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          )
                          : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/ob/google.png',
                                width: googleIconSize,
                                height: googleIconSize,
                              ),
                              SizedBox(width: buttonInnerGap),
                              Text(
                                'Continue with Google',
                                style: TextStyle(
                                  fontFamily: 'NeueMontreal',
                                  fontSize: buttonTextSize,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                ),
              ),
            ),

            SizedBox(height: buttonToTermsGap),

            // ── Terms & Conditions ──
            Padding(
              padding: EdgeInsets.symmetric(horizontal: termsPadH),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontFamily: 'NeueMontreal',
                    fontSize: termsSize,
                    fontWeight: FontWeight.w400,
                    color: Colors.black87,
                  ),
                  children: [
                    const TextSpan(text: 'By continuing, I agree to the '),
                    TextSpan(
                      text: 'Terms and Conditions',
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer:
                          TapGestureRecognizer()
                            ..onTap = () {
                              _launchUrl(
                                'https://v1-biblio.vercel.app/terms-and-conditions',
                              );
                            },
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: bottomGap),
          ],
        ),
      ),
    );
  }
}
