import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/ui/logo.dart';

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
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _didReadArgs = false;
  bool _isLoading = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  bool _tokenCameFromLink = false;
  String? _message;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didReadArgs) return;
    _didReadArgs = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _tokenController.text = args['token']?.toString() ?? '';
      _emailController.text = args['email']?.toString() ?? '';
      _tokenCameFromLink = _tokenController.text.isNotEmpty;
    }

    final routeName = ModalRoute.of(context)?.settings.name;
    final routeUri = routeName == null ? null : Uri.tryParse(routeName);
    final routeQuery = routeUri?.queryParameters ?? const <String, String>{};
    final baseQuery = Uri.base.queryParameters;
    final token = routeQuery['token'] ?? baseQuery['token'];
    final email = routeQuery['email'] ?? baseQuery['email'];

    if (_tokenController.text.isEmpty && token != null) {
      _tokenController.text = token;
      _tokenCameFromLink = true;
    }
    if (_emailController.text.isEmpty && email != null) {
      _emailController.text = email;
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
    if (!_isValidEmail(email)) {
      setState(() => _setError('Format email belum valid.'));
      return;
    }
    if (password.length < 8) {
      setState(() => _setError('Kata sandi minimal 8 karakter.'));
      return;
    }
    if (password != confirmation) {
      setState(() => _setError('Konfirmasi kata sandi tidak cocok.'));
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
        _message = 'Kata sandi berhasil direset. Silakan masuk kembali.';
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
    final size = MediaQuery.of(context).size;
    final isCompact = size.height < 760 || size.width < 390;
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
                                'Buat Kata Sandi Baru',
                                style: TextStyle(
                                  color: const Color(0xFF111827),
                                  fontSize: titleSize,
                                  fontWeight: FontWeight.w800,
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Minimal 8 karakter. Gunakan kombinasi huruf, angka, dan simbol.',
                                style: TextStyle(
                                  color: Color(0xFF566174),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  height: 1.35,
                                ),
                              ),
                              SizedBox(height: isCompact ? 22 : 24),
                              if (!_tokenCameFromLink) ...[
                                _buildAuthInput(
                                  label: 'Token Reset',
                                  hintText: 'Token dari email',
                                  controller: _tokenController,
                                ),
                                SizedBox(height: isCompact ? 15 : 17),
                              ],
                              _buildAuthInput(
                                label: 'Email',
                                hintText: 'Email akun Anda',
                                keyboardType: TextInputType.emailAddress,
                                controller: _emailController,
                                textInputAction: TextInputAction.next,
                              ),
                              SizedBox(height: isCompact ? 15 : 17),
                              _buildAuthInput(
                                label: 'Kata Sandi Baru',
                                hintText: 'Minimal 8 karakter',
                                obscureText: !_showNewPassword,
                                controller: _passwordController,
                                textInputAction: TextInputAction.next,
                                suffixIcon: _buildPasswordToggle(
                                  isVisible: _showNewPassword,
                                  onPressed: () {
                                    setState(() =>
                                        _showNewPassword = !_showNewPassword);
                                  },
                                ),
                              ),
                              const SizedBox(height: 10),
                              _buildStrengthMeter(),
                              SizedBox(height: isCompact ? 15 : 17),
                              _buildAuthInput(
                                label: 'Konfirmasi Kata Sandi',
                                hintText: 'Ulangi kata sandi baru',
                                obscureText: !_showConfirmPassword,
                                controller: _confirmPasswordController,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _handleSubmit(),
                                suffixIcon: _buildPasswordToggle(
                                  isVisible: _showConfirmPassword,
                                  onPressed: () {
                                    setState(() => _showConfirmPassword =
                                        !_showConfirmPassword);
                                  },
                                ),
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
                                            'Atur Kata Sandi Baru',
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
                                onPressed: () =>
                                    Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  '/login',
                                  (route) => false,
                                ),
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

  Widget _buildPasswordToggle({
    required bool isVisible,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      tooltip: isVisible ? 'Sembunyikan kata sandi' : 'Tampilkan kata sandi',
      icon: Icon(
        isVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: Colors.grey[600],
      ),
      onPressed: onPressed,
    );
  }

  Widget _buildAuthInput({
    required String label,
    required String hintText,
    required TextEditingController controller,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
    Widget? suffixIcon,
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
            obscureText: obscureText,
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
              suffixIcon: suffixIcon,
              suffixIconConstraints: const BoxConstraints(
                minWidth: 44,
                minHeight: 44,
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
