import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:biblio/core/models/book_model.dart';
import 'package:biblio/core/providers/book_provider.dart';
import 'package:biblio/core/providers/xp_provider.dart';
import 'package:biblio/core/services/highlights_service.dart';
import 'package:biblio/core/services/reading_preferences_service.dart';
import 'package:biblio/epub_viewer/controllers/epub_theme_controller.dart';
import 'package:biblio/epub_viewer/quote_dialog/save_quote_dialog.dart';
import 'package:biblio/epub_viewer/widgets/ai_definition_sheet.dart';
import 'package:biblio/pdf_viewer/controllers/pdf_session_controller.dart';
import 'package:biblio/epub_viewer/widgets/return_to_current_button.dart';
import 'package:biblio/pdf_viewer/presentation/widgets/pdf_bottom_sheet_new.dart';
import 'package:biblio/pdf_viewer/presentation/widgets/pdf_header.dart';
import 'package:biblio/pdf_viewer/presentation/widgets/pdf_text_selection_menu.dart';
import 'package:biblio/pdf_viewer/presentation/widgets/table_of_contents_sheet.dart';
import 'package:biblio/core/widgets/circle_to_search_overlay.dart';
import 'package:biblio/core/widgets/circle_search_result_sheet.dart';
import 'package:biblio/reading_session/controllers/reading_timer_controller.dart';
import 'package:biblio/reading_session/dialogs/session_summary_dialog.dart';
import 'package:biblio/reading_session/reading_session_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewerPage extends ConsumerStatefulWidget {
  final Book book;

  const PdfViewerPage({super.key, required this.book});

  @override
  ConsumerState<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends ConsumerState<PdfViewerPage>
    with WidgetsBindingObserver {
  // Controllers
  late final PdfViewerController _pdfViewerController;
  late final ReadingTimerController _timerController;
  late final PdfSessionController _sessionController;

  // GlobalKey for accessing SfPdfViewer state (getSelectedTextLines)
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();

  // For AI / Quote dialogs that need EpubThemeController
  late final EpubThemeController _themeController;

  // PDF State
  bool _fileExists = false;
  bool _isDarkMode = false;
  int _currentPage = 1;
  int _totalPages = 0;

  // Text selection state
  String? _selectedText;
  bool _showSelectionMenu = false;

  // Guard: suppress any pop triggered by Syncfusion during/after text deselection.
  // Syncfusion internally calls Navigator.pop() when clearing selection in
  // PdfInteractionMode.selection — this flag blocks that from ending the session.
  bool _suppressNextPop = false;
  Timer? _suppressPopTimer;

  // When true, canPop becomes true so programmatic Navigator.pop() from
  // _handleBackPress can actually close the page.
  bool _readyToExit = false;

  // Deferred PDF loading: show a lightweight placeholder until the route
  // transition finishes, then build SfPdfViewer. Prevents the 2-3s freeze.
  bool _pdfReady = false;

  // Tracks whether onDocumentLoaded has fired so we can fade in the content.
  bool _documentLoaded = false;

  // Return-to-current-page overlay
  OverlayEntry? _returnOverlay;

  // Track highlight annotations so we can recolor them on dark mode toggle
  final List<HighlightAnnotation> _highlightAnnotations = [];

  // Focus mode (landscape, header + bottom bar hidden, floating controls)
  bool _isFocusMode = false;
  bool _showFocusControls = false;

  // Circle-to-search
  final GlobalKey _readerBoundaryKey = GlobalKey();
  bool _isCircleSearchActive = false;

  // Preserved zoom level for focus mode — restored on every page change
  // so swiping pages doesn't reset the zoom the user set.
  double _focusModeZoom = 1.0;

  // Color inversion matrix for dark mode
  static const List<double> _invertMatrix = <double>[
    -1,
    0,
    0,
    0,
    255,
    0,
    -1,
    0,
    0,
    255,
    0,
    0,
    -1,
    0,
    255,
    0,
    0,
    0,
    1,
    0,
  ];

  // ──────────────────────────────────────────────
  // Lifecycle
  // ──────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    _pdfViewerController = PdfViewerController();
    // Track zoom changes for focus mode zoom-preservation
    _pdfViewerController.addListener(_onControllerChanged);
    _timerController = ReadingTimerController();
    _themeController = EpubThemeController();
    _sessionController = PdfSessionController(
      bookId: widget.book.id,
      bookTitle: widget.book.title,
      timerController: _timerController,
    );

    _checkFile();
    _loadSavedSettings();

    // Defer building the heavy SfPdfViewer until after the route
    // transition animation completes (~300ms). This keeps the
    // page push animation silky smooth.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final route = ModalRoute.of(context);
      if (route != null && route.animation != null) {
        void listener(AnimationStatus status) {
          if (status == AnimationStatus.completed) {
            route.animation!.removeStatusListener(listener);
            if (mounted) setState(() => _pdfReady = true);
          }
        }

        if (route.animation!.isCompleted) {
          // Already completed (e.g. instant push)
          if (mounted) setState(() => _pdfReady = true);
        } else {
          route.animation!.addStatusListener(listener);
        }
      } else {
        // Fallback if no route animation
        if (mounted) setState(() => _pdfReady = true);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    if (_fileExists) {
      _saveProgress();
    }

    _timerController.dispose();
    _sessionController.dispose();
    _pdfViewerController.removeListener(_onControllerChanged);
    _pdfViewerController.dispose();
    _removeReturnOverlay();
    _suppressPopTimer?.cancel();

    // Ensure we restore portrait if focus mode was active on dispose
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      // Only save on true background (not on text selection / inactive)
      _sessionController.saveSessionOnCrash(isDarkMode: _isDarkMode);
    } else if (state == AppLifecycleState.resumed) {
      // Make sure timer is running when app comes back
      if (!_timerController.isRunning) {
        _timerController.resumeTimer();
      }
    }
  }

  // ──────────────────────────────────────────────
  // Settings & Restore
  // ──────────────────────────────────────────────

  /// Called whenever the PdfViewerController notifies listeners (zoom, page, etc.)
  /// We use this to track the current zoom so focus mode can restore it on page changes.
  void _onControllerChanged() {
    if (_isFocusMode) {
      final z = _pdfViewerController.zoomLevel;
      if (z != _focusModeZoom) {
        _focusModeZoom = z;
      }
    }
  }

  void _checkFile() {
    final path = widget.book.filePath ?? '';
    if (path.isEmpty) {
      _fileExists = false;
      return;
    }
    _fileExists = File(path).existsSync();
    if (_fileExists) {
      _totalPages = widget.book.totalPages;
      _currentPage = (widget.book.currentPage + 1).clamp(
        1,
        _totalPages > 0 ? _totalPages : 1,
      );
    }
  }

  Future<void> _loadSavedSettings() async {
    try {
      final saved = await ReadingPreferencesService().loadBookSettings(
        widget.book.id,
      );

      if (saved != null && mounted) {
        final isDark = saved['is_dark_mode'] ?? false;
        final savedPage = saved['current_page'] as int?;
        final initialProgress = saved['progress_percent'] as double? ?? 0.0;

        setState(() {
          _isDarkMode = isDark;
          if (isDark) {
            _themeController.toggleDarkMode();
          }
        });

        _timerController.setInitialProgress(initialProgress);

        if (savedPage != null && savedPage > 0) {
          _sessionController.savedPage = savedPage;
        }
      }
    } catch (e) {
      debugPrint('⚠️ Failed to load PDF saved settings: $e');
    } finally {
      _sessionController.hasLoadedSettings = true;
      _timerController.startTimer();
    }
  }

  void _saveProgress() {
    try {
      final safePage = (_currentPage - 1).clamp(0, _totalPages);
      ref
          .read(bookServiceProvider)
          .updateReadingProgress(bookId: widget.book.id, currentPage: safePage);
      final updatedBook = widget.book.copyWith(currentPage: safePage);
      ref.read(currentlyReadingProvider.notifier).setBook(updatedBook);
    } catch (e) {
      debugPrint('Error saving reading progress: $e');
    }
  }

  // ──────────────────────────────────────────────
  // Page & UI Events
  // ──────────────────────────────────────────────

  void _onPageChanged(PdfPageChangedDetails details) {
    if (!mounted) return;

    setState(() {
      _currentPage = details.newPageNumber;
    });

    final progress = _totalPages > 0 ? (_currentPage / _totalPages * 100) : 0.0;

    _sessionController.lastTrackedPage = _currentPage;
    _timerController.updatePosition('pdf-page-$_currentPage', progress);
    _sessionController.queueAutoSave(
      currentPage: _currentPage,
      progress: progress,
      isDarkMode: _isDarkMode,
    );

    // Clear text selection on page change
    if (_showSelectionMenu) {
      _clearSelection();
    }

    // In focus mode, restore the zoom level the user had set.
    // Syncfusion resets zoom to 1.0 on each page change, so we
    // re-apply the last stored zoom one frame later.
    if (_isFocusMode && _focusModeZoom != 1.0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _isFocusMode) {
          _pdfViewerController.zoomLevel = _focusModeZoom;
        }
      });
    }

    debugPrint(
      '📄 Page changed: $_currentPage / $_totalPages (${progress.toStringAsFixed(1)}%)',
    );
  }

  void _onDocumentLoaded(PdfDocumentLoadedDetails details) {
    if (!mounted) return;

    setState(() {
      _totalPages = details.document.pages.count;
    });

    _sessionController.totalPages = _totalPages;

    debugPrint('📄 PDF loaded. Pages: $_totalPages');

    // Restore saved page position, then reveal the viewer.
    // Keep the "Opening book..." overlay until the jump is done
    // so the user never sees a flash of page 1.
    final needsJump =
        _sessionController.savedPage > 0 &&
        _sessionController.savedPage <= _totalPages;

    if (needsJump) {
      // Small delay so Syncfusion finishes its initial layout
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        _pdfViewerController.jumpToPage(_sessionController.savedPage);
        // Wait one more frame for the jump to render, then fade in
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) setState(() => _documentLoaded = true);
        });
      });
    } else {
      // No page restore needed — fade in immediately
      if (mounted) setState(() => _documentLoaded = true);
    }
  }

  void _onTextSelectionChanged(PdfTextSelectionChangedDetails? details) {
    if (details == null ||
        details.selectedText == null ||
        details.selectedText!.trim().isEmpty) {
      if (_showSelectionMenu) {
        _armSuppressPopTimer(); // block any Syncfusion-triggered pop
        setState(() {
          _showSelectionMenu = false;
          _selectedText = null;
        });
      }
      return;
    }

    setState(() {
      _selectedText = details.selectedText;
      _showSelectionMenu = true;
    });
  }

  /// Suppress any pop() call from Syncfusion for the next 600ms.
  void _armSuppressPopTimer() {
    _suppressNextPop = true;
    _suppressPopTimer?.cancel();
    _suppressPopTimer = Timer(const Duration(milliseconds: 600), () {
      _suppressNextPop = false;
    });
  }

  void _clearSelection() {
    _armSuppressPopTimer(); // block Syncfusion-triggered pop
    _pdfViewerController.clearSelection();
    setState(() {
      _showSelectionMenu = false;
      _selectedText = null;
    });
  }

  void _onDarkModeToggle() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    // Keep EpubThemeController in sync for dialogs
    if (_isDarkMode != _themeController.isDarkMode) {
      _themeController.toggleDarkMode();
    }
    // Recolor highlight annotations for visibility in current mode
    for (final annotation in _highlightAnnotations) {
      annotation.color = _isDarkMode ? Colors.orange : Colors.amber;
      annotation.opacity = _isDarkMode ? 0.5 : 0.65;
    }
    HapticFeedback.mediumImpact();
  }

  // ──────────────────────────────────────────────
  // Focus Mode
  // ──────────────────────────────────────────────

  void _toggleFocusMode() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isFocusMode = !_isFocusMode;
      _showFocusControls = false;
      if (!_isFocusMode) {
        // Reset stored zoom when leaving focus mode
        _focusModeZoom = 1.0;
        _pdfViewerController.zoomLevel = 1.0;
      }
    });

    if (_isFocusMode) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  void _toggleFocusControls() {
    HapticFeedback.lightImpact();
    setState(() {
      _showFocusControls = !_showFocusControls;
    });
  }

  // ──────────────────────────────────────────────
  // Text Selection Actions
  // ──────────────────────────────────────────────

  void _onHighlightTapped() async {
    if (_selectedText == null) return;

    // Grab text lines BEFORE clearing selection (needed for visual annotation)
    final textLines = _pdfViewerKey.currentState?.getSelectedTextLines() ?? [];

    final success = await HighlightsService().saveHighlight(
      bookId: widget.book.id,
      highlightedText: _selectedText!,
      cfiRange: 'pdf-page-$_currentPage',
      cfiStart: 'pdf-page-$_currentPage',
    );

    // Add visual highlight annotation
    if (textLines.isNotEmpty) {
      final annotation = HighlightAnnotation(textBoundsCollection: textLines);
      annotation.color = _isDarkMode ? Colors.orange : Colors.amber;
      annotation.opacity = _isDarkMode ? 0.5 : 0.65;
      _pdfViewerController.addAnnotation(annotation);
      _highlightAnnotations.add(annotation);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Highlight saved!' : 'Failed to save highlight',
          ),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          backgroundColor: success ? null : Colors.red,
        ),
      );
    }

    _clearSelection();
  }

  void _onNoteTapped() {
    if (_selectedText == null) return;

    final textToSave = _selectedText!;

    _clearSelection();
    _suppressNextPop = false;
    _suppressPopTimer?.cancel();

    // Push as a full route (same pattern as NotebookPage._openEditQuote)
    // so its internal Navigator.pop() only closes itself and not the PDF page.
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder:
            (_, __, ___) => SaveQuoteDialog(
              quoteText: textToSave,
              bookTitle: widget.book.title,
              authorName: widget.book.author,
              bookId: widget.book.id,
              bookCoverUrl: widget.book.coverUrl,
              themeController: _themeController,
              onSave: () {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Quote saved to notebook! ✨'),
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _onAiButtonTapped() {
    if (_selectedText == null) return;

    final text = _selectedText!;
    _clearSelection();

    // Reset the suppress flag so the bottom sheet can close normally.
    _suppressNextPop = false;
    _suppressPopTimer?.cancel();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => AiDefinitionSheet(
            selectedText: text,
            contextText: '',
            bookTitle: widget.book.title,
            themeController: _themeController,
          ),
    );
  }

  // ──────────────────────────────────────────────
  // Navigation Actions
  // ──────────────────────────────────────────────

  void _jumpToPage(int pageNumber) {
    final pageBeforeJump = _currentPage;
    _pdfViewerController.jumpToPage(pageNumber);

    // Show return button if we moved to a different page
    if ((pageBeforeJump - pageNumber).abs() > 1) {
      _showReturnOverlay(pageBeforeJump);
    }
  }

  void _showReturnOverlay(int returnPage) {
    _removeReturnOverlay();

    _returnOverlay = OverlayEntry(
      builder:
          (ctx) => Positioned(
            bottom: 130,
            left: 20,
            right: 20,
            child: ReturnToCurrentButton(
              currentPage: returnPage,
              onTap: () {
                _pdfViewerController.jumpToPage(returnPage);
                _removeReturnOverlay();
              },
              onDismiss: () {
                _removeReturnOverlay();
              },
            ),
          ),
    );

    Overlay.of(context).insert(_returnOverlay!);
  }

  void _removeReturnOverlay() {
    _returnOverlay?.remove();
    _returnOverlay = null;
  }

  void _openContents() {
    HapticFeedback.lightImpact();
    final filePath = widget.book.filePath;
    if (filePath == null) return;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Table of Contents',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return TableOfContentsSheet(
          filePath: filePath,
          currentPage: _currentPage,
          totalPages: _totalPages,
          isDarkMode: _isDarkMode,
          bookId: widget.book.id,
          onChapterTap: (pageNumber) {
            _jumpToPage(pageNumber);
          },
        );
      },
    );
  }

  void _onReadingTimeTap() {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        pageBuilder:
            (context, animation, secondaryAnimation) => ReadingSessionPage(
              book: widget.book,
              timerController: _timerController,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fade = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(fade);

          return FadeTransition(
            opacity: fade,
            child: SlideTransition(position: slide, child: child),
          );
        },
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Back Press & Session End
  // ──────────────────────────────────────────────

  Future<bool> _handleBackPress() async {
    // If in focus mode, exit focus mode first instead of closing page
    if (_isFocusMode) {
      _toggleFocusMode();
      return false;
    }
    debugPrint('🔵 PDF BACK PRESSED');
    _timerController.pauseTimer();

    final sessionData = _timerController.getSessionData();
    debugPrint('   Duration: ${sessionData.duration} seconds');

    if (sessionData.duration <= 30) {
      debugPrint('❌ Session too short (${sessionData.duration}s), not saving');
      _timerController.endSession();

      // Directly set ready to exit and pop
      if (mounted) {
        setState(() => _readyToExit = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.of(context).pop();
        });
      }

      await Future.delayed(const Duration(milliseconds: 200));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session too short to save.'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      return false;
    }

    debugPrint('✅ Session long enough, showing mood dialog');

    if (mounted) {
      debugPrint('   Opening SessionSummaryDialog...');
      final container = ProviderScope.containerOf(context, listen: false);
      final mood = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder:
            (_) => SessionSummaryDialog(
              duration: sessionData.formattedDurationShort,
              progressGained: sessionData.progressGained,
            ),
      );

      debugPrint('   Mood selected: $mood');

      if (mood != null) {
        debugPrint('   Saving session in background...');

        // Brief loading animation for user feedback
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder:
                (_) => const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFB85C38),
                    ),
                  ),
                ),
          );
        }

        unawaited(
          _sessionController
              .saveSession(mood: mood, isDarkMode: _isDarkMode)
              .then((_) {
                container.invalidate(currentStreakProvider);
                container.invalidate(todayReadingSecondsProvider);
                container.invalidate(currentWeekReadDaysProvider);
                container.invalidate(userProfileProvider);
              })
              .catchError((e) {
                debugPrint('❌ Background save failed: $e');
              }),
        );

        await Future.delayed(const Duration(milliseconds: 250));

        debugPrint('   Closing page while save continues');

        // Close loading dialog first
        if (mounted) Navigator.of(context).pop();

        // Now set ready to exit and pop the PDF page on the next frame
        if (mounted) {
          setState(() => _readyToExit = true);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.of(context).pop();
          });
        }
      } else {
        debugPrint('❌ Mood was null, resuming timer');
        _timerController.resumeTimer();
      }
    }

    return false;
  }

  // ──────────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);

    final filePath = widget.book.filePath ?? '';
    if (filePath.isEmpty || !_fileExists) {
      return const Scaffold(body: Center(child: Text('File not found')));
    }

    return PopScope(
      canPop: _readyToExit,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          // Ignore pops triggered by Syncfusion during text selection/deselection
          if (_suppressNextPop) {
            _suppressNextPop = false;
            return;
          }
          await _handleBackPress();
        }
      },
      child: Scaffold(
        backgroundColor: _isDarkMode ? Colors.black : Colors.white,
        body:
            _isFocusMode
                ? _buildFocusModeBody(filePath, scale)
                : _buildNormalBody(filePath, scale),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Normal Mode Layout
  // ──────────────────────────────────────────────

  Widget _buildNormalBody(String filePath, double scale) {
    return Column(
      children: [
        // Header
        PdfHeader(
          bookTitle: widget.book.title,
          bookAuthor: widget.book.author,
          onBackPressed: () async => await _handleBackPress(),
          onFocusModeTap: _toggleFocusMode,
          isDarkMode: _isDarkMode,
        ),

        // PDF Content
        Expanded(
          child: RepaintBoundary(
            key: _readerBoundaryKey,
            child: Stack(
              children: [
                if (_pdfReady) ...[
                  // PDF Viewer with optional color inversion
                  AnimatedOpacity(
                    opacity: _documentLoaded ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                    child: ColorFiltered(
                      colorFilter:
                          _isDarkMode
                              ? const ColorFilter.matrix(_invertMatrix)
                              : const ColorFilter.mode(
                                Colors.transparent,
                                BlendMode.dst,
                              ),
                      child: SfPdfViewer.file(
                        File(filePath),
                        key: _pdfViewerKey,
                        controller: _pdfViewerController,
                        pageLayoutMode: PdfPageLayoutMode.single,
                        scrollDirection: PdfScrollDirection.horizontal,
                        canShowScrollHead: false,
                        canShowScrollStatus: false,
                        enableDoubleTapZooming: true,
                        enableTextSelection: true,
                        canShowTextSelectionMenu: false,
                        interactionMode: PdfInteractionMode.selection,
                        pageSpacing: 0,
                        onPageChanged: _onPageChanged,
                        onDocumentLoaded: _onDocumentLoaded,
                        onTextSelectionChanged: _onTextSelectionChanged,
                      ),
                    ),
                  ),
                ],

                // Smooth loading placeholder while PDF parses
                if (!_documentLoaded)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: (28 * scale).roundToDouble(),
                          height: (28 * scale).roundToDouble(),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _isDarkMode
                                  ? Colors.white54
                                  : const Color(0xFFB85C38),
                            ),
                          ),
                        ),
                        SizedBox(height: (12 * scale).roundToDouble()),
                        Text(
                          'Opening book...',
                          style: TextStyle(
                            fontFamily: 'SF-UI-Display',
                            fontSize: (13 * scale).clamp(11.0, 13.0),
                            color:
                                _isDarkMode
                                    ? Colors.white38
                                    : Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Text selection action menu
                if (_showSelectionMenu)
                  PdfTextSelectionMenu(
                    isDarkMode: _isDarkMode,
                    onHighlight: _onHighlightTapped,
                    onAi: _onAiButtonTapped,
                    onNote: _onNoteTapped,
                    onClose: _clearSelection,
                  ),

                // Circle-to-search overlay
                if (_isCircleSearchActive)
                  Positioned.fill(
                    child: CircleToSearchOverlay(
                      readerBoundaryKey: _readerBoundaryKey,
                      isDarkMode: _isDarkMode,
                      onCaptured: _onCircleSearchCaptured,
                      onDismiss: _dismissCircleSearch,
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Bottom Panel
        PdfBottomSheet(
          timerController: _timerController,
          isDarkMode: _isDarkMode,
          onOpenContents: _openContents,
          onReadingTimeTap: _onReadingTimeTap,
          onDarkModeToggle: _onDarkModeToggle,
          onCircleSearch: _activateCircleSearch,
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────
  // Circle-to-Search
  // ──────────────────────────────────────────────

  void _activateCircleSearch() {
    HapticFeedback.lightImpact();
    if (_showSelectionMenu) _clearSelection();
    setState(() => _isCircleSearchActive = true);
  }

  void _dismissCircleSearch() {
    setState(() => _isCircleSearchActive = false);
  }

  void _onCircleSearchCaptured(Uint8List imageBytes, Rect cropRect) {
    setState(() => _isCircleSearchActive = false);

    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => CircleSearchResultSheet(
            imageBytes: imageBytes,
            bookTitle: widget.book.title,
            isDarkMode: _isDarkMode,
          ),
    );
  }

  // ──────────────────────────────────────────────
  // Focus Mode Layout
  // ──────────────────────────────────────────────

  Widget _buildFocusModeBody(String filePath, double scale) {
    return Stack(
      children: [
        // Full-screen PDF Viewer
        Positioned.fill(
          child: ColorFiltered(
            colorFilter:
                _isDarkMode
                    ? const ColorFilter.matrix(_invertMatrix)
                    : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
            child: SfPdfViewer.file(
              File(filePath),
              key: _pdfViewerKey,
              controller: _pdfViewerController,
              pageLayoutMode: PdfPageLayoutMode.single,
              scrollDirection: PdfScrollDirection.horizontal,
              canShowScrollHead: false,
              canShowScrollStatus: false,
              enableDoubleTapZooming: true,
              enableTextSelection: true,
              canShowTextSelectionMenu: false,
              interactionMode: PdfInteractionMode.selection,
              pageSpacing: 0,
              maxZoomLevel: 8.0,
              onPageChanged: _onPageChanged,
              onDocumentLoaded: _onDocumentLoaded,
              onTextSelectionChanged: _onTextSelectionChanged,
            ),
          ),
        ),

        // Text selection action menu
        if (_showSelectionMenu)
          PdfTextSelectionMenu(
            isDarkMode: _isDarkMode,
            onHighlight: _onHighlightTapped,
            onAi: _onAiButtonTapped,
            onNote: _onNoteTapped,
            onClose: _clearSelection,
          ),

        // Floating controls
        _buildFocusModeControls(scale),
      ],
    );
  }

  Widget _buildFocusModeControls(double scale) {
    final bottomPadding =
        MediaQuery.of(context).padding.bottom + (16 * scale).roundToDouble();
    final rightPadding =
        MediaQuery.of(context).padding.right + (16 * scale).roundToDouble();

    return Positioned(
      bottom: bottomPadding,
      right: rightPadding,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.15, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        },
        child:
            _showFocusControls
                ? _buildExpandedFocusBar(scale)
                : _buildFocusFab(scale),
      ),
    );
  }

  Widget _buildFocusFab(double scale) {
    final bgColor =
        _isDarkMode
            ? Colors.white.withOpacity(0.15)
            : Colors.black.withOpacity(0.08);
    final iconColor = _isDarkMode ? Colors.white : Colors.black87;

    return GestureDetector(
      key: const ValueKey('focus_fab'),
      onTap: _toggleFocusControls,
      child: Container(
        width: (48 * scale).roundToDouble(),
        height: (48 * scale).roundToDouble(),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular((24 * scale).roundToDouble()),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.more_horiz_rounded,
          color: iconColor,
          size: (24 * scale).roundToDouble(),
        ),
      ),
    );
  }

  Widget _buildExpandedFocusBar(double scale) {
    final bgColor =
        _isDarkMode
            ? const Color(0xFF1C1C1E).withOpacity(0.95)
            : Colors.white.withOpacity(0.95);
    final iconColor = _isDarkMode ? Colors.white : Colors.black87;
    final activeColor = const Color(0xFF4A9FFF);
    final dividerColor =
        _isDarkMode
            ? Colors.white.withOpacity(0.12)
            : Colors.black.withOpacity(0.08);

    return Container(
      key: const ValueKey('focus_bar'),
      padding: EdgeInsets.symmetric(
        horizontal: (8 * scale).roundToDouble(),
        vertical: (6 * scale).roundToDouble(),
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular((28 * scale).roundToDouble()),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // TOC / Journal
          _focusBarButton(
            icon: Icons.format_list_bulleted_rounded,
            color: iconColor,
            onTap: () {
              _toggleFocusControls();
              _openContents();
            },
            tooltip: 'Contents',
            scale: scale,
          ),
          _focusBarDivider(dividerColor, scale),

          // Timer
          ListenableBuilder(
            listenable: _timerController,
            builder: (context, _) {
              return _focusBarButton(
                icon: Icons.access_time_rounded,
                color: iconColor,
                label: _timerController.bottomSheetDisplay,
                onTap: () {
                  _toggleFocusControls();
                  _onReadingTimeTap();
                },
                tooltip: 'Timer',
                scale: scale,
              );
            },
          ),
          _focusBarDivider(dividerColor, scale),

          // Dark mode
          _focusBarButton(
            icon:
                _isDarkMode
                    ? Icons.wb_sunny_rounded
                    : Icons.brightness_2_rounded,
            color: _isDarkMode ? activeColor : iconColor,
            onTap: () {
              _onDarkModeToggle();
            },
            tooltip: 'Dark Mode',
            scale: scale,
          ),
          _focusBarDivider(dividerColor, scale),

          // Exit focus mode
          _focusBarButton(
            icon: Icons.fullscreen_exit_rounded,
            color: iconColor,
            onTap: _toggleFocusMode,
            tooltip: 'Exit Focus',
            scale: scale,
          ),
          _focusBarDivider(dividerColor, scale),

          // Collapse bar
          _focusBarButton(
            icon: Icons.close_rounded,
            color: iconColor.withOpacity(0.5),
            onTap: _toggleFocusControls,
            tooltip: 'Close',
            scale: scale,
          ),
        ],
      ),
    );
  }

  Widget _focusBarButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? label,
    String? tooltip,
    required double scale,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: (6 * scale).roundToDouble(),
          vertical: (4 * scale).roundToDouble(),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: (22 * scale).roundToDouble()),
            if (label != null) ...[
              SizedBox(width: (4 * scale).roundToDouble()),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: (13 * scale).clamp(11.0, 13.0),
                  fontWeight: FontWeight.w600,
                  fontFamily: 'SF-UI-Display',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _focusBarDivider(Color color, double scale) {
    return Container(
      width: 1,
      height: (20 * scale).roundToDouble(),
      margin: EdgeInsets.symmetric(horizontal: (2 * scale).roundToDouble()),
      color: color,
    );
  }
}
