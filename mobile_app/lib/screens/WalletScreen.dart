// ignore_for_file: file_names

import 'package:flutter/material.dart';
import '../services/profile_service.dart';
import '../services/payment_service.dart';
import '../widgets/ui/frosted_app_bar.dart';
import '../widgets/ui/logo_loader.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final ProfileService _profileService = ProfileService();
  final PaymentService _paymentService = PaymentService();

  double _balance = 0.0;
  List<dynamic> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = await _profileService.getProfile();
      final history = await _paymentService
          .getPurchaseHistory(); // fallback untuk list transaksi
      if (!mounted) return;
      setState(() {
        _balance = user?.walletBalance ?? 0.0;
        _transactions = history;
      });
    } catch (_) {
      // ignore, tampilkan kosong
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
      title: 'Saldo & Transaksi',
      backgroundColor: Colors.white,
      body: _isLoading
          ? const JualinLogoLoader(size: 64)
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Saldo Anda',
                            style: TextStyle(color: Colors.black54)),
                        const SizedBox(height: 8),
                        Text(_formatCurrency(_balance),
                            style: const TextStyle(
                                fontSize: 26, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed:
                              () {}, // tambahkan aksi tarik saldo jika ada screen
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE83030)),
                          child: const Text('Tarik Saldo'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Transaksi Terbaru',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ..._transactions.map((t) {
                    final title =
                        t['first_item_name'] ?? 'Order #${t['order_id'] ?? ''}';
                    final amount = t['gross_amount'] ?? 0;
                    final status = t['transaction_status'] ?? '';
                    final transactionTime = t['transaction_time']?.toString();
                    final time =
                        transactionTime != null && transactionTime.length >= 10
                            ? transactionTime.substring(0, 10)
                            : '-';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(title),
                      subtitle: Text('$time · ${status.toString()}'),
                      trailing: Text(_formatCurrency(amount)),
                      onTap: () =>
                          Navigator.pushNamed(context, '/purchase_history'),
                    );
                  }).toList(),
                  if (_transactions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Center(child: Text('Belum ada transaksi')),
                    ),
                ],
              ),
            ),
    );
  }
}
