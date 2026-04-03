// Handles loading, saving, and deleting journal data (highlights & notes)
// from Supabase via HighlightsService and NotebookService.

import 'package:flutter/material.dart';
import '../../core/services/highlights_service.dart';
import '../../core/services/notebook_service.dart';
import '../models/journal_entry.dart';

class JournalDataController extends ChangeNotifier {
  final HighlightsService _highlightsService = HighlightsService();
  final NotebookService _notebookService = NotebookService();

  List<Map<String, dynamic>> _highlights = [];
  List<Map<String, dynamic>> _notes = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get highlights => _highlights;
  List<Map<String, dynamic>> get notes => _notes;
  bool get isLoading => _isLoading;

  Future<void> loadJournalData(String bookId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _highlights = await _highlightsService.getHighlightsByBook(bookId);
      _notes = await _notebookService.getQuotesByBook(bookId);
    } catch (e) {
      debugPrint('❌ Error loading journal data: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> saveNote({
    required String bookId,
    required String noteText,
    String? bookTitle,
    String? authorName,
  }) async {
    final success = await _notebookService.saveQuote(
      bookId: bookId,
      quoteText: noteText,
      bookTitle: bookTitle,
      authorName: authorName,
    );
    if (success) {
      await loadJournalData(bookId);
    }
    return success;
  }

  Future<void> deleteHighlight(String highlightId, String bookId) async {
    await _highlightsService.deleteHighlight(highlightId);
    await loadJournalData(bookId);
  }

  Future<void> deleteNote(String noteId, String bookId) async {
    await _notebookService.deleteQuote(noteId);
    await loadJournalData(bookId);
  }

  int estimatePage(double? progress, int? totalPages) {
    if (progress == null) return 0;
    final total = totalPages ?? 300;
    return (progress * total).round().clamp(1, total);
  }

  /// Extract page number from PDF-style CFI like 'pdf-page-5'
  int? _parsePdfPage(String? cfi) {
    if (cfi == null || !cfi.startsWith('pdf-page-')) return null;
    return int.tryParse(cfi.replaceFirst('pdf-page-', ''));
  }

  List<JournalEntry> buildJournalEntries(int? totalPages) {
    final entries = <JournalEntry>[];

    for (final h in _highlights) {
      final createdAt = DateTime.tryParse(h['created_at']?.toString() ?? '');
      if (createdAt == null) continue;

      final progress = h['progress_percent'] as double?;
      final cfi = h['cfi_range'] as String?;
      final page = _parsePdfPage(cfi) ?? estimatePage(progress, totalPages);
      final chapterTitle = h['chapter_title'] as String?;

      entries.add(
        JournalEntry(
          type: JournalEntryType.highlight,
          text: (h['highlighted_text'] ?? '').toString(),
          page: page,
          date: createdAt,
          chapterTitle: chapterTitle,
          progress: progress,
          cfi: cfi,
          highlightId: h['id'] as String?,
        ),
      );
    }

    for (final n in _notes) {
      final createdAt = DateTime.tryParse(n['created_at']?.toString() ?? '');
      if (createdAt == null) continue;

      final progress = n['progress_percent'] as double?;
      final cfi = n['cfi_range'] as String?;
      final page = _parsePdfPage(cfi) ?? estimatePage(progress, totalPages);
      final quoteText = n['quote_text'] as String?;
      final noteText = n['note_text'] as String?;

      if (quoteText != null && quoteText.isNotEmpty) {
        entries.add(
          JournalEntry(
            type: JournalEntryType.quote,
            text: quoteText,
            page: page,
            date: createdAt,
            imagePath: n['image_path'] as String?,
            progress: progress,
            cfi: cfi,
            noteId: n['id'] as String?,
          ),
        );
      } else if (noteText != null && noteText.isNotEmpty) {
        entries.add(
          JournalEntry(
            type: JournalEntryType.note,
            text: noteText,
            page: page,
            date: createdAt,
            imagePath: n['image_path'] as String?,
            progress: progress,
            cfi: cfi,
            noteId: n['id'] as String?,
          ),
        );
      }
    }

    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }
}
