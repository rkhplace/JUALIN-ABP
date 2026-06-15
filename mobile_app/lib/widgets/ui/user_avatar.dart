import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String name;
  final String imageUrl;
  final double radius;
  final bool showBorder;
  final Color accentColor;

  const UserAvatar({
    super.key,
    required this.name,
    this.imageUrl = '',
    this.radius = 24,
    this.showBorder = true,
    this.accentColor = const Color(0xFFE83030),
  });

  String get _initial {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed == '-') return 'U';
    return trimmed.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;

    Widget fallback() {
      return Container(
        color: const Color(0xFFFFEFEF),
        alignment: Alignment.center,
        child: Text(
          _initial,
          style: TextStyle(
            color: accentColor,
            fontWeight: FontWeight.w900,
            fontSize: radius * 0.72,
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(color: const Color(0xFFFFDADA), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipOval(
        child: imageUrl.trim().isEmpty
            ? fallback()
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => fallback(),
              ),
      ),
    );
  }
}
