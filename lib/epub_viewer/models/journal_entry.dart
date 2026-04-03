// Model class representing a journal entry (highlight, quote, or personal note)
//associated with a book in the epub reader.

enum JournalEntryType { highlight, quote, note }

class JournalEntry {
  final JournalEntryType type;
  final String text;
  final int page;
  final DateTime date;
  final String? chapterTitle;
  final String? imagePath;
  final double? progress;
  final String? cfi;
  final String? highlightId;
  final String? noteId;

  const JournalEntry({
    required this.type,
    required this.text,
    required this.page,
    required this.date,
    this.chapterTitle,
    this.imagePath,
    this.progress,
    this.cfi,
    this.highlightId,
    this.noteId,
  });
}
