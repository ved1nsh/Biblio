// Displays the journal timeline view with highlights, quotes, and notes.
// Uses JournalEntryCards for rendering and JournalDataController for data.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/journal_entry.dart';
import 'journal_entry_cards.dart';

class JournalView extends StatelessWidget {
  final List<JournalEntry> entries;
  final bool isLoading;
  final Color textColor;
  final void Function(JournalEntry) onEntryTap;
  final void Function(JournalEntry) onDeleteHighlight;
  final void Function(JournalEntry) onDeleteNote;

  const JournalView({
    super.key,
    required this.entries,
    required this.isLoading,
    required this.textColor,
    required this.onEntryTap,
    required this.onDeleteHighlight,
    required this.onDeleteNote,
  });

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDay = DateTime(date.year, date.month, date.day);

    if (entryDay == today) return 'Today';
    if (entryDay == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    }
    if (now.difference(entryDay).inDays < 7) {
      return DateFormat('EEEE').format(date);
    }
    return DateFormat('MMM d').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(Color(0xFFD97757)),
        ),
      );
    }

    if (entries.isEmpty) {
      return _buildEmptyState(scale);
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        (24 * scale).clamp(16.0, 24.0),
        (20 * scale).clamp(16.0, 20.0),
        (20 * scale).clamp(16.0, 20.0),
        (100 * scale).clamp(80.0, 100.0),
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final isLast = index == entries.length - 1;
        return _buildTimelineRow(entry, isLast, scale);
      },
    );
  }

  Widget _buildEmptyState(double scale) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all((32 * scale).clamp(24.0, 32.0)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_stories_rounded,
              size: (64 * scale).clamp(50.0, 64.0),
              color: textColor.withValues(alpha: 0.2),
            ),
            SizedBox(height: (16 * scale).clamp(12.0, 16.0)),
            Text(
              'No journal entries yet',
              style: TextStyle(
                fontSize: (18 * scale).clamp(15.0, 18.0),
                fontWeight: FontWeight.w600,
                fontFamily: 'SF-UI-Display',
                color: textColor.withValues(alpha: 0.6),
              ),
            ),
            SizedBox(height: (8 * scale).clamp(6.0, 8.0)),
            Text(
              'Highlight text or add notes\nwhile reading to build your journal.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: (14 * scale).clamp(12.0, 14.0),
                fontFamily: 'SF-UI-Display',
                color: textColor.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineRow(JournalEntry entry, bool isLast, double scale) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: (24 * scale).clamp(20.0, 24.0),
            child: Column(
              children: [
                Container(
                  width: (14 * scale).clamp(12.0, 14.0),
                  height: (14 * scale).clamp(12.0, 14.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFD97757).withValues(alpha: 0.2),
                    border: Border.all(
                      color: const Color(0xFFD97757),
                      width: 2.5,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: textColor.withValues(alpha: 0.12),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: (14 * scale).clamp(10.0, 14.0)),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: (28 * scale).clamp(22.0, 28.0)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMetaRow(entry, scale),
                  SizedBox(height: (10 * scale).clamp(8.0, 10.0)),
                  _buildEntryCard(entry, scale),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(JournalEntry entry, double scale) {
    final pagePart = entry.page > 0 ? 'Pg ${entry.page}' : null;
    final datePart = _formatDate(entry.date);
    final metaFontSize = (13 * scale).clamp(11.0, 13.0);

    return Row(
      children: [
        if (pagePart != null)
          Text(
            '$pagePart · ',
            style: TextStyle(
              fontSize: metaFontSize,
              fontWeight: FontWeight.w700,
              fontFamily: 'SF-UI-Display',
              color: textColor.withValues(alpha: 0.55),
            ),
          ),
        Text(
          datePart,
          style: TextStyle(
            fontSize: metaFontSize,
            fontFamily: 'SF-UI-Display',
            color: textColor.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }

  Widget _buildEntryCard(JournalEntry entry, double scale) {
    switch (entry.type) {
      case JournalEntryType.highlight:
        return HighlightCard(
          entry: entry,
          textColor: textColor,
          onTap: () => onEntryTap(entry),
          onDelete: () => onDeleteHighlight(entry),
          scale: scale,
        );
      case JournalEntryType.quote:
        return QuoteCard(
          entry: entry,
          textColor: textColor,
          onTap: () => onEntryTap(entry),
          onDelete: () => onDeleteNote(entry),
          scale: scale,
        );
      case JournalEntryType.note:
        return NoteCard(
          entry: entry,
          textColor: textColor,
          onTap: () => onEntryTap(entry),
          onDelete: () => onDeleteNote(entry),
          scale: scale,
        );
    }
  }
}
