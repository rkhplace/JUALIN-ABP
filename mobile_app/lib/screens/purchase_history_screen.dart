import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/payment_service.dart';
import '../services/escrow_service.dart';
import '../widgets/ui/frosted_app_bar.dart';
import '../widgets/ui/logo_loader.dart';
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
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _purchases = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isProcessingAction = false;
  String _statusFilter = 'all';

  bool _isWaitingForPayment = false;
  String? _currentOrderId;

  List<dynamic> get _filteredPurchases {
    final query = _searchController.text.trim().toLowerCase();

    return _purchases.where((purchase) {
      final p = purchase as Map<String, dynamic>;
      final status =
          p['transaction_status']?.toString().toLowerCase() ?? 'pending';
      final statusMatches = switch (_statusFilter) {
        'pending' => status == 'pending',
        'waiting_cod' => status == 'waiting_cod',
        'completed' => status == 'verified' ||
            status == 'completed' ||
            status == 'settlement' ||
            status == 'capture' ||
            status == 'paid',
        'refunded' => status == 'refunded' || status == 'cancelled',
        _ => true,
      };

      if (!statusMatches) return false;
      if (query.isEmpty) return true;

      final transactionInfo = p['transaction'] as Map<String, dynamic>? ?? {};
      final searchable = [
        p['order_id'],
        p['first_item_name'],
        p['seller_name'],
        p['transaction_time'],
        p['gross_amount'],
        transactionInfo['auth_code'],
        _statusLabel(status),
        status,
      ].whereType<Object>().join(' ').toLowerCase();

      return searchable.contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _searchController.addListener(() => setState(() {}));
    _fetchHistory();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleBack() async {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    navigator.pushReplacementNamed('/main');
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
    const reasons = [
      'Penjual tidak merespons',
      'Produk tidak tersedia',
      'Pembeli membatalkan pesanan',
      'Produk tidak sesuai',
      'Transaksi bermasalah',
      'Lainnya',
    ];
    String selectedReason = 'Pembeli membatalkan pesanan';
    final customReasonController = TextEditingController();
    bool customReasonError = false;

    final String? refundReason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return SafeArea(
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 18),
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const Text(
                      'Ajukan Pengembalian Dana',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Apakah Anda yakin ingin membatalkan pesanan ini? Dana akan dikembalikan ke saldo Jualin Anda.',
                      style: TextStyle(fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Alasan pengembalian dana',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...reasons.map(
                      (reason) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            setSheetState(() {
                              selectedReason = reason;
                              customReasonError = false;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 13,
                            ),
                            decoration: BoxDecoration(
                              color: selectedReason == reason
                                  ? const Color(0xFFFFEEEE)
                                  : const Color(0xFFF8F8F8),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: selectedReason == reason
                                    ? const Color(0xFFE83030)
                                    : Colors.black12,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    reason,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: selectedReason == reason
                                          ? const Color(0xFFE83030)
                                          : Colors.black87,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                if (selectedReason == reason)
                                  const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFFE83030),
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (selectedReason == 'Lainnya') ...[
                      const SizedBox(height: 4),
                      TextField(
                        controller: customReasonController,
                        maxLines: 3,
                        onChanged: (_) {
                          if (customReasonError) {
                            setSheetState(() => customReasonError = false);
                          }
                        },
                        decoration: InputDecoration(
                          hintText: 'Tulis alasan pengembalian dana',
                          hintStyle: const TextStyle(fontSize: 13),
                          filled: true,
                          fillColor: const Color(0xFFF8F8F8),
                          errorText: customReasonError
                              ? 'Alasan pengembalian dana wajib diisi.'
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFE83030),
                              width: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFE83030),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                            child: const Text('Batal'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE83030),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                            onPressed: () {
                              final reason = selectedReason == 'Lainnya'
                                  ? customReasonController.text.trim()
                                  : selectedReason;

                              if (reason.isEmpty) {
                                setSheetState(() => customReasonError = true);
                                return;
                              }

                              Navigator.pop(sheetContext, reason);
                            },
                            child: const Text('Ya, Ajukan'),
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

    if (!mounted || refundReason == null || refundReason.trim().isEmpty) {
      return;
    }

    setState(() => _isProcessingAction = true);

    try {
      await _escrowService.refundPayment(transactionId, refundReason.trim());
      if (mounted) {
        _showRefundSuccessDialog(context);
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
        : num.tryParse(amount?.toString() ?? '')?.toInt() ?? 0;

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

  void _showRefundSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 64,
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Transaksi Berhasil Dibatalkan',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                'Dana pengembalian telah masuk ke saldo Jualin Anda.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 13),
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
                  elevation: 0,
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
      ),
    );
  }

  Color _statusColor(String status) {
    status = status.toLowerCase();
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'waiting_cod':
        return const Color(0xFFE87D30);
      case 'verified':
      case 'completed':
      case 'settlement':
      case 'capture':
      case 'paid':
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
    status = status.toLowerCase();
    switch (status) {
      case 'pending':
        return 'Menunggu';
      case 'waiting_cod':
        return 'Tunggu COD';
      case 'verified':
        return 'Selesai';
      case 'processing':
        return 'Diproses';
      case 'settlement':
      case 'capture':
      case 'paid':
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
              onRefresh: _fetchHistory,
              child: _buildBody(),
            ),
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
      return const JualinLogoLoader(size: 64);
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

    final purchases = _filteredPurchases;

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: purchases.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPageHeader(purchases.length),
              const SizedBox(height: 14),
              _buildSearchAndFilterBar(),
              if (purchases.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(
                    child: Text(
                      'Tidak ada riwayat sesuai pencarian atau filter.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                ),
            ],
          );
        }

        final p = purchases[index - 1];
        final String status =
            p['transaction_status']?.toString().toLowerCase() ?? 'pending';

        // Wait COD overrides regular status visually
        final bool isWaitingCod = status == 'waiting_cod';
        final String displayStatus = isWaitingCod ? 'waiting_cod' : status;

        final bool isPending = displayStatus == 'pending';

        final String title =
            p['first_item_name']?.toString() ?? 'Pesanan #${p['order_id']}';
        final String subtitle = p['seller_name']?.toString() ?? 'Penjual';
        final transactionInfo = p['transaction'] as Map<String, dynamic>? ?? {};
        final refundReason = p['refund_reason']?.toString() ??
            transactionInfo['refund_reason']?.toString() ??
            '';
        final refundedAt = p['refunded_at']?.toString() ??
            transactionInfo['refunded_at']?.toString() ??
            '';

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
                                  child: const Text('Kembalikan Dana',
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
                ],

                if (status == 'refunded' && refundReason.isNotEmpty) ...[
                  const SizedBox(height: 16),
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
                          'Alasan pengembalian dana: $refundReason',
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
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPageHeader(int purchaseCount) {
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
              Material(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(15),
                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: _handleBack,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
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
                      'Riwayat Pembelian',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$purchaseCount transaksi ditampilkan',
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

  Widget _buildSearchAndFilterBar() {
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
                hintText: 'Cari riwayat...',
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
              onPressed: _showHistoryFilterSheet,
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

  void _showHistoryFilterSheet() {
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
                      'Filter Riwayat',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Status Transaksi',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _historyFilterChip(
                          label: 'Semua',
                          active: tempStatus == 'all',
                          onTap: () => setSheetState(() => tempStatus = 'all'),
                        ),
                        _historyFilterChip(
                          label: 'Menunggu Bayar',
                          active: tempStatus == 'pending',
                          onTap: () =>
                              setSheetState(() => tempStatus = 'pending'),
                        ),
                        _historyFilterChip(
                          label: 'Menunggu COD',
                          active: tempStatus == 'waiting_cod',
                          onTap: () =>
                              setSheetState(() => tempStatus = 'waiting_cod'),
                        ),
                        _historyFilterChip(
                          label: 'Selesai',
                          active: tempStatus == 'completed',
                          onTap: () =>
                              setSheetState(() => tempStatus = 'completed'),
                        ),
                        _historyFilterChip(
                          label: 'Dana Dikembalikan',
                          active: tempStatus == 'refunded',
                          onTap: () =>
                              setSheetState(() => tempStatus = 'refunded'),
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

  Widget _historyFilterChip({
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
