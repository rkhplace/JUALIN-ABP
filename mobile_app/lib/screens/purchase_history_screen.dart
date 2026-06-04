import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/payment_service.dart';
import '../services/escrow_service.dart';
import '../widgets/ui/frosted_app_bar.dart';
import 'escrow_qr_screen.dart';

class PurchaseHistoryScreen extends StatefulWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  State<PurchaseHistoryScreen> createState() => _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends State<PurchaseHistoryScreen>
    with WidgetsBindingObserver {
  final PaymentService _paymentService = PaymentService();
  final EscrowService _escrowService = EscrowService();

  List<dynamic> _purchases = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isProcessingAction = false;

  bool _isWaitingForPayment = false;
  String? _currentOrderId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchHistory();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isWaitingForPayment) {
      _isWaitingForPayment = false;
      _checkLatestTransactionStatus();
    }
  }

  Future<void> _checkLatestTransactionStatus() async {
    if (!mounted) return;
    setState(() => _isProcessingAction = true);

    try {
      if (_currentOrderId != null) {
        // Force backend to sync with Midtrans first
        await _paymentService.checkPaymentStatus(_currentOrderId!);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingAction = false);
        // Refresh the list after the forced sync
        _fetchHistory();
      }
    }
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _paymentService.getPurchaseHistory();
      if (mounted) {
        setState(() {
          _purchases = data;
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

  Future<void> _handleResumePayment(
      String? snapToken, String? snapUrl, String? orderId) async {
    if (snapUrl == null || snapUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL Pembayaran tidak tersedia.')),
      );
      return;
    }

    try {
      _currentOrderId = orderId;
      _isWaitingForPayment = true;

      final url = Uri.parse(snapUrl);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Gagal membuka Midtrans');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleRefund(int transactionId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Refund'),
        content: const Text(
            'Apakah Anda yakin ingin membatalkan pesanan ini? Dana akan dikembalikan ke saldo Jualin Anda.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Ya, Refund', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessingAction = true);

    try {
      await _escrowService.refundPayment(transactionId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Refund berhasil diproses! Dana telah kembali ke Saldo.'),
            backgroundColor: Colors.green,
          ),
        );
      }
      _fetchHistory();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingAction = false);
    }
  }

  void _showQrCode(String? authCode, String? orderId, dynamic amount) {
    if (authCode == null || authCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kode tidak tersedia')),
      );
      return;
    }

    final parsedAmount = amount is num
        ? amount.toInt()
        : int.tryParse(amount?.toString() ?? '') ?? 0;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EscrowQrScreen(
          transactionId: orderId ?? 'unknown',
          amount: parsedAmount,
          sellerId: 'buyer',
          authCode: authCode,
          expiresAt: null,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    status = status.toLowerCase();
    switch (status) {
      case 'pending':
        return Colors.red;
      case 'waiting_cod':
        return Colors.orange;
      case 'verified':
      case 'processing':
        return Colors.blue;
      case 'completed':
      case 'settlement':
      case 'capture':
        return Colors.green;
      case 'refunded':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    status = status.toLowerCase();
    switch (status) {
      case 'pending':
        return 'Menunggu Pembayaran';
      case 'waiting_cod':
        return 'Menunggu COD (Tunjukkan Kode)';
      case 'verified':
        return 'Terverifikasi';
      case 'settlement':
      case 'capture':
      case 'paid':
      case 'completed':
        return 'Selesai';
      case 'refunded':
        return 'Dikembalikan & Dibatalkan';
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
    return FrostedScaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      title: 'Riwayat Pembelian',
      body: Stack(
        children: [
          RefreshIndicator(
            color: const Color(0xFFE83030),
            onRefresh: _fetchHistory,
            child: _buildBody(),
          ),
          if (_isProcessingAction)
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
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFFE83030)));
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(_errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _fetchHistory,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }
    if (_purchases.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Center(
            child: Column(
              children: [
                Icon(Icons.receipt_long, size: 56, color: Colors.grey),
                SizedBox(height: 12),
                Text('Belum ada riwayat pembelian.',
                    style: TextStyle(color: Colors.black54, fontSize: 16)),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _purchases.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final p = _purchases[index];
        final String status =
            p['transaction_status']?.toString().toLowerCase() ?? 'pending';

        // Wait COD overrides regular status visually
        final bool isWaitingCod = status == 'waiting_cod';
        final String displayStatus = isWaitingCod ? 'waiting_cod' : status;

        final bool isPending = displayStatus == 'pending';

        final String title =
            p['first_item_name']?.toString() ?? 'Order #${p['order_id']}';
        final String subtitle = p['seller_name']?.toString() ?? 'Penjual';
        final transactionInfo = p['transaction'] as Map<String, dynamic>? ?? {};

        return GestureDetector(
          onTap: isPending
              ? () => _handleResumePayment(
                  p['snap_token'], p['snap_url'], p['order_id'])
              : null,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isPending ? Colors.red[200]! : Colors.black12,
              ),
              boxShadow: isPending
                  ? [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.1),
                        blurRadius: 8,
                      )
                    ]
                  : [
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
                // Header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isPending
                                  ? const Color(0xFFE83030)
                                  : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: const TextStyle(
                                fontSize: 13, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            _statusColor(displayStatus).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _statusColor(displayStatus)
                                .withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        _statusLabel(displayStatus),
                        style: TextStyle(
                          color: _statusColor(displayStatus),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Content Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Date
                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 14, color: Colors.black45),
                        const SizedBox(width: 6),
                        Text(
                          p['transaction_time'] != null
                              ? p['transaction_time']
                                  .toString()
                                  .substring(0, 10)
                              : '-',
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black54),
                        ),
                      ],
                    ),
                    // Total
                    Text(
                      _formatCurrency(p['gross_amount']),
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),

                if (isPending) ...[
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text('Klik untuk melanjutkan pembayaran →',
                        style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFFE83030),
                            fontWeight: FontWeight.w600)),
                  ),
                ],

                // Escrow Action Block
                if (isWaitingCod) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Tunjukkan kode ini kepada penjual jika barang sudah diterima dengan baik.',
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              transactionInfo['auth_code'] ?? '-----',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 4,
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE83030),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  onPressed: () => _showQrCode(
                                    transactionInfo['auth_code']?.toString(),
                                    p['order_id']?.toString(),
                                    p['gross_amount'],
                                  ),
                                  child: const Text('QR Code',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                    elevation: 0,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  onPressed: () =>
                                      _handleRefund(p['transaction_id']),
                                  child: const Text('Refund Dana',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                ]
              ],
            ),
          ),
        );
      },
    );
  }
}
