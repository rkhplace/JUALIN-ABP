import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/seller_service.dart';
import '../../widgets/ui/frosted_app_bar.dart';

class SellerWithdrawScreen extends StatefulWidget {
  const SellerWithdrawScreen({super.key});

  @override
  State<SellerWithdrawScreen> createState() => _SellerWithdrawScreenState();
}

class _SellerWithdrawScreenState extends State<SellerWithdrawScreen> {
  final SellerService _sellerService = SellerService();

  static const List<String> _bankOptions = [
    'Bank Aladin Syariah',
    'Bank Amar Indonesia',
    'Bank Artha Graha Internasional',
    'Bank BCA Syariah',
    'Bank BJB',
    'Bank BJB Syariah',
    'Bank BNI',
    'Bank BRI',
    'Bank BRI Agroniaga (BRI Agro)',
    'Bank BSI (Bank Syariah Indonesia)',
    'Bank BTN',
    'Bank BTN Syariah',
    'Bank Bukopin',
    'Bank CIMB Niaga',
    'Bank Danamon Indonesia',
    'Bank DKI',
    'Bank INA Perdana',
    'Bank Jago',
    'Bank Jambi',
    'Bank Jateng',
    'Bank Jatim',
    'Bank Kalbar',
    'Bank Kalsel',
    'Bank Kalteng',
    'Bank Kaltimtara',
    'Bank Lampung',
    'Bank Mandiri',
    'Bank Mayapada',
    'Bank Maybank Indonesia',
    'Bank Mega',
    'Bank Muamalat Indonesia',
    'Bank Nagari',
    'Bank Neo Commerce',
    'Bank NTT',
    'Bank OCBC',
    'Bank Panin Bank',
    'Bank Papua',
    'Bank Permata',
    'Bank Raya Indonesia',
    'Bank Riau Kepri Syariah',
    'Bank Sinarmas',
    'Bank Sulselbar',
    'Bank Sultra',
    'Bank Sulteng',
    'Bank Sumsel Babel',
    'Bank Sumut',
    'Bank UOB Indonesia',
    'Bank Victoria International',
    'Bank Woori Saudara',
    'SeaBank Indonesia',
    'Superbank Indonesia',
  ];

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();

  bool _isLoading = false;
  bool _isBalanceLoading = true;
  double _walletBalance = 0;
  String? _errorMessage;
  String? _balanceError;

  @override
  void initState() {
    super.initState();
    _fetchWalletBalance();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  Future<void> _fetchWalletBalance() async {
    setState(() {
      _isBalanceLoading = true;
      _balanceError = null;
    });

    try {
      final stats = await _sellerService.getSellerStats(type: 'withdraw');
      final rawBalance = stats['wallet_balance'] ??
          stats['current_balance'] ??
          stats['balance'] ??
          0;
      final balance = rawBalance is num
          ? rawBalance.toDouble()
          : double.tryParse(rawBalance.toString()) ?? 0;

      if (!mounted) return;
      setState(() {
        _walletBalance = balance;
        _isBalanceLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isBalanceLoading = false;
        _balanceError = 'Saldo belum bisa dimuat';
      });
    }
  }

  Future<void> _handleWithdraw() async {
    if (!_formKey.currentState!.validate()) return;

    final amountText = _amountController.text;
    final bankName = _bankNameController.text.trim();
    final accountNumber = _accountNumberController.text.trim();
    final accountName = _accountNameController.text.trim();
    final amount = double.tryParse(
      amountText.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = 'Masukkan jumlah yang valid.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final remainingBalance = await _sellerService.withdrawWallet(
        amount: amount,
        bankName: bankName,
        accountNumber: accountNumber,
        accountName: accountName,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _walletBalance = remainingBalance;
          _balanceError = null;
        });
        await _showWithdrawSuccessDialog(
          amountText: _formatCurrency(amount),
          bankName: bankName,
          accountNumber: accountNumber,
          accountName: accountName,
        );
        if (mounted) Navigator.pop(context); // Return to stats / dashboard
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  void _handleBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    navigator.pushReplacementNamed('/seller_main');
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

  String _maskAccountNumber(String value) {
    if (value.length <= 4) return value;
    final suffix = value.substring(value.length - 4);
    return '•••• $suffix';
  }

  Future<void> _showWithdrawSuccessDialog({
    required String amountText,
    required String bankName,
    required String accountNumber,
    required String accountName,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 22),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF16A34A), Color(0xFF22C55E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF16A34A).withValues(alpha: 0.24),
                          blurRadius: 22,
                          spreadRadius: -8,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 38,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Penarikan Berhasil Diajukan',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Saldo akan diproses dalam 1–3 hari kerja ke rekening tujuan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12.5,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    children: [
                      _buildSuccessDetailRow('Nominal', amountText,
                          valueColor: const Color(0xFFE83030)),
                      const SizedBox(height: 10),
                      _buildSuccessDetailRow('Bank', bankName),
                      const SizedBox(height: 10),
                      _buildSuccessDetailRow(
                        'Rekening',
                        _maskAccountNumber(accountNumber),
                      ),
                      const SizedBox(height: 10),
                      _buildSuccessDetailRow('Atas Nama', accountName),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFED7AA)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.schedule_rounded,
                          color: Color(0xFFEA580C), size: 18),
                      SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'Pengajuan penarikan sudah tercatat. Pantau saldo Anda secara berkala di menu statistik.',
                          style: TextStyle(
                            color: Color(0xFF9A3412),
                            fontSize: 12,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE83030),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Lihat Statistik',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuccessDetailRow(
    String label,
    String value, {
    Color valueColor = const Color(0xFF111827),
  }) {
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
            style: TextStyle(
              color: valueColor,
              fontSize: 13,
              fontWeight: FontWeight.w900,
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Column(
                    children: [
                      _buildWithdrawHero(),
                      const SizedBox(height: 14),
                      _buildCurrentBalanceCard(),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: Colors.black.withValues(alpha: 0.06),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 24,
                              spreadRadius: -8,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildInfoBanner(),
                              const SizedBox(height: 22),
                              _buildTextField(
                                label: 'Jumlah Penarikan',
                                controller: _amountController,
                                hint: 'Contoh: Rp100.000',
                                icon: Icons.payments_outlined,
                                keyboardType: TextInputType.number,
                                inputFormatters: [RupiahInputFormatter()],
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Jumlah wajib diisi.';
                                  }
                                  final n = double.tryParse(
                                    v.replaceAll(RegExp(r'[^0-9]'), ''),
                                  );
                                  if (n == null || n <= 0) {
                                    return 'Masukkan jumlah yang valid.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildBankDropdown(),
                              const SizedBox(height: 16),
                              _buildTextField(
                                label: 'Nomor Rekening',
                                controller: _accountNumberController,
                                hint: 'Contoh: 1234567890',
                                icon: Icons.credit_card_outlined,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Nomor rekening wajib diisi.'
                                        : null,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                label: 'Nama Pemilik Rekening',
                                controller: _accountNameController,
                                hint: 'Sesuai buku tabungan',
                                icon: Icons.person_outline,
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Nama pemilik wajib diisi.'
                                        : null,
                              ),
                              const SizedBox(height: 16),
                              if (_errorMessage != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.red[200]!),
                                  ),
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                        color: Colors.red, fontSize: 13),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                              const SizedBox(height: 4),
                              _isLoading
                                  ? const Center(
                                      child: CircularProgressIndicator(
                                          color: Color(0xFFE83030)))
                                  : SizedBox(
                                      height: 52,
                                      child: ElevatedButton(
                                        onPressed: _handleWithdraw,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFFE83030),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                          elevation: 5,
                                          shadowColor: const Color(0xFFE83030)
                                              .withValues(alpha: 0.35),
                                        ),
                                        child: const Text(
                                          'Tarik Saldo',
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCurrentBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE83030).withValues(alpha: 0.08),
            blurRadius: 28,
            spreadRadius: -12,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 22,
            spreadRadius: -14,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE83030), Color(0xFFFF5A5A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE83030).withValues(alpha: 0.25),
                  blurRadius: 18,
                  spreadRadius: -8,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Saldo Saat Ini',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: _isBalanceLoading
                      ? Container(
                          key: const ValueKey('balance-loading'),
                          width: 126,
                          height: 18,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        )
                      : Text(
                          _balanceError ?? _formatCurrency(_walletBalance),
                          key: ValueKey(_balanceError ?? _walletBalance),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _balanceError == null
                                ? const Color(0xFF111827)
                                : const Color(0xFFE83030),
                            fontSize: _balanceError == null ? 21 : 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Saldo tersedia untuk dicairkan ke rekening.',
                  style: TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 11,
                    height: 1.25,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Refresh saldo',
            onPressed: _isBalanceLoading ? null : _fetchWalletBalance,
            icon: AnimatedRotation(
              turns: _isBalanceLoading ? 0.12 : 0,
              duration: const Duration(milliseconds: 180),
              child: const Icon(Icons.refresh_rounded),
            ),
            color: const Color(0xFFE83030),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFFFEFEF),
              disabledBackgroundColor: const Color(0xFFF3F4F6),
              disabledForegroundColor: const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawHero() {
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
      child: Row(
        children: [
          Material(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(15),
            child: InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: _handleBack,
              child: Container(
                width: 46,
                height: 46,
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
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.white,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tarik Saldo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Ajukan pencairan saldo ke rekening bank.',
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
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE83030).withValues(alpha: 0.18),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Color(0xFFE83030), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Penarikan akan diproses dalam 1-3 hari kerja ke rekening bank yang terdaftar.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.35,
                color: Color(0xFFE83030),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: _inputDecoration(hint, icon),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildBankDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nama Bank',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        FormField<String>(
          initialValue: _bankNameController.text,
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Nama bank wajib diisi.'
              : null,
          builder: (field) {
            final selectedBank = field.value?.trim() ?? '';
            final hasValue = selectedBank.isNotEmpty;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      final bank = await _showBankPicker(selectedBank);
                      if (bank == null) return;

                      _bankNameController.text = bank;
                      field.didChange(bank);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      constraints: const BoxConstraints(minHeight: 56),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F9F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: field.hasError
                              ? Colors.red
                              : hasValue
                                  ? const Color(0xFFE83030)
                                      .withValues(alpha: 0.36)
                                  : Colors.black.withValues(alpha: 0.08),
                          width: hasValue ? 1.15 : 1,
                        ),
                        boxShadow: hasValue
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFE83030)
                                      .withValues(alpha: 0.08),
                                  blurRadius: 18,
                                  spreadRadius: -10,
                                  offset: const Offset(0, 10),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEFEF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.account_balance_outlined,
                              color: Color(0xFFE83030),
                              size: 19,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              hasValue ? selectedBank : 'Pilih bank tujuan',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: hasValue
                                    ? const Color(0xFF111827)
                                    : Colors.black38,
                                fontSize: 13.5,
                                fontWeight: hasValue
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Color(0xFFE83030),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (field.hasError) ...[
                  const SizedBox(height: 7),
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(
                      field.errorText!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Future<String?> _showBankPicker(String selectedBank) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _BankPickerSheet(
          banks: _bankOptions,
          selectedBank: selectedBank,
        );
      },
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
      filled: true,
      fillColor: const Color(0xFFF9F9F9),
      prefixIcon: Icon(icon, color: const Color(0xFFE83030), size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE83030), width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }
}

class RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final normalized = digits.replaceFirst(RegExp(r'^0+(?=.)'), '');
    final formatted =
        'Rp${normalized.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}';

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _BankPickerSheet extends StatefulWidget {
  const _BankPickerSheet({
    required this.banks,
    required this.selectedBank,
  });

  final List<String> banks;
  final String selectedBank;

  @override
  State<_BankPickerSheet> createState() => _BankPickerSheetState();
}

class _BankPickerSheetState extends State<_BankPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredBanks = widget.banks
        .where((bank) => bank.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.42,
      maxChildSize: 0.86,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 32,
                spreadRadius: -10,
                offset: Offset(0, -12),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEFEF),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.account_balance_rounded,
                        color: Color(0xFFE83030),
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pilih Bank',
                            style: TextStyle(
                              color: Color(0xFF111827),
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Cari dan pilih rekening tujuan',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      color: const Color(0xFF6B7280),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFF3F4F6),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value.trim()),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Cari bank...',
                    hintStyle: const TextStyle(
                      color: Colors.black38,
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFFE83030),
                    ),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(Icons.close_rounded, size: 18),
                          ),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                        color: Color(0xFFE83030),
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: filteredBanks.isEmpty
                    ? const Center(
                        child: Text(
                          'Bank tidak ditemukan',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
                        physics: const BouncingScrollPhysics(),
                        itemCount: filteredBanks.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final bank = filteredBanks[index];
                          final isSelected = bank == widget.selectedBank;

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () => Navigator.pop(context, bank),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                curve: Curves.easeOutCubic,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 13,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFFFEFEF)
                                      : const Color(0xFFFDFDFD),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFFE83030)
                                            .withValues(alpha: 0.28)
                                        : const Color(0xFFE5E7EB),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFFE83030)
                                            : const Color(0xFFF3F4F6),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(
                                        Icons.account_balance_outlined,
                                        color: isSelected
                                            ? Colors.white
                                            : const Color(0xFFE83030),
                                        size: 19,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        bank,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: const Color(0xFF111827),
                                          fontSize: 13.5,
                                          height: 1.25,
                                          fontWeight: isSelected
                                              ? FontWeight.w900
                                              : FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    AnimatedOpacity(
                                      duration:
                                          const Duration(milliseconds: 140),
                                      opacity: isSelected ? 1 : 0,
                                      child: const Icon(
                                        Icons.check_circle_rounded,
                                        color: Color(0xFFE83030),
                                        size: 22,
                                      ),
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
        );
      },
    );
  }
}
