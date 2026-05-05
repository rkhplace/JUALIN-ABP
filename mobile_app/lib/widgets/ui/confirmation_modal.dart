import 'package:flutter/material.dart';

class ConfirmationModal extends StatelessWidget {
  const ConfirmationModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ConfirmationModal")),
      body: const Center(child: Text("ConfirmationModal Screen")),
    );
  }
}
