import 'package:flutter/material.dart';
import '../widgets/ui/custom_button.dart';
import '../services/product_service.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import '../models/product.dart';
import '../widgets/ui/login_required_dialog.dart';
import 'chat_screen.dart';
import '../../utils/formatters.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ProductService _productService = ProductService();
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  Product? _product;
  bool _isLoading = true;
  bool _isChatLoading = false;
  String? _errorMessage;

  Future<bool> requireLogin(
    BuildContext context, {
    String message = 'Silakan login terlebih dahulu untuk membeli produk.',
  }) async {
    final isLoggedIn = await _authService.isLoggedIn();
    if (!context.mounted) return false;

    if (!isLoggedIn) {
      final shouldLogin = await showLoginRequiredDialog(
        context,
        message: message,
      );
      if (!context.mounted) return false;
      if (shouldLogin) Navigator.pushNamed(context, '/login');
      return false;
    }
    return true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchProductDetails();
  }

  Future<void> _fetchProductDetails() async {
    // Product ID is passed as a route argument: Navigator.pushNamed(context, '/product_detail', arguments: id)
    final productId = ModalRoute.of(context)?.settings.arguments as int?;

    if (productId == null) {
      setState(() {
        _errorMessage = 'ID produk tidak ditemukan.';
        _isLoading = false;
      });
      return;
    }

    try {
      final product = await _productService.getProductDetails(productId);
      if (mounted) {
        setState(() {
          _product = product;
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

  Future<void> _handleChatPenjual() async {
    if (_product == null) return;

    final loggedIn = await requireLogin(
      context,
      message: 'Silakan login terlebih dahulu untuk chat dengan penjual.',
    );
    if (!mounted || !loggedIn) return;

    final sellerId = _product!.sellerId;
    final productId = _product!.id;

    if (sellerId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informasi penjual tidak tersedia.')),
      );
      return;
    }

    setState(() => _isChatLoading = true);

    try {
      final roomId = await _chatService.startRoom(sellerId, productId);

      if (!mounted) return;

      if (roomId == null) {
        throw Exception('Room ID tidak diterima dari server.');
      }

      // Navigate directly to the ChatRoomScreen with the room ID
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatRoomScreen(
            roomId: roomId,
            roomName: _product!.sellerName,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e
                .toString()
                .replaceFirst('Exception: ', 'Gagal membuka chat: ')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isChatLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_product?.title ?? 'Detail Produk'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 48, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isLoading = true;
                                _errorMessage = null;
                              });
                              _fetchProductDetails();
                            },
                            child: const Text('Coba lagi'),
                          )
                        ],
                      ),
                    ),
                  )
                : _product == null
                    ? const Center(child: Text('Data produk tidak ditemukan.'))
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Image
                            Container(
                              height: 300,
                              width: double.infinity,
                              color: Colors.grey[200],
                              child: _product!.imagePath.isNotEmpty
                                  ? Image.network(
                                      _product!.imagePath,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Center(
                                        child: Icon(Icons.image,
                                            size: 80, color: Colors.grey[400]),
                                      ),
                                    )
                                  : Center(
                                      child: Icon(Icons.image,
                                          size: 80, color: Colors.grey[400]),
                                    ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Price
                                  Text(
                                    formatCurrency(_product!.price),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFE83030),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Title
                                  Text(
                                    _product!.title,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Badges
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      _buildBadge(_product!.categoryName,
                                          Colors.grey[200]!, Colors.black87),
                                      _buildBadge(
                                          _product!.condition,
                                          Colors.orange.withValues(alpha: 0.1),
                                          Colors.orange[800]!),
                                      if (_product!.isNegotiable)
                                        _buildBadge(
                                            'Bisa Nego',
                                            Colors.blue.withValues(alpha: 0.1),
                                            Colors.blue[800]!),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  const Divider(),
                                  const SizedBox(height: 16),
                                  // Seller Info
                                  Row(
                                    children: [
                                      const CircleAvatar(
                                        backgroundColor: Color(0xFFF5F5F5),
                                        radius: 20,
                                        child: Icon(Icons.person,
                                            color: Colors.grey),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(_product!.sellerName,
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            const Text('Penjual',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.black54)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  const Divider(),
                                  const SizedBox(height: 16),
                                  // Description
                                  const Text('Deskripsi Produk',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Text(
                                    _product!.description.isEmpty
                                        ? 'Tidak ada deskripsi.'
                                        : _product!.description,
                                    style: const TextStyle(
                                        color: Colors.black87, height: 1.5),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Stok: ${_product!.stock}',
                                    style: TextStyle(
                                        color: Colors.grey[600], fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
      ),
      bottomNavigationBar: _product == null
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, -4),
                    blurRadius: 10,
                  )
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: _isChatLoading
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Center(
                                  child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))),
                            )
                          : CustomButton(
                              text: 'Chat Penjual',
                              isSecondary: true,
                              onPressed: _handleChatPenjual,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        text: 'Beli Sekarang',
                        onPressed: () async {
                          // Check if user is logged in using existing AuthService
                          final loggedIn = await requireLogin(context);

                          if (!context.mounted) return;
                          if (!loggedIn) return;

                          Navigator.pushNamed(
                            context,
                            '/checkout',
                            arguments: _product,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
            fontSize: 12, color: textColor, fontWeight: FontWeight.w600),
      ),
    );
  }
}
