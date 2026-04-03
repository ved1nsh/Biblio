// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:biblio/core/providers/shelf_provider.dart';
// import 'package:biblio/core/models/shelf_model.dart';
// import 'package:biblio/Homescreen/pages/library/widgets/book_details_sheet.dart';
// import 'package:biblio/Homescreen/pages/library/shelf widgets/create_shelf_dialog.dart';
// import 'package:biblio/Homescreen/pages/library/widgets/shelf_card.dart';
// import 'package:biblio/core/models/book_model.dart';
// import 'package:biblio/core/providers/book_provider.dart';

// Color _colorFromHex(String hexColor) {
//   hexColor = hexColor.replaceAll("#", "");
//   if (hexColor.length == 6) {
//     hexColor = "FF$hexColor";
//   }
//   if (hexColor.length == 8) {
//     return Color(int.parse("0x$hexColor"));
//   }
//   // Return a default color if hex is invalid
//   return Colors.grey;
// }

// Color _shiftHue(Color color, double amount) {
//   final hsl = HSLColor.fromColor(color);
//   return hsl.withHue((hsl.hue + amount) % 360.0).toColor();
// }

// IconData _getShelfIcon(String name) {
//   final lower = name.toLowerCase();
//   if (lower.contains('read') && lower.contains('to')) {
//     return Icons.bookmark_outline;
//   }
//   if (lower.contains('top')) return Icons.emoji_events_outlined;
//   if (lower.contains('own')) return Icons.menu_book_outlined;
//   if (lower.contains('pdf') || lower.contains('library')) {
//     return Icons.library_books_outlined;
//   }
//   if (lower.contains('fav')) return Icons.favorite_outline;
//   return Icons.collections_bookmark_outlined;
// }

// class BookshelvesWidget extends ConsumerStatefulWidget {
//   final VoidCallback? onShelfTap;

//   const BookshelvesWidget({super.key, this.onShelfTap});

//   @override
//   ConsumerState<BookshelvesWidget> createState() => _BookshelvesWidgetState();
// }

// class _BookshelvesWidgetState extends ConsumerState<BookshelvesWidget> {
//   int? expandedIndex = 0; // Default to expanding the first shelf

//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.sizeOf(context).width;
//     final scale = (screenWidth / 393).clamp(0.85, 1.0);

//     final shelvesAsync = ref.watch(allShelvesProvider);
//     final allBooksAsync = ref.watch(allBooksProvider);
//     final allBooks = allBooksAsync.when(
//       data: (books) => books,
//       loading: () => [],
//       error: (_, __) => [],
//     );

//     return shelvesAsync.when(
//       loading:
//           () => SizedBox(
//             height: 100 * scale,
//             child: const Center(child: CircularProgressIndicator()),
//           ),
//       error: (err, stack) {
//         debugPrint('Error loading shelves: $err');
//         return const SizedBox.shrink();
//       },
//       data: (shelves) {
//         final sectionTitle = (18 * scale).clamp(16.0, 20.0);

//         final customShelves =
//             shelves.where((s) {
//               final lower = s.name.toLowerCase();
//               return lower != 'all books' && lower != 'reading now';
//             }).toList();

//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'My Bookshelves',
//               style: TextStyle(
//                 fontSize: sectionTitle,
//                 fontWeight: FontWeight.w700,
//                 fontFamily: 'SF-UI-Display',
//                 color: Colors.black87,
//               ),
//             ),
//             SizedBox(height: 8 * scale),
//             ListView.builder(
//               shrinkWrap: true,
//               physics: const NeverScrollableScrollPhysics(),
//               itemCount: customShelves.length + 1, // +1 for New Shelf
//               itemBuilder: (context, index) {
//                 if (index == customShelves.length) {
//                   return _buildNewShelfCard(context, scale);
//                 }

//                 final shelf = customShelves[index];
//                 final isExpanded = expandedIndex == index;
//                 final shelfBooks =
//                     (allBooks
//                             .where(
//                               (b) => b.shelfIds?.contains(shelf.id) ?? false,
//                             )
//                             .toList()
//                         as List<Book>);

//                 return ExpandableShelfTile(
//                   shelf: shelf,
//                   books: shelfBooks,
//                   isExpanded: isExpanded,
//                   scale: scale,
//                   onTap: () {
//                     setState(() {
//                       if (isExpanded) {
//                         expandedIndex = null;
//                       } else {
//                         expandedIndex = index;
//                       }
//                     });
//                   },
//                   onViewShelf: () {
//                     ref.read(selectedShelfProvider.notifier).state = shelf.name;
//                     widget.onShelfTap?.call();
//                   },
//                 );
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Widget _buildNewShelfCard(BuildContext context, double scale) {
//     final tileHeight = (70 * scale).roundToDouble();
//     final iconSize = (24 * scale).clamp(22.0, 28.0);
//     final nameSize = (16 * scale).clamp(14.0, 18.0);

//     return GestureDetector(
//       onTap: () {
//         showModalBottomSheet(
//           context: context,
//           backgroundColor: Colors.transparent,
//           isScrollControlled: true,
//           builder: (context) => const CreateShelfDialog(),
//         );
//       },
//       child: Container(
//         height: tileHeight,
//         margin: EdgeInsets.only(bottom: 12 * scale),
//         padding: EdgeInsets.symmetric(horizontal: 16 * scale),
//         decoration: BoxDecoration(
//           color: Colors.grey[100],
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(color: Colors.grey[300]!, width: 1.5),
//         ),
//         child: Row(
//           children: [
//             Icon(Icons.add, color: Colors.grey[500], size: iconSize),
//             SizedBox(width: 16 * scale),
//             Expanded(
//               child: Text(
//                 'New Shelf',
//                 style: TextStyle(
//                   fontSize: nameSize,
//                   fontFamily: 'SF-UI-Display',
//                   fontWeight: FontWeight.w600,
//                   color: Colors.grey[700],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class ExpandableShelfTile extends ConsumerStatefulWidget {
//   final Shelf shelf;
//   final List<Book> books;
//   final bool isExpanded;
//   final VoidCallback onTap;
//   final VoidCallback onViewShelf;
//   final double scale;

//   const ExpandableShelfTile({
//     super.key,
//     required this.shelf,
//     required this.books,
//     required this.isExpanded,
//     required this.onTap,
//     required this.onViewShelf,
//     required this.scale,
//   });

//   @override
//   ConsumerState<ExpandableShelfTile> createState() =>
//       _ExpandableShelfTileState();
// }
