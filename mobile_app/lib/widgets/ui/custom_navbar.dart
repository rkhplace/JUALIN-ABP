import 'dart:ui';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/notification_service.dart';
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
  final NotificationService _notificationService = NotificationService();
  int _unreadCount = 0;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _hasText = _searchController.text.isNotEmpty);
    });
    _fetchNotificationCount();
    // Poll every 10 seconds to keep the badge updated even if we navigate back
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _fetchNotificationCount();
    });
  }

  Future<void> _fetchNotificationCount() async {
    try {
      final data = await _notificationService.getNotifications();
      if (mounted) {
        setState(() {
          _unreadCount = (data['unread_count'] as num?)?.toInt() ?? 0;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
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
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined, color: Colors.black87),
                if (_unreadCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE83030),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        _unreadCount > 99 ? '99+' : '$_unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => _showNotificationPopup(context),
          ),
          const SizedBox(width: 8),
        ]
      ],
    );
  }

  void _showNotificationPopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Notifikasi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<Map<String, dynamic>>(
                  future: _notificationService.getNotifications(markRead: true),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Color(0xFFE83030)),
                      );
                    }
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text(
                          'Gagal memuat notifikasi.',
                          style: TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    final dataMap = snapshot.data ?? {};
                    final items = (dataMap['data'] as List<dynamic>?) ?? [];

                    // Reset unread count on view
                    if (_unreadCount > 0) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) setState(() => _unreadCount = 0);
                      });
                    }

                    if (items.isEmpty) {
                      return const Center(
                        child: Text('Belum ada notifikasi', style: TextStyle(color: Colors.black54)),
                      );
                    }

                    return ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 24),
                      itemBuilder: (context, index) {
                        final item = items[index] as Map<String, dynamic>;
                        final type = item['type'] ?? '';
                        IconData iconData = Icons.notifications;
                        Color iconColor = Colors.blue;

                        if (type == 'order') {
                          iconData = Icons.shopping_bag;
                          iconColor = Colors.orange;
                        } else if (type == 'payment') {
                          iconData = Icons.payment;
                          iconColor = Colors.green;
                        } else if (type == 'chat') {
                          iconData = Icons.chat;
                          iconColor = Colors.purple;
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: iconColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(iconData, color: iconColor, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item['title'] ?? '',
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        item['created_at'] ?? '',
                                        style: const TextStyle(fontSize: 11, color: Colors.black45),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item['body'] ?? '',
                                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
