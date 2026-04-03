import 'package:flutter/material.dart';

class ReturnToCurrentButton extends StatefulWidget {
  final int currentPage;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const ReturnToCurrentButton({
    super.key,
    required this.currentPage,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<ReturnToCurrentButton> createState() => _ReturnToCurrentButtonState();
}

class _ReturnToCurrentButtonState extends State<ReturnToCurrentButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _controller.reverse().then((_) => widget.onDismiss());
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final cardPadH = (20 * scale).clamp(16.0, 20.0);
    final cardPadV = (14 * scale).clamp(10.0, 14.0);
    final avatarSize = (40 * scale).clamp(32.0, 40.0).roundToDouble();
    final iconSize = (20 * scale).clamp(16.0, 20.0).roundToDouble();
    final titleFont = (16 * scale).clamp(13.0, 16.0);
    final subtitleFont = (13 * scale).clamp(11.0, 13.0);
    final primaryGap = (14 * scale).clamp(10.0, 14.0);
    final secondaryGap = (8 * scale).clamp(6.0, 8.0);
    final actionPad = (10 * scale).clamp(8.0, 10.0);
    final closePad = (6 * scale).clamp(5.0, 6.0);
    final closeSize = (18 * scale).clamp(14.0, 18.0).roundToDouble();

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: cardPadH,
              vertical: cardPadV,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD97757), Color(0xFFE89A7A)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD97757).withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.bookmark_rounded,
                    color: Colors.white,
                    size: iconSize,
                  ),
                ),
                SizedBox(width: primaryGap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Back to Page ${widget.currentPage}',
                        style: TextStyle(
                          fontSize: titleFont,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontFamily: 'SF-UI-Display',
                        ),
                      ),
                      Text(
                        'Resume Reading',
                        style: TextStyle(
                          fontSize: subtitleFont,
                          color: Colors.white.withValues(alpha: 0.85),
                          fontFamily: 'SF-UI-Display',
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: widget.onTap,
                  child: Container(
                    padding: EdgeInsets.all(actionPad),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: iconSize,
                    ),
                  ),
                ),
                SizedBox(width: secondaryGap),
                GestureDetector(
                  onTap: _dismiss,
                  child: Container(
                    padding: EdgeInsets.all(closePad),
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white.withValues(alpha: 0.7),
                      size: closeSize,
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
