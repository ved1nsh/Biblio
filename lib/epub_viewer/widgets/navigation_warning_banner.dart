import 'package:flutter/material.dart';

class NavigationWarningBanner extends StatefulWidget {
  final VoidCallback onDismiss;

  const NavigationWarningBanner({super.key, required this.onDismiss});

  @override
  State<NavigationWarningBanner> createState() =>
      _NavigationWarningBannerState();
}

class _NavigationWarningBannerState extends State<NavigationWarningBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    // Auto-dismiss after 5 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        dismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void dismiss() {
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final bannerPadH = (16 * scale).clamp(12.0, 16.0);
    final bannerPadV = (12 * scale).clamp(10.0, 12.0);
    final infoIconSize = (20 * scale).clamp(16.0, 20.0).roundToDouble();
    final textFont = (13 * scale).clamp(11.0, 13.0);
    final closeIconSize = (18 * scale).clamp(14.0, 18.0).roundToDouble();
    final gapLarge = (12 * scale).clamp(8.0, 12.0);
    final gapSmall = (8 * scale).clamp(6.0, 8.0);

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(12),
          color: Colors.amber.shade100,
          child: InkWell(
            onTap: dismiss,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: bannerPadH,
                vertical: bannerPadV,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.amber.shade700.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Colors.amber.shade900,
                    size: infoIconSize,
                  ),
                  SizedBox(width: gapLarge),
                  Expanded(
                    child: Text(
                      'The text might be 2-3 swipes ahead due to zoom or formatting',
                      style: TextStyle(
                        color: Colors.amber.shade900,
                        fontSize: textFont,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ),
                  SizedBox(width: gapSmall),
                  Icon(
                    Icons.close,
                    color: Colors.amber.shade700,
                    size: closeIconSize,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
