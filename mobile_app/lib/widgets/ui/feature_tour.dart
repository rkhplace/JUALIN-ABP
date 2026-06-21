import 'dart:math' as math;

import 'package:flutter/material.dart';

class FeatureTourStep {
  const FeatureTourStep({
    required this.targetKey,
    required this.title,
    required this.description,
    required this.icon,
  });

  final GlobalKey targetKey;
  final String title;
  final String description;
  final IconData icon;
}

class FeatureTour {
  const FeatureTour._();

  static Future<void> show(
    BuildContext context, {
    required List<FeatureTourStep> steps,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Panduan pengguna baru',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, __, ___) => _FeatureTourView(steps: steps),
      transitionBuilder: (_, animation, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween<double>(begin: .96, end: 1).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _FeatureTourView extends StatefulWidget {
  const _FeatureTourView({required this.steps});

  final List<FeatureTourStep> steps;

  @override
  State<_FeatureTourView> createState() => _FeatureTourViewState();
}

class _FeatureTourViewState extends State<_FeatureTourView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  int _index = 0;

  FeatureTourStep get _step => widget.steps[_index];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Rect _targetRect() {
    final renderBox =
        _step.targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) {
      final size = MediaQuery.sizeOf(context);
      return Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: 64,
        height: 64,
      );
    }
    return renderBox.localToGlobal(Offset.zero) & renderBox.size;
  }

  void _next() {
    if (_index == widget.steps.length - 1) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _index++);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final safePadding = MediaQuery.paddingOf(context);
    final target = _targetRect().inflate(12);
    const cardHeight = 190.0;
    final showAbove = target.center.dy > screenSize.height * .55;
    final cardTop = showAbove
        ? math.max(safePadding.top + 16, target.top - cardHeight - 24)
        : math.min(
            screenSize.height - cardHeight - safePadding.bottom - 16,
            target.bottom + 24,
          );

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _SpotlightPainter(target)),
          ),
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              final scale = 1 + (_pulseController.value * .12);
              return Positioned.fromRect(
                rect: Rect.fromCenter(
                  center: target.center,
                  width: target.width * scale,
                  height: target.height * scale,
                ),
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .9),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            left: 16,
            right: 16,
            top: cardTop,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: Tween<double>(begin: .88, end: 1).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
                ),
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: _TourCard(
                key: ValueKey(_index),
                step: _step,
                index: _index,
                total: widget.steps.length,
                onSkip: () => Navigator.of(context).pop(),
                onNext: _next,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TourCard extends StatelessWidget {
  const _TourCard({
    super.key,
    required this.step,
    required this.index,
    required this.total,
    required this.onSkip,
    required this.onNext,
  });

  final FeatureTourStep step;
  final int index;
  final int total;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final isLast = index == total - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(step.icon, size: 21, color: const Color(0xFFE83030)),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  step.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ...List.generate(
                total,
                (dot) => AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: dot == index ? 16 : 5,
                  height: 5,
                  margin: const EdgeInsets.only(left: 4),
                  decoration: BoxDecoration(
                    color: dot == index
                        ? const Color(0xFFE83030)
                        : const Color(0xFFE2E2E2),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            step.description,
            style: const TextStyle(
              color: Color(0xFF686868),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF777777),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: onSkip,
                child: const Text('Lewati'),
              ),
              const Spacer(),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE83030),
                  visualDensity: VisualDensity.compact,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                onPressed: onNext,
                child: Text(isLast ? 'Selesai' : 'Lanjut'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  const _SpotlightPainter(this.target);

  final Rect target;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Path()..addRect(Offset.zero & size);
    final hole = Path()
      ..addRRect(RRect.fromRectAndRadius(target, const Radius.circular(18)));
    final overlay = Path.combine(PathOperation.difference, background, hole);
    canvas.drawPath(
        overlay, Paint()..color = Colors.black.withValues(alpha: .58));
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) =>
      oldDelegate.target != target;
}
