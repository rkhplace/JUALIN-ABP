import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/seller_service.dart';
import '../../services/auth_service.dart';
import '../../services/escrow_service.dart';
import '../../widgets/ui/frosted_app_bar.dart';
import '../../widgets/ui/logo_loader.dart';
import 'dart:convert';

class SellerOrdersScreen extends StatefulWidget {
  const SellerOrdersScreen({super.key});

  @override
  State<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends State<SellerOrdersScreen> {
  final SellerService _sellerService = SellerService();
  final AuthService _authService = AuthService();
  final EscrowService _escrowService = EscrowService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _currentUserId = 0;
  bool _isClaiming = false;
  String _statusFilter = 'all';

  List<Map<String, dynamic>> get _filteredOrders {
    final query = _searchController.text.trim().toLowerCase();

    return _orders.where((order) {
      final status = (order['status'] ?? '').toString().toLowerCase();
      final statusMatches = switch (_statusFilter) {
        'waiting_cod' => status == 'waiting_cod',
        'completed' => status == 'verified' || status == 'completed',
        'cancelled' => status == 'cancelled' || status == 'refunded',
        'pending' => status == 'pending' || status == 'processing',
        _ => true,
      };

      if (!statusMatches) return false;
      if (query.isEmpty) return true;

      final customer = order['customer'] as Map<String, dynamic>? ?? {};
      final items = (order['items'] as List<dynamic>?) ?? [];
      final firstItem =
          items.isNotEmpty ? (items[0] as Map<String, dynamic>?) ?? {} : {};
      final product = firstItem['product'] as Map<String, dynamic>? ?? {};
      final searchable = [
        order['id'],
        order['order_id'],
        product['name'],
        customer['username'],
        customer['name'],
        _statusLabel(status),
        status,
      ].whereType<Object>().join(' ').toLowerCase();

      return searchable.contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _init();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    // Load user_id from prefs so we can filter seller-side orders
    final prefs = await _authService.getUserIdAndRole();
    _currentUserId = prefs['id'] ?? 0;
    await _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final all = await _sellerService.getSellerOrders();
      // Filter orders where current user is the seller
      final sellerOrders = all
          .where((o) =>
              _currentUserId == 0 || (o['seller_id'] as int?) == _currentUserId)
          .toList();
      if (mounted) {
        setState(() {
          _orders = sellerOrders;
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

  Future<void> _handleClaimPayment(
      BuildContext context, Map<String, dynamic> order) async {
    final transactionId = _parseInt(order['id']);
    debugPrint(
        '[SellerOrders] Claim button clicked for transactionId=$transactionId');
    final TextEditingController authCodeController = TextEditingController();

    debugPrint('[SellerOrders] Opening claim code dialog');
    final String? authCode = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool showCodeError = false;

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final code = authCodeController.text.trim().toUpperCase();
            final canClaim = code.length == 6;

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.14),
                      blurRadius: 28,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEAEA),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.payments_outlined,
                              color: Color(0xFFE83030),
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Klaim Pembayaran',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1D1D1F),
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Cek kode dari pembeli',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF8C8C8C),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7F7),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFFFD6D6)),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 19,
                              color: Color(0xFFE83030),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Minta pembeli membuka Riwayat Pembelian, lalu tunjukkan kode atau QR penukaran untuk barang ini.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  height: 1.35,
                                  color: Color(0xFF5B3A3A),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: authCodeController,
                        maxLength: 6,
                        keyboardType: TextInputType.text,
                        textAlign: TextAlign.center,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z0-9]'),
                          ),
                          UpperCaseTextFormatter(),
                        ],
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 5,
                          color: Color(0xFF1D1D1F),
                        ),
                        decoration: InputDecoration(
                          labelText: 'Kode Autentikasi',
                          hintText: 'ABC123',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade300,
                            letterSpacing: 4,
                            fontWeight: FontWeight.w700,
                          ),
                          counterText: '',
                          errorText: showCodeError && !canClaim
                              ? 'Kode harus 6 karakter.'
                              : null,
                          filled: true,
                          fillColor: const Color(0xFFFAFAFA),
                          floatingLabelStyle:
                              const TextStyle(color: Color(0xFFE83030)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                const BorderSide(color: Color(0xFFE7E7E7)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFE83030),
                              width: 1.4,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                const BorderSide(color: Color(0xFFE83030)),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFE83030),
                              width: 1.4,
                            ),
                          ),
                        ),
                        onChanged: (_) {
                          if (showCodeError) {
                            setDialogState(() => showCodeError = false);
                          } else {
                            setDialogState(() {});
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final scanned = await _scanAuthCode(ctx);
                          if (!ctx.mounted) return;
                          if (scanned != null && scanned.isNotEmpty) {
                            Navigator.pop(ctx, scanned.toUpperCase());
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFE83030),
                          side: const BorderSide(color: Color(0xFFFFC8C8)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        icon: const Icon(Icons.qr_code_scanner, size: 19),
                        label: const Text(
                          'Scan QR dari pembeli',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(ctx, null),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF777777),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'Batal',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE83030),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () {
                                final submittedCode =
                                    authCodeController.text.trim();
                                debugPrint(
                                  '[SellerOrders] Claim dialog submit tapped '
                                  'for transactionId=$transactionId codeLength=${submittedCode.length}',
                                );
                                if (submittedCode.length == 6) {
                                  Navigator.pop(ctx, submittedCode);
                                } else {
                                  debugPrint(
                                      '[SellerOrders] Claim dialog ignored: code must be 6 chars');
                                  setDialogState(() => showCodeError = true);
                                }
                              },
                              child: const Text(
                                'Klaim',
                                style: TextStyle(fontWeight: FontWeight.w800),
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
        );
      },
    );
    authCodeController.dispose();

    if (authCode == null || authCode.isEmpty) return;

    if (!context.mounted) return;
    setState(() => _isClaiming = true);

    try {
      debugPrint(
          '[SellerOrders] Sending escrow claim for transactionId=$transactionId');
      await _escrowService.claimPayment(transactionId, authCode);
      debugPrint(
          '[SellerOrders] Escrow claim success for transactionId=$transactionId');
      if (!context.mounted) return;
      _showClaimSuccessDialog(context, order);
      await _fetchOrders();
    } catch (e) {
      debugPrint(
          '[SellerOrders] Escrow claim failed for transactionId=$transactionId: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isClaiming = false);
      }
    }
  }

  Future<String?> _scanAuthCode(BuildContext context) async {
    return showDialog<String>(
      context: context,
      builder: (_) => const _EscrowCodeScannerDialog(),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'waiting_cod':
        return const Color(0xFFE87D30);
      case 'verified':
      case 'completed':
        return Colors.green;
      case 'processing':
        return Colors.blue;
      case 'refunded':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Menunggu';
      case 'waiting_cod':
        return 'Tunggu COD';
      case 'verified':
        return 'Selesai';
      case 'processing':
        return 'Diproses';
      case 'completed':
        return 'Selesai';
      case 'refunded':
        return 'Dikembalikan';
      default:
        return status;
    }
  }

  String _formatCurrency(dynamic amount) {
    int val = 0;
    if (amount is num) {
      val = amount.toInt();
    } else if (amount is String) {
      val = double.tryParse(amount)?.toInt() ?? 0;
    }
    return 'Rp${val.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Widget _buildBuyerCredibilityCard(Map<String, dynamic> customer) {
    final rawCredibility = customer['buyer_credibility'];
    if (rawCredibility is! Map) return const SizedBox.shrink();

    final credibility = rawCredibility.cast<String, dynamic>();
    final level = credibility['level']?.toString() ?? 'new';
    final label = credibility['label']?.toString() ?? 'Pembeli Baru';
    final signals = (credibility['signals'] as List<dynamic>? ?? [])
        .map((item) => item.toString())
        .where((item) => item.trim().isNotEmpty)
        .take(3)
        .toList();
    final color = _buyerCredibilityColor(level);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10, bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _buyerCredibilityIcon(level),
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  signals.isEmpty
                      ? 'Belum ada riwayat kredibilitas pembeli.'
                      : signals.join(' | '),
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Colors.black54,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (level == 'new') ...[
                  const SizedBox(height: 3),
                  const Text(
                    'Saran: pastikan kode/QR cocok sebelum menyerahkan barang.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.black45,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _buyerCredibilityColor(String level) {
    switch (level) {
      case 'trusted':
        return Colors.green;
      case 'active':
        return Colors.blue;
      case 'needs_attention':
        return const Color(0xFFD97706);
      default:
        return Colors.grey;
    }
  }

  IconData _buyerCredibilityIcon(String level) {
    switch (level) {
      case 'trusted':
        return Icons.verified_rounded;
      case 'active':
        return Icons.history_rounded;
      case 'needs_attention':
        return Icons.info_outline_rounded;
      default:
        return Icons.person_search_rounded;
    }
  }

  void _showClaimSuccessDialog(
      BuildContext context, Map<String, dynamic> order) {
    final orderId = order['order_id']?.toString() ?? order['id']?.toString();
    final amount = _formatCurrency(order['total_amount']);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 64,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Transaksi Berhasil Diklaim!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Dana transaksi telah masuk ke saldo dompet Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  if (orderId != null && orderId.isNotEmpty) ...[
                    _buildDetailRow('Order ID', orderId),
                    const SizedBox(height: 8),
                  ],
                  _buildDetailRow('Total Pembayaran', amount),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    'Status',
                    'DIKLAIM',
                    valueColor: Colors.green[800],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE83030),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Tutup',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.black54, fontSize: 13)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.black87,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FrostedScaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      showAppBar: false,
      body: Stack(
        children: [
          SafeArea(
            child: RefreshIndicator(
              color: const Color(0xFFE83030),
              onRefresh: _fetchOrders,
              child: _buildBody(),
            ),
          ),
          if (_isClaiming)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const JualinLogoLoader(size: 64);
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(_errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _fetchOrders,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }
    if (_orders.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Center(
            child: Column(
              children: [
                Icon(Icons.receipt_long, size: 56, color: Colors.grey),
                SizedBox(height: 12),
                Text('Belum ada pesanan masuk.',
                    style: TextStyle(color: Colors.black54, fontSize: 16)),
              ],
            ),
          ),
        ],
      );
    }

    final orders = _filteredOrders;

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPageHeader(orders.length),
              const SizedBox(height: 14),
              _buildSearchAndFilterBar(),
              if (orders.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(
                    child: Text(
                      'Tidak ada pesanan sesuai filter.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                ),
            ],
          );
        }

        final order = orders[index - 1];
        final customer = order['customer'] as Map<String, dynamic>? ?? {};
        final items = (order['items'] as List<dynamic>?) ?? [];
        final firstItem =
            items.isNotEmpty ? (items[0] as Map<String, dynamic>?) ?? {} : {};
        final product = firstItem['product'] as Map<String, dynamic>? ?? {};
        final status = (order['status'] as String?) ?? 'pending';
        final refundReason = order['refund_reason']?.toString() ?? '';
        final refundedAt = order['refunded_at']?.toString() ?? '';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                spreadRadius: -9,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: Order ID + Status badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pesanan #${order['id'] ?? '-'}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  _StatusBadge(
                      label: _statusLabel(status), color: _statusColor(status)),
                ],
              ),
              const SizedBox(height: 10),
              // Product name
              Row(
                children: [
                  const Icon(Icons.shopping_bag_outlined,
                      size: 16, color: Colors.black45),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      product['name']?.toString() ?? 'Produk',
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Buyer name
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 16, color: Colors.black45),
                  const SizedBox(width: 6),
                  Text(
                    customer['username']?.toString() ?? 'Pembeli',
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
              _buildBuyerCredibilityCard(customer),
              const SizedBox(height: 6),
              // Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total',
                      style: TextStyle(
                          color: Colors.black45,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  Text(
                    _formatCurrency(order['total_amount']),
                    style: const TextStyle(
                      color: Color(0xFFE83030),
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),

              if ((status == 'refunded' || status == 'cancelled') &&
                  refundReason.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.purple[100]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alasan refund: $refundReason',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (refundedAt.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Diproses: $refundedAt',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],

              if (status == 'waiting_cod') ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE83030),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _isClaiming
                        ? null
                        : () {
                            debugPrint(
                              '[SellerOrders] Claim CTA pressed for orderId=${order['id']}',
                            );
                            _handleClaimPayment(context, order);
                          },
                    child: const Text('Klaim Pembayaran (Input Kode)',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPageHeader(int orderCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE83030), Color(0xFFF64A4A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE83030).withValues(alpha: 0.22),
            blurRadius: 24,
            spreadRadius: -8,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -30,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.13),
                  width: 2,
                ),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(15),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pesanan Masuk',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$orderCount pesanan ditampilkan',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderFilterPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            spreadRadius: -8,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari pesanan...',
                prefixIcon:
                    const Icon(Icons.search, color: Colors.black45, size: 20),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: _searchController.clear,
                      ),
                filled: true,
                fillColor: const Color(0xFFF7F7F7),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 48,
            width: 48,
            child: ElevatedButton(
              onPressed: _showOrderFilterSheet,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE83030),
                foregroundColor: Colors.white,
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

  Widget _buildSearchAndFilterBar() => _buildOrderFilterPanel();

  void _showOrderFilterSheet() {
    var tempStatus = _statusFilter;

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
                      'Filter Pesanan',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Status Pesanan',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _filterChip(
                          label: 'Semua',
                          active: tempStatus == 'all',
                          onTap: () => setSheetState(() => tempStatus = 'all'),
                        ),
                        _filterChip(
                          label: 'Diproses',
                          active: tempStatus == 'pending',
                          onTap: () =>
                              setSheetState(() => tempStatus = 'pending'),
                        ),
                        _filterChip(
                          label: 'Menunggu COD',
                          active: tempStatus == 'waiting_cod',
                          onTap: () =>
                              setSheetState(() => tempStatus = 'waiting_cod'),
                        ),
                        _filterChip(
                          label: 'Selesai',
                          active: tempStatus == 'completed',
                          onTap: () =>
                              setSheetState(() => tempStatus = 'completed'),
                        ),
                        _filterChip(
                          label: 'Batal/Pengembalian',
                          active: tempStatus == 'cancelled',
                          onTap: () =>
                              setSheetState(() => tempStatus = 'cancelled'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() => _statusFilter = 'all');
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFE83030),
                              side: const BorderSide(color: Color(0xFFE83030)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('Reset'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() => _statusFilter = tempStatus);
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE83030),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('Terapkan'),
                          ),
                        ),
                      ],
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

  Widget _filterChip({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFE83030) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active
                ? const Color(0xFFE83030)
                : Colors.black.withValues(alpha: 0.16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (active) ...[
              const Icon(Icons.check, color: Colors.white, size: 16),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : Colors.black54,
                fontWeight: active ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EscrowCodeScannerDialog extends StatefulWidget {
  const _EscrowCodeScannerDialog();

  @override
  State<_EscrowCodeScannerDialog> createState() =>
      _EscrowCodeScannerDialogState();
}

class _EscrowCodeScannerDialogState extends State<_EscrowCodeScannerDialog> {
  late final MobileScannerController _scannerController;
  bool _hasScanned = false;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleDetect(BarcodeCapture capture) async {
    if (_hasScanned) return;

    String? value;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue?.trim();
      if (raw != null && raw.isNotEmpty) {
        value = raw;
        break;
      }
    }

    if (value == null || value.isEmpty) return;

    String? authCode = value;
    try {
      final payload = jsonDecode(value);
      if (payload is Map<String, dynamic>) {
        authCode = payload['auth_code']?.toString().trim() ??
            payload['data']?['auth_code']?.toString().trim();
      }
    } catch (_) {
      // bukan JSON, terus gunakan value apa adanya
    }

    if (authCode == null || authCode.isEmpty) return;

    _hasScanned = true;
    await _scannerController.stop();
    if (mounted) {
      Navigator.pop(context, authCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 10, 10),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Scan Escrow Code',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tutup',
                    onPressed: () => Navigator.pop(context, null),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      MobileScanner(
                        controller: _scannerController,
                        fit: BoxFit.cover,
                        onDetect: _handleDetect,
                        placeholderBuilder: (context, child) => Container(
                          color: Colors.black,
                          alignment: Alignment.center,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        ),
                        errorBuilder: (context, error, child) => Container(
                          color: Colors.black,
                          padding: const EdgeInsets.all(18),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.no_photography_outlined,
                                color: Colors.white,
                                size: 44,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _scannerErrorMessage(error),
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IgnorePointer(
                        child: Center(
                          child: Container(
                            width: 210,
                            height: 210,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 12, 18, 4),
              child: Text(
                'Arahkan kamera ke QR/barcode escrow. Jika tidak terbaca, tutup scanner dan masukkan kode manual.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _scannerController.switchCamera(),
                      icon: const Icon(Icons.cameraswitch_outlined),
                      label: const Text('Ganti Kamera'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE83030),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context, null),
                      child: const Text('Input Manual'),
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

  String _scannerErrorMessage(MobileScannerException error) {
    return switch (error.errorCode) {
      MobileScannerErrorCode.permissionDenied =>
        'Izin kamera ditolak. Aktifkan izin kamera atau gunakan input manual.',
      MobileScannerErrorCode.unsupported =>
        'Kamera tidak didukung di perangkat ini. Gunakan input manual.',
      _ => 'Kamera belum bisa dibuka. Coba lagi atau gunakan input manual.',
    };
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
