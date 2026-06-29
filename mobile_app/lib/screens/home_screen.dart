import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/ui/app_chrome.dart';
import '../widgets/ui/logo_loader.dart';
import '../widgets/product/product_card.dart';
import '../services/product_service.dart';
import '../models/product.dart';

class HomeScreen extends StatefulWidget {
  /// Called when a category pill or search triggers navigation to Products tab.
  final void Function({String? category, String? search})? onNavigateToProducts;

  const HomeScreen({super.key, this.onNavigateToProducts});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProductService _productService = ProductService();
  List<Product> _products = [];
  bool _isLoading = true;
  String? _errorMessage;

  // ── Banner ─────────────────────────────────────────────────────────────────
  final PageController _bannerController = PageController();
  int _currentBannerPage = 0;
  Timer? _bannerTimer;

  static const List<String> _bannerImages = [
    'assets/images/Banner_1.png',
    'assets/images/Banner_2.png',
    'assets/images/Banner_3.png',
  ];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _startBannerAutoSlide();
    _categoryKeys.addAll(List.generate(_categories.length, (_) => GlobalKey()));
  }

  void _startBannerAutoSlide() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      final nextPage = (_currentBannerPage + 1) % _bannerImages.length;
      _bannerController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    _categoryScrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final products = await _productService.getProducts();
      if (mounted) {
        setState(() {
          _products = products.take(8).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _onSearch(String query) {
    if (query.isEmpty) return;
    widget.onNavigateToProducts?.call(search: query);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount =
        screenWidth > 800 ? 5 : (screenWidth > 600 ? 4 : 2);

    return AppChrome(
      showTopBar: false,
      showNavbar: true,
      showSearch: true,
      onSearch: _onSearch,
      child: RefreshIndicator(
        onRefresh: _fetchProducts,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // 1. Hero Banner — Auto-Sliding
              _buildHeroBanner(),
              // 2. Section Title
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Produk yang mungkin kamu suka',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // 3. Category Pills — tapping navigates to Products tab with filter
              // --- Category row with compact left/right buttons ---
              SizedBox(
                height: 48,
                child: Row(
                  children: [
                    Expanded(
                      child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context)
                            .copyWith(scrollbars: false),
                        child: SingleChildScrollView(
                          controller: _categoryScrollController,
                          scrollDirection: Axis.horizontal,
                          physics: const ClampingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Row(
                            children: List.generate(
                              _categories.length,
                              (index) =>
                                  _buildCategoryPill(_categories[index], index),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 4. Product Grid (top 8 featured)
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(48.0),
                  child: JualinLogoLoader(size: 64),
                )
              else if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: _fetchProducts,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Coba lagi'),
                      )
                    ],
                  ),
                )
              else if (_products.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(48.0),
                  child: Center(child: Text('Belum ada produk.')),
                )
              else
                GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    mainAxisExtent: 314,
                  ),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    return ProductCard(
                      productId: product.id,
                      title: product.title,
                      category: product.categoryName,
                      description: product.description,
                      sellerName: product.sellerName,
                      price: product.price,
                      stock: product.stock,
                      imagePath: product.imagePath,
                      offeredAgoLabel: product.offeredAgoLabel,
                    );
                  },
                ),

              if (!_isLoading && _errorMessage == null && _products.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                  child: Center(
                    child: TextButton(
                      onPressed: () => widget.onNavigateToProducts?.call(),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFE83030),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      child: const Text(
                        'Lihat semua produk',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -18,
            right: 34,
            top: 18,
            bottom: -10,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFE83030).withValues(alpha: 0.08),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(34),
                  topRight: Radius.circular(90),
                  bottomLeft: Radius.circular(90),
                  bottomRight: Radius.circular(34),
                ),
              ),
            ),
          ),
          Positioned(
            right: -10,
            top: -6,
            child: Container(
              width: 118,
              height: 74,
              decoration: BoxDecoration(
                color: const Color(0xFFE83030).withValues(alpha: 0.06),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(64),
                  topRight: Radius.circular(24),
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(64),
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(4),
            child: AspectRatio(
              aspectRatio: 16 / 7,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: PageView.builder(
                      controller: _bannerController,
                      itemCount: _bannerImages.length,
                      onPageChanged: (index) {
                        setState(() => _currentBannerPage = index);
                      },
                      itemBuilder: (context, index) {
                        return Image.asset(
                          _bannerImages[index],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFF910A0A),
                            child: const Center(
                              child: Text(
                                'JUALIN',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _bannerImages.length,
                        (index) => _buildDot(index == _currentBannerPage),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 20 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildCategoryPill(String label, int index) {
    final bool isSelected = _selectedCategoryIndex == index;

    return GestureDetector(
      onTap: () => _onCategoryPillTap(label, index),
      child: Container(
        key: _categoryKeys[index],
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE83030) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFE83030) : Colors.grey[300]!,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  final ScrollController _categoryScrollController = ScrollController();
  final List<String> _categories = [
    'Semua',
    'Elektronik',
    'Fashion',
    'Hobi & Olahraga',
    'Rumah Tangga',
    'Aksesoris',
    'Otomotif',
  ];
  final List<GlobalKey> _categoryKeys = [];
  int _selectedCategoryIndex = 0;
  void _scrollToCategory(int index) {
    final context = _categoryKeys[index].currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 250),
        alignment: 0.5,
        curve: Curves.easeInOut,
      );
    }
  }

  void _onCategoryPillTap(String label, int index) {
    setState(() {
      _selectedCategoryIndex = index;
    });
    _scrollToCategory(index);

    widget.onNavigateToProducts?.call(
      category: label == 'Semua' ? null : label,
    );
  }
}
