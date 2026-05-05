import 'package:flutter/material.dart';

class ProductDetailSkeleton extends StatelessWidget {
  const ProductDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ProductDetailSkeleton")),
      body: const Center(child: Text("ProductDetailSkeleton Screen")),
    );
  }
}
