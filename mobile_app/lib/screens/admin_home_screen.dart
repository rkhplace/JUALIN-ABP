import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/admin_service.dart';
import '../services/auth_service.dart';
import '../utils/image_url_helper.dart';
import '../widgets/ui/logo_loader.dart';
import '../widgets/ui/user_avatar.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final AdminService _adminService = AdminService();
  final AuthService _authService = AuthService();
  final TextEditingController _productSearchController =
      TextEditingController();
  final TextEditingController _userSearchController = TextEditingController();
  final TextEditingController _reportSearchController = TextEditingController();

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _reports = [];
  String _productSearchQuery = '';
  String _userSearchQuery = '';
  String _reportSearchQuery = '';
  String _userRoleFilter = 'all';
  String _userStatusFilter = 'all';
  String _productCategoryFilter = 'all';
  String _productStockFilter = 'all';
  String _reportStatusFilter = 'all';
  String _reportTypeFilter = 'all';
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAdminData();
  }

  @override
  void dispose() {
    _productSearchController.dispose();
    _userSearchController.dispose();
    _reportSearchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredUsers {
    final query = _userSearchQuery.trim().toLowerCase();

    return _users.where((user) {
      final username = _text(user['username'] ?? user['name'] ?? user['email'])
          .toLowerCase();
      final email = _text(user['email']).toLowerCase();
      final role = _text(user['role']).toLowerCase();
      final status = _isCurrentlyBanned(user) ? 'diblokir' : 'aktif';
      final roleMatches = _userRoleFilter == 'all' || role == _userRoleFilter;
      final statusMatches = switch (_userStatusFilter) {
        'banned' => _isCurrentlyBanned(user),
        'active' => !_isCurrentlyBanned(user),
        _ => true,
      };
      final searchMatches = query.isEmpty ||
          username.contains(query) ||
          email.contains(query) ||
          role.contains(query) ||
          status.contains(query);

      return searchMatches && roleMatches && statusMatches;
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredProducts {
    final query = _productSearchQuery.trim().toLowerCase();

    return _products.where((product) {
      final name = _text(product['name'] ?? product['title']).toLowerCase();
      final category = _text(product['category']).toLowerCase();
      final seller = _text(
        _nested(product['seller'], 'username') ??
            product['seller_name'] ??
            product['sellerName'],
      ).toLowerCase();
      final stock = _parseInt(product['stock_quantity'] ?? product['stock']);
      final categoryMatches = _productCategoryFilter == 'all' ||
          category == _productCategoryFilter.trim().toLowerCase();
      final stockMatches = switch (_productStockFilter) {
        'empty' => stock <= 0,
        'available' => stock > 0,
        _ => true,
      };
      final searchMatches = query.isEmpty ||
          name.contains(query) ||
          category.contains(query) ||
          seller.contains(query);

      return searchMatches && categoryMatches && stockMatches;
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredReports {
    final query = _reportSearchQuery.trim().toLowerCase();

    return _reports.where((report) {
      final id = _parseInt(report['id']).toString();
      final status =
          _formatReportStatus(_uiReportStatus(_text(report['status'])))
              .toLowerCase();
      final type = _reportDisplayType(report).toLowerCase();
      final reason = _reportReason(report).toLowerCase();
      final reporter = _text(report['reporter_username'] ?? report['username'])
          .toLowerCase();
      final reported =
          _text(report['reported_username'] ?? report['target_username'])
              .toLowerCase();
      final product = _text(report['reported_product_name']).toLowerCase();
      final description = _text(report['description']).toLowerCase();
      final rawStatus = _uiReportStatus(_text(report['status'], 'pending'));
      final statusMatches =
          _reportStatusFilter == 'all' || rawStatus == _reportStatusFilter;
      final typeMatches = _reportTypeFilter == 'all' ||
          type == _reportTypeFilter.trim().toLowerCase();
      final searchMatches = query.isEmpty ||
          id.contains(query) ||
          status.contains(query) ||
          type.contains(query) ||
          reason.contains(query) ||
          reporter.contains(query) ||
          reported.contains(query) ||
          product.contains(query) ||
          description.contains(query);

      return searchMatches && statusMatches && typeMatches;
    }).toList();
  }

  List<String> get _productCategories {
    final categories = _products
        .map((product) => _text(product['category']).trim())
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return categories;
  }

  List<String> get _reportTypes {
    final types = _reports
        .map((report) => _reportDisplayType(report).trim())
        .where((type) => type.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return types;
  }

  Future<void> _fetchAdminData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _adminService.getUsers(),
        _adminService.getProducts(),
        _adminService.getTransactions(),
        _adminService.getReports(),
      ]);

      if (!mounted) return;
      setState(() {
        _users = results[0];
        _products = results[1];
        _transactions = results[2];
        _reports = results[3];
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
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: const Color(0xFFF6F6F7),
          body: Column(
            children: [
              _buildAdminHero(),
              Container(
                color: Colors.white,
                child: const TabBar(
                  indicatorColor: Color(0xFFE83030),
                  indicatorWeight: 3,
                  labelColor: Color(0xFFE83030),
                  unselectedLabelColor: Colors.black54,
                  labelStyle:
                      TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  unselectedLabelStyle:
                      TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  tabs: [
                    Tab(text: 'Ringkasan'),
                    Tab(text: 'Pengguna'),
                    Tab(text: 'Produk'),
                    Tab(text: 'Laporan'),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const JualinLogoLoader(size: 72)
                    : _errorMessage != null
                        ? _buildErrorState()
                        : RefreshIndicator(
                            color: const Color(0xFFE83030),
                            onRefresh: _fetchAdminData,
                            child: TabBarView(
                              children: [
                                _buildOverviewTab(),
                                _buildUsersTab(),
                                _buildProductsTransactionsTab(),
                                _buildReportsTab(),
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

  Widget _buildAdminHero() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        24,
        MediaQuery.of(context).padding.top + 18,
        20,
        28,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE83030), Color(0xFFF13838)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(34),
          bottomRight: Radius.circular(34),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -50,
            bottom: -32,
            child: _buildHeroBlob(150, 106, 0.15),
          ),
          Positioned(
            right: 18,
            top: 50,
            child: _buildHeroBlob(90, 120, 0.10),
          ),
          Positioned(
            right: 84,
            bottom: -22,
            child: _buildHeroBlob(102, 96, 0.13),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Panel Admin',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Admin Utama',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 29,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Pantau pengguna, produk, transaksi,\ndan laporan.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Keluar',
                onPressed: _logout,
                icon: const Icon(Icons.logout, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBlob(double width, double height, double alpha) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: alpha),
        borderRadius: BorderRadius.circular(28),
      ),
    );
  }

  Widget _buildOverviewTab() {
    final pendingReports =
        _reports.where((item) => _text(item['status']) == 'pending').toList();
    final bannedUsers = _users.where((item) => _isCurrentlyBanned(item)).length;
    final latestTransaction =
        _transactions.isEmpty ? null : _transactions.first;
    final latestProduct = _products.isEmpty ? null : _products.first;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        const Text(
          'Ringkasan',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.75,
          children: [
            _buildSummaryTile('Pengguna', _users.length.toString(),
                'Total pengguna', Icons.people_alt_outlined),
            _buildSummaryTile('Produk', _products.length.toString(),
                'Total produk', Icons.inventory_2_outlined),
            _buildSummaryTile('Transaksi', _transactions.length.toString(),
                'Total transaksi', Icons.receipt_long_outlined),
            _buildSummaryTile(
                'Laporan Menunggu',
                pendingReports.length.toString(),
                'Perlu ditinjau',
                Icons.report_outlined),
          ],
        ),
        const SizedBox(height: 10),
        _buildBannedOverviewCard(bannedUsers),
        const SizedBox(height: 14),
        const Text(
          'Aktivitas Terbaru',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        if (latestProduct != null)
          _buildActivityRow(
            icon: Icons.inventory_2_outlined,
            title: _text(latestProduct['name'] ?? latestProduct['title'],
                'Produk terbaru'),
            subtitle: 'Produk terbaru dalam katalog',
            onTap: () => DefaultTabController.of(context).animateTo(2),
          ),
        if (latestProduct != null && latestTransaction != null)
          const SizedBox(height: 8),
        if (latestTransaction != null)
          _buildActivityRow(
            icon: Icons.receipt_long_outlined,
            title: 'Transaksi #${_parseInt(latestTransaction['id'])}',
            subtitle: _formatTransactionStatus(
              _text(latestTransaction['status'], 'pending'),
            ),
            onTap: () => DefaultTabController.of(context).animateTo(2),
          ),
        if (latestProduct == null && latestTransaction == null)
          _buildCard(
            child: const Text(
              'Belum ada aktivitas terbaru.',
              style: TextStyle(color: Colors.black54),
            ),
          ),
        const SizedBox(height: 14),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Perlu Ditinjau',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ),
            TextButton(
              onPressed: pendingReports.isEmpty
                  ? null
                  : () => _showPendingReportsSheet(pendingReports),
              child: const Text('Lihat semua'),
            ),
          ],
        ),
        if (pendingReports.isEmpty)
          _buildCard(
            child: const Text(
              'Belum ada laporan yang perlu ditinjau.',
              style: TextStyle(color: Colors.black54),
            ),
          )
        else
          ...pendingReports.take(3).map(
                (report) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildReviewPreviewCard(report),
                ),
              ),
      ],
    );
  }

  Widget _buildUsersTab() {
    final filteredUsers = _filteredUsers;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildUserSearch(),
        const SizedBox(height: 12),
        if (filteredUsers.isEmpty)
          _buildEmptyUserSearchState()
        else
          ...filteredUsers.map(
            (user) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildAdminUserCard(user),
            ),
          ),
      ],
    );
  }

  Widget _buildAdminUserCard(Map<String, dynamic> user) {
    final id = _parseInt(user['id']);
    final username =
        _text(user['username'] ?? user['name'] ?? user['email'], '-');
    final email = _text(user['email'], '-');
    final role = _text(user['role'], '-');
    final isBanned = _isCurrentlyBanned(user);
    final avatarUrl = ImageUrlHelper.resolve(
      user['profile_picture'] ??
          user['avatar_url'] ??
          user['avatar'] ??
          user['photo'],
    );

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(name: username, imageUrl: avatarUrl, radius: 23),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(color: Colors.black45, fontSize: 12),
                    ),
                  ],
                ),
              ),
              _buildStatusChip(_formatUserRole(role), Colors.blue),
            ],
          ),
          if (isBanned) ...[
            const SizedBox(height: 10),
            Text(
              'Diblokir sampai ${_formatDate(user['banned_until'])}',
              style: const TextStyle(color: Color(0xFFE83030), fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: role == 'admin' || id == 0
                      ? null
                      : () => isBanned
                          ? _unbanUser(id)
                          : _showBanDurationDialog(id, username),
                  icon: Icon(isBanned ? Icons.lock_open : Icons.block),
                  label: Text(isBanned ? 'Buka Blokir' : 'Blokir'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE83030),
                    side: const BorderSide(color: Color(0xFFE83030)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: role == 'admin' || id == 0
                      ? null
                      : () => _confirmDeleteUser(id, username),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Hapus Akun'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE83030),
                    side: const BorderSide(color: Color(0xFFE83030)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserSearch() {
    return _buildAdminSearchAndFilterBar(
      controller: _userSearchController,
      query: _userSearchQuery,
      hintText: 'Cari nama, email, atau peran',
      onChanged: (value) => setState(() => _userSearchQuery = value),
      onClear: () {
        _userSearchController.clear();
        setState(() => _userSearchQuery = '');
      },
      onFilter: _showUserFilterSheet,
      hasActiveFilter: _userRoleFilter != 'all' || _userStatusFilter != 'all',
    );
  }

  Widget _buildEmptyUserSearchState() {
    return _buildCard(
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Column(
          children: [
            Icon(Icons.search_off, color: Colors.black38, size: 42),
            SizedBox(height: 10),
            Text(
              'Pengguna tidak ditemukan',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 4),
            Text(
              'Coba ubah kata kunci pencarian.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black45, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsTransactionsTab() {
    final filteredProducts = _filteredProducts;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildProductSearch(),
        const SizedBox(height: 12),
        if (filteredProducts.isEmpty)
          _buildEmptyProductSearchState()
        else
          ...filteredProducts.map(_buildProductCard),
        const SizedBox(height: 22),
        const Text(
          'Monitoring Transaksi',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        ..._transactions.map(_buildTransactionCard),
      ],
    );
  }

  Widget _buildProductSearch() {
    return _buildAdminSearchAndFilterBar(
      controller: _productSearchController,
      query: _productSearchQuery,
      hintText: 'Cari produk, penjual, atau kategori',
      onChanged: (value) => setState(() => _productSearchQuery = value),
      onClear: () {
        _productSearchController.clear();
        setState(() => _productSearchQuery = '');
      },
      onFilter: _showProductFilterSheet,
      hasActiveFilter:
          _productCategoryFilter != 'all' || _productStockFilter != 'all',
    );
  }

  Widget _buildEmptyProductSearchState() {
    return _buildCard(
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Column(
          children: [
            Icon(Icons.search_off, color: Colors.black38, size: 42),
            SizedBox(height: 10),
            Text(
              'Produk tidak ditemukan',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 4),
            Text(
              'Coba ubah kata kunci pencarian.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black45, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportSearch() {
    return _buildAdminSearchAndFilterBar(
      controller: _reportSearchController,
      query: _reportSearchQuery,
      hintText: 'Cari laporan, pelapor, status, atau produk',
      onChanged: (value) => setState(() => _reportSearchQuery = value),
      onClear: () {
        _reportSearchController.clear();
        setState(() => _reportSearchQuery = '');
      },
      onFilter: _showReportFilterSheet,
      hasActiveFilter:
          _reportStatusFilter != 'all' || _reportTypeFilter != 'all',
    );
  }

  Widget _buildAdminSearchAndFilterBar({
    required TextEditingController controller,
    required String query,
    required String hintText,
    required ValueChanged<String> onChanged,
    required VoidCallback onClear,
    required VoidCallback onFilter,
    required bool hasActiveFilter,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Color(0xFFE83030)),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: onClear,
                        icon: const Icon(Icons.close, size: 18),
                      ),
                filled: true,
                fillColor: const Color(0xFFF7F7F7),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: Color(0xFFE83030), width: 1.2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 48,
            height: 48,
            child: ElevatedButton(
              onPressed: onFilter,
              style: ElevatedButton.styleFrom(
                backgroundColor: hasActiveFilter
                    ? const Color(0xFFE83030)
                    : const Color(0xFFFFEFEF),
                foregroundColor:
                    hasActiveFilter ? Colors.white : const Color(0xFFE83030),
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Icon(Icons.tune),
            ),
          ),
        ],
      ),
    );
  }

  void _showUserFilterSheet() {
    var tempRole = _userRoleFilter;
    var tempStatus = _userStatusFilter;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSheetHandle(),
                    const SizedBox(height: 18),
                    const Text(
                      'Filter Pengguna',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 14),
                    const Text('Peran',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _adminFilterChip(
                          label: 'Semua',
                          active: tempRole == 'all',
                          onTap: () => setSheetState(() => tempRole = 'all'),
                        ),
                        _adminFilterChip(
                          label: 'Pembeli',
                          active: tempRole == 'customer',
                          onTap: () =>
                              setSheetState(() => tempRole = 'customer'),
                        ),
                        _adminFilterChip(
                          label: 'Penjual',
                          active: tempRole == 'seller',
                          onTap: () => setSheetState(() => tempRole = 'seller'),
                        ),
                        _adminFilterChip(
                          label: 'Admin',
                          active: tempRole == 'admin',
                          onTap: () => setSheetState(() => tempRole = 'admin'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Status',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _adminFilterChip(
                          label: 'Semua',
                          active: tempStatus == 'all',
                          onTap: () => setSheetState(() => tempStatus = 'all'),
                        ),
                        _adminFilterChip(
                          label: 'Aktif',
                          active: tempStatus == 'active',
                          onTap: () =>
                              setSheetState(() => tempStatus = 'active'),
                        ),
                        _adminFilterChip(
                          label: 'Diblokir',
                          active: tempStatus == 'banned',
                          onTap: () =>
                              setSheetState(() => tempStatus = 'banned'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildFilterActions(
                      onReset: () {
                        setState(() {
                          _userRoleFilter = 'all';
                          _userStatusFilter = 'all';
                        });
                        Navigator.pop(context);
                      },
                      onApply: () {
                        setState(() {
                          _userRoleFilter = tempRole;
                          _userStatusFilter = tempStatus;
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showProductFilterSheet() {
    var tempCategory = _productCategoryFilter;
    var tempStock = _productStockFilter;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSheetHandle(),
                      const SizedBox(height: 18),
                      const Text(
                        'Filter Produk',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 14),
                      const Text('Kategori',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _adminFilterChip(
                            label: 'Semua',
                            active: tempCategory == 'all',
                            onTap: () =>
                                setSheetState(() => tempCategory = 'all'),
                          ),
                          ..._productCategories.map(
                            (category) => _adminFilterChip(
                              label: category,
                              active: tempCategory.toLowerCase() ==
                                  category.toLowerCase(),
                              onTap: () => setSheetState(
                                () => tempCategory = category.toLowerCase(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('Stok',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _adminFilterChip(
                            label: 'Semua',
                            active: tempStock == 'all',
                            onTap: () => setSheetState(() => tempStock = 'all'),
                          ),
                          _adminFilterChip(
                            label: 'Stok Habis',
                            active: tempStock == 'empty',
                            onTap: () =>
                                setSheetState(() => tempStock = 'empty'),
                          ),
                          _adminFilterChip(
                            label: 'Stok Tersedia',
                            active: tempStock == 'available',
                            onTap: () =>
                                setSheetState(() => tempStock = 'available'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildFilterActions(
                        onReset: () {
                          setState(() {
                            _productCategoryFilter = 'all';
                            _productStockFilter = 'all';
                          });
                          Navigator.pop(context);
                        },
                        onApply: () {
                          setState(() {
                            _productCategoryFilter = tempCategory;
                            _productStockFilter = tempStock;
                          });
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showReportFilterSheet() {
    var tempStatus = _reportStatusFilter;
    var tempType = _reportTypeFilter;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSheetHandle(),
                      const SizedBox(height: 18),
                      const Text(
                        'Filter Laporan',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 14),
                      const Text('Status',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _adminFilterChip(
                            label: 'Semua',
                            active: tempStatus == 'all',
                            onTap: () =>
                                setSheetState(() => tempStatus = 'all'),
                          ),
                          ...const [
                            'pending',
                            'processing',
                            'accepted',
                            'rejected',
                          ].map(
                            (status) => _adminFilterChip(
                              label: _formatReportStatus(status),
                              active: tempStatus == status,
                              onTap: () =>
                                  setSheetState(() => tempStatus = status),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('Tipe',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _adminFilterChip(
                            label: 'Semua',
                            active: tempType == 'all',
                            onTap: () => setSheetState(() => tempType = 'all'),
                          ),
                          ..._reportTypes.map(
                            (type) => _adminFilterChip(
                              label: type,
                              active:
                                  tempType.toLowerCase() == type.toLowerCase(),
                              onTap: () => setSheetState(
                                () => tempType = type.toLowerCase(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildFilterActions(
                        onReset: () {
                          setState(() {
                            _reportStatusFilter = 'all';
                            _reportTypeFilter = 'all';
                          });
                          Navigator.pop(context);
                        },
                        onApply: () {
                          setState(() {
                            _reportStatusFilter = tempStatus;
                            _reportTypeFilter = tempType;
                          });
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSheetHandle() {
    return Center(
      child: Container(
        width: 42,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }

  Widget _buildFilterActions({
    required VoidCallback onReset,
    required VoidCallback onApply,
  }) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onReset,
            child: const Text('Reset'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: onApply,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE83030),
              foregroundColor: Colors.white,
            ),
            child: const Text('Terapkan'),
          ),
        ),
      ],
    );
  }

  Widget _adminFilterChip({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: active,
      onSelected: (_) => onTap(),
      selectedColor: const Color(0xFFE83030),
      backgroundColor: const Color(0xFFF5F5F5),
      labelStyle: TextStyle(
        color: active ? Colors.white : Colors.black54,
        fontWeight: active ? FontWeight.bold : FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }

  Widget _buildEmptyReportSearchState() {
    return _buildCard(
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Column(
          children: [
            Icon(Icons.search_off, color: Colors.black38, size: 42),
            SizedBox(height: 10),
            Text(
              'Laporan tidak ditemukan',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 4),
            Text(
              'Coba ubah kata kunci pencarian.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black45, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsTab() {
    final filteredReports = _filteredReports;

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filteredReports.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            children: [
              _buildReportSearch(),
              if (filteredReports.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _buildEmptyReportSearchState(),
                ),
            ],
          );
        }

        return _buildReportCard(filteredReports[index - 1]);
      },
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final id = _parseInt(product['id']);
    final name = _text(product['name'] ?? product['title'], 'Produk');
    final category = _text(product['category'], 'Uncategorized');
    final price = _parseInt(product['price']);
    final stock = _parseInt(product['stock_quantity'] ?? product['stock']);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _buildCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(product['image'] ?? product['image_path']),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(category,
                      style: const TextStyle(color: Colors.blue, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text('Stok: $stock',
                      style:
                          const TextStyle(color: Colors.black45, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _formatCurrency(price),
                          style: const TextStyle(
                            color: Color(0xFFE83030),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed:
                            id == 0 ? null : () => _deleteProduct(id, name),
                        icon: const Icon(Icons.delete_outline,
                            color: Color(0xFFE83030)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> trx) {
    final id = _parseInt(trx['id']);
    final status = _text(trx['status'], 'pending');
    final customer = _text(_nested(trx['customer'], 'username'), '-');
    final seller = _text(_nested(trx['seller'], 'username'), '-');
    final total = _parseInt(trx['total_price'] ?? trx['total_amount']);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _buildCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildIconBox(Icons.receipt_long_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'TRX-$id',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                _buildStatusChip(_formatAdminOptionLabel(status), Colors.green),
              ],
            ),
            const SizedBox(height: 10),
            Text('Pembeli: $customer',
                style: const TextStyle(color: Colors.black54, fontSize: 12)),
            Text('Penjual: $seller',
                style: const TextStyle(color: Colors.black54, fontSize: 12)),
            Text(_formatCurrency(total),
                style: const TextStyle(
                    color: Color(0xFFE83030), fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            _buildStatusDropdown(
              value: status,
              options: const [
                'pending',
                'waiting_cod',
                'paid',
                'processing',
                'completed',
                'cancelled',
                'refunded',
              ],
              onChanged: id == 0
                  ? null
                  : (value) => _updateTransactionStatus(id, value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final id = _parseInt(report['id']);
    final status = _uiReportStatus(_text(report['status'], 'pending'));
    final reporter =
        _text(report['reporter_username'] ?? report['username'], '-');
    final reported = _text(
      report['reported_username'] ?? report['target_username'],
      'Tidak tersedia',
    );
    final product = _reportProductName(report);
    final description = _text(report['description'], '-');
    final displayType = _reportDisplayType(report);
    final reason = _reportReason(report);
    final isProductReport = _isProductReport(report);
    final reportedUserId = _parseInt(report['reported_user_id']);
    final isReportedBanned = _parseBool(report['reported_user_is_banned']);

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildIconBox(_reportIcon(report)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      id == 0 ? displayType : '$displayType #LP-$id',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    if (reason.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Alasan: $reason',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black45,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _buildStatusChip(_formatReportStatus(status), Colors.orange),
            ],
          ),
          const SizedBox(height: 10),
          Text('Pelapor: $reporter',
              style: const TextStyle(color: Colors.black54, fontSize: 12)),
          if (isProductReport) ...[
            Text('Terlapor: $reported',
                style: const TextStyle(color: Color(0xFFE83030), fontSize: 12)),
            Text('Produk: $product',
                style: const TextStyle(color: Colors.black54, fontSize: 12)),
          ],
          const SizedBox(height: 8),
          Text(description, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 12),
          _buildStatusDropdown(
            value: status,
            options: const ['pending', 'processing', 'accepted', 'rejected'],
            onChanged:
                id == 0 ? null : (value) => _updateReportStatus(id, value),
          ),
          if (reportedUserId > 0) ...[
            const SizedBox(height: 12),
            _buildReportedAccountActions(
              username: reported,
              isBanned: isReportedBanned,
              onToggleBan: isReportedBanned
                  ? () => _unbanUser(reportedUserId)
                  : () => _showBanDurationDialog(reportedUserId, reported),
              onDelete: () => _confirmDeleteUser(reportedUserId, reported),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReportedAccountActions({
    required String username,
    required bool isBanned,
    required VoidCallback onToggleBan,
    required VoidCallback onDelete,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD8D8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEFEF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_outlined,
                  color: Color(0xFFE83030),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Aksi Akun Terlapor',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black45,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onToggleBan,
                  icon: Icon(isBanned ? Icons.lock_open : Icons.block),
                  label: Text(isBanned ? 'Buka Blokir' : 'Blokir'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE83030),
                    side: const BorderSide(color: Color(0xFFE83030)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Hapus Akun'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE83030),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTile(
    String title,
    String value,
    String subtitle,
    IconData icon,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildSmallIconBox(icon),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black54, fontSize: 11),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.black38, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildBannedOverviewCard(int bannedUsers) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _showBannedUsersSheet,
      child: _buildCard(
        child: Row(
          children: [
            _buildIconBox(Icons.block_outlined),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Akun Diblokir',
                    style: TextStyle(
                      color: Color(0xFFE83030),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Akun yang dibatasi/diblokir',
                    style: TextStyle(color: Colors.black45, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              bannedUsers.toString(),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.black26),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: _buildCard(
        child: Row(
          children: [
            _buildIconBox(icon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black45,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewPreviewCard(Map<String, dynamic> report) {
    final id = _parseInt(report['id']);
    final product = _reportProductName(report);
    final description = _text(report['description'], '-');
    final status = _uiReportStatus(_text(report['status'], 'pending'));
    final displayType = _reportDisplayType(report);
    final reason = _reportReason(report);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _openReportDetail(report),
      child: _buildCard(
        child: Row(
          children: [
            _buildIconBox(_reportIcon(report)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    id == 0 ? displayType : '$displayType #LP-$id',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  if (product.isNotEmpty)
                    Text(
                      product,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  if (reason.isNotEmpty)
                    Text(
                      'Alasan: $reason',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(color: Colors.black54, fontSize: 11),
                    ),
                  Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black45, fontSize: 11),
                  ),
                ],
              ),
            ),
            _buildStatusChip(_formatReportStatus(status), Colors.orange),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: Colors.black26),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSmallIconBox(IconData icon) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFFFFEFEF),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, color: const Color(0xFFE83030), size: 18),
    );
  }

  Widget _buildIconBox(IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFFFEFEF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: const Color(0xFFE83030), size: 21),
    );
  }

  Widget _buildImage(dynamic rawImage) {
    final imageUrl = _extractImageUrl(rawImage);
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: imageUrl.isEmpty
          ? const Icon(Icons.image_outlined, color: Colors.grey)
          : ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                },
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.image_outlined, color: Colors.grey),
              ),
            ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildStatusDropdown({
    required String value,
    required List<String> options,
    required ValueChanged<String>? onChanged,
  }) {
    final selected = options.contains(value) ? value : options.first;
    return _buildChoiceField(
      value: _formatAdminOptionLabel(selected),
      hint: 'Pilih status',
      enabled: onChanged != null,
      onTap: onChanged == null
          ? null
          : () async {
              final picked = await _showAdminOptionSheet(
                title: 'Pilih Status',
                selected: selected,
                options: options,
                labelBuilder: _formatAdminOptionLabel,
              );
              if (picked != null && picked != selected) onChanged(picked);
            },
    );
  }

  Widget _buildChoiceField({
    required String? value,
    required String hint,
    required VoidCallback? onTap,
    bool enabled = true,
    String? errorText,
  }) {
    final hasValue = value != null && value.trim().isNotEmpty;
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: enabled ? const Color(0xFFFDFDFD) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: hasError
                      ? const Color(0xFFE83030)
                      : Colors.black.withValues(alpha: 0.10),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.035),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      hasValue ? value : hint,
                      style: TextStyle(
                        color: hasValue ? Colors.black87 : Colors.black38,
                        fontWeight:
                            hasValue ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: enabled ? const Color(0xFFE83030) : Colors.black26,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Text(
              errorText,
              style: const TextStyle(color: Color(0xFFE83030), fontSize: 11),
            ),
          ),
        ],
      ],
    );
  }

  Future<String?> _showAdminOptionSheet({
    required String title,
    required String? selected,
    required List<String> options,
    required String Function(String value) labelBuilder,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final maxHeight = MediaQuery.of(sheetContext).size.height * 0.72;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      itemCount: options.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final option = options[index];
                        final isSelected = option == selected;
                        return Material(
                          color: isSelected
                              ? const Color(0xFFFFEFEF)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => Navigator.pop(sheetContext, option),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 13,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFE83030)
                                      : Colors.black.withValues(alpha: 0.08),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      labelBuilder(option),
                                      style: TextStyle(
                                        color: isSelected
                                            ? const Color(0xFFE83030)
                                            : Colors.black87,
                                        fontWeight: isSelected
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle,
                                      color: Color(0xFFE83030),
                                      size: 20,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.admin_panel_settings_outlined,
                size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Gagal memuat data admin.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _fetchAdminData,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE83030),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showBannedUsersSheet() {
    final bannedUsers =
        _users.where((user) => _isCurrentlyBanned(user)).toList();

    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.72,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Akun Diblokir',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  if (bannedUsers.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 22),
                      child: Center(
                        child: Text(
                          'Tidak ada akun yang sedang diban.',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: bannedUsers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final user = bannedUsers[index];
                          final username = _text(
                            user['username'] ?? user['name'] ?? user['email'],
                            '-',
                          );
                          return Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                Navigator.pop(sheetContext);
                                DefaultTabController.of(this.context)
                                    .animateTo(1);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.black.withValues(alpha: 0.08),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    _buildSmallIconBox(
                                        Icons.person_off_outlined),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            username,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          Text(
                                            'Sampai ${_formatDate(user['banned_until'])}',
                                            style: const TextStyle(
                                              color: Colors.black45,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: Colors.black26,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showPendingReportsSheet(
    List<Map<String, dynamic>> pendingReports,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.78,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Laporan Menunggu',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: pendingReports.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final report = pendingReports[index];
                        final id = _parseInt(report['id']);
                        final displayType = _reportDisplayType(report);
                        final product = _reportProductName(report);
                        final reason = _reportReason(report);
                        final description = _text(report['description'], '-');

                        return Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              Navigator.pop(sheetContext);
                              Future.microtask(
                                () => _openReportDetail(report),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.black.withValues(alpha: 0.08),
                                ),
                              ),
                              child: Row(
                                children: [
                                  _buildSmallIconBox(_reportIcon(report)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          id == 0
                                              ? displayType
                                              : '$displayType #LP-$id',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        if (product.isNotEmpty)
                                          Text(
                                            product,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.black54,
                                              fontSize: 11,
                                            ),
                                          ),
                                        if (reason.isNotEmpty)
                                          Text(
                                            'Alasan: $reason',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.black54,
                                              fontSize: 11,
                                            ),
                                          ),
                                        Text(
                                          description,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.black45,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: Colors.black26,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openReportDetail(Map<String, dynamic> report) {
    final id = _parseInt(report['id']);
    final status = _uiReportStatus(_text(report['status'], 'pending'));
    final reporter =
        _text(report['reporter_username'] ?? report['username'], '-');
    final reported = _text(
      report['reported_username'] ?? report['target_username'],
      'Tidak tersedia',
    );
    final product = _reportProductName(report);
    final displayType = _reportDisplayType(report);
    final reason = _reportReason(report);
    final isProductReport = _isProductReport(report);
    final description = _text(report['description'], '-');

    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: RouteSettings(
          name: '/admin/reports/$id',
          arguments: report,
        ),
        builder: (context) => Scaffold(
          backgroundColor: const Color(0xFFF6F6F7),
          appBar: AppBar(
            title: const Text('Detail Laporan'),
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildIconBox(_reportIcon(report)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            id == 0 ? displayType : '$displayType #LP-$id',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        _buildStatusChip(
                          _formatReportStatus(status),
                          Colors.orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _buildReportDetailRow('Pelapor', reporter),
                    if (isProductReport)
                      _buildReportDetailRow('Terlapor', reported),
                    if (product.isNotEmpty)
                      _buildReportDetailRow('Produk', product),
                    if (reason.isNotEmpty)
                      _buildReportDetailRow('Alasan', reason),
                    _buildReportDetailRow(
                      'Tanggal',
                      _formatDate(report['created_at']),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Deskripsi',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(description, style: const TextStyle(height: 1.45)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showBanDurationDialog(int userId, String username) async {
    const durationOptions = ['1', '7', '30'];
    String? selectedDuration;

    final duration = await showDialog<int>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 34,
                    spreadRadius: -12,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEFEF),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.block,
                          color: Color(0xFFE83030),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Blokir $username',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Pilih durasi pembatasan akun.',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Durasi Blokir',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: durationOptions
                        .map(
                          (duration) => ChoiceChip(
                            label: Text('$duration hari'),
                            selected: selectedDuration == duration,
                            onSelected: (_) => setDialogState(
                              () => selectedDuration = duration,
                            ),
                            selectedColor: const Color(0xFFE83030),
                            backgroundColor: const Color(0xFFF5F5F5),
                            labelStyle: TextStyle(
                              color: selectedDuration == duration
                                  ? Colors.white
                                  : Colors.black54,
                              fontWeight: selectedDuration == duration
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFE3A3)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Color(0xFFF59E0B),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Akun tidak dapat beraktivitas selama durasi blokir aktif.',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFE83030),
                            side: const BorderSide(color: Color(0xFFFFC7C7)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Batal',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: selectedDuration == null
                              ? null
                              : () => Navigator.pop(
                                    context,
                                    int.parse(selectedDuration!),
                                  ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE83030),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFFFFDADA),
                            disabledForegroundColor: Colors.white70,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Blokir',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (duration == null) return;
    await _banUser(userId, duration);
  }

  Future<void> _banUser(int userId, int durationDays) async {
    await _runAdminAction(
      action: () => _adminService.banUser(userId, durationDays),
      successMessage: 'Pengguna berhasil diblokir.',
    );
  }

  Future<void> _unbanUser(int userId) async {
    await _runAdminAction(
      action: () => _adminService.unbanUser(userId),
      successMessage: 'Blokir pengguna berhasil dibuka.',
    );
  }

  Future<void> _confirmDeleteUser(int userId, String username) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.38),
      builder: (dialogContext) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: _buildDangerDialogCard(
            icon: Icons.delete_forever_outlined,
            title: 'Hapus Akun',
            message:
                'Apakah Anda yakin ingin menghapus akun "$username"? Tindakan ini tidak dapat dibatalkan.',
            primaryLabel: 'Hapus',
            onCancel: () => Navigator.pop(dialogContext, false),
            onPrimary: () => Navigator.pop(dialogContext, true),
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      await _adminService.deleteUser(userId);
      if (!mounted) return;
      await _fetchAdminData();
      if (!mounted) return;
      await _showAdminSuccessDialog(
        title: 'Akun Berhasil Dihapus',
        message: 'Akun "$username" sudah dihapus dari Jualin.',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildDangerDialogCard({
    required IconData icon,
    required String title,
    required String message,
    required String primaryLabel,
    required VoidCallback onCancel,
    required VoidCallback onPrimary,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 34,
            spreadRadius: -12,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEFEF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: const Color(0xFFE83030), size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE83030),
                    side: const BorderSide(color: Color(0xFFFFC7C7)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Batal',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onPrimary,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE83030),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    primaryLabel,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showAdminSuccessDialog({
    required String title,
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (dialogContext) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 34,
                  spreadRadius: -12,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7EE),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF41B34D),
                    size: 34,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE83030),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Mengerti',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteProduct(int productId, String productName) async {
    const reasons = [
      'Produk melanggar ketentuan',
      'Foto produk tidak sesuai',
      'Deskripsi produk tidak jelas',
      'Produk terindikasi penipuan',
      'Produk duplikat',
      'Kategori produk tidak sesuai',
      'Stok atau informasi produk tidak valid',
      'Lainnya',
    ];

    final customReasonController = TextEditingController();
    String? selectedReason;

    final reason = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.38),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final needsCustom = selectedReason == 'Lainnya';
          final customReason = customReasonController.text.trim();
          final canDelete = selectedReason != null &&
              (!needsCustom || customReason.isNotEmpty);

          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 22),
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 34,
                      spreadRadius: -12,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEFEF),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.inventory_2_outlined,
                            color: Color(0xFFE83030),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Hapus Produk',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                productName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Alasan Penghapusan',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildChoiceField(
                      value: selectedReason,
                      hint: 'Pilih alasan penghapusan',
                      onTap: () async {
                        final picked = await _showAdminOptionSheet(
                          title: 'Alasan Penghapusan',
                          selected: selectedReason,
                          options: reasons,
                          labelBuilder: (value) => value,
                        );
                        if (picked == null || !context.mounted) return;
                        setDialogState(() => selectedReason = picked);
                      },
                    ),
                    if (needsCustom) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: customReasonController,
                        minLines: 2,
                        maxLines: 4,
                        onChanged: (_) => setDialogState(() {}),
                        decoration: InputDecoration(
                          labelText: 'Alasan lainnya',
                          hintText: 'Tulis alasan penghapusan',
                          filled: true,
                          fillColor: const Color(0xFFF8F8F8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFFE3A3)),
                      ),
                      child: const Text(
                        'Produk yang dihapus tidak akan tampil lagi di katalog.',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFE83030),
                              side: const BorderSide(color: Color(0xFFFFC7C7)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Batal',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: canDelete
                                ? () => Navigator.pop(
                                      context,
                                      needsCustom
                                          ? customReason
                                          : selectedReason,
                                    )
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE83030),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(0xFFFFDADA),
                              disabledForegroundColor: Colors.white70,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Hapus',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    customReasonController.dispose();
    if (reason == null || reason.trim().isEmpty) return;

    await _runAdminAction(
      action: () => _adminService.deleteProduct(productId, reason.trim()),
      successMessage: 'Produk berhasil dihapus.',
    );
  }

  Future<void> _updateTransactionStatus(int id, String status) async {
    await _runAdminAction(
      action: () => _adminService.updateTransactionStatus(id, status),
      successMessage: 'Status transaksi diperbarui.',
    );
  }

  Future<void> _updateReportStatus(int id, String status) async {
    await _runAdminAction(
      action: () => _adminService.updateReportStatus(id, status),
      successMessage: 'Status laporan diperbarui.',
    );
  }

  Future<void> _runAdminAction({
    required Future<void> Function() action,
    required String successMessage,
  }) async {
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
      await _fetchAdminData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (dialogContext) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 34,
                  spreadRadius: -12,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEEEE),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFE83030),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Konfirmasi Keluar',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Apakah Anda yakin ingin keluar dari Panel Admin?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFE83030),
                          side: const BorderSide(color: Color(0xFFFFC7C7)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text(
                          'Batal',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE83030),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Ya, Keluar',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    await _authService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().toLowerCase();
    return text == 'true' || text == '1' || text == 'yes';
  }

  bool _isCurrentlyBanned(Map<String, dynamic> user) {
    if (!_parseBool(user['is_banned'])) return false;

    final bannedUntil =
        DateTime.tryParse(user['banned_until']?.toString() ?? '');
    if (bannedUntil == null) return true;

    return bannedUntil.isAfter(DateTime.now());
  }

  String _text(dynamic value, [String fallback = '']) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  dynamic _nested(dynamic parent, String key) {
    if (parent is Map) return parent[key];
    return null;
  }

  bool _isProductReport(Map<String, dynamic> report) {
    final productId = _parseInt(report['product_id']);
    return productId > 0 || _reportProductName(report).isNotEmpty;
  }

  String _reportProductName(Map<String, dynamic> report) {
    return _text(
      report['reported_product_name'] ??
          _nested(report['product'], 'name') ??
          _nested(report['reported_product'], 'name'),
    );
  }

  String _reportReason(Map<String, dynamic> report) {
    final reason = _text(report['type']);
    if (reason.toLowerCase() == 'laporan umum') return '';
    return reason;
  }

  String _reportDisplayType(Map<String, dynamic> report) {
    return _isProductReport(report) ? 'Laporan Produk' : 'Laporan Umum';
  }

  IconData _reportIcon(Map<String, dynamic> report) {
    return _isProductReport(report)
        ? Icons.inventory_2_outlined
        : Icons.report_outlined;
  }

  String _extractImageUrl(dynamic raw) {
    return ImageUrlHelper.resolve(raw);
  }

  String _formatCurrency(int amount) {
    return 'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  String _formatDate(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed == null) return '-';
    return '${parsed.day}/${parsed.month}/${parsed.year}';
  }

  String _uiReportStatus(String status) {
    if (status == 'reviewed') return 'accepted';
    if (status == 'resolved') return 'rejected';
    if (status == 'processed') return 'processing';
    return status;
  }

  String _formatReportStatus(String status) {
    switch (status) {
      case 'pending':
        return 'Menunggu';
      case 'processing':
      case 'processed':
        return 'Diproses';
      case 'accepted':
      case 'reviewed':
        return 'Diterima';
      case 'rejected':
      case 'resolved':
        return 'Ditolak';
      default:
        return status;
    }
  }

  String _formatAdminOptionLabel(String value) {
    switch (value) {
      case 'pending':
        return 'Menunggu';
      case 'waiting_cod':
        return 'Menunggu COD';
      case 'paid':
        return 'Dibayar';
      case 'processing':
      case 'processed':
        return 'Diproses';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      case 'refunded':
        return 'Pengembalian Dana';
      case 'accepted':
      case 'reviewed':
        return 'Diterima';
      case 'rejected':
      case 'resolved':
        return 'Ditolak';
      default:
        return _formatTransactionStatus(value);
    }
  }

  String _formatTransactionStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Menunggu';
      case 'waiting_cod':
        return 'Menunggu COD';
      case 'paid':
        return 'Dibayar';
      case 'processing':
      case 'processed':
        return 'Diproses';
      case 'completed':
      case 'verified':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      case 'refunded':
        return 'Pengembalian Dana';
    }
    return status
        .replaceAll('_', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  String _formatUserRole(String role) {
    switch (role.toLowerCase()) {
      case 'customer':
        return 'Pembeli';
      case 'seller':
        return 'Penjual';
      case 'admin':
        return 'Admin';
      default:
        return role;
    }
  }
}
