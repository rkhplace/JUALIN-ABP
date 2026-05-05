import 'package:flutter/material.dart';

class Badge extends StatelessWidget {
  const Badge({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Badge")),
      body: const Center(child: Text("Badge Screen")),
    );
  }
}
