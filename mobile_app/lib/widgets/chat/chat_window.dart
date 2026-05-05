import 'package:flutter/material.dart';

class ChatWindow extends StatelessWidget {
  const ChatWindow({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ChatWindow")),
      body: const Center(child: Text("ChatWindow Screen")),
    );
  }
}
