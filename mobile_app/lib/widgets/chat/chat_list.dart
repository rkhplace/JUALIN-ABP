import 'package:flutter/material.dart';

class ChatList extends StatelessWidget {
  const ChatList({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ChatList")),
      body: const Center(child: Text("ChatList Screen")),
    );
  }
}
