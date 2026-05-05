import 'package:flutter/material.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("NotFound Screen")),
      body: const Center(child: Text("NotFound Screen Screen")),
    );
  }
}
