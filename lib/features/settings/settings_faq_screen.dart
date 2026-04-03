import 'package:flutter/material.dart';

class SettingsFaqScreen extends StatelessWidget {
  const SettingsFaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);

    final horizontalPadding = (24 * scale).clamp(16.0, 24.0);
    final sectionGap = (20 * scale).clamp(16.0, 20.0);
    final cardRadius = (24 * scale).clamp(18.0, 24.0);

    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black87,
            size: (20 * scale).roundToDouble(),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'FAQs',
          style: TextStyle(
            fontFamily: 'SF-UI-Display',
            fontSize: (22 * scale).clamp(18.0, 22.0),
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            (12 * scale).clamp(10.0, 12.0),
            horizontalPadding,
            (28 * scale).clamp(20.0, 28.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all((20 * scale).clamp(16.0, 20.0)),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4ECE3),
                  borderRadius: BorderRadius.circular(cardRadius),
                  border: Border.all(color: const Color(0xFFE2D4C4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: (44 * scale).clamp(40.0, 44.0),
                      height: (44 * scale).clamp(40.0, 44.0),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFE3E0),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.priority_high_rounded,
                        color: const Color(0xFFD64545),
                        size: (24 * scale).clamp(20.0, 24.0),
                      ),
                    ),
                    SizedBox(height: (16 * scale).clamp(12.0, 16.0)),
                    Text(
                      'Why does text selection stop working in EPUB sometimes?',
                      style: TextStyle(
                        fontFamily: 'SF-UI-Display',
                        fontSize: (22 * scale).clamp(18.0, 22.0),
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: (10 * scale).clamp(8.0, 10.0)),
                    Text(
                      'This usually happens when the reading font size is pushed too high. Large text can change the EPUB layout enough to interfere with text selection and highlight positioning.',
                      style: TextStyle(
                        fontFamily: 'SF-UI-Display',
                        fontSize: (15 * scale).clamp(13.0, 15.0),
                        fontWeight: FontWeight.w400,
                        color: Colors.black87.withValues(alpha: 0.72),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: sectionGap),
              _FaqSectionCard(
                scale: scale,
                title: 'What you can do',
                items: const [
                  'Reduce the EPUB text size a little and try selecting the text again.',
                  'If selection still feels off, close the EPUB view and open the book again.',
                  'After reopening, keep the font size slightly smaller for more stable text selection.',
                ],
              ),
              SizedBox(height: sectionGap),
              _FaqSectionCard(
                scale: scale,
                title: 'Good to know',
                items: const [
                  'This issue is layout-related, so it may affect some books more than others.',
                  'You do not need to reset the whole app. Usually a smaller font size or reopening the EPUB view is enough.',
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqSectionCard extends StatelessWidget {
  final double scale;
  final String title;
  final List<String> items;

  const _FaqSectionCard({
    required this.scale,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all((20 * scale).clamp(16.0, 20.0)),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFEF),
        borderRadius: BorderRadius.circular((24 * scale).clamp(18.0, 24.0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'SF-UI-Display',
              fontSize: (18 * scale).clamp(16.0, 18.0),
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: (14 * scale).clamp(10.0, 14.0)),
          ...items.map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: (10 * scale).clamp(8.0, 10.0)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      top: (6 * scale).clamp(4.0, 6.0),
                      right: (10 * scale).clamp(8.0, 10.0),
                    ),
                    child: Container(
                      width: (6 * scale).clamp(5.0, 6.0),
                      height: (6 * scale).clamp(5.0, 6.0),
                      decoration: const BoxDecoration(
                        color: Color(0xFFD64545),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontFamily: 'SF-UI-Display',
                        fontSize: (15 * scale).clamp(13.0, 15.0),
                        fontWeight: FontWeight.w400,
                        color: Colors.black87.withValues(alpha: 0.74),
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
