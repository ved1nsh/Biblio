import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:biblio/core/providers/auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final user = await authService.signInWithGoogle();

      if (user != null && mounted) {
        // User signed in successfully
        // Navigation will be handled by authStateProvider listener
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign in failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final outerPadH = (32 * scale).clamp(24.0, 32.0);
    final logoSize = (100 * scale).clamp(82.0, 100.0);
    final appNameSize = (48 * scale).clamp(40.0, 48.0);
    final taglineSize = (16 * scale).clamp(13.0, 16.0);
    final buttonHeight = (56 * scale).clamp(48.0, 56.0);
    final buttonTextSize = (16 * scale).clamp(13.0, 16.0);
    final legalTextSize = (12 * scale).clamp(10.0, 12.0);
    final topGap = (24 * scale).clamp(18.0, 24.0);
    final ctaGap = (60 * scale).clamp(46.0, 60.0);

    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F5),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: outerPadH),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo/Icon
                Icon(
                  Icons.menu_book_rounded,
                  size: logoSize,
                  color: const Color(0xFFD97A73),
                ),
                SizedBox(height: topGap),

                // App Name
                Text(
                  'Biblio',
                  style: TextStyle(
                    fontSize: appNameSize,
                    fontFamily: 'SF-UI-Display',
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),

                // Tagline
                Text(
                  'Your personal library companion',
                  style: TextStyle(
                    fontSize: taglineSize,
                    fontFamily: 'SF-UI-Display',
                    fontWeight: FontWeight.w400,
                    color: Colors.black.withValues(alpha: 0.6),
                  ),
                ),
                SizedBox(height: ctaGap),

                // Google Sign-In Button
                SizedBox(
                  width: double.infinity,
                  height: buttonHeight,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Colors.black.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    child:
                        _isLoading
                            ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFFD97A73),
                                ),
                              ),
                            )
                            : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(width: 12),
                                Text(
                                  'Continue with Google',
                                  style: TextStyle(
                                    fontSize: buttonTextSize,
                                    fontFamily: 'SF-UI-Display',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                  ),
                ),
                const SizedBox(height: 24),

                // Privacy Policy / Terms
                Text(
                  'By continuing, you agree to our Terms of Service\nand Privacy Policy',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: legalTextSize,
                    fontFamily: 'SF-UI-Display',
                    color: Colors.black.withValues(alpha: 0.4),
                    height: 1.5,
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
