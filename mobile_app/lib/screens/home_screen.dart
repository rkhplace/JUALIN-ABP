import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/ui/app_chrome.dart';
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

  void _onCategoryPillTap(String label) {
    widget.onNavigateToProducts?.call(
      category: label == 'Semua' ? null : label,
    );
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
      showTopBar: true,
      showNavbar: true,
      showSearch: true,
      onSearch: _onSearch,
      child: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Hero Banner — Auto-Sliding
            Container(
              height: 180,
              margin: const EdgeInsets.all(16),
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
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Dot indicators
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
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                children: [
                  _buildCategoryPill('Semua'),
                  _buildCategoryPill('Elektronik'),
                  _buildCategoryPill('Fashion'),
                  _buildCategoryPill('Hobi & Olahraga'),
                  _buildCategoryPill('Rumah Tangga'),
                  _buildCategoryPill('Aksesoris'),
                  _buildCategoryPill('Otomotif'),
                ],
              ),
            ),

            // 4. "Lihat semua" link
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => widget.onNavigateToProducts?.call(),
                  child: const Text(
                    'Lihat semua',
                    style: TextStyle(
                      color: Color(0xFFE83030),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            // 5. Product Grid (top 8 featured)
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(48.0),
                child: Center(child: CircularProgressIndicator()),
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
                  childAspectRatio: 0.52,
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
                  );
                },
              ),

            const SizedBox(height: 48),
          ],
        ),
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

  Widget _buildCategoryPill(String label) {
    return GestureDetector(
      onTap: () => _onCategoryPillTap(label),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
