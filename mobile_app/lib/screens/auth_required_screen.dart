import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/ui/login_required_dialog.dart';
import '../widgets/ui/logo_loader.dart';

class AuthRequiredScreen extends StatefulWidget {
  final Widget child;
  final String message;

  const AuthRequiredScreen({
    super.key,
    required this.child,
    this.message = 'Silakan login terlebih dahulu untuk melanjutkan.',
  });

  @override
  State<AuthRequiredScreen> createState() => _AuthRequiredScreenState();
}

class _AuthRequiredScreenState extends State<AuthRequiredScreen> {
  final AuthService _authService = AuthService();
  bool _isAllowed = false;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final isLoggedIn = await _authService.isLoggedIn();
    if (!mounted) return;

    if (!isLoggedIn) {
      final shouldLogin = await showLoginRequiredDialog(
        context,
        message: widget.message,
      );
      if (!mounted) return;

      if (shouldLogin) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        Navigator.pushReplacementNamed(context, '/main');
      }
      return;
    }

    setState(() {
      _isAllowed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isAllowed) return widget.child;

    return const Scaffold(
      backgroundColor: Colors.white,
      body: JualinLogoLoader(size: 72),
    );
  }
}
