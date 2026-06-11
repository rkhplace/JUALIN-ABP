import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/notification_service.dart';
import '../../screens/chat_screen.dart';

class NotificationButton extends StatefulWidget {
  final Color iconColor;
  final Color badgeColor;
  final Color badgeTextColor;

  const NotificationButton({
    super.key,
    this.iconColor = Colors.black87,
    this.badgeColor = const Color(0xFFE83030),
    this.badgeTextColor = Colors.white,
  });

  @override
  State<NotificationButton> createState() => _NotificationButtonState();
}

class _NotificationButtonState extends State<NotificationButton> {
  final NotificationService _notificationService = NotificationService();
  int _unreadCount = 0;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _fetchNotificationCount();
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _fetchNotificationCount();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchNotificationCount() async {
    try {
      final data = await _notificationService.getNotifications();
      if (!mounted) return;
      setState(() {
        _unreadCount = (data['unread_count'] as num?)?.toInt() ?? 0;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.notifications_outlined, color: widget.iconColor),
          if (_unreadCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: widget.badgeColor,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  _unreadCount > 99 ? '99+' : '$_unreadCount',
                  style: TextStyle(
                    color: widget.badgeTextColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      onPressed: () => _showNotificationPopup(context),
    );
  }

  void _showNotificationPopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.68,
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<Map<String, dynamic>>(
                  future: _notificationService.getNotifications(markRead: true),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child:
                            CircularProgressIndicator(color: Color(0xFFE83030)),
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

                    if (_unreadCount > 0) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) setState(() => _unreadCount = 0);
                      });
                    }

                    if (items.isEmpty) {
                      return const Center(
                        child: Text(
                          'Belum ada notifikasi',
                          style: TextStyle(color: Colors.black54),
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 24),
                      itemBuilder: (context, index) {
                        final item = Map<String, dynamic>.from(
                          items[index] as Map,
                        );
                        final type = item['type']?.toString() ?? '';
                        final visual = _notificationVisual(type);

                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _openNotificationTarget(context, item),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: visual.color.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    visual.icon,
                                    color: visual.color,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item['title']?.toString() ?? '',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            item['created_at']?.toString() ??
                                                '',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.black45,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item['body']?.toString() ?? '',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black87,
                                        ),
                                        maxLines: type == 'product_deleted' ||
                                                type == 'account'
                                            ? 5
                                            : 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
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

  _NotificationVisual _notificationVisual(String type) {
    switch (type) {
      case 'order':
        return const _NotificationVisual(
          Icons.shopping_bag,
          Colors.orange,
        );
      case 'payment':
        return const _NotificationVisual(Icons.payment, Colors.green);
      case 'chat':
        return const _NotificationVisual(Icons.chat, Colors.purple);
      case 'product_deleted':
        return const _NotificationVisual(
          Icons.inventory_2_outlined,
          Color(0xFFE83030),
        );
      case 'account':
        return const _NotificationVisual(Icons.person_off_outlined, Colors.red);
      default:
        return const _NotificationVisual(Icons.notifications, Colors.blue);
    }
  }

  void _openNotificationTarget(
    BuildContext context,
    Map<String, dynamic> item,
  ) {
    final targetType = item['target_type']?.toString();
    final targetId = item['target_id'] is num
        ? (item['target_id'] as num).toInt()
        : int.tryParse(item['target_id']?.toString() ?? '');
    Navigator.pop(context);

    if (targetType == 'chat_room' && targetId != null && targetId > 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatRoomScreen(
            roomId: targetId,
            roomName: 'Chat',
          ),
        ),
      );
      return;
    }

    switch (targetType ?? item['type']?.toString()) {
      case 'order':
      case 'payment':
        Navigator.pushNamed(context, '/purchase_history');
        break;
      case 'wallet':
        Navigator.pushNamed(context, '/wallet');
        break;
      default:
        break;
    }
  }
}

class _NotificationVisual {
  final IconData icon;
  final Color color;

  const _NotificationVisual(this.icon, this.color);
}
