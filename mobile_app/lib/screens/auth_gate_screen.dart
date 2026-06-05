import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/ui/logo_loader.dart';

class AuthGateScreen extends StatefulWidget {
  const AuthGateScreen({super.key});

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _routeFromSession();
  }

  Future<void> _routeFromSession() async {
    final route = await _authService.resolveInitialRoute();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: JualinLogoLoader(),
    );
  }
}
