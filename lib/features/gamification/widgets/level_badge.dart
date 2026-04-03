// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:biblio/core/providers/xp_provider.dart';

// class LevelBadge extends ConsumerWidget {
//   final double size;
//   final bool showLabel;

//   const LevelBadge({super.key, this.size = 50, this.showLabel = false});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final levelAsync = ref.watch(currentLevelProvider);
//     final screenWidth = MediaQuery.sizeOf(context).width;
//     final scale = (screenWidth / 393).clamp(0.85, 1.0);
//     final effectiveSize = (size * scale).clamp(size * 0.85, size);
//     final numberSize = (effectiveSize * 0.4).clamp(14.0, effectiveSize * 0.4);
//     final labelSize = (12 * scale).clamp(10.0, 12.0);

//     return levelAsync.when(
//       data:
//           (level) => Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 width: effectiveSize,
//                 height: effectiveSize,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   gradient: LinearGradient(
//                     colors: _getLevelColors(level),
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   ),
//                   boxShadow: [
//                     BoxShadow(
//                       color: _getLevelColors(level)[0].withOpacity(0.3),
//                       blurRadius: 8,
//                       offset: const Offset(0, 4),
//                     ),
//                   ],
//                 ),
//                 child: Center(
//                   child: Text(
//                     '$level',
//                     style: TextStyle(
//                       fontSize: numberSize,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//               ),
//               if (showLabel) ...[
//                 const SizedBox(height: 4),
//                 Text(
//                   'Level $level',
//                   style: TextStyle(
//                     fontSize: labelSize,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ],
//             ],
//           ),
//       loading:
//           () => Container(
//             width: effectiveSize,
//             height: effectiveSize,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               color: Colors.grey[300],
//             ),
//           ),
//       error: (_, __) => const SizedBox.shrink(),
//     );
//   }

//   List<Color> _getLevelColors(int level) {
//     if (level < 5) return [Colors.blue, Colors.blue[700]!];
//     if (level < 10) return [Colors.purple, Colors.purple[700]!];
//     if (level < 20) return [Colors.orange, Colors.deepOrange];
//     return [Colors.amber, Colors.orange];
//   }
// }
