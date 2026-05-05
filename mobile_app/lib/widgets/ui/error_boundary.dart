import 'package:flutter/material.dart';

class ErrorBoundary extends StatelessWidget {
  const ErrorBoundary({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ErrorBoundary")),
      body: const Center(child: Text("ErrorBoundary Screen")),
    );
  }
}
