import 'package:flutter/material.dart';
import '../controllers/epub_theme_controller.dart';

class SheetHeader extends StatelessWidget {
  final bool showBookJournal;
  final String bookTitle;
  final Color textColor;
  final VoidCallback onClose;
  final VoidCallback onToggleContents;
  final VoidCallback onToggleJournal;
  final double scale;

  const SheetHeader({
    super.key,
    required this.showBookJournal,
    required this.bookTitle,
    required this.textColor,
    required this.onClose,
    required this.onToggleContents,
    required this.onToggleJournal,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final padH = (20 * scale).clamp(16.0, 20.0);
    final padT = (20 * scale).clamp(16.0, 20.0);
    final padR = (12 * scale).clamp(10.0, 12.0);
    final padB = (16 * scale).clamp(12.0, 16.0);
    final paddingBetween = (12 * scale).clamp(10.0, 12.0);
    final arrowSize = (18 * scale).clamp(14.0, 18.0).roundToDouble();
    final titleFontSize = (20 * scale).clamp(16.0, 20.0);
    final pillSpacing = (8 * scale).clamp(6.0, 8.0);

    return Padding(
      padding: EdgeInsets.fromLTRB(padH, padT, padR, padB),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (showBookJournal)
                GestureDetector(
                  onTap: onToggleContents,
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: (8 * scale).clamp(6.0, 8.0),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: arrowSize,
                      color: textColor,
                    ),
                  ),
                ),
              Expanded(
                child: Text(
                  showBookJournal ? 'Journal: $bookTitle' : 'Table of Contents',
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'SF-UI-Display',
                    color: textColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onClose,
                color: textColor.withValues(alpha: 0.6),
                iconSize: (20 * scale).clamp(16.0, 20.0).roundToDouble(),
              ),
            ],
          ),
          SizedBox(height: paddingBetween),
          Row(
            children: [
              TabPill(
                label: 'Contents',
                active: !showBookJournal,
                onTap: onToggleContents,
                textColor: textColor,
                scale: scale,
              ),
              SizedBox(width: pillSpacing),
              TabPill(
                label: 'Journal',
                active: showBookJournal,
                onTap: onToggleJournal,
                textColor: textColor,
                scale: scale,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TabPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color textColor;
  final double scale;

  const TabPill({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
    required this.textColor,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final padH = (16 * scale).clamp(12.0, 16.0);
    final padV = (8 * scale).clamp(6.0, 8.0);
    final radius = (20 * scale).clamp(16.0, 20.0).roundToDouble();
    final fontSize = (14 * scale).clamp(12.0, 14.0);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFD97757) : Colors.transparent,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color:
                active
                    ? const Color(0xFFD97757)
                    : textColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : textColor.withValues(alpha: 0.7),
            fontFamily: 'SF-UI-Display',
          ),
        ),
      ),
    );
  }
}

class ReadingProgressBar extends StatelessWidget {
  final double readingProgress;
  final Color textColor;
  final Color dividerColor;
  final double scale;

  const ReadingProgressBar({
    super.key,
    required this.readingProgress,
    required this.textColor,
    required this.dividerColor,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (readingProgress * 100).toInt();
    final allPad = (20 * scale).clamp(16.0, 20.0);
    final labelFontSize = (14 * scale).clamp(12.0, 14.0);
    final percentFontSize = (16 * scale).clamp(14.0, 16.0);
    final progressHeight = (8 * scale).clamp(6.0, 8.0);
    final progressRadius = (10 * scale).clamp(8.0, 10.0).roundToDouble();
    final spacingMid = (12 * scale).clamp(10.0, 12.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(height: 1, color: dividerColor),
        Container(
          padding: EdgeInsets.all(allPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Reading Progress',
                    style: TextStyle(
                      fontSize: labelFontSize,
                      fontWeight: FontWeight.w600,
                      color: textColor.withValues(alpha: 0.7),
                      fontFamily: 'SF-UI-Display',
                    ),
                  ),
                  Text(
                    '$pct%',
                    style: TextStyle(
                      fontSize: percentFontSize,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFD97757),
                      fontFamily: 'SF-UI-Display',
                    ),
                  ),
                ],
              ),
              SizedBox(height: spacingMid),
              ClipRRect(
                borderRadius: BorderRadius.circular(progressRadius),
                child: LinearProgressIndicator(
                  value: readingProgress,
                  minHeight: progressHeight,
                  backgroundColor: textColor.withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFFD97757)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class NoteInputBar extends StatelessWidget {
  final Color backgroundColor;
  final Color textColor;
  final Color dividerColor;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSave;
  final double scale;

  const NoteInputBar({
    super.key,
    required this.backgroundColor,
    required this.textColor,
    required this.dividerColor,
    required this.controller,
    required this.focusNode,
    required this.onSave,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final padH = (16 * scale).clamp(12.0, 16.0);
    final padV = (12 * scale).clamp(10.0, 12.0);
    final iconSize = (38 * scale).roundToDouble().clamp(30.0, 38.0);
    final iconInnerSize = (18 * scale).clamp(14.0, 18.0).roundToDouble();
    final spacing = (12 * scale).clamp(10.0, 12.0);
    final fieldSpacing = (10 * scale).clamp(8.0, 10.0);
    final fieldRadius = (24 * scale).clamp(18.0, 24.0).roundToDouble();
    final fieldPadH = (14 * scale).clamp(12.0, 14.0);
    final inputFontSize = (15 * scale).clamp(13.0, 15.0);
    final hintFontSize = (15 * scale).clamp(13.0, 15.0);
    final inputPadV = (10 * scale).clamp(8.0, 10.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(height: 1, color: dividerColor),
        Container(
          padding: EdgeInsets.fromLTRB(
            padH,
            padV,
            padH,
            padV + MediaQuery.of(context).padding.bottom + bottomInset,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: const Color(0xFFD97757).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.edit_rounded,
                  color: const Color(0xFFD97757),
                  size: iconInnerSize,
                ),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: fieldPadH),
                  decoration: BoxDecoration(
                    color: textColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(fieldRadius),
                  ),
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    style: TextStyle(
                      fontSize: inputFontSize,
                      fontFamily: 'SF-UI-Display',
                      color: textColor,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Add a quick note...',
                      hintStyle: TextStyle(
                        color: textColor.withValues(alpha: 0.35),
                        fontFamily: 'SF-UI-Display',
                        fontSize: hintFontSize,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: inputPadV),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSave(),
                  ),
                ),
              ),
              SizedBox(width: fieldSpacing),
              GestureDetector(
                onTap: onSave,
                child: Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD97757),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: iconInnerSize,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

void showDeleteConfirmation({
  required BuildContext context,
  required EpubThemeController themeController,
  required String title,
  required Future<void> Function() onConfirm,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final textColor = themeController.textColor;
      final screenWidth = MediaQuery.sizeOf(ctx).width;
      final scale = (screenWidth / 393).clamp(0.85, 1.0);

      final containerMargin = (16 * scale).clamp(12.0, 16.0);
      final containerPad = (20 * scale).clamp(16.0, 20.0);
      final containerRadius = (20 * scale).clamp(16.0, 20.0).roundToDouble();
      final titleFontSize = (18 * scale).clamp(15.0, 18.0);
      final messageSpacing = (8 * scale).clamp(6.0, 8.0);
      final messageFontSize = (14 * scale).clamp(12.0, 14.0);
      final spacingBefore = (20 * scale).clamp(16.0, 20.0);
      final buttonSpacing = (12 * scale).clamp(10.0, 12.0);
      final buttonPad = (14 * scale).clamp(12.0, 14.0);
      final buttonRadius = (12 * scale).clamp(10.0, 12.0).roundToDouble();

      return Container(
        margin: EdgeInsets.all(containerMargin),
        padding: EdgeInsets.all(containerPad),
        decoration: BoxDecoration(
          color: themeController.backgroundColor,
          borderRadius: BorderRadius.circular(containerRadius),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w700,
                fontFamily: 'SF-UI-Display',
                color: textColor,
              ),
            ),
            SizedBox(height: messageSpacing),
            Text(
              'This action cannot be undone.',
              style: TextStyle(
                fontSize: messageFontSize,
                color: textColor.withValues(alpha: 0.5),
                fontFamily: 'SF-UI-Display',
              ),
            ),
            SizedBox(height: spacingBefore),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textColor,
                      side: BorderSide(color: textColor.withValues(alpha: 0.2)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(buttonRadius),
                      ),
                      padding: EdgeInsets.symmetric(vertical: buttonPad),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                SizedBox(width: buttonSpacing),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await onConfirm();
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(buttonRadius),
                      ),
                      padding: EdgeInsets.symmetric(vertical: buttonPad),
                    ),
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
