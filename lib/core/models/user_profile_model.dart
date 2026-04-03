class UserProfile {
  final String id;
  final String userId;
  final int totalXp;
  final int currentLevel;
  final int streakSaversAvailable;
  final String? selectedBadgeId;
  final String? username;
  final int dailyReadingGoalMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.userId,
    required this.totalXp,
    required this.currentLevel,
    required this.streakSaversAvailable,
    this.selectedBadgeId,
    this.username,
    required this.dailyReadingGoalMinutes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      totalXp: map['total_xp'] as int? ?? 0,
      currentLevel: map['current_level'] as int? ?? 1,
      streakSaversAvailable: map['streak_savers_available'] as int? ?? 1,
      selectedBadgeId: map['selected_badge_id'] as String?,
      username: map['username'] as String?,
      dailyReadingGoalMinutes: map['daily_reading_goal_minutes'] as int? ?? 30,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'total_xp': totalXp,
      'current_level': currentLevel,
      'streak_savers_available': streakSaversAvailable,
      'selected_badge_id': selectedBadgeId,
      'username': username,
      'daily_reading_goal_minutes': dailyReadingGoalMinutes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? userId,
    int? totalXp,
    int? currentLevel,
    int? streakSaversAvailable,
    String? selectedBadgeId,
    String? username,
    int? dailyReadingGoalMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      totalXp: totalXp ?? this.totalXp,
      currentLevel: currentLevel ?? this.currentLevel,
      streakSaversAvailable:
          streakSaversAvailable ?? this.streakSaversAvailable,
      selectedBadgeId: selectedBadgeId ?? this.selectedBadgeId,
      username: username ?? this.username,
      dailyReadingGoalMinutes:
          dailyReadingGoalMinutes ?? this.dailyReadingGoalMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
