import 'package:flutter/material.dart';

class SortOptionsSheet extends StatelessWidget {
  final String currentSort;
  final ValueChanged<String> onSortChanged;

  const SortOptionsSheet({
    super.key,
    required this.currentSort,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final titleSize = (20 * scale).clamp(16.0, 20.0);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sort by',
            style: TextStyle(
              fontSize: titleSize,
              fontFamily: 'SF-UI-Display',
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _buildSortOption(context, label: 'Date Added', value: 'date'),
          _buildSortOption(context, label: 'Title', value: 'title'),
          _buildSortOption(context, label: 'Author', value: 'author'),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSortOption(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final isSelected = currentSort == value;

    return InkWell(
      onTap: () {
        onSortChanged(value);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: currentSort,
              onChanged: (newValue) {
                onSortChanged(newValue!);
                Navigator.pop(context);
              },
              activeColor: const Color(0xFFD97A73),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'SF-UI-Display',
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
