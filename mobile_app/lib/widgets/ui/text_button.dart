import 'package:flutter/material.dart';

class TextButton extends StatelessWidget {
  const TextButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("TextButton")),
      body: const Center(child: Text("TextButton Screen")),
    );
  }
}
