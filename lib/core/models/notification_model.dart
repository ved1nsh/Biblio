class UserNotification {
  final String id;
  final String userId;
  final String type; // 'achievement', 'level_up', 'streak_broken', 'daily_goal'
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final bool isRead;
  final bool requiresAction;
  final DateTime createdAt;

  UserNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    required this.isRead,
    required this.requiresAction,
    required this.createdAt,
  });

  factory UserNotification.fromMap(Map<String, dynamic> map) {
    return UserNotification(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      type: map['type'] as String,
      title: map['title'] as String,
      message: map['message'] as String,
      data: map['data'] as Map<String, dynamic>?,
      isRead: map['is_read'] as bool? ?? false,
      requiresAction: map['requires_action'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'title': title,
      'message': message,
      'data': data,
      'is_read': isRead,
      'requires_action': requiresAction,
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserNotification copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? message,
    Map<String, dynamic>? data,
    bool? isRead,
    bool? requiresAction,
    DateTime? createdAt,
  }) {
    return UserNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      requiresAction: requiresAction ?? this.requiresAction,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}