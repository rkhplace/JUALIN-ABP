import 'package:flutter/material.dart';
import 'package:mobile_app/screens/home_screen.dart';
import 'package:mobile_app/screens/products_screen.dart';
import 'package:mobile_app/screens/chat_screen.dart';
import 'package:mobile_app/screens/profile_screen.dart';
import 'package:mobile_app/screens/purchase_history_screen.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/widgets/ui/login_required_dialog.dart';
import 'package:mobile_app/services/chat_service.dart';
import 'package:mobile_app/widgets/ui/feature_tour.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();
  int _currentIndex = 0;
  int _chatUnreadCount = 0;
  bool _checkedOnboarding = false;
  final GlobalKey _homeTourKey = GlobalKey();
  final GlobalKey _historyTourKey = GlobalKey();
  final GlobalKey _chatTourKey = GlobalKey();
  final GlobalKey _profileTourKey = GlobalKey();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_checkedOnboarding) return;
    _checkedOnboarding = true;
    final arguments = ModalRoute.of(context)?.settings.arguments;
    final showOnboarding =
        arguments is Map && arguments['showOnboarding'] == true;
    if (showOnboarding) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showOnboarding());
    }
  }

  Future<void> _showOnboarding() async {
    if (!mounted) return;
    await FeatureTour.show(
      context,
      steps: [
        FeatureTourStep(
          targetKey: _homeTourKey,
          title: 'Mulai dari Beranda',
          description: 'Cari produk dan lihat promo terbaru dari sini.',
          icon: Icons.home_rounded,
        ),
        FeatureTourStep(
          targetKey: _chatTourKey,
          title: 'Hubungi penjual',
          description: 'Tanyakan detail produk langsung melalui Pesan.',
          icon: Icons.chat_bubble_rounded,
        ),
        FeatureTourStep(
          targetKey: _profileTourKey,
          title: 'Atur akun',
          description: 'Lengkapi profil dan alamat untuk memudahkan checkout.',
          icon: Icons.person_rounded,
        ),
      ],
    );
  }

  /// Opens the product list from Home search/category entry points.
  void _navigateToProducts({String? category, String? search}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductsScreen(
          initialCategory: category,
          initialSearch: search,
        ),
      ),
    );
  }

  Future<void> _handleTabTap(int index) async {
    if (index == 1 || index == 2 || index == 3) {
      final isLoggedIn = await _authService.isLoggedIn();
      if (!mounted) return;

      if (!isLoggedIn) {
        final message = switch (index) {
          1 => 'Silakan login terlebih dahulu untuk melihat riwayat transaksi.',
          2 => 'Silakan login terlebih dahulu untuk membuka chat.',
          _ => 'Silakan login terlebih dahulu untuk mengakses akun.',
        };
        final shouldLogin = await showLoginRequiredDialog(
          context,
          message: message,
        );
        if (!mounted) return;
        if (shouldLogin) Navigator.pushNamed(context, '/login');
        return;
      }
    }

    setState(() {
      _currentIndex = index;
      if (index == 2) {
        // user membuka Chat -> clear local badge
        _chatUnreadCount = 0;
      }
    });

    // jika pindah ke tab selain Chat, refresh hitungan unread
    if (index != 2) _updateChatUnreadCount();
  }

  @override
  void initState() {
    super.initState();
    _updateChatUnreadCount();
  }

  Future<void> _updateChatUnreadCount() async {
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (!isLoggedIn) {
        if (mounted) setState(() => _chatUnreadCount = 0);
        return;
      }

      final idAndRole = await _authService.getUserIdAndRole();
      final currentUserId = idAndRole['id'] as int? ?? 0;
      final rooms = await _chatService.getChatRooms();

      final count = rooms
          .where((r) =>
              r.latestMessage != null &&
              !r.latestMessage!.isRead &&
              r.latestMessage!.senderId != currentUserId)
          .length;

      if (mounted) setState(() => _chatUnreadCount = count);
    } catch (_) {
      if (mounted) setState(() => _chatUnreadCount = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(onNavigateToProducts: _navigateToProducts),
      _currentIndex == 1 ? const PurchaseHistoryScreen() : const SizedBox(),
      const ChatScreen(),
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
              BottomNavigationBarItem(
                icon: SizedBox(
                    key: _homeTourKey, child: const Icon(Icons.home_outlined)),
                activeIcon: const Icon(Icons.home),
                label: 'Beranda',
              ),
              BottomNavigationBarItem(
                icon: SizedBox(
                    key: _historyTourKey,
                    child: const Icon(Icons.receipt_long_outlined)),
                activeIcon: const Icon(Icons.receipt_long),
                label: 'Riwayat',
              ),
              BottomNavigationBarItem(
                icon: Stack(
                  key: _chatTourKey,
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.chat_bubble_outline),
                    if (_chatUnreadCount > 0)
                      Positioned(
                        right: -8,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE83030),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _chatUnreadCount > 99 ? '99+' : '$_chatUnreadCount',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
                activeIcon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.chat_bubble),
                    if (_chatUnreadCount > 0)
                      Positioned(
                        right: -8,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE83030),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _chatUnreadCount > 99 ? '99+' : '$_chatUnreadCount',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
                label: 'Pesan',
              ),
              BottomNavigationBarItem(
                icon: SizedBox(
                    key: _profileTourKey,
                    child: const Icon(Icons.person_outline)),
                activeIcon: const Icon(Icons.person),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
