import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/ui/custom_button.dart';
import '../widgets/ui/custom_input.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = false;
  String? _message;
  bool _isSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _message = 'Email wajib diisi.';
        _isSuccess = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    final error = await _authService.sendResetLink(email);
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _isSuccess = error == null;
      _message = error ?? 'Link reset password telah dikirim. Silakan cek email Anda.';
      if (error == null) _emailController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F7F8),
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Lupa Password',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Masukkan email Anda untuk menerima tautan reset password.',
                      style: TextStyle(color: Colors.black54, height: 1.4),
                    ),
                    const SizedBox(height: 28),
                    CustomInput(
                      label: 'Email',
                      hintText: 'masukkan email Anda',
                      keyboardType: TextInputType.emailAddress,
                      controller: _emailController,
                    ),
                    const SizedBox(height: 16),
                    if (_message != null) _buildMessage(_message!, _isSuccess),
                    const SizedBox(height: 8),
                    CustomButton(
                      text: 'Kirim Link Reset',
                      isLoading: _isLoading,
                      onPressed: _handleSubmit,
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Kembali ke halaman login',
                        style: TextStyle(color: Color(0xFFE83030)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessage(String message, bool success) {
    final MaterialColor color = success ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: success ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color[200]!),
      ),
      child: Text(message, style: TextStyle(color: color[700], fontSize: 13)),
    );
  }
}
