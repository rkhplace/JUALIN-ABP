import 'package:flutter/material.dart';

class JualinLogoLoader extends StatefulWidget {
  final double size;
  final String? message;

  const JualinLogoLoader({
    super.key,
    this.size = 72,
    this.message,
  });

  @override
  State<JualinLogoLoader> createState() => _JualinLogoLoaderState();
}

class _JualinLogoLoaderState extends State<JualinLogoLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.92, end: 1.04).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _opacity = Tween<double>(begin: 0.18, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: _opacity,
            child: ScaleTransition(
              scale: _scale,
              child: Image.asset(
                'assets/images/Logo.png',
                width: widget.size,
                height: widget.size,
                fit: BoxFit.contain,
              ),
            ),
          ),
          if (message != null && message.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
