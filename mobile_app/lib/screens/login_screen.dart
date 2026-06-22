import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/ui/logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _showPassword = false;
  bool _rememberMe = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRememberedLogin();
  }

  Future<void> _loadRememberedLogin() async {
    final remembered = await _authService.getRememberedLogin();
    if (!mounted) return;

    setState(() {
      _rememberMe = remembered['rememberMe'] == true;
      _emailController.text = remembered['email']?.toString() ?? '';
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(
          () => _errorMessage = 'Email dan kata sandi tidak boleh kosong.');
      return;
    }
    if (!_isValidEmail(email)) {
      setState(() => _errorMessage = 'Format email belum valid.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final error = await _authService.login(
      email,
      password,
      rememberMe: _rememberMe,
    );
    if (!mounted) return;

    if (error == null) {
      final role = await _authService.getUserRole();
      final nextRoute = _authService.routeForRole(role);
      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(context, nextRoute, (route) => false);
      return;
    }

    final loginLock = _authService.lastLoginLock;
    if (loginLock != null) {
      setState(() => _isLoading = false);
      Navigator.pushReplacementNamed(
        context,
        '/forgot_password',
        arguments: {
          ...loginLock,
          'email': email.toLowerCase(),
        },
      );
      return;
    }

    setState(() {
      _isLoading = false;
      _errorMessage = error;
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
                                'Selamat Datang Kembali!',
                                style: TextStyle(
                                  color: const Color(0xFF111827),
                                  fontSize: titleSize,
                                  fontWeight: FontWeight.w800,
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Masuk untuk mendapatkan harga terbaik!',
                                style: TextStyle(
                                  color: Color(0xFF566174),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  height: 1.35,
                                ),
                              ),
                              SizedBox(height: isCompact ? 22 : 24),
                              _buildLoginInput(
                                label: 'Email',
                                hintText: 'Masukkan Alamat Email',
                                keyboardType: TextInputType.emailAddress,
                                controller: _emailController,
                                textInputAction: TextInputAction.next,
                              ),
                              SizedBox(height: isCompact ? 15 : 17),
                              _buildLoginInput(
                                label: 'Kata Sandi',
                                hintText: 'Masukkan Kata Sandi',
                                obscureText: !_showPassword,
                                controller: _passwordController,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _handleLogin(),
                                suffixIcon: IconButton(
                                  tooltip: _showPassword
                                      ? 'Sembunyikan kata sandi'
                                      : 'Tampilkan kata sandi',
                                  icon: Icon(
                                    _showPassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: Colors.grey[600],
                                  ),
                                  onPressed: () {
                                    setState(
                                        () => _showPassword = !_showPassword);
                                  },
                                ),
                              ),
                              SizedBox(height: isCompact ? 13 : 15),
                              Row(
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      onChanged: (value) {
                                        setState(
                                            () => _rememberMe = value ?? false);
                                      },
                                      activeColor: const Color(0xFFE83030),
                                      side: const BorderSide(
                                        color: Color(0xFF6B7280),
                                        width: 1.2,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Ingat Saya',
                                    style: TextStyle(
                                      color: Color(0xFF4B5563),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Spacer(),
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: () => Navigator.pushNamed(
                                      context,
                                      '/forgot_password',
                                    ),
                                    child: const Text(
                                      'Lupa Kata Sandi?',
                                      style: TextStyle(
                                        color: Color(0xFFE83030),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: isCompact ? 16 : 18),
                              if (_errorMessage != null)
                                _buildError(_errorMessage!),
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
                                    onPressed: _isLoading ? null : _handleLogin,
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
                                            'Masuk',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                              SizedBox(height: isCompact ? 16 : 18),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Belum Punya Akun? ',
                                    style: TextStyle(
                                      color: Color(0xFF566174),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      '/register',
                                    ),
                                    child: const Text(
                                      'Daftar disini',
                                      style: TextStyle(
                                        color: Color(0xFFE83030),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
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

  Widget _buildLoginInput({
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

  Widget _buildError(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFC9C9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Color(0xFFFFE1E1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFE83030),
              size: 19,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Login belum berhasil',
                  style: TextStyle(
                    color: Color(0xFFB42318),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFF7A271A),
                    fontSize: 12,
                    height: 1.4,
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
}
