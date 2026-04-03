import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:biblio/core/models/shelf_model.dart';
import 'package:biblio/core/providers/shelf_provider.dart';

class EditShelfDialog extends ConsumerStatefulWidget {
  final Shelf shelf;

  const EditShelfDialog({super.key, required this.shelf});

  @override
  ConsumerState<EditShelfDialog> createState() => _EditShelfDialogState();
}

class _EditShelfDialogState extends ConsumerState<EditShelfDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late Color _selectedColor;
  bool _isSaving = false;

  final List<Map<String, Color>> _colorPairs = const [
    {'bg': Color(0xFFE8F5E9), 'icon': Color(0xFF2D5A3D)}, // Green
    {'bg': Color(0xFFE3F2FD), 'icon': Color(0xFF1565C0)}, // Blue
    {'bg': Color(0xFFFCE4EC), 'icon': Color(0xFFD97A73)}, // Pink
    {'bg': Color(0xFFFFF3E0), 'icon': Color(0xFFD9A373)}, // Orange
    {'bg': Color(0xFFF3E5F5), 'icon': Color(0xFF9B8FD9)}, // Purple
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.shelf.name);
    _descriptionController = TextEditingController(
      text: widget.shelf.description ?? '',
    );
    _selectedColor = Color(
      int.parse(widget.shelf.color.replaceFirst('#', '0xFF')),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Color _darkenColor(Color color, [double amount = 0.2]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final titleSize = (22 * scale).clamp(16.0, 22.0);
    final padH = (24 * scale).clamp(18.0, 24.0);

    return Container(
      padding: EdgeInsets.only(
        left: padH,
        right: padH,
        top: padH,
        bottom: MediaQuery.of(context).viewInsets.bottom + padH,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFCF9F5),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          Text(
            'Edit Shelf',
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w700,
              fontFamily: 'SF-UI-Display',
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),

          // Shelf Name
          const Text(
            'Shelf Name',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'SF-UI-Display',
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'e.g., Science Fiction, Favorites',
              hintStyle: TextStyle(
                fontFamily: 'SF-UI-Display',
                color: Colors.black.withValues(alpha: 0.4),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            style: const TextStyle(fontFamily: 'SF-UI-Display'),
          ),
          const SizedBox(height: 16),

          // Description (optional)
          const Text(
            'Description (Optional)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'SF-UI-Display',
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Add a description...',
              hintStyle: TextStyle(
                fontFamily: 'SF-UI-Display',
                color: Colors.black.withValues(alpha: 0.4),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            style: const TextStyle(fontFamily: 'SF-UI-Display'),
          ),
          const SizedBox(height: 16),

          // Color Picker
          const Text(
            'Choose Color',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'SF-UI-Display',
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children:
                _colorPairs.map((pair) {
                  final bgColor = pair['bg']!;
                  final iconColor = pair['icon']!;
                  final isSelected = _selectedColor == iconColor;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = iconColor;
                      });
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              isSelected
                                  ? Colors.black
                                  : _darkenColor(bgColor, 0.2),
                          width: isSelected ? 2.5 : 1.5,
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 24),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSaving ? null : _updateShelf,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD97A73),
                disabledBackgroundColor: const Color(
                  0xFFD97A73,
                ).withValues(alpha: 0.6),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child:
                  _isSaving
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'SF-UI-Display',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _updateShelf() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a shelf name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final shelfService = ref.read(shelfServiceProvider);

      await shelfService.updateShelf(
        shelfId: widget.shelf.id,
        name: _nameController.text.trim(),
        description:
            _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
        color:
            '#${_selectedColor.value.toRadixString(16).padLeft(8, '0').substring(2)}',
      );

      ref.invalidate(allShelvesProvider);

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_nameController.text} updated!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update shelf: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
