import 'package:flutter/material.dart';
import '../widgets/ui/frosted_app_bar.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FrostedScaffold(
      title: 'Dasbor',
      body: Center(child: Text('Halaman dasbor')),
    );
  }
}
