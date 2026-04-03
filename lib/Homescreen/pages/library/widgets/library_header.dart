import 'package:flutter/material.dart';

class LibraryHeader extends StatelessWidget implements PreferredSizeWidget {
  const LibraryHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final titleSize = (32 * scale).clamp(26.0, 32.0);

    return Padding(
      padding: const EdgeInsets.only(top: 15.0),
      child: AppBar(
        backgroundColor: const Color(0xFFFCF9F5),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          'Library',
          style: TextStyle(
            color: Colors.black,
            fontSize: titleSize,
            fontWeight: FontWeight.w600,
            fontFamily: 'SF-UI-Display',
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 15);
}
