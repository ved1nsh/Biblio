import 'package:flutter/material.dart';

class FeatureCard {
  final String title;
  final String subtitle;
  final String imagePath;
  final Color cardColor;

  const FeatureCard({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.cardColor,
  });
}

const List<FeatureCard> featureCards = [
  FeatureCard(
    title: 'Your Ultimate Reading\nHeadquarters',
    subtitle:
        "Whether it's an ePub, a PDF, Biblio handles your formats with a beautiful, unified reading experience.",
    imagePath: 'assets/ob/ob1.png',
    cardColor: Color(0xFF191B46),
  ),
  FeatureCard(
    title: 'Read with an AI\ncompanion.',
    subtitle:
        "Don't just consume text—interact with it. Highlight to get instant context, definitions, or summaries powered by advanced AI.",
    imagePath: 'assets/ob/obb3.png',
    cardColor: Color(0xFFA1052C),
  ),
  FeatureCard(
    title: 'Built for the consistent\nreader.',
    subtitle:
        "Stay motivated with smart streaks and progress tracking. Biblio turns your reading goals into a rewarding daily habit.",
    imagePath: 'assets/ob/ob3.png',
    cardColor: Color(0xFF043222),
  ),
  FeatureCard(
    title: 'Your insights, archived\nforever.',
    subtitle:
        "Every quote you save and every note you write is synced to your personal journal, creating a searchable \"second brain\".",
    imagePath: 'assets/ob/ob4.png',
    cardColor: Color(0xFF381932),
  ),
];
