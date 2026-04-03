import 'dart:io';
import 'package:flutter/material.dart';

/// The result from the scan quote choice dialog.
enum ScanQuoteChoice { saveAsImage, saveAsText }

/// Shows the captured image and lets the user choose:
///   • "Save as Image" — upload the cropped image to Supabase Storage
///   • "Save as Text (OCR)" — run OCR and open the editable text screen
class ScanQuoteChoiceDialog extends StatelessWidget {
  final String imagePath;

  const ScanQuoteChoiceDialog({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFFCF9F5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image preview
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Image.file(
              File(imagePath),
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Save this quote',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'SF-UI-Display',
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Choose how you\'d like to save this scanned quote.',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'SF-UI-Display',
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 24),

                // Save as Image
                _ChoiceButton(
                  icon: Icons.image_rounded,
                  label: 'Save as Image',
                  description: 'Keep the original photo of the quote',
                  color: const Color(0xFF8B4513),
                  onTap:
                      () => Navigator.pop(context, ScanQuoteChoice.saveAsImage),
                ),

                const SizedBox(height: 12),

                // Save as Text (OCR)
                _ChoiceButton(
                  icon: Icons.text_fields_rounded,
                  label: 'Save as Text (OCR)',
                  description: 'Extract text from the image & edit it',
                  color: const Color(0xFFD97A73),
                  onTap:
                      () => Navigator.pop(context, ScanQuoteChoice.saveAsText),
                ),

                const SizedBox(height: 16),

                // Cancel
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 15,
                      fontFamily: 'SF-UI-Display',
                      fontWeight: FontWeight.w600,
                      color: Colors.black45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _ChoiceButton({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
            borderRadius: BorderRadius.circular(14),
            color: color.withOpacity(0.06),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'SF-UI-Display',
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'SF-UI-Display',
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: color.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
