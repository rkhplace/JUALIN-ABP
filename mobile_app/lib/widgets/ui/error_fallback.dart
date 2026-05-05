import 'package:flutter/material.dart';

class ErrorFallback extends StatelessWidget {
  const ErrorFallback({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ErrorFallback")),
      body: const Center(child: Text("ErrorFallback Screen")),
    );
  }
}
