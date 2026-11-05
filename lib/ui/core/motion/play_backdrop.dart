import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../parts/ribbon.dart' show auraPlayBackground;
import 'motion.dart';

/// The blue play background with the prototype's life in it: white rays
/// turning once a minute and nine twinkling sparkles, both behind [child]
/// and deaf to taps. Takes the room it is given; [child] fills it.
class PlayBackdrop extends StatelessWidget {
  const PlayBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      const DecoratedBox(decoration: auraPlayBackground),
      const IgnorePointer(child: ExcludeSemantics(child: _Rays())),
      const IgnorePointer(child: ExcludeSemantics(child: _Sparkles())),
      child,
    ],
  );
}

/// `repeating-conic-gradient`: 9° wedges at 7% white every 22°, one turn
/// per 60 s.
class _Rays extends StatelessWidget {
  const _Rays();

  @override
  Widget build(BuildContext context) => calmMotion(context)
      // held still they only fade the text's backdrop (WCAG contrast)
      ? const SizedBox.shrink()
      : RepaintBoundary(
          child: Loop(
            period: const Duration(seconds: 60),
            builder: (context, t, _) =>
                CustomPaint(size: Size.infinite, painter: _RaysPainter(t)),
          ),
        );
}

class _RaysPainter extends CustomPainter {
  _RaysPainter(this.turn);

  final double turn;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.bottomRight(Offset.zero).distance;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: radius,
    );
    final paint = Paint()..color = const Color(0x12FFFFFF);
    const deg = math.pi / 180;
    // conic angles run clockwise from straight up
    final start = -math.pi / 2 + turn * 2 * math.pi;
    for (var a = 0; a < 360; a += 22) {
      canvas.drawArc(rect, start + a * deg, 9 * deg, true, paint);
    }
  }

  @override
  bool shouldRepaint(_RaysPainter old) => old.turn != turn;
}

/// The prototype's `sparkles(9)`: ✦ at fixed spots, each twinkling.
class _Sparkles extends StatelessWidget {
  const _Sparkles();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) => Stack(
      children: [
        for (var i = 0; i < 9; i++)
          Positioned(
            left: c.maxWidth * ((i * 37) % 92 + 4) / 100,
            top: c.maxHeight * ((i * 53) % 70 + 8) / 100,
            child: Loop(
              period: const Duration(milliseconds: 2400),
              delay: Duration(milliseconds: i * 300),
              builder: (context, t, child) {
                final h = halfway(t);
                return Opacity(
                  opacity: 0.7 - 0.55 * h,
                  child: Transform.rotate(
                    angle: h * 30 * math.pi / 180,
                    child: Transform.scale(scale: 1 - 0.4 * h, child: child),
                  ),
                );
              },
              child: Text(
                '✦',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.0 + (i % 3) * 6,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
