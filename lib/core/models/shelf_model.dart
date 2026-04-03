class Shelf {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String color;
  final int orderIndex;
  final DateTime createdAt;
  final DateTime updatedAt;

  Shelf({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.color,
    this.orderIndex = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Shelf.fromJson(Map<String, dynamic> json) {
    return Shelf(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      color: json['color'] as String,
      orderIndex: json['order_index'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'color': color,
      'order_index': orderIndex,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Shelf copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    String? color,
    int? orderIndex,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Shelf(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      orderIndex: orderIndex ?? this.orderIndex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
