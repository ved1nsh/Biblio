// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:biblio/core/services/streak_service.dart';

// final streakServiceProvider = Provider((ref) => StreakService());

// final currentStreakProvider = FutureProvider<int>((ref) async {
//   final service = ref.watch(streakServiceProvider);
//   return await service.calculateCurrentStreak();
// });

// class StreakFlameWidget extends ConsumerWidget {
//   final double size;
//   final bool showLabel;

//   const StreakFlameWidget({super.key, this.size = 40, this.showLabel = true});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final streakAsync = ref.watch(currentStreakProvider);
//     final screenWidth = MediaQuery.sizeOf(context).width;
//     final scale = (screenWidth / 393).clamp(0.85, 1.0);
//     final effectiveSize = (size * scale).clamp(size * 0.85, size);
//     final fireIconSize = (effectiveSize * 0.8).clamp(24.0, size * 0.8);
//     final countSize = (effectiveSize * 0.3).clamp(10.0, size * 0.3);
//     final labelSize = (12 * scale).clamp(10.0, 12.0);
//     final loadingWidth = (50 * scale).clamp(42.0, 50.0);
//     final loadingHeight = (12 * scale).clamp(10.0, 12.0);

//     return streakAsync.when(
//       data:
//           (streak) => Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Stack(
//                 alignment: Alignment.center,
//                 children: [
//                   // Flame Icon with glow effect
//                   Container(
//                     width: effectiveSize,
//                     height: effectiveSize,
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       boxShadow:
//                           streak > 0
//                               ? [
//                                 BoxShadow(
//                                   color: _getFlameColor(
//                                     streak,
//                                   ).withOpacity(0.5),
//                                   blurRadius: 12,
//                                   spreadRadius: 2,
//                                 ),
//                               ]
//                               : null,
//                     ),
//                     child: Icon(
//                       Icons.local_fire_department,
//                       size: fireIconSize,
//                       color:
//                           streak > 0
//                               ? _getFlameColor(streak)
//                               : Colors.grey[400],
//                     ),
//                   ),
//                   // Streak number
//                   if (streak > 0)
//                     Positioned(
//                       bottom: 0,
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 6,
//                           vertical: 2,
//                         ),
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(10),
//                           border: Border.all(
//                             color: _getFlameColor(streak),
//                             width: 2,
//                           ),
//                         ),
//                         child: Text(
//                           '$streak',
//                           style: TextStyle(
//                             fontSize: countSize,
//                             fontWeight: FontWeight.bold,
//                             color: _getFlameColor(streak),
//                           ),
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//               if (showLabel) ...[
//                 const SizedBox(height: 4),
//                 Text(
//                   streak == 0
//                       ? 'Start streak!'
//                       : streak == 1
//                       ? '1 day'
//                       : '$streak days',
//                   style: TextStyle(
//                     fontSize: labelSize,
//                     fontWeight: FontWeight.w600,
//                     color:
//                         streak > 0 ? _getFlameColor(streak) : Colors.grey[600],
//                   ),
//                 ),
//               ],
//             ],
//           ),
//       loading:
//           () => Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(
//                 Icons.local_fire_department,
//                 size: fireIconSize,
//                 color: Colors.grey[400],
//               ),
//               if (showLabel) ...[
//                 const SizedBox(height: 4),
//                 SizedBox(
//                   width: loadingWidth,
//                   height: loadingHeight,
//                   child: LinearProgressIndicator(),
//                 ),
//               ],
//             ],
//           ),
//       error:
//           (_, __) => Icon(
//             Icons.local_fire_department,
//             size: fireIconSize,
//             color: Colors.grey[400],
//           ),
//     );
//   }

//   Color _getFlameColor(int streak) {
//     if (streak == 0) return Colors.grey[400]!;
//     if (streak < 3) return Colors.orange[300]!;
//     if (streak < 7) return Colors.orange[600]!;
//     if (streak < 30) return Colors.deepOrange;
//     if (streak < 100) return Colors.red[700]!;
//     return Colors.purple[700]!; // Epic streak
//   }
// }
