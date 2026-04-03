// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:biblio/core/providers/notification_provider.dart';

// class NotificationBadge extends ConsumerWidget {
//   final Widget child;
//   final bool showZero;

//   const NotificationBadge({
//     super.key,
//     required this.child,
//     this.showZero = false,
//   });

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final unreadCountAsync = ref.watch(unreadCountProvider);
//     final screenWidth = MediaQuery.sizeOf(context).width;
//     final scale = (screenWidth / 393).clamp(0.85, 1.0);
//     final badgePadding = (4 * scale).clamp(3.0, 4.0);
//     final badgeBorder = (2 * scale).clamp(1.5, 2.0);
//     final badgeMinSize = (20 * scale).clamp(17.0, 20.0);
//     final textSize = (10 * scale).clamp(8.0, 10.0);

//     return unreadCountAsync.when(
//       data: (count) {
//         if (count == 0 && !showZero) return child;

//         return Stack(
//           clipBehavior: Clip.none,
//           children: [
//             child,
//             Positioned(
//               right: -6,
//               top: -6,
//               child: Container(
//                 padding: EdgeInsets.all(badgePadding),
//                 decoration: BoxDecoration(
//                   color: Colors.red,
//                   shape: BoxShape.circle,
//                   border: Border.all(color: Colors.white, width: badgeBorder),
//                 ),
//                 constraints: BoxConstraints(
//                   minWidth: badgeMinSize,
//                   minHeight: badgeMinSize,
//                 ),
//                 child: Center(
//                   child: Text(
//                     count > 99 ? '99+' : '$count',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: textSize,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         );
//       },
//       loading: () => child,
//       error: (_, __) => child,
//     );
//   }
// }
