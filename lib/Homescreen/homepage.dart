import 'package:biblio/Homescreen/pages/streak/streak_page.dart';
import 'package:biblio/Homescreen/widgets/book upload/add_book_options_dialog.dart';
import 'package:biblio/Homescreen/widgets/book upload/confirm_book_details_dialog.dart';
import 'package:biblio/Homescreen/widgets/book upload/manual book entry/manual_book_entry_dialog.dart';
import 'package:biblio/Homescreen/widgets/homepage widgets/bookshelves_widget.dart';
import 'package:biblio/Homescreen/widgets/homepage widgets/homepage_reading_widget.dart';
import 'package:biblio/Homescreen/widgets/homepage widgets/custom_bottom_navigation.dart';
import 'package:biblio/Homescreen/widgets/homepage widgets/homepage_header.dart';
import 'package:biblio/Homescreen/widgets/homepage widgets/todays_goal_widget.dart';
import 'package:biblio/core/models/book_model.dart';
import 'package:biblio/core/providers/book_provider.dart';
import 'package:biblio/core/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:epubx/epubx.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:io';
import 'pages/library/library_page.dart';
import 'package:biblio/notebook/notebook_page.dart';
import 'package:biblio/features/settings/user_setting_screen.dart';

class Homepage extends ConsumerStatefulWidget {
  const Homepage({super.key});

  @override
  ConsumerState<Homepage> createState() => _HomepageState();
}

class _HomepageState extends ConsumerState<Homepage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showAddBookOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: false,
      builder:
          (context) => AddBookOptionsDialog(
            onImportFile: _handleImportFile,
            onAddManually: _handleAddManually,
          ),
    );
  }

  Future<void> _handleImportFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'epub'],
    );

    if (result == null || result.files.single.path == null) return;

    final path = result.files.single.path!;
    final extension = path.split('.').last.toLowerCase();

    if (extension == 'pdf') {
      await _handlePdfImport(path);
    } else if (extension == 'epub') {
      await _handleEpubImport(path);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Unsupported file type')));
      }
    }
  }

  Future<void> _handlePdfImport(String path) async {
    try {
      final file = File(path);
      final document = PdfDocument(inputBytes: file.readAsBytesSync());

      String title = document.documentInformation.title ?? 'Untitled Book';
      String author = document.documentInformation.author ?? 'Unknown Author';
      int totalPages = document.pages.count;

      document.dispose();

      ref.invalidate(allBooksProvider);

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder:
            (_) => ConfirmBookDetailsDialog(
              filePath: path,
              initialTitle: title,
              initialAuthor: author,
              totalPages: totalPages,
              fileType: 'pdf',
            ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to read PDF metadata.')),
        );
      }
    }
  }

  Future<void> _handleEpubImport(String path) async {
    String title = 'Untitled Book';
    String author = 'Unknown Author';

    try {
      final file = File(path);
      final bytes = await file.readAsBytes();

      final epubBook = await EpubReader.readBook(bytes);

      if (epubBook.Title != null && epubBook.Title!.isNotEmpty) {
        title = epubBook.Title!;
      }

      if (epubBook.Author != null && epubBook.Author!.isNotEmpty) {
        author = epubBook.Author!;
      }
    } catch (e) {
      debugPrint('Error reading EPUB metadata: $e');
    }

    ref.invalidate(allBooksProvider);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => ConfirmBookDetailsDialog(
            filePath: path,
            initialTitle: title,
            initialAuthor: author,
            totalPages: 0,
            fileType: 'epub',
          ),
    );
  }

  void _handleAddManually() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ManualBookEntryDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<Book>>>(allBooksProvider, (previous, next) {
      if (next is AsyncData<List<Book>>) {
        final books = next.value;
        if (books.isNotEmpty && ref.read(currentlyReadingProvider) == null) {
          ref.read(currentlyReadingProvider.notifier).setBook(books.last);
        }
      }
    });

    final allBooksAsync = ref.watch(allBooksProvider);

    return allBooksAsync.when(
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
      data: (books) {
        return Scaffold(
          backgroundColor: const Color(0xFFFCF9F5),
          body: Stack(
            clipBehavior: Clip.none,
            children: [
              IndexedStack(
                index: _selectedIndex,
                children: [
                  _buildHomePage(),
                  _buildLibraryPage(),
                  StreakPage(),
                  NotebookPage(),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: CustomBottomNavigation(
                  currentIndex: _selectedIndex,
                  onTap: _onItemTapped,
                  onUploadTap: _showAddBookOptions,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _switchToLibrary() {
    setState(() {
      _selectedIndex = 1;
    });
  }

  void _switchToStreak() {
    setState(() {
      _selectedIndex = 2;
    });
  }

  Widget _buildHomePage() {
    final user = ref.watch(authStateProvider).value;
    final topPadding = MediaQuery.of(context).padding.top;
    final appBarHeight = topPadding + 115.h.clamp(105.0, 130.0);

    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.fromLTRB(22.w, appBarHeight + 20.h, 22.w, 120),
          children: [
            const HomepageReadingWidget(),
            SizedBox(height: 28.h),
            BookshelvesWidget(onShelfTap: _switchToLibrary),
            SizedBox(height: 28.h),
            TodaysGoalWidget(
              onStreakTap: _switchToStreak,
              onGoalTap: _switchToStreak,
            ),
          ],
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            color: const Color(0xFFFCF9F5),
            padding: EdgeInsets.fromLTRB(
              22.w,
              topPadding + 22.h.clamp(18.0, 28.0),
              22.w,
              10.h,
            ),
            child: HomepageGreeting(
              userName: user?.displayName,
              userPhotoUrl: user?.photoUrl,
              onProfileTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UserSettingsScreen()),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLibraryPage() {
    return const LibraryPage();
  }
}
