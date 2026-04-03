// Main EPUB viewer page orchestrating reading experience, state management,
// and user interactions with the book content.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:biblio/core/models/book_model.dart';
import 'package:biblio/core/services/reading_preferences_service.dart';
import 'package:biblio/epub_viewer/controllers/epub_font_controller.dart';
import 'package:biblio/epub_viewer/controllers/epub_highlight_controller.dart';
import 'package:biblio/epub_viewer/controllers/epub_navigation_controller.dart';
import 'package:biblio/epub_viewer/controllers/epub_session_controller.dart';
import 'package:biblio/epub_viewer/controllers/epub_theme_controller.dart';
import 'package:biblio/epub_viewer/quote_dialog/save_quote_dialog.dart';
import 'package:biblio/epub_viewer/utils/epub_css_builder.dart';
import 'package:biblio/epub_viewer/widgets/ai_definition_sheet.dart';
import 'package:biblio/epub_viewer/widgets/epub_bottom_sheet.dart';
import 'package:biblio/epub_viewer/widgets/epub_font_settings_sheet.dart';
import 'package:biblio/epub_viewer/widgets/epub_table_of_contents_sheet.dart';
import 'package:biblio/epub_viewer/widgets/epub_viewer_header.dart';
import 'package:biblio/epub_viewer/widgets/epub_viewer_reader.dart';
import 'package:biblio/epub_viewer/widgets/text_selection_menu.dart';
import 'package:biblio/reading_session/dialogs/session_summary_dialog.dart';
import 'package:biblio/reading_session/reading_session_page.dart';
import 'package:biblio/reading_session/controllers/reading_timer_controller.dart';
import 'package:biblio/core/providers/xp_provider.dart';
import 'package:biblio/core/widgets/circle_to_search_overlay.dart';
import 'package:biblio/core/widgets/circle_search_result_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EpubViewerPage extends StatefulWidget {
  final Book book;

  const EpubViewerPage({super.key, required this.book});

  @override
  State<EpubViewerPage> createState() => _EpubViewerPageState();
}

class _EpubViewerPageState extends State<EpubViewerPage>
    with WidgetsBindingObserver {
  // Core controllers
  late final EpubController _epubController;
  late final EpubThemeController _themeController;
  late final ReadingTimerController _timerController;

  // Extracted controllers
  late final EpubFontController _fontController;
  late final EpubHighlightController _highlightController;
  late final EpubNavigationController _navigationController;
  late final EpubSessionController _sessionController;

  // Epub state
  String _currentChapter = 'Chapter 1';
  double _currentProgress = 0.0;
  bool _isReady = false;
  List<EpubChapter> _chapters = [];
  String _lastFontFamily = 'Bookerly';

  // Loading flow: start with loader visible to prevent flash of page 1
  bool _isLoaderVisible = true;

  // Text selection state
  String? _selectedAiText;
  String? _selectedAiContext;
  String? _selectedCfi;
  bool _showAiButton = false;

  // Polling
  Timer? _locationPollTimer;

  // Circle-to-search
  final GlobalKey _readerBoundaryKey = GlobalKey();
  bool _isCircleSearchActive = false;

  // Full-screen mode
  bool _isFullScreen = false;
  bool _showFocusControls = false;

  static const double _headerHeight = 130.0;
  static final EpubTheme _darkEpubTheme = EpubTheme.custom(
    backgroundDecoration: const BoxDecoration(color: Colors.black),
    foregroundColor: Colors.white,
  );

  static final EpubTheme _lightEpubTheme = EpubTheme.light();

  EpubTheme get _currentEpubTheme =>
      _themeController.isDarkMode ? _darkEpubTheme : _lightEpubTheme;

  // ──────────────────────────────────────────────
  // Lifecycle
  // ──────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _timerController = ReadingTimerController();
    _epubController = EpubController();
    _themeController = EpubThemeController();

    _fontController = EpubFontController();
    _highlightController = EpubHighlightController();
    _navigationController = EpubNavigationController();
    _sessionController = EpubSessionController(
      bookId: widget.book.id,
      bookTitle: widget.book.title,
      timerController: _timerController,
    );

    _themeController.addListener(_onThemeChanged);
    _lastFontFamily = _themeController.fontFamily;

    _loadInitialFont();
    _loadSavedSettings();
  }

  @override
  void dispose() {
    _sessionController.dispose();
    _locationPollTimer?.cancel();
    _navigationController.dispose();
    _highlightController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _timerController.dispose();
    _themeController.removeListener(_onThemeChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _sessionController.saveSessionOnCrash(
        themeSettings: _currentThemeSettings,
      );
    }
  }

  // ──────────────────────────────────────────────
  // Settings & Font Loading
  // ──────────────────────────────────────────────

  Map<String, dynamic> get _currentThemeSettings => {
    'font_family': _themeController.fontFamily,
    'font_size': _themeController.fontSize,
    'line_height': _themeController.lineHeight,
    'letter_spacing': _themeController.letterSpacing,
    'text_align': _textAlignToString(_themeController.textAlign),
    'is_dark_mode': _themeController.isDarkMode,
  };

  Future<void> _loadSavedSettings() async {
    try {
      final saved = await ReadingPreferencesService().loadBookSettings(
        widget.book.id,
      );

      if (saved != null && mounted) {
        _themeController.setFontFamily(saved['font_family'] ?? 'Bookerly');
        _themeController.setFontSize((saved['font_size'] ?? 16).toDouble());
        _themeController.setLineHeight(
          (saved['line_height'] ?? 1.5).toDouble(),
        );
        _themeController.setLetterSpacing(
          (saved['letter_spacing'] ?? 0.0).toDouble(),
        );

        final textAlignStr = saved['text_align'] ?? 'left';
        TextAlign textAlign;
        switch (textAlignStr) {
          case 'right':
            textAlign = TextAlign.right;
          case 'center':
            textAlign = TextAlign.center;
          case 'justify':
            textAlign = TextAlign.justify;
          default:
            textAlign = TextAlign.left;
        }
        _themeController.setTextAlign(textAlign);

        final isDark = saved['is_dark_mode'] ?? false;
        if (isDark != _themeController.isDarkMode) {
          _themeController.toggleDarkMode();
        }

        _sessionController.savedCfi = saved['current_cfi'] as String?;

        final initialProgress = saved['progress_percent'] as double? ?? 0.0;
        _timerController.setInitialProgress(initialProgress);
      }
    } catch (e) {
      debugPrint('⚠️ Failed to load saved settings: $e');
    } finally {
      _sessionController.hasLoadedSettings = true;
      _timerController.startTimer();

      // Don't wait for position restore - let it happen asynchronously
      if (_isReady) {
        _tryRestorePosition();
      }
    }
  }

  Future<void> _loadInitialFont() async {
    await _fontController.loadFont(_themeController.fontFamily);
    _applyEpubThemeIfReady();
  }

  void _applyEpubThemeIfReady() {
    if (!_isReady || !_sessionController.hasLoadedSettings) return;
    _epubController.updateTheme(theme: _currentEpubTheme);
    _epubController.setCustomCss(
      EpubCssBuilder.buildReaderCss(
        theme: _themeController,
        selectedFont: _themeController.fontFamily,
        fontBase64: _fontController.getFontBase64(_themeController.fontFamily),
      ),
    );
  }

  void _onThemeChanged() async {
    if (mounted) {
      if (_themeController.fontFamily != _lastFontFamily) {
        _lastFontFamily = _themeController.fontFamily;
        await _fontController.loadFont(_lastFontFamily);
      }

      setState(() {});
      SystemChrome.setSystemUIOverlayStyle(
        _themeController.isDarkMode
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      );
      _applyEpubThemeIfReady();
    }
  }

  // ──────────────────────────────────────────────
  // Position Restore & Polling - FIXED
  // ──────────────────────────────────────────────

  void _tryRestorePosition() {
    if (!_isReady || !_sessionController.hasLoadedSettings) return;
    if (_sessionController.hasJumpedToSavedPosition) return;

    _sessionController.hasJumpedToSavedPosition = true;

    // If no saved position, dismiss loader and start polling
    if (_sessionController.savedCfi == null ||
        _sessionController.savedCfi!.isEmpty) {
      debugPrint('📖 No saved position - showing content immediately');
      _dismissLoader();
      _startLocationPolling();
      return;
    }

    // Safety timeout: force dismiss loader after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      if (_isLoaderVisible) {
        debugPrint('⚠️ Safety timeout: force dismissing loader');
        _dismissLoader();
        _startLocationPolling();
      }
    });

    // Short delay to ensure EPUB rendition is fully initialized
    Future.delayed(const Duration(milliseconds: 800), () async {
      if (!mounted) return;

      final cfi = _sessionController.savedCfi!;
      debugPrint('🎯 Restoring position to: $cfi');

      try {
        // Sanitize CFI for JavaScript
        final escapedCfi = cfi
            .replaceAll('\\', '\\\\')
            .replaceAll("'", "\\'")
            .replaceAll('"', '\\"');

        // Use snapToHighlight for precise position restore
        final result = await _epubController.webViewController
            ?.evaluateJavascript(
              source: "window.snapToHighlight('$escapedCfi');",
            );

        if (result == true || result == 'true') {
          debugPrint('✅ Position restored via snapToHighlight');
        } else {
          debugPrint('⚠️ Snap failed, using fallback display()');
          _epubController.display(cfi: cfi);
        }
      } catch (e) {
        debugPrint('⚠️ Failed to restore position: $e');
        // Fallback to regular display
        _epubController.display(cfi: cfi);
      }

      // Wait for the page to render at the correct position
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        _dismissLoader();
        _startLocationPolling();
        debugPrint('📖 Position restore complete - showing content');
      });
    });
  }

  /// Smoothly dismiss the loading overlay with a fade.
  void _dismissLoader() {
    if (!mounted || !_isLoaderVisible) return;
    setState(() => _isLoaderVisible = false);
  }

  void _startLocationPolling() {
    _locationPollTimer?.cancel();

    debugPrint('🔄 Starting location polling...');

    _locationPollTimer = Timer.periodic(const Duration(seconds: 1), (
      timer,
    ) async {
      if (!mounted || !_isReady) {
        timer.cancel();
        return;
      }

      try {
        final raw = await _epubController.webViewController?.evaluateJavascript(
          source: 'rendition.currentLocation()',
        );

        if (raw == null) return;

        final Map<String, dynamic>? result =
            raw is String
                ? jsonDecode(raw) as Map<String, dynamic>?
                : (raw is Map ? raw.cast<String, dynamic>() : null);

        if (result == null) return;

        final start = result['start'] as Map<String, dynamic>?;
        final startCfi = start?['cfi'] as String?;
        final progressPercent = ((start?['percentage'] as num?) ?? 0.0) * 100;

        if (startCfi != null && startCfi != _sessionController.lastTrackedCfi) {
          _sessionController.lastTrackedCfi = startCfi;

          _timerController.updatePosition(startCfi, progressPercent.toDouble());
          _sessionController.queueAutoSave(
            cfi: startCfi,
            progress: progressPercent.toDouble(),
            themeSettings: _currentThemeSettings,
          );

          debugPrint(
            '🔄 Polled - CFI: $startCfi, Progress: ${progressPercent.toStringAsFixed(2)}%',
          );
        }
      } catch (e) {
        debugPrint('⚠️ Polling error: $e');
      }
    });
  }

  // ──────────────────────────────────────────────
  // Chapter Detection
  // ──────────────────────────────────────────────

  Future<void> _updateCurrentChapter(EpubLocation location) async {
    if (_chapters.isEmpty) return;

    try {
      final result = await _epubController.webViewController
          ?.evaluateJavascript(
            source: '''
          (function() {
            try {
              var loc = rendition.currentLocation();
              if (loc && loc.start) {
                return JSON.stringify({
                  href: loc.start.href || '',
                  index: loc.start.index || 0
                });
              }
            } catch(e) {
              console.log('Chapter detection error:', e);
            }
            return null;
          })();
        ''',
          );

      String? matchedTitle;

      if (result != null && result != 'null' && result.isNotEmpty) {
        try {
          final data = jsonDecode(result);
          final href = data['href'] as String?;
          final index = data['index'] as int?;

          if (href != null && href.isNotEmpty) {
            for (final chapter in _chapters) {
              if (chapter.href.contains(href) || href.contains(chapter.href)) {
                matchedTitle = chapter.title;
                break;
              }
              final chapterFileName =
                  chapter.href.split('/').last.split('#').first;
              final currentFileName = href.split('/').last.split('#').first;
              if (chapterFileName == currentFileName) {
                matchedTitle = chapter.title;
                break;
              }
            }
          }

          if (matchedTitle == null &&
              index != null &&
              index >= 0 &&
              index < _chapters.length) {
            matchedTitle = _chapters[index].title;
          }
        } catch (e) {
          debugPrint('⚠️ JSON parse error for chapter: $e');
        }
      }

      if (matchedTitle == null) {
        final progress = location.progress;
        final chapterIndex = (progress * _chapters.length).floor().clamp(
          0,
          _chapters.length - 1,
        );
        matchedTitle = _chapters[chapterIndex].title;
      }

      if (matchedTitle != _currentChapter && mounted) {
        setState(() => _currentChapter = matchedTitle!);
        debugPrint('📖 Current chapter updated: $_currentChapter');
      }
    } catch (e) {
      debugPrint('⚠️ Chapter detection error: $e');
    }
  }

  // ──────────────────────────────────────────────
  // Text Selection
  // ──────────────────────────────────────────────

  void _clearSelection() {
    _epubController.webViewController?.evaluateJavascript(
      source: r'''
      try {
          if (typeof rendition !== 'undefined') {
              var contents = rendition.getContents();
              for (var i = 0; i < contents.length; i++) {
                  var win = contents[i].window;
                  if (win && win.getSelection) {
                      win.getSelection().removeAllRanges();
                  }
              }
          }
      } catch (e) { console.log(e); }
    ''',
    );

    if (_showAiButton) {
      setState(() {
        _showAiButton = false;
        _selectedAiText = null;
        _selectedAiContext = null;
        _selectedCfi = null;
      });
    }
  }

  void _onAiButtonTapped() {
    if (_selectedAiText == null) return;

    final text = _selectedAiText!;
    final contextTxt = _selectedAiContext ?? '';

    _clearSelection();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => AiDefinitionSheet(
            selectedText: text,
            contextText: contextTxt,
            bookTitle: widget.book.title,
            themeController: _themeController,
          ),
    );
  }

  void _onHighlightTapped() async {
    if (_selectedCfi == null || _selectedAiText == null) return;

    final success = await _highlightController.saveHighlight(
      bookId: widget.book.id,
      highlightedText: _selectedAiText!,
      cfiRange: _selectedCfi!,
      epubController: _epubController,
    );

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
    if (_selectedAiText == null) return;

    final textToSave = _selectedAiText!;

    _clearSelection();

    showDialog(
      context: context,
      builder:
          (context) => SaveQuoteDialog(
            quoteText: textToSave,
            bookTitle: widget.book.title,
            authorName: widget.book.author,
            bookId: widget.book.id,
            bookCoverUrl: widget.book.coverUrl,
            themeController: _themeController,
            onSave: () {
              // Journal data will reload automatically
              // Quote is already saved by the dialog itself
            },
          ),
    );
  }

  // ──────────────────────────────────────────────
  // Navigation Actions
  // ──────────────────────────────────────────────

  Future<void> _refreshView() async {
    HapticFeedback.lightImpact();

    // Save current position as the restore target
    final cfi = _sessionController.lastTrackedCfi;
    _sessionController.savedCfi = cfi;

    // Show loader and reset ready state so the epub load flow runs fresh
    setState(() {
      _isLoaderVisible = true;
      _isReady = false;
    });
    _sessionController.hasJumpedToSavedPosition = false;
    _sessionController.hasRestoredHighlights = false;

    // Reload the webview — onEpubLoaded will fire and handle position restore
    await _epubController.webViewController?.reload();
  }

  void _onFontSettings() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EpubFontSettingsSheet(themeController: _themeController),
    );
  }

  void _openContents() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'toc',
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (dialogContext, _, __) {
        return EpubTableOfContentsSheet(
          chapters: _chapters,
          onChapterTap: (chapter) => _epubController.display(cfi: chapter.href),
          themeController: _themeController,
          currentChapterTitle: _currentChapter,
          readingProgress: _currentProgress,
          bookId: widget.book.id,
          bookTitle: widget.book.title,
          onNavigateToProgress: (progress) {
            _navigationController.navigateToProgress(
              targetProgress: progress,
              currentProgress: _currentProgress,
              lastTrackedCfi: _sessionController.lastTrackedCfi,
              epubController: _epubController,
              context: context, // Use main context, not dialogContext
            );
          },
          onNavigateToCfi: (cfi) {
            _navigationController.navigateToCfi(
              cfi: cfi,
              lastTrackedCfi: _sessionController.lastTrackedCfi,
              currentProgress: _currentProgress,
              epubController: _epubController,
              context: context, // Use main context, not dialogContext
            );
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
    debugPrint('🔵 BACK PRESSED');
    _timerController.pauseTimer();

    final sessionData = _timerController.getSessionData();
    debugPrint('   Duration: ${sessionData.duration} seconds');

    if (sessionData.duration <= 30) {
      debugPrint('❌ Session too short (${sessionData.duration}s), not saving');
      _timerController.endSession();

      if (mounted) Navigator.pop(context);

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

    // ❌ DON'T POP YET - Keep page alive for dialogs
    // if (mounted) Navigator.pop(context);

    // await Future.delayed(const Duration(milliseconds: 300));

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

        // Show brief loading animation for user feedback
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
              .saveSession(mood: mood, themeSettings: _currentThemeSettings)
              .then((_) {
                container.invalidate(currentStreakProvider);
                container.invalidate(todayReadingSecondsProvider);
                container.invalidate(currentWeekReadDaysProvider);
                container.invalidate(userProfileProvider);
              })
              .catchError((e) {
                debugPrint('❌ Session save failed: $e');
              }),
        );

        await Future.delayed(const Duration(milliseconds: 250));

        debugPrint('   Closing page while save continues');
        if (mounted) Navigator.pop(context); // Close loading dialog
        if (mounted) Navigator.pop(context); // Close EPUB page
      } else {
        debugPrint('❌ Mood was null, resuming timer');
        _timerController.resumeTimer();
      }
    }

    return false;
  }

  // ──────────────────────────────────────────────
  // Custom CSS & JavaScript Injection
  // ──────────────────────────────────────────────

  Future<void> _injectCustomStyles() async {
    if (!_isReady) return;

    try {
      // ✅ FIXED: Use buildReaderCss with correct parameters
      final css = EpubCssBuilder.buildReaderCss(
        theme: _themeController,
        selectedFont: _themeController.fontFamily,
        fontBase64: _fontController.getFontBase64(_themeController.fontFamily),
      );

      final escapedCss = css
          .replaceAll('\\', '\\\\')
          .replaceAll("'", "\\'")
          .replaceAll('\n', ' ');

      await _epubController.webViewController?.evaluateJavascript(
        source: '''
        (function() {
          const styleId = 'custom-reader-styles';
          let style = document.getElementById(styleId);
          if (!style) {
            style = document.createElement('style');
            style.id = styleId;
            document.head.appendChild(style);
          }
          style.textContent = '$escapedCss';
        })();
      ''',
      );

      // ✅ Inject snapToHighlight function
      await _injectSnapToHighlightFunction();

      debugPrint('✅ Custom styles and navigation functions injected');
    } catch (e) {
      debugPrint('❌ Failed to inject styles: $e');
    }
  }

  // ✅ Inject the snapToHighlight JavaScript function
  Future<void> _injectSnapToHighlightFunction() async {
    try {
      await _epubController.webViewController?.evaluateJavascript(
        source: '''
        (function() {
          // Create global snapToHighlight function
          window.snapToHighlight = async function(cfi) {
            try {
              console.log('📍 snapToHighlight called with CFI:', cfi);
              
              // Step 1: Navigate to the chapter containing the CFI
              await rendition.display(cfi);
              
              // Step 2: Wait for chapter to load and render (300ms)
              await new Promise(resolve => setTimeout(resolve, 300));
              
              // Step 3: Get the DOM range for this CFI
              const range = rendition.getRange(cfi);
              
              if (!range) {
                console.warn('⚠️ Could not get range for CFI:', cfi);
                return false;
              }
              
              // Step 4: Get the bounding rectangle of the highlighted text
              const rect = range.getBoundingClientRect();
              
              // Step 5: Calculate scroll position (150px from top for better visibility)
              const offsetY = rect.top + window.pageYOffset - 150;
              
              // Step 6: Smooth scroll to position
              window.scrollTo({
                top: Math.max(0, offsetY),
                behavior: 'smooth'
              });
              
              console.log('✅ Snapped to highlight at Y:', offsetY);
              return true;
              
            } catch (error) {
              console.error('❌ snapToHighlight error:', error);
              return false;
            }
          };
          
          console.log('✅ snapToHighlight function registered');
        })();
      ''',
      );

      debugPrint('✅ snapToHighlight function injected into WebView');
    } catch (e) {
      debugPrint('❌ Failed to inject snapToHighlight function: $e');
    }
  }

  // ──────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────

  String _textAlignToString(TextAlign align) {
    switch (align) {
      case TextAlign.right:
        return 'right';
      case TextAlign.center:
        return 'center';
      case TextAlign.justify:
        return 'justify';
      default:
        return 'left';
    }
  }

  // ──────────────────────────────────────────────
  // Circle-to-Search
  // ──────────────────────────────────────────────

  void _activateCircleSearch() {
    HapticFeedback.lightImpact();
    // Clear any existing text selection first
    if (_showAiButton) _clearSelection();
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
            isDarkMode: _themeController.isDarkMode,
          ),
    );
  }

  // ──────────────────────────────────────────────
  // Full-screen toggle & Focus Controls
  // ──────────────────────────────────────────────

  void _toggleFocusControls() {
    HapticFeedback.mediumImpact();
    setState(() => _showFocusControls = !_showFocusControls);
  }

  void _toggleFullScreen() {
    HapticFeedback.lightImpact();
    setState(() {
      _showFocusControls = false;
      _isFullScreen = !_isFullScreen;
    });
  }

  Widget _buildFocusModeControls(double scale) {
    if (!_isFullScreen) return const SizedBox.shrink();

    return Positioned(
      bottom: (16 * scale).roundToDouble(),
      right: (16 * scale).roundToDouble(),
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
    final isDarkMode = _themeController.isDarkMode;
    final bgColor =
        isDarkMode
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.black.withValues(alpha: 0.08);
    final iconColor = isDarkMode ? Colors.white : Colors.black87;

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
              color: Colors.black.withValues(alpha: 0.12),
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
    final isDarkMode = _themeController.isDarkMode;
    final bgColor =
        isDarkMode
            ? const Color(0xFF1C1C1E).withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.95);
    final iconColor = isDarkMode ? Colors.white : Colors.black87;
    final dividerColor =
        isDarkMode
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.black.withValues(alpha: 0.08);

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
            color: Colors.black.withValues(alpha: 0.15),
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

          // Font Settings
          _focusBarButton(
            icon: Icons.text_fields_rounded,
            color: iconColor,
            onTap: () {
              _toggleFocusControls();
              _onFontSettings();
            },
            tooltip: 'Font Settings',
            scale: scale,
          ),
          _focusBarDivider(dividerColor, scale),

          // Exit focus mode
          _focusBarButton(
            icon: Icons.fullscreen_exit_rounded,
            color: iconColor,
            onTap: _toggleFullScreen,
            tooltip: 'Exit Focus',
            scale: scale,
          ),
          _focusBarDivider(dividerColor, scale),

          // Collapse bar
          _focusBarButton(
            icon: Icons.close_rounded,
            color: iconColor.withValues(alpha: 0.5),
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

  // ──────────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);

    final filePath = widget.book.filePath;

    if (filePath == null || !File(filePath).existsSync()) {
      return Scaffold(
        backgroundColor: _themeController.backgroundColor,
        body: const Center(child: Text('EPUB file not found')),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          if (_showAiButton) {
            _clearSelection();
            return;
          }
          await _handleBackPress();
        }
      },
      child: Scaffold(
        backgroundColor: _themeController.backgroundColor,
        body: Stack(
          children: [
            // 1. The Reader at the bottom of the stack
            Positioned.fill(
              child: Padding(
                padding:
                    _isFullScreen
                        ? EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top,
                          bottom: MediaQuery.of(context).padding.bottom,
                        )
                        : EdgeInsets.only(
                          top: _headerHeight,
                          bottom: MediaQuery.of(context).padding.bottom + 90.0,
                        ),
                child: RepaintBoundary(
                  key: _readerBoundaryKey,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      EpubViewerReader(
                        filePath: filePath,
                        epubController: _epubController,
                        displaySettings: EpubDisplaySettings(
                          allowScriptedContent: true,
                        ),
                        isRestoringPosition: _isLoaderVisible,
                        loaderColor: const Color(0xFFB85C38),
                        backgroundColor: _themeController.backgroundColor,
                        onEpubLoaded: () async {
                          debugPrint('📖 EPUB loaded successfully');

                          if (mounted) {
                            setState(() => _isReady = true);
                          }

                          _applyEpubThemeIfReady();

                          // ✅ ONLY restore highlights once per session
                          if (!_sessionController.hasRestoredHighlights) {
                            await _highlightController.restoreHighlights(
                              bookId: widget.book.id,
                              epubController: _epubController,
                            );
                            _sessionController.hasRestoredHighlights = true;
                            debugPrint(
                              '✅ Highlights restored for the first time',
                            );
                          } else {
                            debugPrint(
                              '⏭️ Skipping highlight restore - already done',
                            );
                          }

                          // Inject custom styles AFTER a delay to ensure rendition exists
                          Future.delayed(const Duration(milliseconds: 800), () {
                            if (!mounted) return;
                            _injectCustomStyles();
                          });

                          // Try restore position if settings already loaded
                          if (_sessionController.hasLoadedSettings) {
                            _tryRestorePosition();
                          }
                        },

                        onChaptersLoaded: (chapters) {
                          debugPrint('📚 Chapters loaded: ${chapters.length}');
                          if (mounted) {
                            setState(() {
                              _chapters = chapters;
                              if (chapters.isNotEmpty) {
                                _currentChapter = chapters[0].title;
                              }
                            });
                          }
                        },
                        onRelocated: (EpubLocation location) {
                          if (_showAiButton) _clearSelection();

                          _updateCurrentChapter(location);

                          if (mounted) {
                            setState(
                              () => _currentProgress = location.progress,
                            );
                          }

                          if (_sessionController.hasJumpedToSavedPosition ||
                              _sessionController.savedCfi == null) {
                            final progressPercent = location.progress * 100;

                            _sessionController.lastTrackedCfi =
                                location.startCfi;

                            _timerController.updatePosition(
                              location.startCfi,
                              progressPercent,
                            );

                            _sessionController.queueAutoSave(
                              cfi: location.startCfi,
                              progress: progressPercent,
                              themeSettings: _currentThemeSettings,
                            );

                            debugPrint(
                              '✅ Position updated - CFI: ${location.startCfi}, '
                              'Progress: ${progressPercent.toStringAsFixed(2)}%',
                            );
                          }
                        },
                        onTextSelected: (selectedText, contextText, cfiRange) {
                          if (selectedText.trim().isEmpty) {
                            _clearSelection();
                            return;
                          }

                          setState(() {
                            _selectedAiText = selectedText;
                            _selectedAiContext = contextText;
                            _selectedCfi = cfiRange;
                            _showAiButton = true;
                          });
                        },
                      ),
                      if (_showAiButton)
                        Positioned.fill(
                          child: GestureDetector(
                            onTap: _clearSelection,
                            behavior: HitTestBehavior.translucent,
                            child: Container(color: Colors.transparent),
                          ),
                        ),

                      if (_showAiButton)
                        TextSelectionMenu(
                          themeController: _themeController,
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
                            isDarkMode: _themeController.isDarkMode,
                            onCaptured: _onCircleSearchCaptured,
                            onDismiss: _dismissCircleSearch,
                            screenshotProvider: () async {
                              // Use InAppWebView's takeScreenshot for EPUB
                              return await _epubController.webViewController
                                  ?.takeScreenshot();
                            },
                          ),
                        ),

                      _buildFocusModeControls(scale),
                    ],
                  ),
                ),
              ),
            ),

            // 2. The Header Overlay
            if (!_isFullScreen)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: EpubViewerHeader(
                  height: _headerHeight,
                  chapterTitle: _currentChapter,
                  bookTitle: widget.book.title,
                  author: widget.book.author,
                  textColor: _themeController.textColor,
                  backgroundColor: _themeController.backgroundColor,
                  onBack: () async => await _handleBackPress(),
                  isFullScreen: _isFullScreen,
                  onToggleFullScreen: _toggleFullScreen,
                ),
              ),

            // 3. The Bottom Sheet Overlay
            if (!_isFullScreen)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: EpubBottomSheet(
                  themeController: _themeController,
                  timerController: _timerController,
                  onFontSettings: _onFontSettings,
                  onOpenContents: _openContents,
                  onReadingTimeTap: _onReadingTimeTap,
                  onCircleSearch: _activateCircleSearch,
                  onRefresh: _refreshView,
                  book: widget.book,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
