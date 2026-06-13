import 'dart:async';
import 'package:flutter/material.dart';

class TopBar extends StatefulWidget {
  const TopBar({super.key});

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  final List<String> _messages = [
    'Most News: Tetap waspada! Jangan lakukan pembayaran di luar platform.',
    'Most News: Produk baru tersedia setiap hari — jangan sampai kehabisan!',
    'Info terbaru: Penjual terverifikasi kini hadir di Jualin untuk pengalaman belanja aman.',
  ];
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _messages.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF1E1E1E),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, animation) {
          // Slide ke ATAS: masuk dari bawah → tengah saat muncul
          //                keluar dari tengah → atas saat pergi
          final inAnimation = Tween<Offset>(
            begin: const Offset(0.0, 1.0), // masuk dari bawah
            end: const Offset(0.0, 0.0),
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

          return SlideTransition(
            position: inAnimation,
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        layoutBuilder: (currentChild, previousChildren) {
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.hardEdge,
            children: [
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          );
        },
        child: Text(
          _messages[_currentIndex],
          key: ValueKey<int>(_currentIndex),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
