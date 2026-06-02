import 'package:flutter/material.dart';
import 'package:mobile_app/screens/home_screen.dart';
import 'package:mobile_app/screens/products_screen.dart';
import 'package:mobile_app/screens/chat_screen.dart';
import 'package:mobile_app/screens/profile_screen.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/widgets/ui/login_required_dialog.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final AuthService _authService = AuthService();
  int _currentIndex = 0;

  // Shared filter state for ProductsScreen — set by HomeScreen
  String? _productsCategory;
  String? _productsSearch;

  /// Called by HomeScreen when a category pill or search is triggered.
  void _navigateToProducts({String? category, String? search}) {
    setState(() {
      _productsCategory = category;
      _productsSearch = search;
      _currentIndex = 1; // switch to Products tab
    });
  }

  Future<void> _handleTabTap(int index) async {
    if (index == 2 || index == 3) {
      final isLoggedIn = await _authService.isLoggedIn();
      if (!mounted) return;

      if (!isLoggedIn) {
        final message = index == 2
            ? 'Silakan login terlebih dahulu untuk membuka chat.'
            : 'Silakan login terlebih dahulu untuk mengakses akun.';
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
      if (index == 1) {
        _productsCategory = null;
        _productsSearch = null;
      }
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(onNavigateToProducts: _navigateToProducts),
      ProductsScreen(
        key: ValueKey('${_productsCategory}_$_productsSearch'),
        initialCategory: _productsCategory,
        initialSearch: _productsSearch,
      ),
      const ChatScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _handleTabTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFE83030),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category_outlined),
            activeIcon: Icon(Icons.category),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
