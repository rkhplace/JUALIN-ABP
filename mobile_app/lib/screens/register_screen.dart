import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/ui/custom_button.dart';
import '../widgets/ui/custom_input.dart';
import '../widgets/ui/logo.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  String _role = 'customer';
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmation = _confirmPasswordController.text;

    final username = name.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmation.isEmpty) {
      setState(() => _errorMessage = 'Semua field harus diisi.');
      return;
    }
    if (username.length < 3) {
      setState(() => _errorMessage = 'Nama menghasilkan username minimal 3 karakter.');
      return;
    }
    if (!_isValidEmail(email)) {
      setState(() => _errorMessage = 'Format email belum valid.');
      return;
    }
    if (password.length < 8) {
      setState(() => _errorMessage = 'Password minimal 8 karakter.');
      return;
    }
    if (password != confirmation) {
      setState(() => _errorMessage = 'Konfirmasi password tidak cocok.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final error = await _authService.register(
      name,
      email,
      password,
      passwordConfirmation: confirmation,
      role: _role,
    );
    if (!mounted) return;

    if (error == null) {
      final role = await _authService.getUserRole();
      final nextRoute = _authService.routeForRole(role);
      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(context, nextRoute, (route) => false);
      return;
    }

    setState(() {
      _isLoading = false;
      _errorMessage = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F7F8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
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
                    const Logo(width: 148, height: 76),
                    const SizedBox(height: 8),
                    const Text(
                      'Daftar akun baru',
                      style: TextStyle(color: Colors.black54, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    CustomInput(
                      label: 'Nama Lengkap',
                      hintText: 'masukkan nama Anda',
                      controller: _nameController,
                    ),
                    const SizedBox(height: 18),
                    CustomInput(
                      label: 'Email',
                      hintText: 'masukkan email Anda',
                      keyboardType: TextInputType.emailAddress,
                      controller: _emailController,
                    ),
                    const SizedBox(height: 18),
                    CustomInput(
                      label: 'Password',
                      hintText: 'minimal 8 karakter',
                      obscureText: !_showPassword,
                      controller: _passwordController,
                      suffixIcon: _buildPasswordToggle(
                        isVisible: _showPassword,
                        onPressed: () {
                          setState(() => _showPassword = !_showPassword);
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    CustomInput(
                      label: 'Konfirmasi Password',
                      hintText: 'ulangi password',
                      obscureText: !_showConfirmPassword,
                      controller: _confirmPasswordController,
                      suffixIcon: _buildPasswordToggle(
                        isVisible: _showConfirmPassword,
                        onPressed: () {
                          setState(() => _showConfirmPassword = !_showConfirmPassword);
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildRoleSelect(),
                    const SizedBox(height: 16),
                    if (_errorMessage != null) _buildError(_errorMessage!),
                    const SizedBox(height: 8),
                    CustomButton(
                      text: 'Daftar',
                      isLoading: _isLoading,
                      onPressed: _handleRegister,
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Sudah punya akun? '),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text(
                            'Masuk',
                            style: TextStyle(
                              color: Color(0xFFE83030),
                              fontWeight: FontWeight.bold,
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
  }

  bool _isValidEmail(String value) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value);
  }

  Widget _buildPasswordToggle({
    required bool isVisible,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      tooltip: isVisible ? 'Sembunyikan password' : 'Tampilkan password',
      icon: Icon(
        isVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: Colors.grey[600],
      ),
      onPressed: onPressed,
    );
  }

  Widget _buildRoleSelect() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Role',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _role,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE83030)),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          items: const [
            DropdownMenuItem(value: 'customer', child: Text('Customer (Buyer)')),
            DropdownMenuItem(value: 'seller', child: Text('Seller')),
          ],
          onChanged: _isLoading
              ? null
              : (value) => setState(() => _role = value ?? 'customer'),
        ),
      ],
    );
  }

  Widget _buildError(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Colors.red, fontSize: 13),
      ),
    );
  }
}
