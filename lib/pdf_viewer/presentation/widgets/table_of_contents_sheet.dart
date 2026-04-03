import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:io';
import 'package:biblio/epub_viewer/controllers/journal_data_controller.dart';
import 'package:biblio/epub_viewer/models/journal_entry.dart';
import 'package:biblio/epub_viewer/widgets/journal_view.dart';
import 'package:biblio/epub_viewer/widgets/sheet_components.dart';

class TableOfContentsSheet extends StatefulWidget {
  final String filePath;
  final Function(int) onChapterTap;
  final int currentPage;
  final int totalPages;
  final bool isDarkMode;
  final String bookId;

  const TableOfContentsSheet({
    super.key,
    required this.filePath,
    required this.onChapterTap,
    this.currentPage = 1,
    this.totalPages = 0,
    this.isDarkMode = false,
    this.bookId = '',
  });

  @override
  State<TableOfContentsSheet> createState() => _TableOfContentsSheetState();
}

class _TableOfContentsSheetState extends State<TableOfContentsSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  List<_ChapterInfo> _chapters = [];
  bool _isLoading = true;
  bool _showBookJournal = false;

  final JournalDataController _journalController = JournalDataController();
  final TextEditingController _noteController = TextEditingController();
  final FocusNode _noteFocusNode = FocusNode();

  // Theme-derived colors
  Color get _backgroundColor =>
      widget.isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
  Color get _textColor => widget.isDarkMode ? Colors.white : Colors.black87;
  Color get _subtitleColor =>
      widget.isDarkMode
          ? Colors.white.withOpacity(0.5)
          : Colors.black.withOpacity(0.5);
  Color get _dividerColor =>
      widget.isDarkMode ? Colors.white10 : Colors.black12;
  Color get _chapterBadgeColor => const Color(0xFFD97A73);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();
    _loadTableOfContents();

    _journalController.addListener(_onJournalUpdate);
    if (widget.bookId.isNotEmpty) {
      _journalController.loadJournalData(widget.bookId);
    }
  }

  void _onJournalUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _loadTableOfContents() async {
    try {
      final PdfDocument document = PdfDocument(
        inputBytes: File(widget.filePath).readAsBytesSync(),
      );
      final PdfBookmarkBase bookmarkBase = document.bookmarks;

      if (bookmarkBase.count > 0) {
        final List<_ChapterInfo> chapters = [];
        for (int i = 0; i < bookmarkBase.count; i++) {
          final bookmark = bookmarkBase[i];
          final title = bookmark.title;

          int pageIndex = 0;
          try {
            if (bookmark.destination != null) {
              final page = bookmark.destination!.page;
              pageIndex = document.pages.indexOf(page);
            }
          } catch (e) {
            debugPrint('Error getting page index for bookmark "$title": $e');
            pageIndex = 0;
          }

          chapters.add(_ChapterInfo(title: title, pageIndex: pageIndex));
        }

        setState(() {
          _chapters = chapters;
          _isLoading = false;
        });
      } else {
        setState(() {
          _chapters = [];
          _isLoading = false;
        });
      }
      document.dispose();
    } catch (e) {
      debugPrint('Error loading table of contents: $e');
      setState(() {
        _chapters = [];
        _isLoading = false;
      });
    }
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
      if (entry.page > 0) {
        widget.onChapterTap(entry.page);
      }
    });
  }

  void _handleDeleteHighlight(JournalEntry entry) {
    _showDeleteConfirmation(
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
    _showDeleteConfirmation(
      title: 'Delete this $label?',
      onConfirm: () async {
        if (entry.noteId != null) {
          await _journalController.deleteNote(entry.noteId!, widget.bookId);
        }
      },
    );
  }

  void _showDeleteConfirmation({
    required String title,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: _backgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              title,
              style: TextStyle(color: _textColor, fontFamily: 'SF-UI-Display'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel', style: TextStyle(color: _subtitleColor)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  onConfirm();
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
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
    }
  }

  /// Find which chapter the current page belongs to
  String? _getCurrentChapterTitle() {
    if (_chapters.isEmpty) return null;
    String? currentTitle;
    for (final chapter in _chapters) {
      if (chapter.pageIndex + 1 <= widget.currentPage) {
        currentTitle = chapter.title;
      } else {
        break;
      }
    }
    return currentTitle;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);

    final entries = _journalController.buildJournalEntries(widget.totalPages);
    final currentChapter = _getCurrentChapterTitle();

    return Stack(
      children: [
        // Dark overlay
        FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onTap: _close,
            child: Container(color: Colors.black.withOpacity(0.5)),
          ),
        ),

        // Sliding sheet
        SlideTransition(
          position: _slideAnimation,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: _backgroundColor,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(2, 0),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with Contents / Journal tabs
                      SheetHeader(
                        showBookJournal: _showBookJournal,
                        bookTitle: '',
                        textColor: _textColor,
                        onClose: _close,
                        onToggleContents:
                            () => setState(() => _showBookJournal = false),
                        onToggleJournal:
                            () => setState(() => _showBookJournal = true),
                        scale: scale,
                      ),
                      Divider(height: 1, color: _dividerColor),

                      // Content area
                      Expanded(
                        child:
                            _showBookJournal
                                ? JournalView(
                                  entries: entries,
                                  isLoading: _journalController.isLoading,
                                  textColor: _textColor,
                                  onEntryTap: _navigateToJournalEntry,
                                  onDeleteHighlight: _handleDeleteHighlight,
                                  onDeleteNote: _handleDeleteNote,
                                )
                                : _buildContentsView(currentChapter, scale),
                      ),

                      // Bottom bar
                      if (_showBookJournal)
                        NoteInputBar(
                          backgroundColor: _backgroundColor,
                          textColor: _textColor,
                          dividerColor: _dividerColor,
                          controller: _noteController,
                          focusNode: _noteFocusNode,
                          onSave: _saveNote,
                          scale: scale,
                        )
                      else
                        _buildProgressBar(scale),
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

  Widget _buildContentsView(String? currentChapter, double scale) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFD97A73)),
      );
    }

    if (_chapters.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all((32.0 * scale).roundToDouble()),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.menu_book_outlined,
                size: (64 * scale).roundToDouble(),
                color: _textColor.withOpacity(0.3),
              ),
              SizedBox(height: (16 * scale).roundToDouble()),
              Text(
                'No chapter data available',
                style: TextStyle(
                  fontSize: (16 * scale).clamp(14.0, 16.0),
                  fontFamily: 'SF-UI-Display',
                  color: _textColor.withOpacity(0.5),
                ),
              ),
              SizedBox(height: (8 * scale).roundToDouble()),
              Text(
                'This PDF doesn\'t contain\ntable of contents information',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: (14 * scale).clamp(12.0, 14.0),
                  fontFamily: 'SF-UI-Display',
                  color: _textColor.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: (8 * scale).roundToDouble()),
      itemCount: _chapters.length,
      itemBuilder: (context, index) {
        final chapter = _chapters[index];
        final isCurrent = chapter.title == currentChapter;
        return _buildChapterItem(
          chapter.title,
          chapter.pageIndex,
          index,
          isCurrent,
          scale,
        );
      },
    );
  }

  Widget _buildChapterItem(
    String title,
    int pageIndex,
    int index,
    bool isCurrent,
    double scale,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          widget.onChapterTap(pageIndex + 1);
          _close();
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: (20 * scale).roundToDouble(),
            vertical: (16 * scale).roundToDouble(),
          ),
          decoration: BoxDecoration(
            color:
                isCurrent
                    ? _chapterBadgeColor.withOpacity(0.06)
                    : Colors.transparent,
            border: Border(bottom: BorderSide(color: _dividerColor, width: 1)),
          ),
          child: Row(
            children: [
              Container(
                width: (36 * scale).roundToDouble(),
                height: (36 * scale).roundToDouble(),
                decoration: BoxDecoration(
                  color:
                      isCurrent
                          ? _chapterBadgeColor.withOpacity(0.15)
                          : _chapterBadgeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    (8 * scale).roundToDouble(),
                  ),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: (14 * scale).clamp(12.0, 14.0),
                      fontWeight: FontWeight.w600,
                      fontFamily: 'SF-UI-Display',
                      color: _chapterBadgeColor,
                    ),
                  ),
                ),
              ),
              SizedBox(width: (16 * scale).roundToDouble()),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: (16 * scale).clamp(14.0, 16.0),
                              fontWeight:
                                  isCurrent ? FontWeight.w700 : FontWeight.w500,
                              fontFamily: 'SF-UI-Display',
                              color: _textColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCurrent)
                          Container(
                            margin: EdgeInsets.only(
                              left: (8 * scale).roundToDouble(),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: (8 * scale).roundToDouble(),
                              vertical: (3 * scale).roundToDouble(),
                            ),
                            decoration: BoxDecoration(
                              color: _chapterBadgeColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(
                                (8 * scale).roundToDouble(),
                              ),
                            ),
                            child: Text(
                              'You are here',
                              style: TextStyle(
                                fontSize: (10 * scale).clamp(9.0, 10.0),
                                fontWeight: FontWeight.w600,
                                color: _chapterBadgeColor,
                                fontFamily: 'SF-UI-Display',
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: (4 * scale).roundToDouble()),
                    Text(
                      'Page ${pageIndex + 1}',
                      style: TextStyle(
                        fontSize: (13 * scale).clamp(11.0, 13.0),
                        fontFamily: 'SF-UI-Display',
                        color: _subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: _textColor.withOpacity(0.3),
                size: (24 * scale).roundToDouble(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(double scale) {
    final progress =
        widget.totalPages > 0 ? widget.currentPage / widget.totalPages : 0.0;
    final progressPercent = (progress * 100).toStringAsFixed(0);

    return Container(
      padding: EdgeInsets.fromLTRB(
        (20 * scale).roundToDouble(),
        (12 * scale).roundToDouble(),
        (20 * scale).roundToDouble(),
        (12 * scale).roundToDouble(),
      ),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: _dividerColor, width: 1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Page ${widget.currentPage} of ${widget.totalPages}',
                style: TextStyle(
                  fontSize: (13 * scale).clamp(11.0, 13.0),
                  fontFamily: 'SF-UI-Display',
                  fontWeight: FontWeight.w500,
                  color: _textColor,
                ),
              ),
              Text(
                '$progressPercent%',
                style: TextStyle(
                  fontSize: (13 * scale).clamp(11.0, 13.0),
                  fontFamily: 'SF-UI-Display',
                  fontWeight: FontWeight.w600,
                  color: _chapterBadgeColor,
                ),
              ),
            ],
          ),
          SizedBox(height: (8 * scale).roundToDouble()),
          ClipRRect(
            borderRadius: BorderRadius.circular((4 * scale).roundToDouble()),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: _dividerColor,
              valueColor: AlwaysStoppedAnimation<Color>(_chapterBadgeColor),
              minHeight: (6 * scale).roundToDouble(),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper class to store chapter info
class _ChapterInfo {
  final String title;
  final int pageIndex;

  _ChapterInfo({required this.title, required this.pageIndex});
}
