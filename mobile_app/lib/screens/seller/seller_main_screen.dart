import 'package:flutter/material.dart';
import 'package:mobile_app/screens/seller_dashboard_screen.dart';
import 'package:mobile_app/screens/seller_products_screen.dart';
import 'package:mobile_app/screens/profile_screen.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/services/chat_service.dart';
import 'package:mobile_app/services/seller_service.dart';
import 'seller_orders_screen.dart';
import 'package:mobile_app/screens/chat_screen.dart';

class SellerMainScreen extends StatefulWidget {
  const SellerMainScreen({super.key});

  @override
  State<SellerMainScreen> createState() => _SellerMainScreenState();
}

class _SellerMainScreenState extends State<SellerMainScreen> {
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();
  final SellerService _sellerService = SellerService();

  int _currentIndex = 0;
  bool _hasUnreadChat = false;
  bool _hasProductAlert = false;
  bool _hasOrderAlert = false;

  @override
  void initState() {
    super.initState();
    _refreshNavAlerts();
  }

  Future<void> _handleTabTap(int index) async {
    setState(() {
      _currentIndex = index;
      if (index == 1) _hasUnreadChat = false;
      if (index == 2) _hasProductAlert = false;
      if (index == 3) _hasOrderAlert = false;
    });

    _refreshNavAlerts();
  }

  Future<void> _refreshNavAlerts() async {
    await Future.wait([
      _refreshChatAlert(),
      _refreshProductAlert(),
      _refreshOrderAlert(),
    ]);
  }

  Future<void> _refreshChatAlert() async {
    try {
      final idAndRole = await _authService.getUserIdAndRole();
      final currentUserId = idAndRole['id'] as int? ?? 0;
      final rooms = await _chatService.getChatRooms();
      final hasUnread = rooms.any(
        (room) =>
            room.latestMessage != null &&
            !room.latestMessage!.isRead &&
            room.latestMessage!.senderId != currentUserId,
      );

      if (mounted && _currentIndex != 1) {
        setState(() => _hasUnreadChat = hasUnread);
      }
    } catch (_) {
      if (mounted) setState(() => _hasUnreadChat = false);
    }
  }

  Future<void> _refreshProductAlert() async {
    try {
      final products = await _sellerService.getSellerProducts();
      final hasLowStock = products.any((product) => product.stock <= 5);

      if (mounted && _currentIndex != 2) {
        setState(() => _hasProductAlert = hasLowStock);
      }
    } catch (_) {
      if (mounted) setState(() => _hasProductAlert = false);
    }
  }

  Future<void> _refreshOrderAlert() async {
    try {
      final orders = await _sellerService.getSellerOrders();
      final hasWaitingCod = orders.any(
        (order) =>
            (order['status'] ?? '').toString().toLowerCase() == 'waiting_cod',
      );

      if (mounted && _currentIndex != 3) {
        setState(() => _hasOrderAlert = hasWaitingCod);
      }
    } catch (_) {
      if (mounted) setState(() => _hasOrderAlert = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const SellerDashboardScreen(),
      const ChatScreen(fallbackRoute: '/seller_main'),
      const SellerProductsScreen(),
      const SellerOrdersScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 22,
              spreadRadius: -8,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _handleTabTap,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 0,
            selectedItemColor: const Color(0xFFE83030),
            unselectedItemColor: const Color(0xFF8C8C8C),
            selectedFontSize: 12,
            unselectedFontSize: 11,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              height: 1.45,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard),
                label: 'Dasbor',
              ),
              BottomNavigationBarItem(
                icon: _navIconWithDot(
                  Icons.chat_bubble_outline,
                  showDot: _hasUnreadChat,
                ),
                activeIcon: _navIconWithDot(
                  Icons.chat_bubble,
                  showDot: _hasUnreadChat,
                ),
                label: 'Pesan',
              ),
              BottomNavigationBarItem(
                icon: _navIconWithDot(
                  Icons.inventory_2_outlined,
                  showDot: _hasProductAlert,
                ),
                activeIcon: _navIconWithDot(
                  Icons.inventory_2,
                  showDot: _hasProductAlert,
                ),
                label: 'Produk',
              ),
              BottomNavigationBarItem(
                icon: _navIconWithDot(
                  Icons.receipt_long_outlined,
                  showDot: _hasOrderAlert,
                ),
                activeIcon: _navIconWithDot(
                  Icons.receipt_long,
                  showDot: _hasOrderAlert,
                ),
                label: 'Pesanan',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navIconWithDot(IconData icon, {required bool showDot}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (showDot)
          Positioned(
            right: -3,
            top: -5,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: const Color(0xFFE83030),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.4),
              ),
            ),
          ),
      ],
    );
  }
}
