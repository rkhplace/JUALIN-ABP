import 'package:flutter/material.dart';
import '../services/seller_service.dart';
import '../models/seller_product.dart';
import '../services/auth_service.dart';

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  final SellerService _sellerService = SellerService();
  final AuthService _authService = AuthService();

  List<SellerProduct> _products = [];
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String _sellerName = '';

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final idAndRole = await _authService.getUserIdAndRole();
      final name = idAndRole['name'] as String? ?? '';

      final products = await _sellerService.getSellerProducts();
      Map<String, dynamic>? stats;
      try {
        stats = await _sellerService.getSellerStats();
      } catch (_) {
        // Stats are optional — dashboard still works without them
      }

      if (mounted) {
        setState(() {
          _products = products;
          _stats = stats;
          _sellerName = name;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatCurrency(dynamic val) {
    int amount = 0;
    if (val is num) {
      amount = val.toInt();
    } else if (val is String) {
      amount = double.tryParse(val)?.toInt() ?? 0;
    }
    return 'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F5F5),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFE83030))),
      );
    }

    final totalProducts = _products.length;
    final walletBalance = _stats?['wallet_balance'] ?? _stats?['balance'] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Dashboard Penjual'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: RefreshIndicator(
        color: const Color(0xFFE83030),
        onRefresh: _fetchDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome banner
              if (_sellerName.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE83030), Color(0xFFE84444)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selamat datang, $_sellerName!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Kelola toko Anda dengan mudah',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Summary Cards Row
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Total Produk',
                      totalProducts.toString(),
                      Icons.inventory_2_outlined,
                      const Color(0xFF2196F3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      'Saldo Dompet',
                      _formatCurrency(walletBalance),
                      Icons.account_balance_wallet_outlined,
                      const Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Text(
                'Kelola Toko',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Menu container
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildMenuItem(
                      context,
                      Icons.list_alt_outlined,
                      'Daftar Produk',
                      'Lihat & kelola produk Anda',
                      () {
                        Navigator.pushNamed(context, '/seller_products');
                      },
                    ),
                    _divider(),
                    _buildMenuItem(
                      context,
                      Icons.add_box_outlined,
                      'Tambah Produk',
                      'Upload produk baru',
                      () {
                        Navigator.pushNamed(context, '/seller_product_new');
                      },
                    ),
                    _divider(),
                    _buildMenuItem(
                      context,
                      Icons.receipt_long_outlined,
                      'Pesanan Masuk',
                      'Monitor pesanan dari pembeli',
                      () {
                        Navigator.pushNamed(context, '/seller_orders');
                      },
                    ),
                    _divider(),
                    _buildMenuItem(
                      context,
                      Icons.bar_chart_outlined,
                      'Statistik Penjualan',
                      'Laporan pendapatan & grafik',
                      () {
                        Navigator.pushNamed(context, '/seller_stats');
                      },
                    ),
                    _divider(),
                    _buildMenuItem(
                      context,
                      Icons.account_balance_wallet_outlined,
                      'Tarik Saldo',
                      'Cairkan saldo ke rekening bank',
                      () {
                        Navigator.pushNamed(context, '/seller_withdraw');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 10),
          Text(title,
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0F0),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFFE83030), size: 20),
      ),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.black45)),
      trailing: const Icon(Icons.chevron_right, color: Colors.black26),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onTap,
    );
  }

  Widget _divider() => const Divider(height: 1, indent: 16, endIndent: 16);
}
