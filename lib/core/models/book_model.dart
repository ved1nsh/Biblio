class Book {
  final String id;
  final String userId;
  final String title;
  final String author;
  final String? coverUrl;
  final String? filePath;
  final int currentPage;
  final int totalPages;
  final bool isStartedReading;
  final bool isManualEntry;
  final String? notes;
  final String? fileStatus;
  final String? fileType;
  final String? originalFileName;
  final DateTime createdAt;
  final DateTime updatedAt;

  // NEW: Reading progress tracking fields
  final String? currentCfi;
  final double? progressPercent;
  final int? totalReadSeconds;
  final DateTime? lastReadAt;
  final List<String>? shelfIds;

  Book({
    required this.id,
    required this.userId,
    required this.title,
    required this.author,
    this.coverUrl,
    this.filePath,
    this.currentPage = 0,
    this.totalPages = 0,
    this.isStartedReading = false,
    this.isManualEntry = false,
    this.notes,
    this.fileStatus = 'available',
    this.fileType,
    this.originalFileName,
    required this.createdAt,
    required this.updatedAt,
    // NEW: Reading progress parameters
    this.currentCfi,
    this.progressPercent,
    this.totalReadSeconds,
    this.lastReadAt,
    this.shelfIds,
  });

  // From Supabase JSON
  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      coverUrl: json['cover_url'] as String?,
      filePath: json['file_path'] as String?,
      currentPage: json['current_page'] as int? ?? 0,
      totalPages: json['total_pages'] as int? ?? 0,
      isStartedReading: json['is_started_reading'] as bool? ?? false,
      isManualEntry: json['is_manual_entry'] as bool? ?? false,
      notes: json['notes'] as String?,
      fileStatus: json['file_status'] as String? ?? 'available',
      fileType: json['file_type'] as String?,
      originalFileName: json['original_file_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      // NEW: Reading progress fields
      currentCfi: json['current_cfi'] as String?,
      progressPercent:
          json['progress_percent'] != null
              ? (json['progress_percent'] as num).toDouble()
              : null,
      totalReadSeconds: json['total_read_seconds'] as int?,
      lastReadAt:
          json['last_read_at'] != null
              ? DateTime.parse(json['last_read_at'] as String)
              : null,
      shelfIds:
          json['shelf_ids'] != null
              ? List<String>.from(json['shelf_ids'])
              : null,
    );
  }

  // To Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'author': author,
      'cover_url': coverUrl,
      'file_path': filePath,
      'current_page': currentPage,
      'total_pages': totalPages,
      'is_started_reading': isStartedReading,
      'is_manual_entry': isManualEntry,
      'notes': notes,
      'file_status': fileStatus,
      'file_type': fileType,
      'original_file_name': originalFileName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      // NEW: Reading progress fields
      'current_cfi': currentCfi,
      'progress_percent': progressPercent,
      'total_read_seconds': totalReadSeconds,
      'last_read_at': lastReadAt?.toIso8601String(),
      'shelf_ids': shelfIds,
    };
  }

  // CopyWith method for easy updates
  Book copyWith({
    String? id,
    String? userId,
    String? title,
    String? author,
    String? coverUrl,
    String? filePath,
    int? currentPage,
    int? totalPages,
    bool? isStartedReading,
    bool? isManualEntry,
    String? notes,
    String? fileStatus,
    String? fileType,
    String? originalFileName,
    DateTime? createdAt,
    DateTime? updatedAt,
    // NEW: Reading progress parameters
    String? currentCfi,
    double? progressPercent,
    int? totalReadSeconds,
    DateTime? lastReadAt,
    List<String>? shelfIds,
  }) {
    return Book(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      author: author ?? this.author,
      coverUrl: coverUrl ?? this.coverUrl,
      filePath: filePath ?? this.filePath,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      isStartedReading: isStartedReading ?? this.isStartedReading,
      isManualEntry: isManualEntry ?? this.isManualEntry,
      notes: notes ?? this.notes,
      fileStatus: fileStatus ?? this.fileStatus,
      fileType: fileType ?? this.fileType,
      originalFileName: originalFileName ?? this.originalFileName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      // NEW: Reading progress fields
      currentCfi: currentCfi ?? this.currentCfi,
      progressPercent: progressPercent ?? this.progressPercent,
      totalReadSeconds: totalReadSeconds ?? this.totalReadSeconds,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      shelfIds: shelfIds ?? this.shelfIds,
    );
  }
}
