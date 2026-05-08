import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/ui/custom_button.dart';
import '../widgets/ui/custom_input.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _didReadArgs = false;
  bool _isLoading = false;
  String? _message;
  bool _isSuccess = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didReadArgs) return;
    _didReadArgs = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _tokenController.text = args['token']?.toString() ?? '';
      _emailController.text = args['email']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final token = _tokenController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmation = _confirmPasswordController.text;

    if (token.isEmpty) {
      setState(() => _setError('Token reset tidak ditemukan dari link email.'));
      return;
    }
    if (email.isEmpty) {
      setState(() => _setError('Email wajib diisi.'));
      return;
    }
    if (password.length < 8) {
      setState(() => _setError('Password minimal 8 karakter.'));
      return;
    }
    if (password != confirmation) {
      setState(() => _setError('Konfirmasi password tidak cocok.'));
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    final error = await _authService.resetPassword(
      token: token,
      email: email,
      password: password,
      passwordConfirmation: confirmation,
    );
    if (!mounted) return;

    if (error == null) {
      setState(() {
        _isLoading = false;
        _isSuccess = true;
        _message = 'Password berhasil direset. Silakan login kembali.';
        _passwordController.clear();
        _confirmPasswordController.clear();
      });
      Future<void>.delayed(const Duration(milliseconds: 900), () {
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
      });
      return;
    }

    setState(() {
      _isLoading = false;
      _isSuccess = false;
      _message = error;
    });
  }

  void _setError(String message) {
    _isSuccess = false;
    _message = message;
  }

  int _passwordStrength() {
    final value = _passwordController.text;
    if (value.isEmpty) return 0;
    if (value.length < 8) return 1;
    var score = 1;
    if (RegExp(r'[A-Z]').hasMatch(value)) score++;
    if (RegExp(r'[0-9]').hasMatch(value)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(value)) score++;
    return score.clamp(0, 4).toInt();
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
                      'Buat Password Baru',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Minimal 8 karakter. Gunakan kombinasi huruf, angka, dan simbol.',
                      style: TextStyle(color: Colors.black54, height: 1.4),
                    ),
                    const SizedBox(height: 28),
                    CustomInput(
                      label: 'Token Reset',
                      hintText: 'token dari email',
                      controller: _tokenController,
                    ),
                    const SizedBox(height: 18),
                    CustomInput(
                      label: 'Email',
                      hintText: 'email akun Anda',
                      keyboardType: TextInputType.emailAddress,
                      controller: _emailController,
                    ),
                    const SizedBox(height: 18),
                    CustomInput(
                      label: 'Password Baru',
                      hintText: 'minimal 8 karakter',
                      obscureText: true,
                      controller: _passwordController,
                    ),
                    const SizedBox(height: 10),
                    _buildStrengthMeter(),
                    const SizedBox(height: 18),
                    CustomInput(
                      label: 'Konfirmasi Password',
                      hintText: 'ulangi password baru',
                      obscureText: true,
                      controller: _confirmPasswordController,
                    ),
                    const SizedBox(height: 16),
                    if (_message != null) _buildMessage(_message!, _isSuccess),
                    const SizedBox(height: 8),
                    CustomButton(
                      text: 'Set Password Baru',
                      isLoading: _isLoading,
                      onPressed: _handleSubmit,
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

  Widget _buildStrengthMeter() {
    final strength = _passwordStrength();
    return Row(
      children: List.generate(4, (index) {
        final active = strength >= index + 1;
        final color = !active
            ? Colors.grey[200]
            : index < 2
                ? const Color(0xFFE83030)
                : index == 2
                    ? Colors.amber
                    : Colors.green;
        return Expanded(
          child: Container(
            height: 6,
            margin: EdgeInsets.only(right: index == 3 ? 0 : 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        );
      }),
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
