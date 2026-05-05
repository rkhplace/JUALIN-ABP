import 'package:flutter/material.dart';

class ChatSidebar extends StatelessWidget {
  const ChatSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ChatSidebar")),
      body: const Center(child: Text("ChatSidebar Screen")),
    );
  }
}
