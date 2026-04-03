import 'package:flutter/material.dart';

class AchievementIcons {
  AchievementIcons._();

  static IconData getIcon(String achievementId) {
    switch (achievementId) {
      // Reading Achievements
      case 'the_finisher':
        return Icons.check_circle;
      case 'bookworm':
        return Icons.menu_book;
      case 'serial_reader':
        return Icons.local_library;
      case 'deep_focus':
        return Icons.psychology;

      // Streak Achievements
      case 'spark':
        return Icons.local_fire_department;
      case 'on_fire':
        return Icons.whatshot;
      case 'committed':
        return Icons.fitness_center;
      case 'centurion':
        return Icons.military_tech;

      // Daily Goal Achievements
      case 'week_warrior':
        return Icons.date_range;
      case 'month_master':
        return Icons.calendar_month;

      // Library Achievements
      case 'the_architect':
        return Icons.architecture;
      case 'librarian':
        return Icons.folder_special;

      // Quote Achievements
      case 'quote_collector':
        return Icons.format_quote;
      case 'golden_line':
        return Icons.star;

      // Default
      default:
        return Icons.emoji_events;
    }
  }

  static Color getIconColor(String tier) {
    switch (tier) {
      case 'bronze':
        return Colors.brown;
      case 'silver':
        return Colors.grey[600]!;
      case 'gold':
        return Colors.amber[700]!;
      default:
        return Colors.blue;
    }
  }

  static String getTierLabel(String tier) {
    switch (tier) {
      case 'bronze':
        return 'Bronze';
      case 'silver':
        return 'Silver';
      case 'gold':
        return 'Gold';
      default:
        return 'Common';
    }
  }

  static IconData getTierIcon(String tier) {
    switch (tier) {
      case 'bronze':
        return Icons.workspace_premium;
      case 'silver':
        return Icons.workspace_premium_outlined;
      case 'gold':
        return Icons.workspace_premium_rounded;
      default:
        return Icons.emoji_events_outlined;
    }
  }
}
