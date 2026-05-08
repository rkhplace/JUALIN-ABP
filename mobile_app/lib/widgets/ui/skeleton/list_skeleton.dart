import 'package:flutter/material.dart';

class ListSkeleton extends StatelessWidget {
  const ListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ListSkeleton")),
      body: const Center(child: Text("ListSkeleton Screen")),
    );
  }
}
