import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'motion.dart';

/// The prototype's `confetti()`: [count] pieces thrown up from the middle
/// that arc and fall over 170 frames (~2.8 s), then nothing. Fills its
/// parent, deaf to taps; calm motion shows none.
class Confetti extends StatefulWidget {
  const Confetti({super.key, this.count = 140, this.delay = Duration.zero});

  final int count;
  final Duration delay;

  @override
  State<Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<Confetti>
    with SingleTickerProviderStateMixin {
  static const _frames = 170;
  static const _colours = [
    Color(0xFFFFC531),
    Color(0xFF2F6BFF),
    Color(0xFFFF7A59),
    Color(0xFF22A06B),
    Color(0xFFA983F5),
    Color(0xFFFFFFFF),
  ];

  final _rand = math.Random();
  late final List<_Piece> _pieces = [
    for (var i = 0; i < widget.count; i++)
      _Piece(
        dx: (_rand.nextDouble() - 0.5) * 0.3,
        vx: (_rand.nextDouble() - 0.5) * 14,
        vy: -(_rand.nextDouble() * 17 + 5),
        r: _rand.nextDouble() * 5 + 3,
        colour: _colours[_rand.nextInt(_colours.length)],
        a: _rand.nextDouble() * 6,
        va: (_rand.nextDouble() - 0.5) * 0.4,
        bar: _rand.nextBool(),
      ),
  ];
  // the delay is part of the run, so a settling test waits through it
  late final _c = AnimationController(
    vsync: this,
    duration:
        widget.delay + const Duration(microseconds: _frames * 1000000 ~/ 60),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started || calmMotion(context)) return;
    _started = true;
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(_pieces, _c, widget.delay.inMicroseconds),
        ),
      ),
    ),
  );
}

class _Piece {
  const _Piece({
    required this.dx,
    required this.vx,
    required this.vy,
    required this.r,
    required this.colour,
    required this.a,
    required this.va,
    required this.bar,
  });

  /// Start x offset from the centre, as a share of the width.
  final double dx;
  final double vx, vy, r, a, va;
  final Color colour;

  /// A small rectangle; otherwise a dot.
  final bool bar;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.run, this.delayMicros)
    : super(repaint: run);

  final List<_Piece> pieces;
  final AnimationController run;
  final int delayMicros;

  /// Gravity per frame and the sideways drag per frame.
  static const _gravity = 0.55;
  static const _drag = 0.985;

  @override
  void paint(Canvas canvas, Size size) {
    final micros = run.value * run.duration!.inMicroseconds - delayMicros;
    final f = (micros * 60 / 1000000).floor();
    if (f < 1 || f >= _ConfettiState._frames) return;
    final paint = Paint();
    for (final p in pieces) {
      // each frame: vy += g; vx *= drag; x += vx; y += vy; a += va
      final x =
          size.width * (0.5 + p.dx) +
          p.vx * _drag * (1 - math.pow(_drag, f)) / (1 - _drag);
      final y = size.height * 0.45 + f * p.vy + _gravity * f * (f + 1) / 2;
      paint.color = p.colour;
      canvas
        ..save()
        ..translate(x, y)
        ..rotate(p.a + p.va * f);
      if (p.bar) {
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: p.r, height: p.r / 2),
          paint,
        );
      } else {
        canvas.drawCircle(Offset.zero, p.r / 2.4, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => false;
}
