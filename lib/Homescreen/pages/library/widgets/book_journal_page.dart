import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:biblio/core/models/book_model.dart';
import 'package:biblio/epub_viewer/controllers/journal_data_controller.dart';
import 'package:biblio/epub_viewer/models/journal_entry.dart';
import 'package:biblio/epub_viewer/widgets/journal_view.dart';

class BookJournalPage extends StatefulWidget {
  final Book book;

  const BookJournalPage({super.key, required this.book});

  @override
  State<BookJournalPage> createState() => _BookJournalPageState();
}

class _BookJournalPageState extends State<BookJournalPage> {
  final JournalDataController _journalController = JournalDataController();
  final TextEditingController _noteController = TextEditingController();
  final FocusNode _noteFocusNode = FocusNode();
  List<JournalEntry> _entries = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadJournal();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _noteFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadJournal() async {
    setState(() => _isLoading = true);
    await _journalController.loadJournalData(widget.book.id);
    if (mounted) {
      setState(() {
        _entries = _journalController.buildJournalEntries(
          widget.book.totalPages,
        );
        _isLoading = false;
      });
    }
  }

  Future<void> _saveNote() async {
    final text = _noteController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final success = await _journalController.saveNote(
      bookId: widget.book.id,
      noteText: text,
      bookTitle: widget.book.title,
      authorName: widget.book.author,
    );

    if (mounted) {
      setState(() => _isSaving = false);

      if (success) {
        _noteController.clear();
        _noteFocusNode.unfocus();
        await _loadJournal();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Note saved',
              style: TextStyle(fontFamily: 'SF-UI-Display'),
            ),
            backgroundColor: const Color(0xFFD97757),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleDeleteHighlight(JournalEntry entry) async {
    if (entry.highlightId == null) return;

    final confirmed = await _showDeleteConfirmation('highlight');
    if (confirmed != true) return;

    await _journalController.deleteHighlight(
      entry.highlightId!,
      widget.book.id,
    );
    await _loadJournal();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Highlight deleted',
            style: TextStyle(fontFamily: 'SF-UI-Display'),
          ),
          backgroundColor: const Color(0xFFD97757),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _handleDeleteNote(JournalEntry entry) async {
    if (entry.noteId == null) return;

    final confirmed = await _showDeleteConfirmation(
      entry.type == JournalEntryType.quote ? 'quote' : 'note',
    );
    if (confirmed != true) return;

    await _journalController.deleteNote(entry.noteId!, widget.book.id);
    await _loadJournal();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${entry.type == JournalEntryType.quote ? 'Quote' : 'Note'} deleted',
            style: const TextStyle(fontFamily: 'SF-UI-Display'),
          ),
          backgroundColor: const Color(0xFFD97757),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<bool?> _showDeleteConfirmation(String type) {
    HapticFeedback.mediumImpact();
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFFFCF9F5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Delete $type?',
              style: const TextStyle(
                fontFamily: 'SF-UI-Display',
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Text(
              'This $type will be permanently deleted.',
              style: const TextStyle(fontFamily: 'SF-UI-Display'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontFamily: 'SF-UI-Display',
                    color: Colors.black.withValues(alpha: 0.6),
                  ),
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(
                    fontFamily: 'SF-UI-Display',
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final headerTitleSize = (20 * scale).clamp(16.0, 20.0);

    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: AppBar(
                backgroundColor: const Color(0xFFFCF9F5),
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                centerTitle: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Column(
                  children: [
                    Text(
                      'Book Journal',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: headerTitleSize,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'SF-UI-Display',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.book.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.5),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'SF-UI-Display',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Journal entries
            Expanded(
              child: JournalView(
                entries: _entries,
                isLoading: _isLoading,
                textColor: Colors.black,
                onEntryTap: (_) {},
                onDeleteHighlight: _handleDeleteHighlight,
                onDeleteNote: _handleDeleteNote,
              ),
            ),

            // Note input bar
            Container(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                12 + MediaQuery.of(context).padding.bottom,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFCF9F5),
                border: Border(
                  top: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.12),
                        ),
                      ),
                      child: TextField(
                        controller: _noteController,
                        focusNode: _noteFocusNode,
                        maxLines: 3,
                        minLines: 1,
                        textInputAction: TextInputAction.newline,
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'SF-UI-Display',
                          color: Colors.black87,
                          height: 1.4,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Add a personal note...',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            fontFamily: 'SF-UI-Display',
                            color: Colors.black.withValues(alpha: 0.35),
                          ),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 12, right: 8),
                            child: Icon(
                              Icons.edit_rounded,
                              size: 18,
                              color: Colors.black.withValues(alpha: 0.4),
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minHeight: 0,
                            minWidth: 0,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _isSaving ? null : _saveNote,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97757),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child:
                          _isSaving
                              ? const Padding(
                                padding: EdgeInsets.all(11),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
