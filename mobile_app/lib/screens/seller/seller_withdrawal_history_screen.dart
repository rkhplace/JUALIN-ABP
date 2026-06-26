import 'package:flutter/material.dart';

import '../../services/seller_service.dart';
import '../../widgets/ui/frosted_app_bar.dart';
import '../../widgets/ui/logo_loader.dart';

class SellerWithdrawalHistoryScreen extends StatefulWidget {
  const SellerWithdrawalHistoryScreen({super.key});

  @override
  State<SellerWithdrawalHistoryScreen> createState() =>
      _SellerWithdrawalHistoryScreenState();
}

class _SellerWithdrawalHistoryScreenState
    extends State<SellerWithdrawalHistoryScreen> {
  final SellerService _sellerService = SellerService();

  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _withdrawals = [];

  @override
  void initState() {
    super.initState();
    _fetchWithdrawals();
  }

  Future<void> _fetchWithdrawals() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _sellerService.getWithdrawalHistory();
      if (!mounted) return;
      setState(() {
        _withdrawals = items;
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

  void _handleBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    navigator.pushReplacementNamed('/seller_stats');
  }

  @override
  Widget build(BuildContext context) {
    return FrostedScaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      showAppBar: false,
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFFE83030),
          onRefresh: _fetchWithdrawals,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const JualinLogoLoader(size: 64);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              children: [
                _buildPageHeader(),
                const SizedBox(height: 14),
                if (_errorMessage != null)
                  _buildError()
                else if (_withdrawals.isEmpty)
                  _buildEmptyState()
                else ...[
                  _buildSummaryCard(),
                  const SizedBox(height: 12),
                  ..._withdrawals.map(
                    (withdrawal) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildWithdrawalCard(withdrawal),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPageHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE83030), Color(0xFFF64A4A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE83030).withValues(alpha: 0.24),
            blurRadius: 24,
            spreadRadius: -8,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -26,
            top: -32,
            child: Container(
              width: 104,
              height: 104,
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
              _buildHeaderButton(
                icon: Icons.arrow_back_rounded,
                onTap: _handleBack,
              ),
              const SizedBox(width: 10),
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Riwayat Penarikan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Pantau pengajuan pencairan saldo toko.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.3,
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

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final total = _withdrawals.fold<double>(
      0,
      (sum, item) => sum + _parseAmount(item['amount']),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 20,
            spreadRadius: -10,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE83030).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.account_balance_rounded,
              color: Color(0xFFE83030),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Riwayat Penarikan',
                  style: TextStyle(color: Colors.black45, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatCurrency(total),
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${_withdrawals.length} data',
            style: const TextStyle(
              color: Color(0xFFE83030),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawalCard(Map<String, dynamic> withdrawal) {
    final amount = _parseAmount(withdrawal['amount']);
    final status = withdrawal['status']?.toString() ?? 'processed';
    final bank = withdrawal['bank_name']?.toString().trim();
    final accountNumber = withdrawal['account_number']?.toString().trim();
    final accountName = withdrawal['account_name']?.toString().trim();
    final createdAt = _formatDate(withdrawal['created_at']);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            spreadRadius: -10,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.payments_outlined,
                  color: Color(0xFFE83030),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatCurrency(amount),
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      createdAt,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusPill(status),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                _buildDetailRow('Bank', _fallback(bank, 'Belum tercatat')),
                const SizedBox(height: 8),
                _buildDetailRow(
                  'Rekening',
                  _maskAccountNumber(_fallback(accountNumber, '-')),
                ),
                const SizedBox(height: 8),
                _buildDetailRow(
                  'Atas Nama',
                  _fallback(accountName, 'Belum tercatat'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    final normalized = status.toLowerCase();
    final color = switch (normalized) {
      'failed' || 'rejected' => const Color(0xFFDC2626),
      'pending' => const Color(0xFFEA580C),
      _ => const Color(0xFF16A34A),
    };
    final label = switch (normalized) {
      'failed' => 'Gagal',
      'rejected' => 'Ditolak',
      'pending' => 'Diproses',
      _ => 'Diproses',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 30, 22, 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: Color(0xFFE83030),
              size: 30,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Belum Ada Penarikan',
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Riwayat akan muncul setelah Anda mengajukan penarikan saldo.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.grey, size: 42),
          const SizedBox(height: 12),
          Text(
            _errorMessage ?? 'Gagal memuat riwayat penarikan.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _fetchWithdrawals,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  double _parseAmount(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatCurrency(dynamic val) {
    int amount = 0;
    if (val is num) {
      amount = val.toInt();
    } else if (val is String) {
      amount =
          double.tryParse(val.replaceAll(RegExp(r'[^0-9]'), ''))?.toInt() ?? 0;
    }
    return 'Rp${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  String _formatDate(dynamic raw) {
    final date = DateTime.tryParse(raw?.toString() ?? '')?.toLocal();
    if (date == null) return 'Tanggal tidak tersedia';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day $month ${date.year}, $hour:$minute';
  }

  String _maskAccountNumber(String value) {
    if (value == '-' || value.length <= 4) return value;
    final suffix = value.substring(value.length - 4);
    return '•••• $suffix';
  }

  String _fallback(String? value, String fallback) {
    if (value == null || value.trim().isEmpty) return fallback;
    return value.trim();
  }
}
