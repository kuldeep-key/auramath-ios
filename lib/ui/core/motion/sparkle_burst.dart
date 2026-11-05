import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'motion.dart';

/// The prototype's soft star burst where something lands: [count] coloured
/// dots fly out from the centre and fade (650–850 ms). Place it with its
/// centre on the spot; it never takes taps.
class SparkleBurst extends StatelessWidget {
  const SparkleBurst({super.key, this.count = 10, this.reach = 46});

  final int count;

  /// How far the dots fly (46 px plus up to 34 more).
  final double reach;

  static const _colors = [
    Color(0xFFFFC531),
    Color(0xFF2F6BFF),
    Color(0xFFFF9EB5),
    Color(0xFF7FD8A8),
    Color(0xFFA983F5),
  ];
  static const _curve = Cubic(0.2, 0.8, 0.3, 1);

  @override
  Widget build(BuildContext context) {
    if (calmMotion(context)) return const SizedBox.shrink();
    final rnd = math.Random();
    return IgnorePointer(
      child: SizedBox.square(
        dimension: 0,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < count; i++)
              _Dot(
                color: _colors[i % _colors.length],
                angle: i / count * math.pi * 2 + rnd.nextDouble() * 0.4,
                distance: reach + rnd.nextDouble() * 34,
                ms: 650 + rnd.nextInt(200),
              ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({
    required this.color,
    required this.angle,
    required this.distance,
    required this.ms,
  });

  final Color color;
  final double angle;
  final double distance;
  final int ms;

  @override
  Widget build(BuildContext context) => Entrance(
    duration: Duration(milliseconds: ms),
    builder: (context, t, _) {
      final e = SparkleBurst._curve.transform(t);
      // out to the distance by 60 %, then a little further, dropping, gone
      final d = keyframes(e, [(0, 0), (0.6, distance), (1, distance * 1.15)]);
      final drop = keyframes(e, const [(0, 0), (0.6, 0), (1, 10)]);
      final scale = keyframes(e, const [(0, 0.4), (0.6, 1), (1, 0.2)]);
      return Transform.translate(
        offset: Offset(math.cos(angle) * d - 5, math.sin(angle) * d + drop - 5),
        child: Opacity(
          opacity: keyframes(e, const [(0, 1), (0.6, 1), (1, 0)]),
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
        ),
      );
    },
  );
}
