import 'package:flutter/material.dart';
import '../services/seller_service.dart';
import '../models/seller_product.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  final SellerService _sellerService = SellerService();
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();

  List<SellerProduct> _products = [];
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String _sellerName = '';
  double _profileWalletBalance = 0;
  int _totalProducts = 0;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    var name = _sellerName;
    var products = _products;
    var totalProducts = _totalProducts;
    var stats = _stats;
    var profileWalletBalance = _profileWalletBalance;

    try {
      final idAndRole = await _authService.getUserIdAndRole();
      name = idAndRole['name'] as String? ?? '';
    } catch (_) {}

    try {
      products = await _sellerService.getSellerProducts();
      final productTotal = await _sellerService.getSellerProductTotal();
      totalProducts = productTotal == 0 ? products.length : productTotal;
    } catch (_) {
      totalProducts = products.length;
    }

    try {
      stats = await _sellerService.getSellerStats();
    } catch (_) {}

    try {
      final user = await _profileService.getProfile();
      if (user != null) {
        profileWalletBalance = user.walletBalance;
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _products = products;
        _totalProducts = totalProducts;
        _stats = stats;
        _sellerName = name;
        _profileWalletBalance = profileWalletBalance;
        _isLoading = false;
      });
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

    final totalProducts = _totalProducts == 0 ? _products.length : _totalProducts;
    final balance = _stats?['balance'];
    final walletBalance = _stats?['wallet_balance'] ?? balance ?? _profileWalletBalance;

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
                      () async {
                        await Navigator.pushNamed(context, '/seller_products');
                        _fetchDashboardData();
                      },
                    ),
                    _divider(),
                    _buildMenuItem(
                      context,
                      Icons.add_box_outlined,
                      'Tambah Produk',
                      'Upload produk baru',
                      () async {
                        await Navigator.pushNamed(context, '/seller_product_new');
                        _fetchDashboardData();
                      },
                    ),
                    _divider(),
                    _buildMenuItem(
                      context,
                      Icons.receipt_long_outlined,
                      'Pesanan Masuk',
                      'Monitor pesanan dari pembeli',
                      () async {
                        await Navigator.pushNamed(context, '/seller_orders');
                        _fetchDashboardData();
                      },
                    ),
                    _divider(),
                    _buildMenuItem(
                      context,
                      Icons.bar_chart_outlined,
                      'Statistik Penjualan',
                      'Laporan pendapatan & grafik',
                      () async {
                        await Navigator.pushNamed(context, '/seller_stats');
                        _fetchDashboardData();
                      },
                    ),
                    _divider(),
                    _buildMenuItem(
                      context,
                      Icons.account_balance_wallet_outlined,
                      'Tarik Saldo',
                      'Cairkan saldo ke rekening bank',
                      () async {
                        await Navigator.pushNamed(context, '/seller_withdraw');
                        _fetchDashboardData();
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
