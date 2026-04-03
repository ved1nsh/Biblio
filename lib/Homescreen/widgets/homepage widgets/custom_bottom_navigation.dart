import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final VoidCallback onUploadTap;

  const CustomBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onUploadTap,
  });

  static const _blurSigma = 25.0;
  static const _horizontalMargin = 16.0;
  static const _bottomMargin = 12.0;
  static const _activeColor = Color(0xFFD97A73);

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: _horizontalMargin,
        right: _horizontalMargin,
        bottom: bottomPadding + _bottomMargin,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: _blurSigma,
            sigmaY: _blurSigma,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFCF9F5).withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.45),
                width: 1.0,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(
                  icon: Icons.home_rounded,
                  index: 0,
                  isSelected: currentIndex == 0,
                ),
                _buildNavItem(
                  icon: Icons.menu_book_rounded,
                  index: 1,
                  isSelected: currentIndex == 1,
                ),
                _buildCenterFab(),
                _buildNavItem(
                  icon: Icons.local_fire_department_rounded,
                  index: 2,
                  isSelected: currentIndex == 2,
                ),
                _buildNavItem(
                  icon: Icons.edit_note_rounded,
                  index: 3,
                  isSelected: currentIndex == 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterFab() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onUploadTap();
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _activeColor,
          boxShadow: [
            BoxShadow(
              color: _activeColor.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(Icons.add, size: 26, color: Colors.white),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required int index,
    required bool isSelected,
  }) {
    final inactiveColor = Colors.black.withValues(alpha: 0.4);

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Icon(
          icon,
          color: isSelected ? _activeColor : inactiveColor,
          size: 27,
        ),
      ),
    );
  }
}
