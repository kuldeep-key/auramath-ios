import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'motion.dart';

/// The prototype's celebration kit (`fxShape`, `fxPlay`, `FX`, `CELE`): one
/// small particle engine and its eight effects. Particles move per 60 fps
/// frame as the prototype's canvas does (on a canvas twice the box, drawn
/// here at half), and everything fades over the last 35 % of the run. With
/// calm motion nothing is drawn: the words and the tutor do the job.
enum Fx { confetti, stars, ribbons, fireworks, balloons, ring, spark, tick }

/// The four repeated moments (`CELE`), each with its length and its three
/// versions; a moment never plays the same version twice running.
enum FxMoment {
  /// A step right, over the board (300 ms).
  step(300, [Fx.spark, Fx.ring, Fx.tick]),

  /// A case solved (1.5 s).
  solved(1500, [Fx.confetti, Fx.stars, Fx.ribbons]),

  /// The session badge (1.5 s).
  badge(1500, [Fx.confetti, Fx.fireworks, Fx.balloons]),

  /// A warm-up done (1 s).
  warm(1000, [Fx.stars, Fx.ring, Fx.ribbons]);

  const FxMoment(this.ms, this.versions);

  final int ms;
  final List<Fx> versions;

  static final _last = <FxMoment, int>{};

  /// Picks this moment's next version: random, but never the last one.
  Fx pick([math.Random? random]) {
    final r = random ?? math.Random();
    var i = r.nextInt(versions.length);
    if (i == _last[this]) i = (i + 1) % versions.length;
    _last[this] = i;
    return versions[i];
  }
}

/// Plays [fx] once over its box for [ms], from [at] (a fraction of the
/// box), then draws nothing. A new [key] plays it again.
class FxBurst extends StatefulWidget {
  const FxBurst({
    super.key,
    required this.fx,
    required this.ms,
    this.at = const Offset(0.5, 0.42),
    this.delay = Duration.zero,
    this.seed,
  });

  /// One of [moment]'s versions, picked as the prototype's `celebrate`.
  factory FxBurst.moment(
    FxMoment moment, {
    Key? key,
    Offset at = const Offset(0.5, 0.42),
    Duration delay = Duration.zero,
  }) =>
      FxBurst(key: key, fx: moment.pick(), ms: moment.ms, at: at, delay: delay);

  final Fx fx;
  final int ms;
  final Offset at;
  final Duration delay;
  final int? seed;

  @override
  State<FxBurst> createState() => _FxBurstState();
}

class _FxBurstState extends State<FxBurst> {
  late final int _seed = widget.seed ?? math.Random().nextInt(1 << 30);

  @override
  Widget build(BuildContext context) {
    if (calmMotion(context)) return const SizedBox.expand();
    return IgnorePointer(
      child: Entrance(
        duration: Duration(milliseconds: widget.ms),
        delay: widget.delay,
        builder: (context, t, _) => t <= 0 || t >= 1
            ? const SizedBox.expand()
            : CustomPaint(
                size: Size.infinite,
                painter: _FxPainter(widget.fx, widget.ms, widget.at, t, _seed),
              ),
      ),
    );
  }
}

const _colors = [
  Color(0xFFFFC531),
  Color(0xFF2F6BFF),
  Color(0xFFFF7A59),
  Color(0xFF22A06B),
  Color(0xFFA983F5),
  Color(0xFFFFFFFF),
];
const _gold = Color(0xFFFFC531), _white = Color(0xFFFFFFFF);
const _green = Color(0xFF22A06B);

enum _Shape { rect, dot, star, strip, ring, tick, balloon }

class _P {
  _P({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.r,
    required this.c,
    required this.s,
    this.g = 0,
    this.f = 1,
    this.a = 0,
    this.va = 0,
    this.vr = 0,
    this.w = 8,
    this.o = 1,
    this.d = 0,
  });

  double x, y, vx, vy, r, a;
  final double g, f, va, vr, w, o, d;
  final Color c;
  final _Shape s;
}

/// The particles of [fx] in a [w] by [h] canvas (twice the box), as
/// `FX[name]` makes them.
List<_P> _make(Fx fx, double w, double h, Offset at, int ms, math.Random r) {
  double rnd(double a, double b) => a + r.nextDouble() * (b - a);
  Color any() => _colors[r.nextInt(_colors.length)];
  final px = w * at.dx, py = h * at.dy;
  switch (fx) {
    case Fx.confetti:
      return [
        for (var i = 0; i < 90; i++)
          _P(
            x: px + rnd(-.15, .15) * w,
            y: py,
            vx: rnd(-14, 14),
            vy: rnd(-40, -10),
            g: 1.1,
            f: .985,
            r: rnd(8, 16),
            c: any(),
            a: rnd(0, 6),
            va: rnd(-.2, .2),
            s: r.nextDouble() < .5 ? _Shape.rect : _Shape.dot,
          ),
      ];
    case Fx.stars:
      return [
        for (var i = 0; i < 44; i++)
          () {
            final a = i / 44 * 6.283 + rnd(-.1, .1), v = rnd(10, 26);
            return _P(
              x: px,
              y: py,
              vx: math.cos(a) * v,
              vy: math.sin(a) * v,
              g: .25,
              f: .97,
              r: rnd(10, 24),
              c: i % 3 != 0 ? _gold : _white,
              a: rnd(0, 6),
              va: rnd(-.15, .15),
              s: _Shape.star,
            );
          }(),
      ];
    case Fx.ribbons:
      return [
        for (var i = 0; i < 34; i++)
          _P(
            x: rnd(0, w),
            y: rnd(-h * .25, -20),
            vx: rnd(-2, 2),
            vy: rnd(18, 34),
            r: rnd(12, 20),
            c: any(),
            a: rnd(-.5, .5),
            va: rnd(-.06, .06),
            s: _Shape.strip,
          ),
      ];
    case Fx.fireworks:
      return [
        for (final d in const [0.0, .22, .44])
          ...() {
            final cx = rnd(.2, .8) * w, cy = rnd(.15, .5) * h, c = any();
            return [
              for (var i = 0; i < 26; i++)
                () {
                  final a = i / 26 * 6.283, v = rnd(8, 18);
                  return _P(
                    d: d,
                    x: cx,
                    y: cy,
                    vx: math.cos(a) * v,
                    vy: math.sin(a) * v,
                    g: .3,
                    f: .96,
                    r: rnd(8, 13),
                    c: i % 4 != 0 ? c : _white,
                    s: _Shape.dot,
                  );
                }(),
            ];
          }(),
      ];
    case Fx.balloons:
      return [
        for (var i = 0; i < 14; i++)
          _P(
            x: rnd(.05, .95) * w,
            y: h + rnd(20, 300),
            vx: rnd(-1.5, 1.5),
            vy: rnd(-30, -18),
            r: rnd(34, 54),
            c: _colors[r.nextInt(5)],
            a: rnd(-.15, .15),
            o: .95,
            s: _Shape.balloon,
          ),
      ];
    case Fx.ring:
      final vr = ms < 500 ? 26.0 : 14.0;
      return [
        _P(
          x: px,
          y: py,
          vx: 0,
          vy: 0,
          r: 20,
          vr: vr,
          w: 10,
          c: _gold,
          s: _Shape.ring,
        ),
        _P(
          d: .2,
          x: px,
          y: py,
          vx: 0,
          vy: 0,
          r: 20,
          vr: vr,
          w: 6,
          c: _white,
          s: _Shape.ring,
        ),
      ];
    case Fx.spark:
      return [
        for (var i = 0; i < 10; i++)
          () {
            final a = i / 10 * 6.283, v = rnd(9, 15);
            return _P(
              x: px,
              y: py,
              vx: math.cos(a) * v,
              vy: math.sin(a) * v,
              f: .9,
              r: rnd(9, 15),
              c: i.isOdd ? _gold : _white,
              a: rnd(0, 6),
              va: .2,
              s: _Shape.star,
            );
          }(),
      ];
    case Fx.tick:
      return [
        _P(
          x: px,
          y: py,
          vx: 0,
          vy: -1.5,
          r: 46,
          vr: 2.2,
          c: _green,
          s: _Shape.tick,
        ),
        _P(
          x: px,
          y: py,
          vx: 0,
          vy: 0,
          r: 30,
          vr: 16,
          w: 6,
          o: .5,
          c: _green,
          s: _Shape.ring,
        ),
      ];
  }
}

class _FxPainter extends CustomPainter {
  _FxPainter(this.fx, this.ms, this.at, this.t, this.seed);

  final Fx fx;
  final int ms;
  final Offset at;
  final double t;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final w = size.width * 2, h = size.height * 2;
    final ps = _make(fx, w, h, at, ms, math.Random(seed));
    // the prototype steps once a frame: replay the frames to t
    final frames = (t * ms / (1000 / 60)).floor();
    for (var n = 0; n <= frames; n++) {
      final tn = n * (1000 / 60) / ms;
      for (final p in ps) {
        if (p.d > 0 && tn < p.d) continue;
        p
          ..vy += p.g
          ..vx *= p.f
          ..vy *= p.f
          ..x += p.vx
          ..y += p.vy
          ..a += p.va
          ..r += p.vr;
      }
    }
    final fade = (1 - math.max(0, t - .65) / .35).clamp(0.0, 1.0);
    canvas
      ..save()
      ..scale(.5);
    for (final p in ps) {
      if (p.d > 0 && t < p.d) continue;
      final paint = Paint()
        ..color = p.c.withValues(alpha: p.c.a * fade * p.o)
        ..isAntiAlias = true;
      canvas
        ..save()
        ..translate(p.x, p.y)
        ..rotate(p.a);
      _shape(canvas, p, paint);
      canvas.restore();
    }
    canvas.restore();
  }

  void _shape(Canvas c, _P p, Paint paint) {
    final r = p.r;
    switch (p.s) {
      case _Shape.dot:
        c.drawCircle(Offset.zero, r / 2, paint);
      case _Shape.star:
        final path = Path();
        for (var i = 0; i < 10; i++) {
          final a = i * math.pi / 5 - math.pi / 2, q = i.isOdd ? r * .45 : r;
          final pt = Offset(math.cos(a) * q, math.sin(a) * q);
          i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
        }
        c.drawPath(path..close(), paint);
      case _Shape.strip:
        c.drawRect(Rect.fromLTWH(-r / 5, -r * 1.6, r / 2.5, r * 3.2), paint);
      case _Shape.ring:
        c.drawCircle(
          Offset.zero,
          r,
          paint
            ..style = PaintingStyle.stroke
            ..strokeWidth = p.w,
        );
      case _Shape.tick:
        c.drawPath(
          Path()
            ..moveTo(-r * .55, 0)
            ..lineTo(-r * .12, r * .42)
            ..lineTo(r * .62, -r * .45),
          paint
            ..style = PaintingStyle.stroke
            ..strokeWidth = r / 3.2
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      case _Shape.balloon:
        c.drawOval(
          Rect.fromCenter(center: Offset.zero, width: r * 1.6, height: r * 2),
          paint,
        );
        c.drawPath(
          Path()
            ..moveTo(0, r)
            ..quadraticBezierTo(r * .3, r * 1.6, 0, r * 2.2),
          Paint()
            ..color = _white.withValues(alpha: .8 * paint.color.a)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
      case _Shape.rect:
        c.drawRect(Rect.fromLTWH(-r / 2, -r / 4, r, r / 2), paint);
    }
  }

  @override
  bool shouldRepaint(_FxPainter old) => old.t != t || old.fx != fx;
}
