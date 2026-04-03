import 'package:flutter/material.dart';

class AddBookOptionsDialog extends StatelessWidget {
  final VoidCallback onImportFile;
  final VoidCallback onAddManually;

  const AddBookOptionsDialog({
    super.key,
    required this.onImportFile,
    required this.onAddManually,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final titleSize = (20 * scale).clamp(16.0, 20.0);
    final padH = (24 * scale).clamp(16.0, 24.0);
    final gap20 = (20 * scale).clamp(16.0, 20.0);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFCF9F5),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(padH, 8, padH, padH),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Text(
              'Add to Library',
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.w700,
                fontFamily: 'SF-UI-Display',
                color: Colors.black87,
              ),
            ),
            SizedBox(height: gap20),

            // Import File Button
            _buildOptionButton(
              icon: Icons.insert_drive_file_outlined,
              label: 'Import File (PDF, EPUB)',
              onTap: () {
                Navigator.pop(context);
                onImportFile();
              },
              isPrimary: true,
            ),
            const SizedBox(height: 12),

            // Add Manually Button
            _buildOptionButton(
              icon: Icons.edit_outlined,
              label: 'Add Manually (Physical, Wishlist)',
              onTap: () {
                Navigator.pop(context);
                onAddManually();
              },
              isPrimary: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          decoration: BoxDecoration(
            color: isPrimary ? const Color(0xFFD97A73) : Colors.white,
            borderRadius: BorderRadius.circular(50),
            border:
                isPrimary
                    ? null
                    : Border.all(
                      color: Colors.black.withValues(alpha: 0.15),
                      width: 1.5,
                    ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isPrimary ? Colors.white : Colors.black87,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontFamily: 'SF-UI-Display',
                  fontWeight: FontWeight.w600,
                  color: isPrimary ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
