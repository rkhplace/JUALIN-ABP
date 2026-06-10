import 'package:flutter/material.dart';
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
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: const Text('Klaim Pembayaran'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  'Masukkan 6 digit kode autentikasi yang diberikan oleh pembeli.'),
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
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final scanned = await _scanAuthCode(ctx);
                  if (!ctx.mounted) return;
                  if (scanned != null && scanned.isNotEmpty) {
                    Navigator.pop(ctx, scanned.toUpperCase());
                  }
                },
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan Kode'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE83030)),
              onPressed: () {
                final code = authCodeController.text.trim();
                debugPrint(
                  '[SellerOrders] Claim dialog submit tapped '
                  'for transactionId=$transactionId codeLength=${code.length}',
                );
                if (code.length == 6) {
                  Navigator.pop(ctx, code);
                } else {
                  debugPrint(
                      '[SellerOrders] Claim dialog ignored: code must be 6 chars');
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
    return 'Rp ${val.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
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
      title: 'Pesanan Masuk',
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

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = _orders[index];
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
              const SizedBox(height: 6),
              // Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total',
                      style: TextStyle(color: Colors.black54, fontSize: 13)),
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

              if ((status == 'refunded' || status == 'cancelled') &&
                  refundReason.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(12),
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
