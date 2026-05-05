import 'package:flutter/material.dart';

class Pagination extends StatelessWidget {
  const Pagination({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pagination")),
      body: const Center(child: Text("Pagination Screen")),
    );
  }
}
