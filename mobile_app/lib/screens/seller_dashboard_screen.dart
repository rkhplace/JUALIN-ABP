import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/seller_service.dart';
import '../models/seller_product.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../widgets/ui/logo_loader.dart';
import '../widgets/ui/notification_button.dart';

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
  double? _profileWalletBalance;
  int _totalProducts = 0;
  bool _didCheckVerificationBenefit = false;

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
      final user = await _profileService.getProfile();
      if (user != null) {
        name = user.name.isNotEmpty ? user.name : name;
        profileWalletBalance = user.walletBalance;
      }
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

    if (mounted) {
      setState(() {
        _products = products;
        _totalProducts = totalProducts;
        _stats = stats;
        _sellerName = name;
        _profileWalletBalance = profileWalletBalance;
        _isLoading = false;
      });
      _maybeShowVerifiedBenefitPopup();
    }
  }

  Future<void> _maybeShowVerifiedBenefitPopup() async {
    if (_didCheckVerificationBenefit) return;
    _didCheckVerificationBenefit = true;

    try {
      final status = await _sellerService.getVerificationStatus();
      final isVerified = status['is_verified'] == true;
      if (isVerified || !mounted) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDialog<void>(
          context: context,
          barrierColor: Colors.black.withValues(alpha: 0.35),
          barrierDismissible: true,
          builder: (dialogContext) => BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Dialog(
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22)),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEAF4FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified_user,
                          color: Color(0xFF1D8BFF),
                          size: 34,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        'Keuntungan Penjual Terverifikasi',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Ayo tingkatkan kepercayaan pembeli dengan menjadi penjual terverifikasi. Selesaikan target verifikasi agar badge biru tampil di tokomu.',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    _benefitRow(
                        'Badge terverifikasi tampil di profil dan produk.'),
                    _benefitRow(
                        'Pembeli lebih mudah percaya saat melihat toko.'),
                    _benefitRow(
                        'Produk terlihat lebih kredibel saat dibandingkan.'),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE83030),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Mengerti'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      });
    } catch (_) {
      // Verification benefit is informational; ignore if the status endpoint fails.
    }
  }

  Widget _benefitRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF1D8BFF), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  color: Colors.black87, fontSize: 13, height: 1.35),
            ),
          ),
        ],
      ),
    );
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
        body: JualinLogoLoader(size: 72),
      );
    }

    final totalProducts = _totalProducts;
    final walletBalance = _profileWalletBalance ??
        _stats?['wallet_balance'] ??
        _stats?['balance'] ??
        0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: RefreshIndicator(
          color: const Color(0xFFE83030),
          onRefresh: _fetchDashboardData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroHeader(totalProducts, walletBalance),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kelola Toko',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
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
                                await Navigator.pushNamed(
                                    context, '/seller_products');
                                _fetchDashboardData();
                              },
                            ),
                            _divider(),
                            _buildMenuItem(
                              context,
                              Icons.add_box_outlined,
                              'Tambah Produk',
                              'Unggah produk baru',
                              () async {
                                await Navigator.pushNamed(
                                    context, '/seller_product_new');
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
                                await Navigator.pushNamed(
                                    context, '/seller_orders');
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
                                await Navigator.pushNamed(
                                    context, '/seller_stats');
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
                                await Navigator.pushNamed(
                                    context, '/seller_withdraw');
                                _fetchDashboardData();
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader(int totalProducts, dynamic walletBalance) {
    final displayName = _sellerName.trim().isEmpty ? 'Penjual' : _sellerName;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        24,
        MediaQuery.of(context).padding.top + 22,
        24,
        30,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE83030), Color(0xFFF13A3A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(44),
          bottomRight: Radius.circular(44),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 24,
            spreadRadius: -8,
            offset: Offset(0, 14),
          ),
          BoxShadow(
            color: Color(0x24E83030),
            blurRadius: 30,
            spreadRadius: -10,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -42,
            top: 18,
            child: Container(
              width: 124,
              height: 124,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 2,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Dasbor Penjual',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const NotificationButton(
                      iconColor: Colors.white,
                      badgeColor: Colors.white,
                      badgeTextColor: Color(0xFFE83030),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                'Halo, $displayName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Pantau performa toko Anda hari ini',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    right: 22,
                    top: -92,
                    child: IgnorePointer(
                      child: Image.asset(
                        'assets/images/seller_mascot.png',
                        width: 118,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          'Total Produk',
                          totalProducts.toString(),
                          Icons.inventory_2_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          'Saldo Dompet',
                          _formatCurrency(walletBalance),
                          Icons.account_balance_wallet_outlined,
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    right: 18,
                    top: 0,
                    child: IgnorePointer(
                      child: Image.asset(
                        'assets/images/seller_mascot_hands.png',
                        width: 122,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.42)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEFEF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFFE83030), size: 22),
          ),
          const SizedBox(height: 10),
          Text(title,
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
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
