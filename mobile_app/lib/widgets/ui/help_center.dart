import 'package:flutter/material.dart';

class HelpCenter extends StatelessWidget {
  const HelpCenter({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("HelpCenter")),
      body: const Center(child: Text("HelpCenter Screen")),
    );
  }
}
