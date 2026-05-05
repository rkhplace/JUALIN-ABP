import 'package:flutter/material.dart';
import '../../services/seller_service.dart';
import '../../services/auth_service.dart';
import '../../services/escrow_service.dart';

class SellerOrdersScreen extends StatefulWidget {
  const SellerOrdersScreen({super.key});

  @override
  State<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends State<SellerOrdersScreen> {
  final SellerService _sellerService = SellerService();
  final AuthService _authService = AuthService();
  final EscrowService _escrowService = EscrowService();

  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _currentUserId = 0;
  bool _isClaiming = false;

  @override
  void initState() {
    super.initState();
    _init();
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
          .where((o) => _currentUserId == 0 || (o['seller_id'] as int?) == _currentUserId)
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

  Future<void> _handleClaimPayment(BuildContext context, int transactionId) async {
    debugPrint('[SellerOrders] Claim button clicked for transactionId=$transactionId');
    final TextEditingController authCodeController = TextEditingController();

    debugPrint('[SellerOrders] Opening claim code dialog');
    final String? authCode = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Klaim Pembayaran'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Masukkan 6 digit kode autentikasi yang diberikan oleh pembeli.'),
              const SizedBox(height: 16),
              TextField(
                controller: authCodeController,
                maxLength: 6,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Kode Autentikasi',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE83030)),
              onPressed: () {
                final code = authCodeController.text.trim();
                debugPrint(
                  '[SellerOrders] Claim dialog submit tapped '
                  'for transactionId=$transactionId codeLength=${code.length}',
                );
                if (code.length == 6) {
                  Navigator.pop(ctx, code);
                } else {
                  debugPrint('[SellerOrders] Claim dialog ignored: code must be 6 chars');
                }
              },
              child: const Text('Klaim', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (authCode == null || authCode.isEmpty) return;

    if (!context.mounted) return;
    setState(() => _isClaiming = true);

    try {
      debugPrint('[SellerOrders] Sending escrow claim for transactionId=$transactionId');
      await _escrowService.claimPayment(transactionId, authCode);
      debugPrint('[SellerOrders] Escrow claim success for transactionId=$transactionId');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pembayaran berhasil diklaim ke saldo Anda!'),
          backgroundColor: Colors.green,
        ),
      );
      _fetchOrders();
    } catch (e) {
      debugPrint('[SellerOrders] Escrow claim failed for transactionId=$transactionId: $e');
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

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'waiting_cod':
        return const Color(0xFFE87D30);
      case 'verified':
      case 'processing':
        return Colors.blue;
      case 'completed':
        return Colors.green;
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
        return 'Terverifikasi';
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
    return 'Rp ${val.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Pesanan Masuk'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            color: const Color(0xFFE83030),
            onRefresh: _fetchOrders,
            child: _buildBody(),
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
      return const Center(child: CircularProgressIndicator(color: Color(0xFFE83030)));
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
              Text(_errorMessage!, textAlign: TextAlign.center,
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

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = _orders[index];
        final customer = order['customer'] as Map<String, dynamic>? ?? {};
        final items = (order['items'] as List<dynamic>?) ?? [];
        final firstItem = items.isNotEmpty ? (items[0] as Map<String, dynamic>?) ?? {} : {};
        final product = firstItem['product'] as Map<String, dynamic>? ?? {};
        final status = (order['status'] as String?) ?? 'pending';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
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
                    'Order #${order['id'] ?? '-'}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  _StatusBadge(label: _statusLabel(status), color: _statusColor(status)),
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
              const SizedBox(height: 6),
              // Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(color: Colors.black54, fontSize: 13)),
                  Text(
                    _formatCurrency(order['total_amount']),
                    style: const TextStyle(
                      color: Color(0xFFE83030),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              
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
                            _handleClaimPayment(context, order['id']);
                          },
                    child: const Text('Klaim Pembayaran (Input Kode)', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ],
          ),
        );
      },
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
