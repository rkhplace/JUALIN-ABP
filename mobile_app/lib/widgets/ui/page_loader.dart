import 'package:flutter/material.dart';

class PageLoader extends StatelessWidget {
  const PageLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("PageLoader")),
      body: const Center(child: Text("PageLoader Screen")),
    );
  }
}
