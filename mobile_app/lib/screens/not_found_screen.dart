import 'package:flutter/material.dart';
import '../widgets/ui/frosted_app_bar.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FrostedScaffold(
      title: 'NotFound Screen',
      body: Center(child: Text("NotFound Screen Screen")),
    );
  }
}
