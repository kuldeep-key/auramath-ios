import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'motion.dart';

/// The prototype's celebration kit (`FX`, `fxPlay`): one small particle
/// engine and its effects. Each runs for its length, fading out over the
/// last 35 %, then draws nothing. With reduced motion nothing plays: the
/// words and the still picture do the job.
enum FxKind { confetti, stars, ribbons, fireworks, balloons, ring }

/// Plays [kind] over its parent for [length], after [delay], from
/// [origin] (a share of the width and height; the prototype's `pt`, by
/// default `{x: .5, y: .42}`). Deaf to taps.
class CelebrationFx extends StatefulWidget {
  const CelebrationFx({
    super.key,
    required this.kind,
    required this.length,
    this.delay = Duration.zero,
    this.origin = const Offset(0.5, 0.42),
    this.seed,
  });

  final FxKind kind;
  final Duration length;
  final Duration delay;
  final Offset origin;

  /// Fixes the particles, for tests and screenshots.
  final int? seed;

  /// The session badge's three versions (`CELE.badge`), by variant 1 to 3.
  static FxKind badgeVersion(int variant) => const [
    FxKind.confetti,
    FxKind.fireworks,
    FxKind.balloons,
  ][(variant - 1) % 3];

  @override
  State<CelebrationFx> createState() => _CelebrationFxState();
}

class _CelebrationFxState extends State<CelebrationFx>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: widget.delay + widget.length,
  );
  bool _started = false;

  // one painter for the run: it keeps the particles between frames
  late final _painter = _FxPainter(
    run: _c,
    kind: widget.kind,
    delay: widget.delay,
    length: widget.length,
    origin: widget.origin,
    seed: widget.seed ?? math.Random().nextInt(1 << 30),
  );

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
        child: CustomPaint(size: Size.infinite, painter: _painter),
      ),
    ),
  );
}

/// The prototype's palette (`FXC`), the same as the confetti's.
const _fxc = [
  Color(0xFFFFC531),
  Color(0xFF2F6BFF),
  Color(0xFFFF7A59),
  Color(0xFF22A06B),
  Color(0xFFA983F5),
  Color(0xFFFFFFFF),
];

enum _Shape { rect, dot, star, strip, ring, balloon }

class _P {
  _P({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.r,
    required this.c,
    required this.s,
    this.a = 0,
    this.va = 0,
    this.g = 0,
    this.f = 1,
    this.vr = 0,
    this.w = 8,
    this.o = 1,
    this.d = 0,
  });

  double x, y, vx, vy, r, a;
  final double va, g, f, vr, w, o, d;
  final Color c;
  final _Shape s;
}

class _FxPainter extends CustomPainter {
  _FxPainter({
    required this.run,
    required this.kind,
    required this.delay,
    required this.length,
    required this.origin,
    required this.seed,
  }) : super(repaint: run);

  final AnimationController run;
  final FxKind kind;
  final Duration delay;
  final Duration length;
  final Offset origin;
  final int seed;

  List<_P>? _ps;
  Size? _for;
  int _frame = 0;

  /// The prototype's canvas is twice the screen: its speeds and sizes are
  /// in those pixels.
  List<_P> _make(double W, double H) {
    final rand = math.Random(seed);
    double rnd(double a, double b) => a + rand.nextDouble() * (b - a);
    Color fxc() => _fxc[rand.nextInt(_fxc.length)];
    final px = W * origin.dx, py = H * origin.dy;
    final ms = length.inMilliseconds;
    switch (kind) {
      case FxKind.confetti:
        return [
          for (var i = 0; i < 90; i++)
            _P(
              x: px + rnd(-.15, .15) * W,
              y: py,
              vx: rnd(-14, 14),
              vy: rnd(-40, -10),
              g: 1.1,
              f: .985,
              r: rnd(8, 16),
              c: fxc(),
              a: rnd(0, 6),
              va: rnd(-.2, .2),
              s: rand.nextBool() ? _Shape.rect : _Shape.dot,
            ),
        ];
      case FxKind.stars:
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
                c: i % 3 != 0 ? _fxc[0] : _fxc[5],
                a: rnd(0, 6),
                va: rnd(-.15, .15),
                s: _Shape.star,
              );
            }(),
        ];
      case FxKind.ribbons:
        return [
          for (var i = 0; i < 34; i++)
            _P(
              x: rnd(0, W),
              y: rnd(-H * .25, -20),
              vx: rnd(-2, 2),
              vy: rnd(18, 34),
              r: rnd(12, 20),
              c: fxc(),
              a: rnd(-.5, .5),
              va: rnd(-.06, .06),
              s: _Shape.strip,
            ),
        ];
      case FxKind.fireworks:
        return [
          for (final d in const [0.0, .22, .44])
            ...() {
              final cx = rnd(.2, .8) * W, cy = rnd(.15, .5) * H, c = fxc();
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
                      c: i % 4 != 0 ? c : _fxc[5],
                      s: _Shape.dot,
                    );
                  }(),
              ];
            }(),
        ];
      case FxKind.balloons:
        return [
          for (var i = 0; i < 14; i++)
            _P(
              x: rnd(.05, .95) * W,
              y: H + rnd(20, 300),
              vx: rnd(-1.5, 1.5),
              vy: rnd(-30, -18),
              r: rnd(34, 54),
              c: _fxc[rand.nextInt(5)],
              a: rnd(-.15, .15),
              o: .95,
              s: _Shape.balloon,
            ),
        ];
      case FxKind.ring:
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
            c: _fxc[0],
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
            c: _fxc[5],
            s: _Shape.ring,
          ),
        ];
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final total = run.duration!.inMicroseconds;
    final micros = run.value * total - delay.inMicroseconds;
    if (micros <= 0 || run.value >= 1) return;
    final W = size.width * 2, H = size.height * 2;
    if (_ps == null || _for != size) {
      _ps = _make(W, H);
      _for = size;
      _frame = 0;
    }
    final ps = _ps!;
    final lengthMs = length.inMilliseconds;
    // one step a frame at 60 fps, as requestAnimationFrame did
    final target = (micros * 60 / 1000000).floor();
    while (_frame < target) {
      _frame++;
      final t = _frame * 1000 / 60 / lengthMs;
      for (final p in ps) {
        if (p.d > 0 && t < p.d) continue;
        p.vy += p.g;
        p.vx *= p.f;
        p.vy *= p.f;
        p.x += p.vx;
        p.y += p.vy;
        p.a += p.va;
        p.r += p.vr;
      }
    }
    final t = _frame * 1000 / 60 / lengthMs;
    if (t >= 1) return;
    final fade = math.max(0.0, 1 - math.max(0.0, t - .65) / .35);
    canvas
      ..save()
      ..scale(0.5);
    final paint = Paint();
    for (final p in ps) {
      if (p.d > 0 && t < p.d) continue;
      paint
        ..color = p.c.withValues(alpha: p.c.a * fade * p.o)
        ..style = PaintingStyle.fill
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.butt;
      canvas
        ..save()
        ..translate(p.x, p.y)
        ..rotate(p.a);
      _shape(canvas, p, paint);
      canvas.restore();
    }
    canvas.restore();
  }

  static void _shape(Canvas x, _P p, Paint paint) {
    final r = p.r;
    switch (p.s) {
      case _Shape.dot:
        x.drawCircle(Offset.zero, r / 2, paint);
      case _Shape.star:
        final path = Path();
        for (var i = 0; i < 10; i++) {
          final a = i * math.pi / 5 - math.pi / 2, q = i.isOdd ? r * .45 : r;
          final o = Offset(math.cos(a) * q, math.sin(a) * q);
          i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
        }
        x.drawPath(path..close(), paint);
      case _Shape.strip:
        x.drawRect(Rect.fromLTWH(-r / 5, -r * 1.6, r / 2.5, r * 3.2), paint);
      case _Shape.ring:
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = p.w;
        x.drawCircle(Offset.zero, r, paint);
      case _Shape.balloon:
        x.drawOval(
          Rect.fromCenter(center: Offset.zero, width: r * 1.6, height: r * 2),
          paint,
        );
        x.drawPath(
          Path()
            ..moveTo(0, r)
            ..quadraticBezierTo(r * .3, r * 1.6, 0, r * 2.2),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = Colors.white.withValues(alpha: .8 * paint.color.a),
        );
      case _Shape.rect:
        x.drawRect(Rect.fromLTWH(-r / 2, -r / 4, r, r / 2), paint);
    }
  }

  @override
  bool shouldRepaint(_FxPainter old) => !identical(old, this);
}
