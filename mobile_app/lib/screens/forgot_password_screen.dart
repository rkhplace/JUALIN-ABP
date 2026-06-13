import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/ui/logo.dart';

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
    if (!_isValidEmail(email)) {
      setState(() {
        _message = 'Format email belum valid.';
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
      _message = error ??
          'Tautan reset kata sandi telah dikirim. Silakan cek email Anda.';
      if (error == null) _emailController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isCompact = size.height < 740 || size.width < 390;
    final cardPadding = isCompact
        ? const EdgeInsets.fromLTRB(22, 28, 22, 24)
        : const EdgeInsets.fromLTRB(34, 34, 34, 30);
    final outerHorizontalPadding = isCompact ? 20.0 : 24.0;
    final outerVerticalPadding = isCompact ? 18.0 : 24.0;
    final logoWidth = isCompact ? 132.0 : 148.0;
    final logoHeight = isCompact ? 58.0 : 64.0;
    final titleSize = isCompact ? 20.0 : 22.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF0F0),
              Color(0xFFFFFFFF),
              Color(0xFFFFFFFF),
              Color(0xFFFFE8EA),
            ],
            stops: [0, 0.26, 0.76, 1],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding:
                    EdgeInsets.symmetric(horizontal: outerHorizontalPadding),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: outerVerticalPadding),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Container(
                          padding: cardPadding,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 36,
                                spreadRadius: -14,
                                offset: const Offset(0, 22),
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Logo(
                                width: logoWidth,
                                height: logoHeight,
                                alignment: Alignment.centerLeft,
                              ),
                              SizedBox(height: isCompact ? 16 : 20),
                              Text(
                                'Lupa Kata Sandi',
                                style: TextStyle(
                                  color: const Color(0xFF111827),
                                  fontSize: titleSize,
                                  fontWeight: FontWeight.w800,
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Masukkan email Anda untuk menerima tautan reset kata sandi.',
                                style: TextStyle(
                                  color: Color(0xFF566174),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  height: 1.35,
                                ),
                              ),
                              SizedBox(height: isCompact ? 22 : 24),
                              _buildAuthInput(
                                label: 'Email',
                                hintText: 'Masukkan alamat email',
                                keyboardType: TextInputType.emailAddress,
                                controller: _emailController,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _handleSubmit(),
                              ),
                              SizedBox(height: isCompact ? 16 : 18),
                              if (_message != null)
                                _buildMessage(_message!, _isSuccess),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: isCompact ? 48 : 50,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFE83030)
                                            .withValues(alpha: 0.2),
                                        blurRadius: 16,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed:
                                        _isLoading ? null : _handleSubmit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFE83030),
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor:
                                          const Color(0xFFE83030)
                                              .withValues(alpha: 0.65),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.3,
                                            ),
                                          )
                                        : const Text(
                                            'Kirim Tautan Reset',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                              SizedBox(height: isCompact ? 16 : 18),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text(
                                  'Kembali ke halaman login',
                                  style: TextStyle(
                                    color: Color(0xFFE83030),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
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
            },
          ),
        ),
      ),
    );
  }

  bool _isValidEmail(String value) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value);
  }

  Widget _buildAuthInput({
    required String label,
    required String hintText,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            children: const [
              TextSpan(
                text: ' *',
                style: TextStyle(color: Color(0xFFE83030)),
              ),
            ],
          ),
          style: const TextStyle(
            color: Color(0xFF374151),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 9,
                spreadRadius: -5,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            onSubmitted: onSubmitted,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFD7DCE5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFD7DCE5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFFE83030),
                  width: 1.4,
                ),
              ),
            ),
          ),
        ),
      ],
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
