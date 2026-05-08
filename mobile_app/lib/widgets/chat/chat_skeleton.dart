import 'package:flutter/material.dart';

class ChatSkeleton extends StatelessWidget {
  const ChatSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ChatSkeleton")),
      body: const Center(child: Text("ChatSkeleton Screen")),
    );
  }
}
