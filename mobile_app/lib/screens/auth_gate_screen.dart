import 'package:flutter/material.dart';

import '../services/auth_service.dart';

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
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 42,
              height: 42,
              child: CircularProgressIndicator(
                color: Color(0xFFE83030),
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: 18),
            Text(
              'Memeriksa sesi...',
              style: TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
