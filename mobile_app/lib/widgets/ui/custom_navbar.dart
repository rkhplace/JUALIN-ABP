import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'logo.dart';
import 'notification_button.dart';

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
    const backgroundColor = Colors.white;
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
          filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: backgroundColor,
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
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border:
                      Border.all(color: Colors.black.withValues(alpha: 0.06)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 16,
                      spreadRadius: -6,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: const Color(0xFFE83030).withValues(alpha: 0.035),
                      blurRadius: 14,
                      spreadRadius: -8,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    Icon(Icons.search, size: 19, color: Colors.grey[500]),
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
                              const EdgeInsets.symmetric(vertical: 10),
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
          const NotificationButton(),
          const SizedBox(width: 8),
        ]
      ],
    );
  }
}
