import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import '../models/chat_room.dart';
import '../models/product.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/product_service.dart';
import '../utils/image_url_helper.dart';
import '../widgets/ui/login_required_dialog.dart';
import '../widgets/ui/logo_loader.dart';
import '../widgets/ui/user_avatar.dart';
import 'chat_screen.dart';
import '../../utils/formatters.dart';

class SellerStoreScreen extends StatefulWidget {
  const SellerStoreScreen({super.key});

  @override
  State<SellerStoreScreen> createState() => _SellerStoreScreenState();
}

class _SellerStoreScreenState extends State<SellerStoreScreen> {
  final ProductService _productService = ProductService();
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  Product? _sellerSeed;
  List<Product> _products = [];
  bool _isLoading = true;
  bool _isChatLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _activeCategory = 'all';

  List<Product> get _filteredProducts {
    final query = _searchQuery.trim().toLowerCase();

    return _products.where((product) {
      final matchesCategory = _activeCategory == 'all' ||
          product.categoryName.toLowerCase() == _activeCategory;
      if (!matchesCategory) return false;
      if (query.isEmpty) return true;

      return product.title.toLowerCase().contains(query) ||
          product.description.toLowerCase().contains(query) ||
          product.categoryName.toLowerCase().contains(query);
    }).toList();
  }

  List<String> get _categories {
    final items = _products
        .map((product) => product.categoryName.trim())
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return items;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sellerSeed == null) {
      _resolveArguments();
      _loadSellerProducts();
    }
  }

  void _resolveArguments() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Product) {
      _sellerSeed = args;
    } else if (args is Map && args['product'] is Product) {
      _sellerSeed = args['product'] as Product;
    }
  }

  Future<void> _loadSellerProducts() async {
    final seed = _sellerSeed;
    if (seed == null || seed.sellerId == 0) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Informasi toko penjual tidak tersedia.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final products = await _productService.getProducts(
        sellerId: seed.sellerId,
        perPage: 100,
      );
      if (!mounted) return;
      setState(() {
        _products = products;
        if (_activeCategory != 'all' &&
            !products.any((product) =>
                product.categoryName.toLowerCase() == _activeCategory)) {
          _activeCategory = 'all';
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<bool> _requireLogin() async {
    final isLoggedIn = await _authService.isLoggedIn();
    if (!mounted) return false;

    if (!isLoggedIn) {
      final shouldLogin = await showLoginRequiredDialog(
        context,
        message: 'Silakan login terlebih dahulu untuk chat dengan penjual.',
      );
      if (!mounted) return false;
      if (shouldLogin) Navigator.pushNamed(context, '/login');
      return false;
    }
    return true;
  }

  Future<void> _handleChatSeller() async {
    final seed = _sellerSeed;
    if (seed == null || seed.sellerId == 0) return;

    final loggedIn = await _requireLogin();
    if (!mounted || !loggedIn) return;

    setState(() => _isChatLoading = true);

    try {
      final roomId = await _chatService.startRoom(seed.sellerId, seed.id);
      if (!mounted) return;
      if (roomId == null) {
        throw Exception('Room ID tidak diterima dari server.');
      }

      final chatProduct = ChatProduct(
        id: seed.id,
        name: seed.title,
        price: seed.price,
        image: seed.imagePath,
        sellerId: seed.sellerId,
        sellerName: seed.sellerName,
      );

      unawaited(
        _chatService.sendProductMessage(roomId, chatProduct).catchError(
          (Object error, StackTrace stackTrace) {
            debugPrint('[SellerStore] Failed to send product preview: $error');
            return null;
          },
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatRoomScreen(
            roomId: roomId,
            roomName: seed.sellerName,
            roomAvatarUrl: seed.sellerProfilePicture,
            product: chatProduct,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', 'Gagal membuka chat: '),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isChatLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final seed = _sellerSeed;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      body: SafeArea(
        child: seed == null
            ? _buildUnavailable()
            : RefreshIndicator(
                onRefresh: _loadSellerProducts,
                color: const Color(0xFFE83030),
                child: Builder(
                  builder: (context) {
                    final filteredProducts = _filteredProducts;

                    return CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(child: _buildHeader(seed)),
                        if (_isLoading)
                          const SliverFillRemaining(
                            child: Center(child: JualinLogoLoader(size: 58)),
                          )
                        else if (_errorMessage != null)
                          SliverFillRemaining(child: _buildError())
                        else ...[
                          SliverToBoxAdapter(child: _buildSearchAndFilter()),
                          if (_products.isEmpty)
                            SliverFillRemaining(child: _buildEmptyState())
                          else if (filteredProducts.isEmpty)
                            SliverFillRemaining(child: _buildNoFilterResult())
                          else
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              sliver: SliverGrid(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) => _buildProductCard(
                                      filteredProducts[index]),
                                  childCount: filteredProducts.length,
                                ),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 0.62,
                                ),
                              ),
                            ),
                        ],
                      ],
                    );
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(Product seed) {
    final sellerImageUrl = ImageUrlHelper.resolve(seed.sellerProfilePicture);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: Colors.white.withValues(alpha: 0.75)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE83030).withValues(alpha: 0.10),
              blurRadius: 34,
              spreadRadius: -16,
              offset: const Offset(0, 20),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 26,
              spreadRadius: -14,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE83030), Color(0xFFFF474F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -28,
                    top: -38,
                    child: Container(
                      width: 126,
                      height: 126,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.16),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 30,
                    bottom: -64,
                    child: Container(
                      width: 118,
                      height: 118,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _headerIconButton(
                            icon: Icons.arrow_back_rounded,
                            onTap: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Profil Toko',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.18),
                              ),
                            ),
                            child: UserAvatar(
                              name: seed.sellerName,
                              imageUrl: sellerImageUrl,
                              radius: 34,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        seed.sellerName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    if (seed.sellerIsVerified) ...[
                                      const SizedBox(width: 5),
                                      const Icon(
                                        Icons.verified_rounded,
                                        color: Colors.white,
                                        size: 19,
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  seed.locationLabel.isEmpty
                                      ? 'Penjual Jualin'
                                      : seed.locationLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _metricTile(
                                icon: Icons.inventory_2_outlined,
                                label: 'Produk Aktif',
                                value: '${_products.length} produk',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _metricTile(
                                icon: seed.sellerIsVerified
                                    ? Icons.verified_user_outlined
                                    : Icons.shield_outlined,
                                label: 'Status',
                                value: seed.sellerIsVerified
                                    ? 'Terverifikasi'
                                    : 'Belum verifikasi',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed:
                                _isChatLoading ? null : _handleChatSeller,
                            icon: _isChatLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.chat_bubble_outline,
                                    size: 18,
                                  ),
                            label: Text(
                              _isChatLoading
                                  ? 'Membuka chat...'
                                  : 'Chat Penjual',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE83030),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              textStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }

  Widget _metricTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEFEF),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: const Color(0xFFE83030), size: 18),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black38,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.045),
                  blurRadius: 18,
                  spreadRadius: -10,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Cari produk di toko ini...',
                hintStyle: const TextStyle(
                  color: Colors.black38,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFFE83030),
                  size: 20,
                ),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        icon: const Icon(Icons.close_rounded, size: 18),
                      ),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCategoryChip('all', 'Semua'),
                ..._categories.map(
                  (category) => _buildCategoryChip(
                    category.toLowerCase(),
                    category,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String value, String label) {
    final isActive = _activeCategory == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => setState(() => _activeCategory = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFE83030) : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isActive
                  ? const Color(0xFFE83030)
                  : Colors.black.withValues(alpha: 0.07),
            ),
            boxShadow: [
              BoxShadow(
                color: (isActive ? const Color(0xFFE83030) : Colors.black)
                    .withValues(alpha: isActive ? 0.16 : 0.035),
                blurRadius: 14,
                spreadRadius: -8,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                value == 'all'
                    ? Icons.grid_view_rounded
                    : Icons.category_outlined,
                size: 14,
                color: isActive ? Colors.white : const Color(0xFFE83030),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.black87,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.pushNamed(
          context,
          '/product_detail',
          arguments: product.id,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.045),
                blurRadius: 16,
                spreadRadius: -9,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(18)),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.network(
                    product.imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFF2F2F2),
                      child: const Icon(
                        Icons.image_outlined,
                        color: Colors.black26,
                        size: 34,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.categoryName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF1976D2),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 12,
                          height: 1.2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (product.offeredAgoLabel.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: 11,
                              color: Colors.black38,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                product.offeredAgoLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.black38,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const Spacer(),
                      Text(
                        formatCurrency(product.price),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFE83030),
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Stok: ${product.stock}',
                        style: const TextStyle(
                          color: Colors.black45,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.black26),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Gagal memuat toko.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _loadSellerProducts,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                color: Color(0xFFF2F2F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: Colors.black26,
                size: 34,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Belum ada produk aktif',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text(
              'Produk dari seller ini akan tampil di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black45, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoFilterResult() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                color: Color(0xFFFFEFEF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                color: Color(0xFFE83030),
                size: 34,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Produk tidak ditemukan',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text(
              'Coba ubah kata kunci atau filter kategori.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black45, fontSize: 12),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _activeCategory = 'all';
                });
              },
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: const Text('Reset Filter'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE83030),
                side: const BorderSide(color: Color(0xFFE83030)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnavailable() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storefront_outlined,
                size: 54, color: Colors.black26),
            const SizedBox(height: 12),
            const Text(
              'Toko tidak tersedia',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Buka profil toko melalui detail produk.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black45, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE83030),
                foregroundColor: Colors.white,
              ),
              child: const Text('Kembali'),
            ),
          ],
        ),
      ),
    );
  }
}
