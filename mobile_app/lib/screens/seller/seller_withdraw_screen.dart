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
      backgroundColor: Colors.white,
      title: 'Tarik Saldo',
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFFE83030).withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Color(0xFFE83030), size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Penarikan akan diproses dalam 1-3 hari kerja ke rekening bank yang terdaftar.',
                          style:
                              TextStyle(fontSize: 13, color: Color(0xFFE83030)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Amount
                _buildLabel('Jumlah Penarikan (Rp)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _inputDecoration('Contoh: 100000'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Jumlah wajib diisi.';
                    final n = double.tryParse(v);
                    if (n == null || n <= 0) {
                      return 'Masukkan jumlah yang valid.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Bank Name
                _buildLabel('Nama Bank'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _bankNameController,
                  decoration: _inputDecoration('Contoh: BCA, Mandiri, BNI'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Nama bank wajib diisi.'
                      : null,
                ),
                const SizedBox(height: 20),

                // Account Number
                _buildLabel('Nomor Rekening'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _accountNumberController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _inputDecoration('Contoh: 1234567890'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Nomor rekening wajib diisi.'
                      : null,
                ),
                const SizedBox(height: 20),

                // Account Name
                _buildLabel('Nama Pemilik Rekening'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _accountNameController,
                  decoration: _inputDecoration('Sesuai buku tabungan'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Nama pemilik wajib diisi.'
                      : null,
                ),
                const SizedBox(height: 16),

                // Error display
                if (_errorMessage != null) ...[
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
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 8),
                _isLoading
                    ? const Center(
                        child:
                            CircularProgressIndicator(color: Color(0xFFE83030)))
                    : SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _handleWithdraw,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE83030),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Tarik Saldo',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF8F8F8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.black12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.black12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE83030)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }
}
