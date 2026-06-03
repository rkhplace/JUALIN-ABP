import 'package:flutter/material.dart';
import '../widgets/ui/app_chrome.dart';
import '../widgets/product/product_card.dart';
import '../services/product_service.dart';
import '../models/product.dart';

// Mapping: display label → API value (LOWER case, matches backend category column)
const Map<String, String?> _categoryMap = {
  'Semua': null,
  'Elektronik': 'elektronik',
  'Fashion': 'fashion',
  'Hobi & Olahraga': 'hobi & olahraga',
  'Rumah Tangga': 'rumah tangga',
  'Aksesoris': 'aksesoris',
  'Otomotif': 'otomotif',
};

class ProductsScreen extends StatefulWidget {
  /// Pre-selected category label (e.g. "Elektronik") passed from home screen pills.
  final String? initialCategory;

  /// Pre-filled search query passed from home screen search bar.
  final String? initialSearch;

  const ProductsScreen({
    super.key,
    this.initialCategory,
    this.initialSearch,
  });

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final ProductService _productService = ProductService();
  List<Product> _products = [];
  bool _isLoading = true;
  String? _errorMessage;

  String _selectedLabel = 'Semua'; // display label
  String _searchQuery = '';

  // New: controllers & helpers for scrollable pills
  final ScrollController _prodCategoryScrollController = ScrollController();
  final List<GlobalKey> _prodCategoryKeys = [];
  late final List<String> _prodCategories;
  int _prodSelectedCategoryIndex = 0;

  @override
  void initState() {
    super.initState();
    // Apply initial values from home screen navigation
    if (widget.initialCategory != null &&
        _categoryMap.containsKey(widget.initialCategory)) {
      _selectedLabel = widget.initialCategory!;
    }
    if (widget.initialSearch != null) {
      _searchQuery = widget.initialSearch!;
    }

    // populate categories and keys
    _prodCategories = _categoryMap.keys.toList();
    _prodCategoryKeys
        .addAll(List.generate(_prodCategories.length, (_) => GlobalKey()));

    // determine initial index
    _prodSelectedCategoryIndex = _prodCategories.indexOf(_selectedLabel);
    if (_prodSelectedCategoryIndex < 0) _prodSelectedCategoryIndex = 0;

    _fetchProducts();
  }

  @override
  void dispose() {
    _prodCategoryScrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _products = [];
    });

    try {
      final categoryValue = _categoryMap[_selectedLabel]; // null = "Semua"
      final products = await _productService.getProducts(
        category: categoryValue,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );
      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memuat produk'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _onCategoryTap(String label, int index) {
    if (_selectedLabel == label) return;
    setState(() {
      _selectedLabel = label;
      _prodSelectedCategoryIndex = index;
    });
    _scrollProdToCategory(index);
    _fetchProducts();
  }

  void _onSearch(String query) {
    _searchQuery = query;
    _fetchProducts();
  }

  // Small nudge scroll helpers
  void _scrollProdCategories(double delta) {
    if (!_prodCategoryScrollController.hasClients) return;
    final maxScroll = _prodCategoryScrollController.position.maxScrollExtent;
    final target =
        (_prodCategoryScrollController.offset + delta).clamp(0.0, maxScroll);
    _prodCategoryScrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _scrollProdToCategory(int index) {
    final ctx = _prodCategoryKeys[index].currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 250),
        alignment: 0.5,
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppChrome(
      showTopBar: false,
      showNavbar: true,
      showSearch: true,
      onSearch: _onSearch,
      child: Column(
        children: [
          // ── Category Pills (scroll + compact buttons) ───────────────────────
          Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      // Left compact button
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 4)
                          ],
                        ),
                        child: IconButton(
                          padding: const EdgeInsets.all(4),
                          iconSize: 18,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.chevron_left,
                              color: Color(0xFFE83030)),
                          onPressed: () => _scrollProdCategories(-120),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Scrollable pills
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _prodCategoryScrollController,
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 8),
                          child: Row(
                            children: List.generate(
                              _prodCategories.length,
                              (index) {
                                final label = _prodCategories[index];
                                final isActive = _selectedLabel == label;
                                return Container(
                                  key: _prodCategoryKeys[index],
                                  margin: const EdgeInsets.only(right: 8),
                                  child: GestureDetector(
                                    onTap: () => _onCategoryTap(label, index),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? const Color(0xFFE83030)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                            color: isActive
                                                ? const Color(0xFFE83030)
                                                : Colors.grey[300]!),
                                      ),
                                      child: Text(
                                        label,
                                        style: TextStyle(
                                          color: isActive
                                              ? Colors.white
                                              : Colors.black87,
                                          fontWeight: isActive
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),
                      // Right compact button
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 4)
                          ],
                        ),
                        child: IconButton(
                          padding: const EdgeInsets.all(4),
                          iconSize: 18,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.chevron_right,
                              color: Color(0xFFE83030)),
                          onPressed: () => _scrollProdCategories(120),
                        ),
                      ),
                    ],
                  ),
                ),

                // Result count bar
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: _isLoading
                      ? const Text('Memuat...',
                          style: TextStyle(color: Colors.black54, fontSize: 13))
                      : Text(
                          _searchQuery.isNotEmpty
                              ? '${_products.length} produk untuk \"$_searchQuery\"'
                              : '${_products.length} produk ditemukan',
                          style: const TextStyle(
                              color: Colors.black54, fontSize: 13),
                        ),
                ),
                Container(height: 1, color: Colors.black12),
              ],
            ),
          ),

          // ── Product Grid ─────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.wifi_off,
                                  size: 48, color: Colors.grey),
                              const SizedBox(height: 12),
                              Text(_errorMessage!,
                                  textAlign: TextAlign.center,
                                  style:
                                      const TextStyle(color: Colors.black54)),
                              const SizedBox(height: 12),
                              TextButton.icon(
                                  onPressed: _fetchProducts,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Coba lagi'))
                            ],
                          ),
                        ),
                      )
                    : _products.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.search_off,
                                    size: 48, color: Colors.grey),
                                const SizedBox(height: 12),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? 'Produk \"$_searchQuery\" tidak ditemukan.'
                                      : 'Tidak ada produk dalam kategori ini.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.black54),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount:
                                  MediaQuery.of(context).size.width > 600
                                      ? 4
                                      : 2,
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
          ),
        ],
      ),
    );
  }
}
