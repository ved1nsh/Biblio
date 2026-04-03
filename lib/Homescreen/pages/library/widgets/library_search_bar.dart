import 'package:flutter/material.dart';

class LibrarySearchBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;
  final FocusNode? focusNode;

  const LibrarySearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hintText = 'Search books and shelves...',
    this.focusNode,
  });

  @override
  State<LibrarySearchBar> createState() => _LibrarySearchBarState();
}

class _LibrarySearchBarState extends State<LibrarySearchBar> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onControllerChange);
  }

  void _onFocusChange() => setState(() {});
  void _onControllerChange() => setState(() {});

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    widget.controller.removeListener(_onControllerChange);
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  bool get _isSearchActive =>
      _focusNode.hasFocus || widget.controller.text.isNotEmpty;

  void _clearSearch() {
    widget.controller.clear();
    widget.onChanged('');
    _focusNode.unfocus();
  }

  Future<bool> _onWillPop() async {
    if (_focusNode.hasFocus) {
      _focusNode.unfocus();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final padH = (24 * scale).clamp(18.0, 24.0);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: padH),
        child: TextField(
          controller: widget.controller,
          onChanged: widget.onChanged,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: TextStyle(
              fontFamily: 'SF-UI-Display',
              color: Colors.black.withValues(alpha: 0.4),
            ),
            prefixIcon:
                _isSearchActive
                    ? GestureDetector(
                      onTap: _clearSearch,
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.black.withValues(alpha: 0.6),
                        size: 20,
                      ),
                    )
                    : Icon(
                      Icons.search,
                      color: Colors.black.withValues(alpha: 0.4),
                    ),
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
        ),
      ),
    );
  }
}
