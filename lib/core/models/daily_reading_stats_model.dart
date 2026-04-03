class DailyReadingStats {
  final String id;
  final String userId;
  final DateTime date;
  final int totalSeconds;
  final List<BookReadingEntry> booksRead;
  final DateTime createdAt;
  final DateTime updatedAt;

  DailyReadingStats({
    required this.id,
    required this.userId,
    required this.date,
    required this.totalSeconds,
    required this.booksRead,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DailyReadingStats.fromJson(Map<String, dynamic> json) {
    return DailyReadingStats(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      date: DateTime.parse(json['date'] as String),
      totalSeconds: json['total_seconds'] as int,
      booksRead: (json['books_read'] as List<dynamic>)
          .map((item) => BookReadingEntry.fromJson(item as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'date': date.toIso8601String().split('T')[0], // Format as YYYY-MM-DD
      'total_seconds': totalSeconds,
      'books_read': booksRead.map((book) => book.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  DailyReadingStats copyWith({
    String? id,
    String? userId,
    DateTime? date,
    int? totalSeconds,
    List<BookReadingEntry>? booksRead,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DailyReadingStats(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      booksRead: booksRead ?? this.booksRead,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class BookReadingEntry {
  final String bookId;
  final String bookTitle;
  final int durationSeconds;
  final double progressGained;
  final String? moodEmoji;

  BookReadingEntry({
    required this.bookId,
    required this.bookTitle,
    required this.durationSeconds,
    required this.progressGained,
    this.moodEmoji,
  });

  factory BookReadingEntry.fromJson(Map<String, dynamic> json) {
    return BookReadingEntry(
      bookId: json['book_id'] as String,
      bookTitle: json['book_title'] as String,
      durationSeconds: json['duration_seconds'] as int,
      progressGained: (json['progress_gained'] as num).toDouble(),
      moodEmoji: json['mood_emoji'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'book_id': bookId,
      'book_title': bookTitle,
      'duration_seconds': durationSeconds,
      'progress_gained': progressGained,
      'mood_emoji': moodEmoji,
    };
  }

  BookReadingEntry copyWith({
    String? bookId,
    String? bookTitle,
    int? durationSeconds,
    double? progressGained,
    String? moodEmoji,
  }) {
    return BookReadingEntry(
      bookId: bookId ?? this.bookId,
      bookTitle: bookTitle ?? this.bookTitle,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      progressGained: progressGained ?? this.progressGained,
      moodEmoji: moodEmoji ?? this.moodEmoji,
    );
  }
}