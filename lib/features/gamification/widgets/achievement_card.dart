// import 'package:flutter/material.dart';
// import 'package:biblio/core/models/achievement_model.dart';
// import 'package:biblio/core/constants/achievement_icons.dart';

// class AchievementCard extends StatelessWidget {
//   final UserAchievement userAchievement;
//   final VoidCallback? onTap;
//   final bool showProgress;

//   const AchievementCard({
//     super.key,
//     required this.userAchievement,
//     this.onTap,
//     this.showProgress = true,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final achievement = userAchievement.achievement;
//     if (achievement == null) return const SizedBox.shrink();
//     final screenWidth = MediaQuery.sizeOf(context).width;
//     final scale = (screenWidth / 393).clamp(0.85, 1.0);

//     final isUnlocked = userAchievement.isUnlocked;
//     final tier = achievement.tier;
//     final progress = userAchievement.currentProgress;
//     final target = achievement.targetValue;
//     final cardPad = (16 * scale).clamp(14.0, 16.0);
//     final iconBoxSize = (50 * scale).clamp(42.0, 50.0);
//     final iconSize = (28 * scale).clamp(23.0, 28.0);
//     final titleSize = (16 * scale).clamp(14.0, 16.0);
//     final xpSize = (12 * scale).clamp(10.0, 12.0);
//     final descSize = (12 * scale).clamp(10.0, 12.0);
//     final progressSize = (11 * scale).clamp(9.0, 11.0);
//     final unlockedIconSize = (14 * scale).clamp(12.0, 14.0);

//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(12),
//       child: Container(
//         padding: EdgeInsets.all(cardPad),
//         decoration: BoxDecoration(
//           color:
//               isUnlocked
//                   ? _getTierColor(tier).withOpacity(0.1)
//                   : Colors.grey[100],
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(
//             color: isUnlocked ? _getTierColor(tier) : Colors.grey[300]!,
//             width: 2,
//           ),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 // Icon
//                 Container(
//                   width: iconBoxSize,
//                   height: iconBoxSize,
//                   decoration: BoxDecoration(
//                     color: isUnlocked ? _getTierColor(tier) : Colors.grey[400],
//                     shape: BoxShape.circle,
//                   ),
//                   child: Icon(
//                     AchievementIcons.getIcon(achievement.id),
//                     color: Colors.white,
//                     size: iconSize,
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 // Title & Description
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           Expanded(
//                             child: Text(
//                               achievement.title,
//                               style: TextStyle(
//                                 fontSize: titleSize,
//                                 fontWeight: FontWeight.bold,
//                                 color:
//                                     isUnlocked
//                                         ? Colors.black
//                                         : Colors.grey[600],
//                               ),
//                             ),
//                           ),
//                           // XP Badge
//                           Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 8,
//                               vertical: 4,
//                             ),
//                             decoration: BoxDecoration(
//                               color: Colors.amber[100],
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: Text(
//                               '+${achievement.xpReward} XP',
//                               style: TextStyle(
//                                 fontSize: xpSize,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.amber[900],
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         achievement.description,
//                         style: TextStyle(
//                           fontSize: descSize,
//                           color:
//                               isUnlocked ? Colors.grey[700] : Colors.grey[500],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             // Progress Bar (for locked achievements)
//             if (!isUnlocked && showProgress) ...[
//               const SizedBox(height: 12),
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Progress: $progress / $target',
//                     style: TextStyle(
//                       fontSize: progressSize,
//                       color: Colors.grey[600],
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   ClipRRect(
//                     borderRadius: BorderRadius.circular(4),
//                     child: LinearProgressIndicator(
//                       value: (progress / target).clamp(0.0, 1.0),
//                       minHeight: 6,
//                       backgroundColor: Colors.grey[300],
//                       valueColor: AlwaysStoppedAnimation<Color>(
//                         _getTierColor(tier),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//             // Unlocked Date
//             if (isUnlocked && userAchievement.unlockedAt != null) ...[
//               const SizedBox(height: 8),
//               Row(
//                 children: [
//                   Icon(
//                     Icons.check_circle,
//                     size: unlockedIconSize,
//                     color: _getTierColor(tier),
//                   ),
//                   const SizedBox(width: 4),
//                   Text(
//                     'Unlocked ${_formatDate(userAchievement.unlockedAt!)}',
//                     style: TextStyle(
//                       fontSize: progressSize,
//                       color: Colors.grey[600],
//                       fontStyle: FontStyle.italic,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Color _getTierColor(String tier) {
//     switch (tier) {
//       case 'bronze':
//         return Colors.brown;
//       case 'silver':
//         return Colors.grey[600]!;
//       case 'gold':
//         return Colors.amber[700]!;
//       default:
//         return Colors.blue;
//     }
//   }

//   String _formatDate(DateTime date) {
//     final now = DateTime.now();
//     final difference = now.difference(date);

//     if (difference.inDays == 0) return 'today';
//     if (difference.inDays == 1) return 'yesterday';
//     if (difference.inDays < 7) return '${difference.inDays} days ago';
//     return '${date.day}/${date.month}/${date.year}';
//   }
// }
