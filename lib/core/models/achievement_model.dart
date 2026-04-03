class Achievement {
  final String id;
  final String title;
  final String description;
  final int xpReward;
  final int targetValue;
  final String category;
  final String iconName;
  final String tier;
  final DateTime createdAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.xpReward,
    required this.targetValue,
    required this.category,
    required this.iconName,
    required this.tier,
    required this.createdAt,
  });

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      xpReward: map['xp_reward'] as int,
      targetValue: map['target_value'] as int,
      category: map['category'] as String,
      iconName: map['icon_name'] as String,
      tier: map['tier'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'xp_reward': xpReward,
      'target_value': targetValue,
      'category': category,
      'icon_name': iconName,
      'tier': tier,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class UserAchievement {
  final String id;
  final String userId;
  final String achievementId;
  final int currentProgress;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final DateTime? viewedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Achievement? achievement; // Joined data

  UserAchievement({
    required this.id,
    required this.userId,
    required this.achievementId,
    required this.currentProgress,
    required this.isUnlocked,
    this.unlockedAt,
    this.viewedAt,
    required this.createdAt,
    required this.updatedAt,
    this.achievement,
  });

  factory UserAchievement.fromMap(Map<String, dynamic> map) {
    return UserAchievement(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      achievementId: map['achievement_id'] as String,
      currentProgress: map['current_progress'] as int? ?? 0,
      isUnlocked: map['is_unlocked'] as bool? ?? false,
      unlockedAt:
          map['unlocked_at'] != null
              ? DateTime.parse(map['unlocked_at'] as String)
              : null,
      viewedAt:
          map['viewed_at'] != null
              ? DateTime.parse(map['viewed_at'] as String)
              : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      achievement:
          map['achievements'] != null
              ? Achievement.fromMap(map['achievements'] as Map<String, dynamic>)
              : null,
    );
  }

  bool get needsConfetti => isUnlocked && viewedAt == null;
}