import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/product.dart';
import '../services/payment_service.dart';
import '../services/profile_service.dart';
import '../widgets/ui/frosted_app_bar.dart';
import '../widgets/ui/logo_loader.dart';

class CheckoutScreen extends StatefulWidget {
  final Product product;
  const CheckoutScreen({super.key, required this.product});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen>
    with WidgetsBindingObserver {
  final PaymentService _paymentService = PaymentService();
  final ProfileService _profileService = ProfileService();

  String _selectedMethod = 'gateway'; // 'wallet' or 'gateway'
  double _walletBalance = 0.0;
  bool _isLoadingWallet = true;
  bool _isProcessing = false;
  String? _errorMessage;
  bool _isWaitingForPayment = false;
  String? _currentOrderId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchWalletBalance();
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
    setState(() => _isProcessing = true);

    try {
      if (_currentOrderId != null) {
        // Force backend to sync with Midtrans first
        await _paymentService.checkPaymentStatus(_currentOrderId!);
      }

      final history = await _paymentService.getPurchaseHistory();
      if (!mounted) return;

      if (history.isNotEmpty) {
        // The most recent transaction is the first item
        final latest = history.first;
        final status =
            latest['transaction_status']?.toString().toLowerCase() ?? 'pending';

        if (['verified', 'processing', 'completed', 'waiting_cod']
            .contains(status)) {
          _showSuccessModal(pending: false, transactionData: latest);
        } else {
          _showSuccessModal(pending: true, transactionData: latest);
        }
      } else {
        _showSuccessModal(pending: true);
      }
    } catch (e) {
      if (mounted) _showSuccessModal(pending: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _fetchWalletBalance() async {
    try {
      final user = await _profileService.getProfile();
      if (mounted) {
        setState(() {
          _walletBalance =
              user?.walletBalance ?? 0.0; // Assuming user model has this
          _isLoadingWallet = false;
        });

        // Auto-select wallet if sufficient
        if (_walletBalance >= widget.product.price) {
          setState(() => _selectedMethod = 'wallet');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingWallet = false;
          // default to gateway
        });
      }
    }
  }

  Future<void> _handlePayment() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      if (_selectedMethod == 'wallet') {
        // WALLET FLOW: POST /transactions/pay-wallet
        await _paymentService.payWallet(
            widget.product.sellerId, widget.product.id);
        Map<String, dynamic>? latest;
        try {
          final history = await _paymentService.getPurchaseHistory();
          if (history.isNotEmpty && history.first is Map) {
            latest = Map<String, dynamic>.from(history.first as Map);
          }
        } catch (_) {}
        if (mounted) {
          _showSuccessModal(isWallet: true, transactionData: latest);
        }
      } else {
        // GATEWAY FLOW:
        // 1. Create transaction
        final trxId = await _paymentService.createTransaction(
            widget.product.sellerId, widget.product.id);

        // 2. Create Payment gateway token
        // Fetch current user details via profile
        final user = await _profileService.getProfile();

        final gatewayResp = await _paymentService.createGatewayPayment(trxId, {
          'first_name': user?.name ?? 'User',
          'email': user?.email ?? 'user@example.com',
        });

        final snapUrl = gatewayResp['snap_url']?.toString() ??
            gatewayResp['payment_url']?.toString() ??
            gatewayResp['redirect_url']?.toString();
        final orderId = gatewayResp['order_id']?.toString() ??
            gatewayResp['orderId']?.toString();
        if (snapUrl == null || orderId == null) {
          throw Exception('Token pembayaran tidak valid');
        }

        // Save order_id for manual sync later
        _currentOrderId = orderId;

        // 3. Launch URL
        final url = Uri.parse(snapUrl);
        if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
          throw Exception('Gagal membuka halaman pembayaran Midtrans');
        }

        // Setup waiting state for lifecycle observer
        _isWaitingForPayment = true;
        // Do NOT process or reset `_isProcessing` yet, keep loading spinner.
        return;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isProcessing = false;
        });
      }
    }
    // We only reach here if an error occurred or wallet was successful.
    // If it's gateway, the observer will fire `_isProcessing = false`.
    if (mounted && _selectedMethod == 'wallet') {
      setState(() => _isProcessing = false);
    }
  }

  void _showSuccessModal(
      {bool pending = false,
      Map<String, dynamic>? transactionData,
      bool isWallet = false}) {
    String detailTitle =
        pending ? 'Menunggu Pembayaran' : 'Pembayaran Berhasil!';
    String detailSubtitle = pending
        ? 'Silakan selesaikan pembayaran Anda di jendela Midtrans.'
        : 'Pesanan Anda telah diteruskan ke penjual. Terima kasih!';

    String? orderId;
    String? amount;
    String? status;

    if (transactionData != null) {
      orderId = transactionData['order_id']?.toString();
      final grossAmount = transactionData['gross_amount'];
      if (grossAmount != null) {
        amount = _formatCurrency(grossAmount);
      }
      status = transactionData['transaction_status']?.toString().toUpperCase();
    } else if (isWallet) {
      amount = _formatCurrency(widget.product.price);
      status = 'VERIFIED';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (context) => Dialog(
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
                spreadRadius: -10,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    color: pending
                        ? const Color(0xFFFFF7E6)
                        : const Color(0xFFEAF8EE),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    pending ? Icons.access_time_filled : Icons.check_rounded,
                    color: pending ? const Color(0xFFF59E0B) : Colors.green,
                    size: 46,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  detailTitle,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  detailSubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5F5),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFE83030).withValues(alpha: 0.18),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFE83030).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(
                          Icons.qr_code_2_rounded,
                          color: Color(0xFFE83030),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kode & QR Penukaran',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Cek di Riwayat Pembelian. Tunjukkan kode atau QR ke penjual saat barang akan ditukar/diambil.',
                              style: TextStyle(
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
                ),
                if (amount != null || orderId != null || status != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Column(
                      children: [
                        if (orderId != null) ...[
                          _buildDetailRow('ID Pesanan', orderId),
                          const SizedBox(height: 8),
                        ],
                        if (amount != null) ...[
                          _buildDetailRow('Total Pembayaran', amount),
                          const SizedBox(height: 8),
                        ],
                        if (status != null) ...[
                          _buildDetailRow(
                            'Status',
                            status,
                            valueColor: pending
                                ? Colors.orange[800]
                                : Colors.green[800],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE83030),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/purchase_history',
                        (route) => route.isFirst,
                      );
                    },
                    icon: const Icon(Icons.receipt_long_outlined, size: 19),
                    label: const Text(
                      'Lihat Riwayat Pembelian',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE83030),
                      side: const BorderSide(color: Color(0xFFE83030)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    child: const Text(
                      'Kembali ke Beranda',
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

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.black54, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.black87,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  String _formatCurrency(dynamic val) {
    int amount = 0;
    if (val is num) {
      amount = val.toInt();
    } else if (val is String) {
      amount = double.tryParse(val)?.toInt() ?? 0;
    }
    return 'Rp${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    final bool isWalletSufficient = _walletBalance >= widget.product.price;

    return FrostedScaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      title: 'Pembayaran',
      body: _isLoadingWallet
          ? const JualinLogoLoader(size: 64)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Product Summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: widget.product.imagePath.isNotEmpty
                              ? Image.network(
                                  widget.product.imagePath,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return const SizedBox(
                                      width: 80,
                                      height: 80,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.image,
                                        color: Colors.grey),
                                  ),
                                )
                              : Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.image,
                                      color: Colors.grey),
                                ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.product.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 16),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _formatCurrency(widget.product.price),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE83030),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text('Metode Pembayaran',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 12),

                  // Wallet Option
                  GestureDetector(
                    onTap: isWalletSufficient
                        ? () => setState(() => _selectedMethod = 'wallet')
                        : null,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _selectedMethod == 'wallet'
                            ? Colors.white
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _selectedMethod == 'wallet'
                              ? const Color(0xFFE83030)
                              : Colors.black12,
                          width: _selectedMethod == 'wallet' ? 2 : 1,
                        ),
                        boxShadow: _selectedMethod == 'wallet'
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFE83030)
                                      .withValues(alpha: 0.1),
                                  blurRadius: 8,
                                )
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          // ignore: deprecated_member_use
                          Radio<String>(
                            value: 'wallet',
                            // ignore: deprecated_member_use
                            groupValue: _selectedMethod,
                            // ignore: deprecated_member_use
                            onChanged: isWalletSufficient
                                ? (val) =>
                                    setState(() => _selectedMethod = val!)
                                : null,
                            activeColor: const Color(0xFFE83030),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.account_balance_wallet,
                                        size: 20, color: Colors.black87),
                                    SizedBox(width: 8),
                                    Text('Saldo Jualin',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Saldo Anda: ${_formatCurrency(_walletBalance)}',
                                  style: TextStyle(
                                    color: isWalletSufficient
                                        ? Colors.black54
                                        : Colors.red,
                                    fontSize: 13,
                                  ),
                                ),
                                if (!isWalletSufficient)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 4.0),
                                    child: Text('Saldo tidak mencukupi',
                                        style: TextStyle(
                                            color: Colors.red,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold)),
                                  )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Gateway Option
                  GestureDetector(
                    onTap: () => setState(() => _selectedMethod = 'gateway'),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _selectedMethod == 'gateway'
                            ? Colors.white
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _selectedMethod == 'gateway'
                              ? const Color(0xFFE83030)
                              : Colors.black12,
                          width: _selectedMethod == 'gateway' ? 2 : 1,
                        ),
                        boxShadow: _selectedMethod == 'gateway'
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFE83030)
                                      .withValues(alpha: 0.1),
                                  blurRadius: 8,
                                )
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          // ignore: deprecated_member_use
                          Radio<String>(
                            value: 'gateway',
                            // ignore: deprecated_member_use
                            groupValue: _selectedMethod,
                            // ignore: deprecated_member_use
                            onChanged: (val) =>
                                setState(() => _selectedMethod = val!),
                            activeColor: const Color(0xFFE83030),
                          ),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.credit_card,
                                        size: 20, color: Colors.black87),
                                    SizedBox(width: 8),
                                    Text('Pembayaran Online',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16)),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Text(
                                    'Bayar via Midtrans (transfer bank, dompet digital, dll)',
                                    style: TextStyle(
                                        color: Colors.black54, fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ]
                ],
              ),
            ),
      bottomNavigationBar: Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Pembayaran',
                      style: TextStyle(color: Colors.black54, fontSize: 13)),
                  Text(
                    _formatCurrency(widget.product.price),
                    style: const TextStyle(
                        color: Color(0xFFE83030),
                        fontWeight: FontWeight.bold,
                        fontSize: 20),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _handlePayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE83030),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Bayar Sekarang',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
