import 'package:flutter/material.dart';
import '../widgets/ui/frosted_app_bar.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FrostedScaffold(
      title: 'Autentikasi',
      body: Center(child: Text('Halaman autentikasi')),
    );
  }
}
