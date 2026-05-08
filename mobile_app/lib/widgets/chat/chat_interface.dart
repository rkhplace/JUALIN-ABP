import 'package:flutter/material.dart';

class ChatInterface extends StatelessWidget {
  const ChatInterface({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ChatInterface")),
      body: const Center(child: Text("ChatInterface Screen")),
    );
  }
}
