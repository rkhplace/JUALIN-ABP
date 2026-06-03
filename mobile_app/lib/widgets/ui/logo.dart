import 'package:flutter/material.dart';

class Logo extends StatelessWidget {
  final double width;
  final double? height;
  final AlignmentGeometry alignment;

  const Logo({
    super.key,
    this.width = 140,
    this.height,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Image.asset(
        'assets/images/Logo.png',
        width: width,
        height: height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => const Text(
          'Jualin',
          style: TextStyle(
            color: Color(0xFFE83030),
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
