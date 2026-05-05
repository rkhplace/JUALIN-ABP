import 'package:flutter/material.dart';
import 'seller_product_new_screen.dart';

class SellerProductEditScreen extends StatelessWidget {
  const SellerProductEditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SellerProductFormScreen(isEdit: true);
  }
}
