import 'package:flutter/material.dart';

import '../../../core/motion/motion.dart';
import '../../../core/theme/tokens.dart';
import 'play_moment.dart';

/// The prototype's big-badge shapes (`medalSVG`, `habitSVG`, `trophySVG`),
/// drawn from its SVG in its own view boxes. Stand-ins until Apoorv's
/// badge art; gold, blue and navy only, never red (NFR-03).

/// A stop medal: a blue ribbon over a gold disc with a star. [size] wide,
/// 1.05 × as tall (view box 200 × 210). [glint] adds the LevelUp star that
/// twinkles every 2.4 s.
class MedalBadge extends StatelessWidget {
  const MedalBadge({super.key, required this.size, this.glint = false});

  final double size;
  final bool glint;

  @override
  Widget build(BuildContext context) {
    final medal = CustomPaint(
      size: Size(size, (size * 1.05).roundToDouble()),
      painter: const _MedalPainter(),
    );
    if (!glint) return medal;
    final k = size / 200;
    return SizedBox(
      width: size,
      height: (size * 1.05).roundToDouble(),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          medal,
          // the glint's own box: (140, 74) to (160, 102), centred on it
          Positioned(
            left: 140 * k,
            top: 74 * k,
            width: 20 * k,
            height: 28 * k,
            child: Glint(child: CustomPaint(painter: _GlintPainter())),
          ),
        ],
      ),
    );
  }
}

/// The prototype's `oGlint`: grows from 0.3 and fades in to full, then
/// back, every 2.4 s, eased in and out.
class Glint extends StatelessWidget {
  const Glint({
    super.key,
    required this.child,
    this.period = const Duration(milliseconds: 2400),
  });

  final Widget child;
  final Duration period;

  @override
  Widget build(BuildContext context) => Loop(
    period: period,
    child: child,
    builder: (context, t, child) {
      final e = halfway(t);
      return Opacity(
        opacity: e,
        child: Transform.scale(scale: 0.3 + 0.7 * e, child: child),
      );
    },
  );
}

/// A habit badge: a blue hexagon with the habit's picture. [size] wide,
/// 1.05 × as tall.
class HabitBadge extends StatelessWidget {
  const HabitBadge({super.key, required this.size, required this.emoji});

  final double size;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    final k = size / 200;
    return SizedBox(
      width: size,
      height: (size * 1.05).roundToDouble(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned.fill(child: CustomPaint(painter: _HexPainter())),
          // the SVG's 78 px emoji, its baseline at y 132
          Positioned(
            top: 62 * k,
            child: Art(emoji, size: 74 * k),
          ),
        ],
      ),
    );
  }
}

/// A land trophy: a gold cup on a blue band and a navy base. [size] wide,
/// 1.1 × as tall (view box 200 × 220).
class TrophyBadge extends StatelessWidget {
  const TrophyBadge({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size(size, (size * 1.1).roundToDouble()),
    painter: const _TrophyPainter(),
  );
}

/// The gold disc of a session badge or First Case: the prototype's
/// `.badge` (a lit gold disc, a darker edge and lip, a soft inner glow and
/// a dashed white ring).
class GoldDisc extends StatelessWidget {
  const GoldDisc({
    super.key,
    required this.emoji,
    required this.size,
    this.blue = false,
  });

  final String emoji;
  final double size;
  final bool blue;

  @override
  Widget build(BuildContext context) {
    final edge = (size / 28).roundToDouble().clamp(3.0, 6.0);
    final c = blue
        ? (
            AuraColors.badgeBlueLight,
            AuraColors.badgeBlue,
            AuraColors.badgeBlueEdge,
            AuraColors.badgeBlueLip,
          )
        : (
            AuraColors.badgeGoldLight,
            AuraColors.badgeGold,
            AuraColors.badgeGoldEdge,
            AuraColors.badgeGoldLip,
          );
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(0, -0.3),
          radius: 0.82,
          stops: const [0, 0.7],
          colors: [c.$1, c.$2],
        ),
        border: Border.all(color: c.$3, width: edge),
        boxShadow: [BoxShadow(color: c.$4, offset: Offset(0, size / 21))],
      ),
      child: CustomPaint(
        painter: _RingPainter(inset: size * 14 / 170, glow: size * 8 / 170),
        child: Center(child: Art(emoji, size: size * 0.44)),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.inset, required this.glow});

  final double inset;
  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    // inset 0 0 0 8px rgba(255,255,255,.35)
    canvas.drawCircle(
      c,
      r - glow / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = glow
        ..color = AuraColors.white.withValues(alpha: 0.35),
    );
    // border: 4px dashed rgba(255,255,255,.8), inset 14
    final ring = r - inset + 2;
    if (ring <= 4) return;
    final dash = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (4 * r / 85).clamp(2.0, 4.0)
      ..color = AuraColors.white.withValues(alpha: 0.8);
    final rect = Rect.fromCircle(center: c, radius: ring);
    final round = 2 * 3.14159265 * ring;
    final n = (round / 20).floor().clamp(8, 80);
    final step = 2 * 3.14159265 / n;
    for (var i = 0; i < n; i++) {
      canvas.drawArc(rect, i * step, step * 0.6, false, dash);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.inset != inset || old.glow != glow;
}

/// A path from [start] through relative steps, closed.
Path _rel(Offset start, List<double> steps) {
  final p = Path()..moveTo(start.dx, start.dy);
  var at = start;
  for (var i = 0; i + 1 < steps.length; i += 2) {
    at = at.translate(steps[i], steps[i + 1]);
    p.lineTo(at.dx, at.dy);
  }
  return p..close();
}

Paint _fill(Color c) => Paint()..color = c;
Paint _line(Color c, double w, {bool round = true}) => Paint()
  ..style = PaintingStyle.stroke
  ..color = c
  ..strokeWidth = w
  ..strokeJoin = StrokeJoin.round
  ..strokeCap = round ? StrokeCap.round : StrokeCap.butt;

class _MedalPainter extends CustomPainter {
  const _MedalPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 200, size.height / 210);
    final ribbon = Path()
      ..moveTo(62, 6)
      ..lineTo(88, 80)
      ..lineTo(112, 80)
      ..lineTo(138, 6)
      ..close();
    canvas
      ..drawPath(ribbon, _fill(AuraColors.blue))
      ..drawPath(ribbon, _line(AuraColors.navy, 5))
      ..drawLine(
        const Offset(82, 6),
        const Offset(96, 66),
        _line(const Color(0xFF8FB0FF), 6, round: false),
      )
      ..drawLine(
        const Offset(118, 6),
        const Offset(104, 66),
        _line(const Color(0xFF8FB0FF), 6, round: false),
      )
      ..drawCircle(const Offset(100, 132), 68, _fill(AuraColors.yellow))
      ..drawCircle(const Offset(100, 132), 68, _line(AuraColors.navy, 6))
      ..drawCircle(const Offset(100, 132), 50, _fill(const Color(0xFFFFE38A)));
    final star = _rel(const Offset(100, 96), const [
      11, 23, 25, 3.6, -18, 17.6, 4.4, 25, -22.4, -12, //
      -22.4, 12, 4.4, -25, -18, -17.6, 25, -3.6,
    ]);
    canvas
      ..drawPath(star, _fill(const Color(0xFFE5A100)))
      ..drawPath(star, _line(const Color(0xFFB87F00), 2));
  }

  @override
  bool shouldRepaint(_MedalPainter old) => false;
}

class _GlintPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 20, size.height / 28);
    // M150 74 l4 10 10 4 -10 4 -4 10 -4 -10 -10 -4 10 -4 z, from (140, 74)
    canvas.drawPath(
      _rel(const Offset(10, 0), const [
        4, 10, 10, 4, -10, 4, -4, 10, -4, -10, -10, -4, 10, -4, //
      ]),
      _fill(AuraColors.white),
    );
  }

  @override
  bool shouldRepaint(_GlintPainter old) => false;
}

class _HexPainter extends CustomPainter {
  const _HexPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 200, size.height / 210);
    Path hex(List<Offset> p) => Path()..addPolygon(p, true);
    final outer = hex(const [
      Offset(100, 8),
      Offset(182, 56),
      Offset(182, 152),
      Offset(100, 200),
      Offset(18, 152),
      Offset(18, 56),
    ]);
    final inner = hex(const [
      Offset(100, 28),
      Offset(164, 66),
      Offset(164, 142),
      Offset(100, 180),
      Offset(36, 142),
      Offset(36, 66),
    ]);
    canvas
      ..drawPath(outer, _fill(AuraColors.blue))
      ..drawPath(outer, _line(AuraColors.navy, 6))
      ..drawPath(inner, _fill(const Color(0xFFEAF1FF)))
      ..drawPath(inner, _line(const Color(0xFF8FB0FF), 4));
  }

  @override
  bool shouldRepaint(_HexPainter old) => false;
}

class _TrophyPainter extends CustomPainter {
  const _TrophyPainter();

  // REG_C[0]: the Orchard's gold, its shade and its blue band
  static const _g = AuraColors.yellow;
  static const _d = Color(0xFFB87F00);
  static const _band = AuraColors.blue;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 200, size.height / 220);
    final handles = Path()
      ..moveTo(48, 44)
      ..lineTo(20, 44)
      ..quadraticBezierTo(16, 88, 60, 98)
      ..moveTo(152, 44)
      ..lineTo(180, 44)
      ..quadraticBezierTo(184, 88, 140, 98);
    final cup = Path()
      ..moveTo(44, 24)
      ..lineTo(156, 24)
      ..lineTo(156, 78)
      ..quadraticBezierTo(156, 132, 100, 138)
      ..quadraticBezierTo(44, 132, 44, 78)
      ..close();
    final shine = Path()
      ..moveTo(60, 34)
      ..lineTo(60, 78)
      ..quadraticBezierTo(60, 108, 82, 120);
    final star = _rel(const Offset(100, 52), const [
      9, 19, 21, 3, -15, 15, 3.6, 21, -18.6, -10, //
      -18.6, 10, 3.6, -21, -15, -15, 21, -3,
    ]);
    const stem = Rect.fromLTWH(88, 136, 24, 26);
    final band = RRect.fromRectAndRadius(
      const Rect.fromLTWH(52, 160, 96, 22),
      const Radius.circular(6),
    );
    final base = RRect.fromRectAndRadius(
      const Rect.fromLTWH(38, 180, 124, 28),
      const Radius.circular(8),
    );
    canvas
      ..drawPath(handles, _line(_d, 12))
      ..drawPath(cup, _fill(_g))
      ..drawPath(cup, _line(AuraColors.navy, 6))
      ..drawPath(shine, _line(AuraColors.white.withValues(alpha: 0.55), 8))
      ..drawPath(star, _fill(AuraColors.white))
      ..drawPath(star, _line(_d, 3))
      ..drawRect(stem, _fill(_d))
      ..drawRect(stem, _line(AuraColors.navy, 5, round: false))
      ..drawRRect(band, _fill(_band))
      ..drawRRect(band, _line(AuraColors.navy, 6))
      ..drawRRect(base, _fill(AuraColors.navy));
  }

  @override
  bool shouldRepaint(_TrophyPainter old) => false;
}
