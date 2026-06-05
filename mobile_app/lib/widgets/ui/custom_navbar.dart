import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'logo.dart';

class CustomNavbar extends StatefulWidget implements PreferredSizeWidget {
  final bool showSearch;
  final bool showLogo;
  final ValueChanged<String>? onSearch;
  final bool scrolled;

  const CustomNavbar({
    super.key,
    this.showSearch = true,
    this.showLogo = true,
    this.onSearch,
    this.scrolled = false,
  });

  @override
  State<CustomNavbar> createState() => _CustomNavbarState();

  @override
  Size get preferredSize => const Size.fromHeight(52);
}

class _CustomNavbarState extends State<CustomNavbar> {
  final TextEditingController _searchController = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _hasText = _searchController.text.isNotEmpty);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _submitSearch() {
    final query = _searchController.text.trim();
    widget.onSearch?.call(query);
    FocusScope.of(context).unfocus();
  }

  void _clearSearch() {
    _searchController.clear();
    widget.onSearch?.call('');
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        widget.scrolled ? Colors.white.withValues(alpha: 0.78) : Colors.white;
    final dividerColor = widget.scrolled
        ? Colors.black.withValues(alpha: 0.10)
        : Colors.grey.withValues(alpha: 0.18);

    return AppBar(
      toolbarHeight: 52,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      centerTitle: false,
      titleSpacing: 14,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: widget.scrolled ? 10 : 0,
            sigmaY: widget.scrolled ? 10 : 0,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border(
                bottom: BorderSide(color: dividerColor, width: 1),
              ),
              boxShadow: widget.scrolled
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
          ),
        ),
      ),
      title: Row(
        children: [
          if (widget.showLogo)
            const Logo(
              width: 88,
              height: 38,
              alignment: Alignment.centerLeft,
            ),
          if (widget.showSearch) ...[
            if (widget.showLogo) const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 32,
                decoration: BoxDecoration(
                  color: widget.scrolled
                      ? Colors.white.withValues(alpha: 0.86)
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.scrolled
                        ? Colors.black.withValues(alpha: 0.12)
                        : Colors.grey[300]!,
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 10),
                    Icon(Icons.search, size: 20, color: Colors.grey[500]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _submitSearch(),
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Cari produk...',
                          hintStyle: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 13,
                              fontWeight: FontWeight.w400),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 9),
                        ),
                      ),
                    ),
                    if (_hasText)
                      GestureDetector(
                        onTap: _clearSearch,
                        child: Icon(Icons.close,
                            size: 18, color: Colors.grey[500]),
                      ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (widget.showSearch) ...[
          IconButton(
            icon:
                const Icon(Icons.notifications_outlined, color: Colors.black87),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ]
      ],
    );
  }
}
