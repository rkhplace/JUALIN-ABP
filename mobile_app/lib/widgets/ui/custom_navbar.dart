import 'package:flutter/material.dart';
import 'logo.dart';

class CustomNavbar extends StatefulWidget implements PreferredSizeWidget {
  final bool showSearch;
  final ValueChanged<String>? onSearch;

  const CustomNavbar({super.key, this.showSearch = true, this.onSearch});

  @override
  State<CustomNavbar> createState() => _CustomNavbarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
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
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 16,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: Colors.grey[200], height: 1),
      ),
      title: Row(
        children: [
          const Logo(
            width: 92,
            height: 42,
            alignment: Alignment.centerLeft,
          ),
          if (widget.showSearch) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
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
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    if (_hasText)
                      GestureDetector(
                        onTap: _clearSearch,
                        child: Icon(Icons.close, size: 18, color: Colors.grey[500]),
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
            icon: const Icon(Icons.notifications_outlined,
                color: Colors.black87),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ]
      ],
    );
  }
}
