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

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _amountController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  Future<void> _handleWithdraw() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(
        _amountController.text.replaceAll(RegExp(r'[^0-9]'), ''));
    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = 'Masukkan jumlah yang valid.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _sellerService.withdrawWallet(
        amount: amount,
        bankName: _bankNameController.text.trim(),
        accountNumber: _accountNumberController.text.trim(),
        accountName: _accountNameController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Penarikan saldo berhasil diproses!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Return to stats / dashboard
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

  @override
  Widget build(BuildContext context) {
    return FrostedScaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      title: 'Tarik Saldo',
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
                                hint: 'Contoh: 100000',
                                icon: Icons.payments_outlined,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Jumlah wajib diisi.';
                                  }
                                  final n = double.tryParse(v);
                                  if (n == null || n <= 0) {
                                    return 'Masukkan jumlah yang valid.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                label: 'Nama Bank',
                                controller: _bankNameController,
                                hint: 'Contoh: BCA, Mandiri, BNI',
                                icon: Icons.account_balance_outlined,
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Nama bank wajib diisi.'
                                        : null,
                              ),
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
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ajukan Penarikan Saldo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Isi data rekening dengan benar agar pencairan berjalan lancar.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.35,
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
