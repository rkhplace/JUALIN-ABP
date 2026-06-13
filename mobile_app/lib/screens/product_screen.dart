import 'package:flutter/material.dart';
import '../widgets/ui/frosted_app_bar.dart';

class ProductScreen extends StatelessWidget {
  const ProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FrostedScaffold(
      title: 'Produk',
      body: Center(child: Text('Halaman produk')),
    );
  }
}
