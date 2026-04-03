import 'package:flutter/material.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import '../controllers/epub_theme_controller.dart';
import '../controllers/journal_data_controller.dart';
import '../models/journal_entry.dart';
import 'table_of_contents_view.dart';
import 'journal_view.dart';
import 'sheet_components.dart';

class EpubTableOfContentsSheet extends StatefulWidget {
  final List<EpubChapter> chapters;
  final Function(EpubChapter) onChapterTap;
  final EpubThemeController themeController;
  final String? currentChapterTitle;
  final double readingProgress;
  final String bookId;
  final String bookTitle;
  final int? totalPages;
  final Function(double)? onNavigateToProgress;
  final Function(String)? onNavigateToCfi;

  const EpubTableOfContentsSheet({
    super.key,
    required this.chapters,
    required this.onChapterTap,
    required this.themeController,
    required this.bookId,
    required this.bookTitle,
    this.currentChapterTitle,
    this.readingProgress = 0.0,
    this.totalPages,
    this.onNavigateToProgress,
    this.onNavigateToCfi,
  });

  @override
  State<EpubTableOfContentsSheet> createState() =>
      _EpubTableOfContentsSheetState();
}

class _EpubTableOfContentsSheetState extends State<EpubTableOfContentsSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  bool _showBookJournal = false;
  final JournalDataController _journalController = JournalDataController();

  final TextEditingController _noteController = TextEditingController();
  final FocusNode _noteFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _slide = Tween<Offset>(
      begin: const Offset(-1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();

    _journalController.addListener(_onJournalUpdate);
    _journalController.loadJournalData(widget.bookId);
  }

  void _onJournalUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    _noteController.dispose();
    _noteFocusNode.dispose();
    _journalController.removeListener(_onJournalUpdate);
    _journalController.dispose();
    super.dispose();
  }

  void _close() {
    _controller.reverse().then((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  void _navigateToJournalEntry(JournalEntry entry) {
    _close();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (entry.cfi != null && entry.cfi!.isNotEmpty) {
        widget.onNavigateToCfi?.call(entry.cfi!);
      } else if (entry.progress != null) {
        widget.onNavigateToProgress?.call(entry.progress!.clamp(0.0, 1.0));
      }
    });
  }

  Future<void> _saveNote() async {
    if (_noteController.text.trim().isEmpty) return;

    final noteText = _noteController.text.trim();
    final success = await _journalController.saveNote(
      bookId: widget.bookId,
      noteText: noteText,
    );

    if (success) {
      _noteController.clear();
      _noteFocusNode.unfocus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Note added to journal!'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFD97757),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to save note'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  void _handleDeleteHighlight(JournalEntry entry) {
    showDeleteConfirmation(
      context: context,
      themeController: widget.themeController,
      title: 'Delete this highlight?',
      onConfirm: () async {
        if (entry.highlightId != null) {
          await _journalController.deleteHighlight(
            entry.highlightId!,
            widget.bookId,
          );
        }
      },
    );
  }

  void _handleDeleteNote(JournalEntry entry) {
    final label = entry.type == JournalEntryType.quote ? 'quote' : 'note';
    showDeleteConfirmation(
      context: context,
      themeController: widget.themeController,
      title: 'Delete this $label?',
      onConfirm: () async {
        if (entry.noteId != null) {
          await _journalController.deleteNote(entry.noteId!, widget.bookId);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);

    final bg = widget.themeController.backgroundColor;
    final text = widget.themeController.textColor;
    final divider = widget.themeController.dividerColor;

    final entries = _journalController.buildJournalEntries(widget.totalPages);
    final sheetWidth = (MediaQuery.of(context).size.width * 0.85).clamp(
      250.0,
      400.0,
    );
    final shadowBlur = (10 * scale).clamp(8.0, 10.0).roundToDouble();
    final topRightRadius = (20 * scale).clamp(16.0, 20.0).roundToDouble();

    return Stack(
      children: [
        FadeTransition(
          opacity: _fade,
          child: GestureDetector(
            onTap: _close,
            child: Container(color: Colors.black.withValues(alpha: 0.5)),
          ),
        ),
        SlideTransition(
          position: _slide,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: sheetWidth,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(topRightRadius),
                    bottomRight: Radius.circular(topRightRadius),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: shadowBlur,
                      offset: const Offset(2, 0),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SheetHeader(
                        showBookJournal: _showBookJournal,
                        bookTitle: widget.bookTitle,
                        textColor: text,
                        onClose: _close,
                        onToggleContents:
                            () => setState(() => _showBookJournal = false),
                        onToggleJournal:
                            () => setState(() => _showBookJournal = true),
                        scale: scale,
                      ),
                      Divider(height: 1, color: divider),
                      Expanded(
                        child:
                            _showBookJournal
                                ? JournalView(
                                  entries: entries,
                                  isLoading: _journalController.isLoading,
                                  textColor: text,
                                  onEntryTap: _navigateToJournalEntry,
                                  onDeleteHighlight: _handleDeleteHighlight,
                                  onDeleteNote: _handleDeleteNote,
                                )
                                : TableOfContentsView(
                                  chapters: widget.chapters,
                                  currentChapterTitle:
                                      widget.currentChapterTitle,
                                  textColor: text,
                                  dividerColor: divider,
                                  onChapterTap: (chapter) {
                                    widget.onChapterTap(chapter);
                                    _close();
                                  },
                                  scale: scale,
                                ),
                      ),
                      if (_showBookJournal)
                        NoteInputBar(
                          backgroundColor: bg,
                          textColor: text,
                          dividerColor: divider,
                          controller: _noteController,
                          focusNode: _noteFocusNode,
                          onSave: _saveNote,
                          scale: scale,
                        )
                      else
                        ReadingProgressBar(
                          readingProgress: widget.readingProgress,
                          textColor: text,
                          dividerColor: divider,
                          scale: scale,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
