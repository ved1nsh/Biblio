// This dialog confirms book details before saving to library
// Uses Google Books API to search for book covers instead of extracting from PDF
//
// SAVE FLOW (correct order):
// 1. Create book in Supabase (without cover URL)
// 2. Upload cover to Storage using the REAL book ID
// 3. Update the book row with the cover URL

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:biblio/Homescreen/pages/library/shelf%20widgets/add_to_shelf.dart';
import 'package:biblio/Homescreen/widgets/book%20upload/book_search_dialog.dart';
import 'package:biblio/core/providers/book_provider.dart';
import 'package:biblio/epub_viewer/epub_viewer_page.dart';
import 'package:biblio/pdf_viewer/presentation/pdf_viewer_page.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:biblio/core/models/book_model.dart';

class ConfirmBookDetailsDialog extends ConsumerStatefulWidget {
  final String filePath;
  final String initialTitle;
  final String initialAuthor;
  final int totalPages;
  final String fileType; // 'pdf' or 'epub'

  const ConfirmBookDetailsDialog({
    super.key,
    required this.filePath,
    required this.initialTitle,
    required this.initialAuthor,
    required this.totalPages,
    this.fileType = 'pdf',
  });

  @override
  ConsumerState<ConfirmBookDetailsDialog> createState() =>
      _ConfirmBookDetailsDialogState();
}

class _ConfirmBookDetailsDialogState
    extends ConsumerState<ConfirmBookDetailsDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _authorController;

  Uint8List? _selectedCoverBytes;
  String? _selectedCoverUrl;
  bool _hasSearchedCover = false;
  bool _isSaving = false;
  String _coverSource = ''; // 'search', 'upload', or ''

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _authorController = TextEditingController(text: widget.initialAuthor);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  Future<void> _searchForCover() async {
    final searchQuery =
        _titleController.text.trim().isEmpty
            ? 'Unknown Book'
            : _titleController.text.trim();

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.9,
            maxChildSize: 0.9,
            minChildSize: 0.5,
            builder:
                (_, scrollController) =>
                    BookSearchDialog(initialQuery: searchQuery),
          ),
    );

    if (result != null) {
      setState(() {
        _titleController.text = result['title'] ?? _titleController.text;
        _authorController.text = result['author'] ?? _authorController.text;
        _selectedCoverBytes = result['coverBytes'];
        _selectedCoverUrl = result['coverUrl'];
        _hasSearchedCover = true;
        _coverSource = 'search';
      });
    }
  }

  /// Pick an image from gallery and compress it
  Future<void> _pickCoverFromGallery() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result == null || result.files.single.path == null) return;

    final file = File(result.files.single.path!);
    final rawBytes = await file.readAsBytes();

    // Compress the image
    final compressed = await _compressImage(
      rawBytes,
      maxWidth: 600,
      quality: 75,
    );

    setState(() {
      _selectedCoverBytes = compressed;
      _selectedCoverUrl = null;
      _hasSearchedCover = true;
      _coverSource = 'upload';
    });
  }

  /// Compress image using dart:ui — resize to maxWidth and encode as JPEG
  Future<Uint8List> _compressImage(
    Uint8List imageBytes, {
    int maxWidth = 600,
    int quality = 75,
  }) async {
    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    // Calculate new dimensions maintaining aspect ratio
    final double ratio = image.width / image.height;
    int targetWidth = image.width;
    int targetHeight = image.height;

    if (targetWidth > maxWidth) {
      targetWidth = maxWidth;
      targetHeight = (maxWidth / ratio).round();
    }

    // Resize
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
    );
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
      Paint()..filterQuality = FilterQuality.medium,
    );
    final picture = recorder.endRecording();
    final resizedImage = await picture.toImage(targetWidth, targetHeight);

    // Encode as PNG (dart:ui doesn't support JPEG quality param)
    final byteData = await resizedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    image.dispose();
    resizedImage.dispose();

    return byteData!.buffer.asUint8List();
  }

  /// Saves the book with correct order:
  /// 1. Create book row (no cover yet)
  /// 2. Upload cover with real book ID
  /// 3. Update book row with cover URL
  Future<void> _saveBook() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final bookService = ref.read(bookServiceProvider);
      final title =
          _titleController.text.trim().isEmpty
              ? 'Untitled Book'
              : _titleController.text.trim();
      final author =
          _authorController.text.trim().isEmpty
              ? 'Unknown Author'
              : _authorController.text.trim();

      // Step 1: Create book WITHOUT cover URL
      final savedBook = await bookService.createBook(
        title: title,
        author: author,
        filePath: widget.filePath,
        coverUrl: null,
        totalPages: widget.totalPages,
        fileType: widget.fileType,
      );

      // Step 2: Upload cover with REAL book ID (only if we have cover data)
      String? coverUrl;
      if (_selectedCoverBytes != null && _selectedCoverBytes!.isNotEmpty) {
        // User-uploaded images are compressed to PNG; API covers are typically JPG
        final ext = _coverSource == 'upload' ? 'png' : 'jpg';
        coverUrl = await bookService.uploadBookCover(
          bookId: savedBook.id,
          imageBytes: _selectedCoverBytes!,
          fileExtension: ext,
        );
      }

      // Step 3: Update book with the cover URL (only if upload succeeded)
      Book finalBook = savedBook;
      if (coverUrl != null) {
        finalBook = await bookService.updateBook(
          bookId: savedBook.id,
          coverUrl: coverUrl,
        );
      }

      ref.invalidate(allBooksProvider);

      if (!mounted) return;
      Navigator.of(context).pop(); // Pop this dialog

      _showPostUploadActions(finalBook);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save book: ${e.toString()}'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  void _showPostUploadActions(Book savedBook) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _PostUploadActionSheet(book: savedBook),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final headerSize = (22 * scale).clamp(18.0, 22.0);
    final padH = (24 * scale).clamp(16.0, 24.0);
    final gap20 = (20 * scale).clamp(16.0, 20.0);
    final gap24 = (24 * scale).clamp(18.0, 24.0);
    final gap32 = (32 * scale).clamp(26.0, 32.0);
    final coverW = (90 * scale).roundToDouble();
    final coverH = (130 * scale).roundToDouble();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      minChildSize: 0.5,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFCF9F5),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: EdgeInsets.fromLTRB(padH, 8, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Confirm Details',
                        style: TextStyle(
                          fontSize: headerSize,
                          fontFamily: 'SF-UI-Display',
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.06),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(padH, 0, padH, bottomInset + 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // File type badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              widget.fileType == 'epub'
                                  ? const Color(0xFFE8F5E9)
                                  : const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.fileType.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'SF-UI-Display',
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color:
                                widget.fileType == 'epub'
                                    ? const Color(0xFF2E7D32)
                                    : const Color(0xFF1565C0),
                          ),
                        ),
                      ),

                      SizedBox(height: gap20),

                      // Title field
                      const Text(
                        'Title',
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: 'SF-UI-Display',
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _titleController,
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'SF-UI-Display',
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter book title',
                          hintStyle: TextStyle(
                            color: Colors.black.withValues(alpha: 0.3),
                            fontFamily: 'SF-UI-Display',
                            fontWeight: FontWeight.w400,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.black.withValues(alpha: 0.08),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.black.withValues(alpha: 0.08),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.black54,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Author field
                      const Text(
                        'Author',
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: 'SF-UI-Display',
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _authorController,
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'SF-UI-Display',
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter author name',
                          hintStyle: TextStyle(
                            color: Colors.black.withValues(alpha: 0.3),
                            fontFamily: 'SF-UI-Display',
                            fontWeight: FontWeight.w400,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.black.withValues(alpha: 0.08),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.black.withValues(alpha: 0.08),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.black54,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: gap24),

                      // Divider
                      Divider(
                        color: Colors.black.withValues(alpha: 0.06),
                        thickness: 1,
                      ),

                      SizedBox(height: gap20),

                      // Cover section
                      const Text(
                        'Book Cover',
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: 'SF-UI-Display',
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _coverSource == 'upload'
                            ? 'Custom cover uploaded'
                            : _coverSource == 'search'
                            ? 'Cover from Google Books'
                            : 'Search online or upload your own',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'SF-UI-Display',
                          fontWeight: FontWeight.w400,
                          color: Colors.black.withValues(alpha: 0.45),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Cover preview + buttons row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Cover thumbnail
                          GestureDetector(
                            onTap:
                                _hasSearchedCover
                                    ? _showCoverOptions
                                    : _searchForCover,
                            child: Container(
                              width: coverW,
                              height: coverH,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color:
                                      _hasSearchedCover
                                          ? Colors.black.withValues(alpha: 0.12)
                                          : Colors.black.withValues(
                                            alpha: 0.08,
                                          ),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child:
                                  _selectedCoverBytes != null
                                      ? ClipRRect(
                                        borderRadius: BorderRadius.circular(9),
                                        child: Image.memory(
                                          _selectedCoverBytes!,
                                          fit: BoxFit.cover,
                                          width: coverW,
                                          height: coverH,
                                        ),
                                      )
                                      : _selectedCoverUrl != null
                                      ? ClipRRect(
                                        borderRadius: BorderRadius.circular(9),
                                        child: Image.network(
                                          _selectedCoverUrl!,
                                          fit: BoxFit.cover,
                                          width: coverW,
                                          height: coverH,
                                          errorBuilder:
                                              (_, __, ___) =>
                                                  _buildCoverPlaceholder(),
                                        ),
                                      )
                                      : _buildCoverPlaceholder(),
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Two buttons stacked
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Search online button
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _searchForCover,
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 11,
                                      ),
                                      side: const BorderSide(
                                        color: Colors.black87,
                                        width: 1.2,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    icon: Icon(
                                      _coverSource == 'search'
                                          ? Icons.refresh_rounded
                                          : Icons.search_rounded,
                                      size: 17,
                                      color: Colors.black87,
                                    ),
                                    label: Text(
                                      _coverSource == 'search'
                                          ? 'Change Cover'
                                          : 'Search Online',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontFamily: 'SF-UI-Display',
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Upload from gallery button
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _pickCoverFromGallery,
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 11,
                                      ),
                                      side: BorderSide(
                                        color: Colors.black.withValues(
                                          alpha: 0.25,
                                        ),
                                        width: 1.2,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    icon: Icon(
                                      _coverSource == 'upload'
                                          ? Icons.check_circle_outline
                                          : Icons.photo_library_outlined,
                                      size: 17,
                                      color:
                                          _coverSource == 'upload'
                                              ? Colors.green.shade700
                                              : Colors.black54,
                                    ),
                                    label: Text(
                                      _coverSource == 'upload'
                                          ? 'Replace Image'
                                          : 'Upload Image',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontFamily: 'SF-UI-Display',
                                        fontWeight: FontWeight.w600,
                                        color:
                                            _coverSource == 'upload'
                                                ? Colors.green.shade700
                                                : Colors.black54,
                                      ),
                                    ),
                                  ),
                                ),
                                if (_hasSearchedCover) ...[
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedCoverBytes = null;
                                        _selectedCoverUrl = null;
                                        _hasSearchedCover = false;
                                        _coverSource = '';
                                      });
                                    },
                                    child: Text(
                                      'Remove cover',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'SF-UI-Display',
                                        fontWeight: FontWeight.w500,
                                        color: Colors.red.shade400,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: gap32),

                      // Pages info
                      if (widget.totalPages > 0)
                        Padding(
                          padding: EdgeInsets.only(bottom: gap24),
                          child: Row(
                            children: [
                              Icon(
                                Icons.auto_stories_outlined,
                                size: 16,
                                color: Colors.black.withValues(alpha: 0.4),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${widget.totalPages} pages',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontFamily: 'SF-UI-Display',
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.black,
                            disabledBackgroundColor: Colors.black.withValues(
                              alpha: 0.4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _isSaving ? null : _saveBook,
                          child:
                              _isSaving
                                  ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'Saving...',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontFamily: 'SF-UI-Display',
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  )
                                  : const Text(
                                    'Save to Library',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontFamily: 'SF-UI-Display',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCoverOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            decoration: const BoxDecoration(
              color: Color(0xFFFCF9F5),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Change Cover',
                    style: TextStyle(
                      fontSize: 17,
                      fontFamily: 'SF-UI-Display',
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: const Icon(
                      Icons.search_rounded,
                      color: Colors.black87,
                    ),
                    title: const Text(
                      'Search Online',
                      style: TextStyle(
                        fontFamily: 'SF-UI-Display',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _searchForCover();
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.photo_library_outlined,
                      color: Colors.black87,
                    ),
                    title: const Text(
                      'Upload from Gallery',
                      style: TextStyle(
                        fontFamily: 'SF-UI-Display',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _pickCoverFromGallery();
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.delete_outline,
                      color: Colors.red.shade400,
                    ),
                    title: Text(
                      'Remove Cover',
                      style: TextStyle(
                        fontFamily: 'SF-UI-Display',
                        fontWeight: FontWeight.w500,
                        color: Colors.red.shade400,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _selectedCoverBytes = null;
                        _selectedCoverUrl = null;
                        _hasSearchedCover = false;
                        _coverSource = '';
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildCoverPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.image_outlined,
          size: 28,
          color: Colors.black.withValues(alpha: 0.2),
        ),
        const SizedBox(height: 4),
        Text(
          'No cover',
          style: TextStyle(
            fontSize: 10,
            fontFamily: 'SF-UI-Display',
            fontWeight: FontWeight.w500,
            color: Colors.black.withValues(alpha: 0.25),
          ),
        ),
      ],
    );
  }
}

// Keep the _PostUploadActionSheet class as is (same as before)
class _PostUploadActionSheet extends ConsumerWidget {
  final Book book;

  const _PostUploadActionSheet({required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEpub = book.filePath?.toLowerCase().endsWith('.epub') ?? false;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFFFCF9F5),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'Book Added Successfully!',
            style: TextStyle(
              fontSize: 22,
              fontFamily: 'SF-UI-Display',
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            'What would you like to do next?',
            style: TextStyle(
              fontSize: 15,
              fontFamily: 'SF-UI-Display',
              fontWeight: FontWeight.w400,
              color: Colors.black.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final bookService = ref.read(bookServiceProvider);
                await bookService.updateBook(
                  bookId: book.id,
                  isStartedReading: true,
                );
                ref.invalidate(allBooksProvider);

                final updatedBook = book.copyWith(isStartedReading: true);
                ref
                    .read(currentlyReadingProvider.notifier)
                    .setBook(updatedBook);

                if (!context.mounted) return;
                Navigator.pop(context);

                if (isEpub) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EpubViewerPage(book: book),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PdfViewerPage(book: book),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.menu_book_rounded),
              label: const Text(
                'Open Now',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'SF-UI-Display',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Colors.black, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder:
                      (context) => AddToShelfDialog(
                        bookId: book.id,
                        bookTitle: book.title,
                      ),
                );
              },
              icon: const Icon(Icons.collections_bookmark, color: Colors.black),
              label: const Text(
                'Add to Shelf...',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'SF-UI-Display',
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Done',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'SF-UI-Display',
                  fontWeight: FontWeight.w600,
                  color: Colors.black.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
