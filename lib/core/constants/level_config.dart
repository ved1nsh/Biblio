import 'package:flutter/material.dart';

class LevelInfo {
  final String tag;
  final String description;
  final List<Color> gradient;
  final IconData icon;

  const LevelInfo({
    required this.tag,
    required this.description,
    required this.gradient,
    required this.icon,
  });
}

class LevelConfig {
  LevelConfig._();

  /// Get info for a specific level
  static LevelInfo getInfo(int level) {
    if (level <= 0) return _levels.first;
    if (level >= _levels.length) return _levels.last;
    return _levels[level];
  }

  /// Get all level tiers (for the levels screen)
  static List<LevelTier> get allTiers => _tiers;

  /// Level → LevelInfo mapping (index = level)
  static const List<LevelInfo> _levels = [
    // Level 0 (fallback)
    LevelInfo(
      tag: 'Newcomer',
      description: 'Just getting started',
      gradient: [Color(0xFF90CAF9), Color(0xFF42A5F5)],
      icon: Icons.auto_stories_outlined,
    ),
    // Level 1
    LevelInfo(
      tag: 'Newcomer',
      description: 'Every great reader starts here',
      gradient: [Color(0xFF90CAF9), Color(0xFF42A5F5)],
      icon: Icons.auto_stories_outlined,
    ),
    // Level 2
    LevelInfo(
      tag: 'Page Turner',
      description: 'Turning pages one by one',
      gradient: [Color(0xFF80CBC4), Color(0xFF26A69A)],
      icon: Icons.menu_book_rounded,
    ),
    // Level 3
    LevelInfo(
      tag: 'Page Turner',
      description: 'Building your reading habit',
      gradient: [Color(0xFF80CBC4), Color(0xFF26A69A)],
      icon: Icons.menu_book_rounded,
    ),
    // Level 4
    LevelInfo(
      tag: 'Curious Reader',
      description: 'Curiosity drives your journey',
      gradient: [Color(0xFFA5D6A7), Color(0xFF66BB6A)],
      icon: Icons.explore_rounded,
    ),
    // Level 5
    LevelInfo(
      tag: 'Curious Reader',
      description: 'Your curiosity has no bounds',
      gradient: [Color(0xFFA5D6A7), Color(0xFF66BB6A)],
      icon: Icons.explore_rounded,
    ),
    // Level 6
    LevelInfo(
      tag: 'Bookworm',
      description: 'Books are your second home',
      gradient: [Color(0xFFFFCC80), Color(0xFFFFA726)],
      icon: Icons.local_library_rounded,
    ),
    // Level 7
    LevelInfo(
      tag: 'Bookworm',
      description: 'Nothing beats a good book',
      gradient: [Color(0xFFFFCC80), Color(0xFFFFA726)],
      icon: Icons.local_library_rounded,
    ),
    // Level 8
    LevelInfo(
      tag: 'Scholar',
      description: 'Reading with purpose and depth',
      gradient: [Color(0xFFCE93D8), Color(0xFFAB47BC)],
      icon: Icons.school_rounded,
    ),
    // Level 9
    LevelInfo(
      tag: 'Scholar',
      description: 'Knowledge is your superpower',
      gradient: [Color(0xFFCE93D8), Color(0xFFAB47BC)],
      icon: Icons.school_rounded,
    ),
    // Level 10
    LevelInfo(
      tag: 'Bibliophile',
      description: 'A true lover of books',
      gradient: [Color(0xFFEF9A9A), Color(0xFFEF5350)],
      icon: Icons.favorite_rounded,
    ),
    // Level 11
    LevelInfo(
      tag: 'Bibliophile',
      description: 'Books run through your veins',
      gradient: [Color(0xFFEF9A9A), Color(0xFFEF5350)],
      icon: Icons.favorite_rounded,
    ),
    // Level 12
    LevelInfo(
      tag: 'Bibliophile',
      description: 'An unstoppable reading force',
      gradient: [Color(0xFFEF9A9A), Color(0xFFEF5350)],
      icon: Icons.favorite_rounded,
    ),
    // Level 13
    LevelInfo(
      tag: 'Sage',
      description: 'Wisdom flows through every page',
      gradient: [Color(0xFFFFD54F), Color(0xFFFFC107)],
      icon: Icons.psychology_rounded,
    ),
    // Level 14
    LevelInfo(
      tag: 'Sage',
      description: 'A beacon of literary knowledge',
      gradient: [Color(0xFFFFD54F), Color(0xFFFFC107)],
      icon: Icons.psychology_rounded,
    ),
    // Level 15
    LevelInfo(
      tag: 'Sage',
      description: 'Wisdom beyond measure',
      gradient: [Color(0xFFFFD54F), Color(0xFFFFC107)],
      icon: Icons.psychology_rounded,
    ),
    // Level 16+
    LevelInfo(
      tag: 'Grandmaster',
      description: 'A living legend among readers',
      gradient: [Color(0xFFFFB74D), Color(0xFFFF7043)],
      icon: Icons.military_tech_rounded,
    ),
    // Level 17
    LevelInfo(
      tag: 'Grandmaster',
      description: 'Master of the literary arts',
      gradient: [Color(0xFFFFB74D), Color(0xFFFF7043)],
      icon: Icons.military_tech_rounded,
    ),
    // Level 18
    LevelInfo(
      tag: 'Grandmaster',
      description: 'Books bow in your presence',
      gradient: [Color(0xFFFFB74D), Color(0xFFFF7043)],
      icon: Icons.military_tech_rounded,
    ),
    // Level 19
    LevelInfo(
      tag: 'Grandmaster',
      description: 'An eternal scholar of stories',
      gradient: [Color(0xFFFFB74D), Color(0xFFFF7043)],
      icon: Icons.military_tech_rounded,
    ),
    // Level 20+
    LevelInfo(
      tag: 'Legend',
      description: 'The ultimate reading legend',
      gradient: [Color(0xFFFFD700), Color(0xFFFF8C00)],
      icon: Icons.emoji_events_rounded,
    ),
  ];

  /// Tier groupings for the levels screen
  static final List<LevelTier> _tiers = [
    LevelTier(
      name: 'Newcomer',
      levelRange: '1',
      gradient: const [Color(0xFF90CAF9), Color(0xFF42A5F5)],
      icon: Icons.auto_stories_outlined,
      description: 'Every reader starts somewhere.',
    ),
    LevelTier(
      name: 'Page Turner',
      levelRange: '2 – 3',
      gradient: const [Color(0xFF80CBC4), Color(0xFF26A69A)],
      icon: Icons.menu_book_rounded,
      description: 'You\'re building a real habit.',
    ),
    LevelTier(
      name: 'Curious Reader',
      levelRange: '4 – 5',
      gradient: const [Color(0xFFA5D6A7), Color(0xFF66BB6A)],
      icon: Icons.explore_rounded,
      description: 'Your curiosity fuels your journey.',
    ),
    LevelTier(
      name: 'Bookworm',
      levelRange: '6 – 7',
      gradient: const [Color(0xFFFFCC80), Color(0xFFFFA726)],
      icon: Icons.local_library_rounded,
      description: 'Books are your second home.',
    ),
    LevelTier(
      name: 'Scholar',
      levelRange: '8 – 9',
      gradient: const [Color(0xFFCE93D8), Color(0xFFAB47BC)],
      icon: Icons.school_rounded,
      description: 'Reading with purpose and depth.',
    ),
    LevelTier(
      name: 'Bibliophile',
      levelRange: '10 – 12',
      gradient: const [Color(0xFFEF9A9A), Color(0xFFEF5350)],
      icon: Icons.favorite_rounded,
      description: 'A true lover of the written word.',
    ),
    LevelTier(
      name: 'Sage',
      levelRange: '13 – 15',
      gradient: const [Color(0xFFFFD54F), Color(0xFFFFC107)],
      icon: Icons.psychology_rounded,
      description: 'Wisdom flows through every page.',
    ),
    LevelTier(
      name: 'Grandmaster',
      levelRange: '16 – 19',
      gradient: const [Color(0xFFFFB74D), Color(0xFFFF7043)],
      icon: Icons.military_tech_rounded,
      description: 'A master of the literary arts.',
    ),
    LevelTier(
      name: 'Legend',
      levelRange: '20+',
      gradient: const [Color(0xFFFFD700), Color(0xFFFF8C00)],
      icon: Icons.emoji_events_rounded,
      description: 'The ultimate reading legend.',
    ),
  ];
}

class LevelTier {
  final String name;
  final String levelRange;
  final List<Color> gradient;
  final IconData icon;
  final String description;

  const LevelTier({
    required this.name,
    required this.levelRange,
    required this.gradient,
    required this.icon,
    required this.description,
  });
}
