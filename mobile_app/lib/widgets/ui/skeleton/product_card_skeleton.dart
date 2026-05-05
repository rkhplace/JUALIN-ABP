import 'package:flutter/material.dart';

class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ProductCardSkeleton")),
      body: const Center(child: Text("ProductCardSkeleton Screen")),
    );
  }
}
