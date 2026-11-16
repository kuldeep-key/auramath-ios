import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../motion/motion.dart';

/// The prototype's tutor drawing (16 Nov: `tutorSVG`, `tutorHead`, `tuFace`,
/// `tuEyes`, `tuMouth`, `tuArm`, `tuArms`, `tuExtras`), painted from the
/// same shapes in the same SVG units: the whole figure in the box
/// (-14, 0, 228, 220), the head alone in (40, 6, 120, 124).
///
/// The moving parts are the prototype's keyframes, from [TutorPose]:
/// `tuBob` (the body, 2.8 s), `tuCheer` (0.5 s each way), `tuTalk` (the
/// mouth, 0.3 s each way), `tuBlink` (every 5 s), `tuDot` (1.2 s, 0.2 s
/// apart) and `tuSpark` (1.1 s, the second 0.35 s late).
class TutorLook {
  const TutorLook({
    required this.skin,
    required this.shade,
    required this.hair,
    required this.highlight,
    required this.top,
    required this.topDark,
    required this.collar,
    required this.glasses,
    this.robot = false,
  });

  final Color skin, shade, hair, highlight, top, topDark, collar;
  final bool glasses;

  /// Drawn as the robot: a rounded head with an antenna, no hair.
  final bool robot;

  /// The prototype's teacher `a` (`teacher_1`): fair, brown hair in a bun,
  /// glasses, a yellow top.
  static const teacherA = TutorLook(
    skin: Color(0xFFF5C9A4),
    shade: Color(0xFFE8AE85),
    hair: Color(0xFF6B4226),
    highlight: Color(0xFF8A5A34),
    top: _yl,
    topDark: Color(0xFFE5A100),
    collar: _wh,
    glasses: true,
  );

  /// The prototype's teacher `b` (`teacher_2`): brown skin, dark curls, a
  /// blue top with a yellow collar.
  static const teacherB = TutorLook(
    skin: Color(0xFFB9794F),
    shade: Color(0xFFA0633D),
    hair: Color(0xFF2A2230),
    highlight: Color(0xFF463A52),
    top: _bl,
    topDark: Color(0xFF1D4FD6),
    collar: _yl,
    glasses: false,
  );

  /// The spec's `robot` (the prototype dropped it on 16 Nov; tutors.yaml
  /// still enables it): the same parts and moves, a pale-blue robot.
  /// DRAFT for Apoorv.
  static const robotLook = TutorLook(
    skin: Color(0xFFDCE6FF),
    shade: Color(0xFFB9C8F0),
    hair: Color(0xFFDCE6FF),
    highlight: Color(0xFFFFFFFF),
    top: _bl,
    topDark: Color(0xFF1D4FD6),
    collar: _yl,
    glasses: false,
    robot: true,
  );

  /// The look for a tutor id (tutors.yaml) and kind.
  static TutorLook of(String tutorId, String kind) => kind == 'robot'
      ? robotLook
      : tutorId == 'teacher_2'
      ? teacherB
      : teacherA;
}

const _nv = Color(0xFF0F2A73);
const _bl = Color(0xFF2F6BFF);
const _yl = Color(0xFFFFC531);
const _wh = Color(0xFFFFFFFF);
const _ink = Color(0xFF2A1A12);
const _mouth = Color(0xFF7A2B2B);
const _tongue = Color(0xFFF08A8A);
const _cheek = Color(0x73FF9E8A); // #FF9E8A at .45
const _shoe = Color(0xFF3B2410);

/// The five states' drawn variants (tutors.yaml `animation.states`).
enum TutorPart { idle, talking, thinking, cheering, encourage }

/// Where each moving part is at one moment.
class TutorPose {
  const TutorPose({
    this.bob = 0,
    this.blink = 1,
    this.talk = 1,
    this.dots = const [1, 1, 1],
    this.sparkScale = const [1, 1],
    this.sparkOpacity = const [1, 1],
  });

  /// The body's lift, in SVG units (negative is up).
  final double bob;

  /// The eyes' height (1 open, 0.1 shut).
  final double blink;

  /// The talking mouth's height (1 to 0.35).
  final double talk;

  /// The thinking dots' opacity.
  final List<double> dots;

  /// The cheering sparks: the first and third, and the second (`.b`).
  final List<double> sparkScale;
  final List<double> sparkOpacity;

  /// The pose for [state] [ms] after it began, as the prototype's CSS
  /// animations run.
  static TutorPose at(TutorPart state, double ms) {
    double phase(double period, [double delay = 0]) =>
        ((ms - delay) % period) / period;
    // tuBlink: 5 s, eyes shut to 0.1 at 97 % (CSS `ease` per segment)
    final blink = cssFrames(phase(5000), const [
      (0, 1),
      (0.94, 1),
      (0.97, 0.1),
      (1, 1),
    ]);
    // tuBob 2.8 s; tuCheer 0.5 s alternate (one up and down is 1 s)
    final bob = switch (state) {
      TutorPart.cheering => -8 * halfway(phase(1000)),
      TutorPart.thinking => 0.0,
      _ => -4 * halfway(phase(2800)),
    };
    // tuTalk: 0.3 s alternate to 0.35
    final talk = 1 - 0.65 * halfway(phase(600));
    // tuDot: 1.2 s, .25 → 1 → .25, the second 0.2 s and the third 0.4 s
    // late (before its delay a dot shows plain, at 1)
    double dot(double delay) => ms < delay
        ? 1
        : cssFrames(phase(1200, delay), const [
            (0, 0.25),
            (0.5, 1),
            (1, 0.25),
          ], Curves.easeInOut);
    // tuSpark: 1.1 s, scale .4 → 1, opacity .3 → 1; `.b` 0.35 s late
    double spark(double delay, double lo) => ms < delay
        ? 1
        : cssFrames(phase(1100, delay), [
            (0, lo),
            (0.5, 1),
            (1, lo),
          ], Curves.easeInOut);
    return TutorPose(
      bob: bob,
      blink: blink,
      talk: talk,
      dots: [dot(0), dot(200), dot(400)],
      sparkScale: [spark(0, 0.4), spark(350, 0.4)],
      sparkOpacity: [spark(0, 0.3), spark(350, 0.3)],
    );
  }
}

/// Paints the tutor: [head] alone (the 56 to 64 pt lesson header, TTR-05)
/// or the whole figure.
class TutorPainter extends CustomPainter {
  TutorPainter({
    required this.look,
    required this.state,
    required this.head,
    required this.pose,
  }) : super(repaint: pose);

  final TutorLook look;
  final TutorPart state;
  final bool head;
  final ValueListenable<TutorPose> pose;

  /// The SVG viewBoxes.
  static const bodyBox = Rect.fromLTWH(-14, 0, 228, 220);
  static const headBox = Rect.fromLTWH(40, 6, 120, 124);

  @override
  void paint(Canvas canvas, Size size) {
    final box = head ? headBox : bodyBox;
    // preserveAspectRatio xMidYMid meet
    final k = (size.width / box.width) < (size.height / box.height)
        ? size.width / box.width
        : size.height / box.height;
    canvas
      ..save()
      ..translate(
        (size.width - box.width * k) / 2,
        (size.height - box.height * k) / 2,
      )
      ..scale(k)
      ..translate(-box.left, -box.top);
    final p = pose.value;
    if (head) {
      _face(canvas, p, 5);
    } else {
      _body(canvas, p);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(TutorPainter old) =>
      old.look != look ||
      old.state != state ||
      old.head != head ||
      old.pose != pose;

  // ---------------------------------------------------------------- body

  void _body(Canvas c, TutorPose p) {
    final l = look;
    c.drawOval(
      Rect.fromCenter(center: const Offset(100, 210), width: 104, height: 16),
      _fill(const Color(0x380F2A73)), // rgba(15,42,115,.22)
    );
    c
      ..save()
      ..translate(0, p.bob);
    _arms(c);
    _rrect(c, 76, 184, 20, 20, 5, _nv);
    _rrect(c, 104, 184, 20, 20, 5, _nv);
    _rrect(c, 70, 200, 28, 10, 5, _shoe);
    _rrect(c, 102, 200, 28, 10, 5, _shoe);
    final torso = svgPath(
      'M62 190 v-42 q0 -24 24 -24 h28 q24 0 24 24 v42 q-38 8 -76 0 z',
    );
    c
      ..drawPath(torso, _fill(l.top))
      ..drawPath(torso, _stroke(_nv, 4, join: StrokeJoin.round))
      ..drawPath(
        svgPath('M66 176 q34 12 68 0 v12 q-34 7 -68 0 z'),
        _fill(l.topDark.withValues(alpha: 0.5)),
      );
    _rrect(c, 90, 112, 20, 18, 6, l.shade);
    final collar = svgPath('M84 124 l16 16 l16 -16 l6 10 l-22 18 l-22 -18 z');
    c
      ..drawPath(collar, _fill(l.robot ? _yl : l.collar))
      ..drawPath(collar, _stroke(_nv, 3, join: StrokeJoin.round))
      ..drawCircle(const Offset(100, 162), 3, _fill(_nv))
      ..drawCircle(const Offset(100, 174), 3, _fill(_nv));
    _face(c, p, 4);
    c.restore();
    _extras(c, p);
  }

  void _arm(
    Canvas c,
    double sx,
    double sy,
    double ex,
    double ey,
    double hx,
    double hy,
  ) {
    final path = Path()
      ..moveTo(sx, sy)
      ..quadraticBezierTo(ex, ey, hx, hy);
    c
      ..drawPath(path, _stroke(_nv, 15, cap: StrokeCap.round))
      ..drawPath(path, _stroke(look.top, 9.5, cap: StrokeCap.round));
    _circle(c, hx, hy, 9, look.skin, 3);
  }

  void _arms(Canvas c) {
    const l = (62.0, 142.0), r = (138.0, 142.0);
    final p = switch (state) {
      TutorPart.talking => const [
        (-14.0, 24.0, -12.0, 44.0),
        (26.0, 14.0, 36.0, -8.0),
      ],
      TutorPart.thinking => const [
        (-14.0, 24.0, -12.0, 44.0),
        (30.0, 20.0, -6.0, -22.0),
      ],
      TutorPart.cheering => const [
        (-26.0, -12.0, -30.0, -48.0),
        (26.0, -12.0, 30.0, -48.0),
      ],
      TutorPart.encourage => const [
        (-14.0, 24.0, -12.0, 44.0),
        (30.0, 10.0, 40.0, -14.0),
      ],
      TutorPart.idle => const [
        (-14.0, 24.0, -12.0, 44.0),
        (14.0, 24.0, 12.0, 44.0),
      ],
    };
    _arm(
      c,
      l.$1,
      l.$2,
      l.$1 + p[0].$1,
      l.$2 + p[0].$2,
      l.$1 + p[0].$3,
      l.$2 + p[0].$4,
    );
    _arm(
      c,
      r.$1,
      r.$2,
      r.$1 + p[1].$1,
      r.$2 + p[1].$2,
      r.$1 + p[1].$3,
      r.$2 + p[1].$4,
    );
    if (state == TutorPart.encourage) {
      // a thumb up
      final thumb = RRect.fromRectAndRadius(
        Rect.fromLTWH(r.$1 + 36, r.$2 - 33, 8, 14),
        const Radius.circular(4),
      );
      c
        ..drawRRect(thumb, _fill(look.skin))
        ..drawRRect(thumb, _stroke(_nv, 3));
    }
  }

  void _extras(Canvas c, TutorPose p) {
    if (state == TutorPart.thinking) {
      const dots = [(150.0, 40.0, 5.0), (165.0, 30.0, 6.0), (183.0, 20.0, 7.0)];
      for (final (i, (x, y, r)) in dots.indexed) {
        final o = p.dots[i];
        c
          ..drawCircle(Offset(x, y), r, _fill(_wh.withValues(alpha: o)))
          ..drawCircle(Offset(x, y), r, _stroke(_nv.withValues(alpha: o), 2));
      }
    }
    if (state == TutorPart.cheering) {
      _spark(c, 8, 40, 11, p.sparkScale[0], p.sparkOpacity[0]);
      _spark(c, 192, 34, 13, p.sparkScale[1], p.sparkOpacity[1]);
      _spark(c, 184, 104, 8, p.sparkScale[0], p.sparkOpacity[0]);
    }
  }

  void _spark(Canvas c, double a, double b, double s, double scale, double o) {
    final star = svgPath(
      'M$a ${b - s} l${s * .3} ${s * .7} ${s * .7} ${s * .3} ${-s * .7} '
      '${s * .3} ${-s * .3} ${s * .7} ${-s * .3} ${-s * .7} ${-s * .7} '
      '${-s * .3} ${s * .7} ${-s * .3} z',
    );
    c
      ..save()
      ..translate(a, b)
      ..scale(scale)
      ..translate(-a, -b)
      ..drawPath(star, _fill(_yl.withValues(alpha: o)))
      ..drawPath(
        star,
        _stroke(_nv.withValues(alpha: o), 1.5, join: StrokeJoin.round),
      )
      ..restore();
  }

  // ---------------------------------------------------------------- head

  /// The head: hair behind, ears, face, hair in front, eyes, glasses,
  /// mouth. The face's centre is (100, 80).
  void _face(Canvas c, TutorPose p, double sw) {
    final l = look;
    if (l.robot) {
      _robotHead(c, p, sw);
      return;
    }
    final a = l.glasses;
    if (a) {
      _circle(c, 100, 22, 14, l.hair, sw);
      _circle(c, 100, 70, 49, l.hair, sw);
    } else {
      const curls = [
        (58.0, 62.0, 17.0),
        (68.0, 40.0, 18.0),
        (90.0, 28.0, 19.0),
        (114.0, 28.0, 19.0),
        (134.0, 42.0, 18.0),
        (143.0, 64.0, 16.0),
      ];
      for (final (x, y, r) in curls) {
        _circle(c, x, y, r, l.hair, sw);
      }
      c.drawCircle(const Offset(100, 58), 40, _fill(l.hair));
    }
    _circle(c, 58, 84, 8, l.skin, sw);
    _circle(c, 142, 84, 8, l.skin, sw);
    _circle(c, 100, 80, 43, l.skin, sw);
    c
      ..drawCircle(const Offset(72, 96), 7, _fill(_cheek))
      ..drawCircle(const Offset(128, 96), 7, _fill(_cheek));
    if (a) {
      c
        ..drawPath(
          svgPath(
            'M59 74 q4 -40 41 -40 q37 0 41 40 q-16 -22 -41 -20 '
            'q-25 -2 -41 20 z',
          ),
          _fill(l.hair),
        )
        ..drawPath(
          svgPath('M76 46 q24 -12 46 2'),
          _stroke(l.highlight, 4, cap: StrokeCap.round),
        );
    } else {
      const front = [
        (70.0, 50.0, 13.0),
        (86.0, 42.0, 14.0),
        (104.0, 40.0, 14.0),
        (122.0, 44.0, 13.0),
        (134.0, 56.0, 11.0),
      ];
      for (final (x, y, r) in front) {
        c.drawCircle(Offset(x, y), r, _fill(l.hair));
      }
      c
        ..drawCircle(const Offset(82, 36), 4, _fill(l.highlight))
        ..drawCircle(const Offset(110, 33), 4, _fill(l.highlight))
        ..drawCircle(const Offset(130, 46), 3.4, _fill(l.highlight));
    }
    _eyes(c, p, 100, 80, 20, 5.6);
    if (a) {
      for (final x in [80.0, 120.0]) {
        c
          ..drawCircle(Offset(x, 80), 14, _fill(const Color(0x59FFFFFF)))
          ..drawCircle(Offset(x, 80), 14, _stroke(_nv, 3.2));
      }
      c.drawPath(svgPath('M94 79 q6 -4 12 0'), _stroke(_nv, 3.2));
    }
    _mouthOf(c, p, 100, 102, 22);
  }

  /// DRAFT: the robot's head in the teachers' frame, the same eyes and
  /// mouth on a pale screen.
  void _robotHead(Canvas c, TutorPose p, double sw) {
    final l = look;
    c.drawLine(
      const Offset(100, 38),
      const Offset(100, 20),
      _stroke(_nv, sw, cap: StrokeCap.round),
    );
    _circle(c, 100, 18, 8, _yl, sw);
    _rrect(c, 48, 70, 14, 28, 5, l.shade, stroke: sw);
    _rrect(c, 138, 70, 14, 28, 5, l.shade, stroke: sw);
    _rrect(c, 58, 38, 84, 84, 28, l.skin, stroke: sw);
    _rrect(c, 66, 56, 68, 58, 20, _wh);
    c
      ..drawCircle(const Offset(72, 96), 6, _fill(_cheek))
      ..drawCircle(const Offset(128, 96), 6, _fill(_cheek));
    _eyes(c, p, 100, 80, 18, 5.6);
    _mouthOf(c, p, 100, 102, 20);
  }

  void _eyes(
    Canvas c,
    TutorPose p,
    double cx,
    double cy,
    double gap,
    double r,
  ) {
    if (state == TutorPart.cheering) {
      // happy closed eyes, no blink
      final arcs = svgPath(
        'M${cx - gap - r} ${cy + r * .4} q$r ${-r * 1.9} ${r * 2} 0 '
        'M${cx + gap - r} ${cy + r * .4} q$r ${-r * 1.9} ${r * 2} 0',
      );
      c.drawPath(arcs, _stroke(_ink, r * .7, cap: StrokeCap.round));
      return;
    }
    final think = state == TutorPart.thinking;
    final dx = think ? r * .7 : 0.0, dy = think ? -r * .7 : 0.0;
    final rr = think ? r * .85 : r;
    // tuBlink: scaleY about the eyes' own middle
    c
      ..save()
      ..translate(0, cy + dy)
      ..scale(1, p.blink)
      ..translate(0, -(cy + dy));
    for (final x in [cx - gap + dx, cx + gap + dx]) {
      c
        ..drawCircle(Offset(x, cy + dy), rr, _fill(_ink))
        ..drawCircle(
          Offset(x + rr * .35, cy + dy - rr * .35),
          rr * .3,
          _fill(_wh),
        );
    }
    c.restore();
    if (state == TutorPart.encourage || think) {
      // raised, friendly brows
      final brows = svgPath(
        'M${cx - gap - r * 1.5} ${cy - r * 2.3} q${r * 1.5} ${-r * .9} '
        '${r * 3} 0 M${cx + gap - r * 1.5} ${cy - r * 2.3} '
        'q${r * 1.5} ${-r * .9} ${r * 3} 0',
      );
      c.drawPath(brows, _stroke(_ink, r * .5, cap: StrokeCap.round));
    }
  }

  void _mouthOf(Canvas c, TutorPose p, double cx, double cy, double w) {
    void smile(double k) => c.drawPath(
      svgPath(
        'M${cx - w * k} ${cy - w * .06} q${w * k} ${w * .5} ${w * k * 2} 0',
      ),
      _stroke(_ink, w * .17, cap: StrokeCap.round),
    );
    switch (state) {
      case TutorPart.talking:
        // tuTalk: scaleY about the mouth's own middle
        final mid = cy + w * .02;
        c
          ..save()
          ..translate(0, mid)
          ..scale(1, p.talk)
          ..translate(0, -mid);
        _rrect(
          c,
          cx - w * .34,
          cy - w * .26,
          w * .68,
          w * .56,
          w * .24,
          _mouth,
        );
        _rrect(c, cx - w * .2, cy + w * .06, w * .4, w * .2, w * .1, _tongue);
        c.restore();
      case TutorPart.thinking:
        c.drawPath(
          svgPath('M${cx - w * .2} $cy q${w * .25} ${w * .14} ${w * .5} 0'),
          _stroke(_ink, w * .16, cap: StrokeCap.round),
        );
      case TutorPart.cheering:
        c
          ..drawPath(
            svgPath(
              'M${cx - w * .5} ${cy - w * .12} h$w q0 ${w * .62} '
              '${-w * .5} ${w * .62} q${-w * .5} 0 ${-w * .5} ${-w * .62} z',
            ),
            _fill(_mouth),
          )
          ..drawPath(
            svgPath('M${cx - w * .5} ${cy - w * .12} h$w v${w * .14} h${-w} z'),
            _fill(_wh),
          );
      case TutorPart.encourage:
        smile(.6);
      case TutorPart.idle:
        smile(.42);
    }
  }

  // --------------------------------------------------------------- paint

  void _circle(Canvas c, double x, double y, double r, Color fill, double sw) =>
      c
        ..drawCircle(Offset(x, y), r, _fill(fill))
        ..drawCircle(Offset(x, y), r, _stroke(_nv, sw));

  void _rrect(
    Canvas c,
    double x,
    double y,
    double w,
    double h,
    double r,
    Color fill, {
    double? stroke,
  }) {
    final rr = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, w, h),
      Radius.circular(r),
    );
    c.drawRRect(rr, _fill(fill));
    if (stroke != null) c.drawRRect(rr, _stroke(_nv, stroke));
  }

  static Paint _fill(Color c) => Paint()
    ..color = c
    ..isAntiAlias = true;

  static Paint _stroke(
    Color c,
    double w, {
    StrokeCap cap = StrokeCap.butt,
    StrokeJoin join = StrokeJoin.miter,
  }) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = cap
    ..strokeJoin = join
    ..isAntiAlias = true;
}

/// An SVG path's `d` with the commands the prototype's tutor uses: M m L l
/// H h V v Q q Z z (an implicit repeat after M is a line, after l or q
/// another of the same).
Path svgPath(String d) {
  final path = Path();
  final tokens = RegExp(
    r'[MmLlHhVvQqZz]|-?\d*\.?\d+(?:e-?\d+)?',
  ).allMatches(d).map((m) => m[0]!).toList();
  var i = 0, cmd = 'M';
  var x = 0.0, y = 0.0, sx = 0.0, sy = 0.0;
  double n() => double.parse(tokens[i++]);
  while (i < tokens.length) {
    if (RegExp(r'[A-Za-z]').hasMatch(tokens[i])) cmd = tokens[i++];
    switch (cmd) {
      case 'M' || 'm':
        final dx = n(), dy = n();
        x = cmd == 'm' ? x + dx : dx;
        y = cmd == 'm' ? y + dy : dy;
        path.moveTo(x, y);
        sx = x;
        sy = y;
        cmd = cmd == 'm' ? 'l' : 'L';
      case 'L' || 'l':
        final dx = n(), dy = n();
        x = cmd == 'l' ? x + dx : dx;
        y = cmd == 'l' ? y + dy : dy;
        path.lineTo(x, y);
      case 'H' || 'h':
        final v = n();
        x = cmd == 'h' ? x + v : v;
        path.lineTo(x, y);
      case 'V' || 'v':
        final v = n();
        y = cmd == 'v' ? y + v : v;
        path.lineTo(x, y);
      case 'Q' || 'q':
        var cx = n(), cy = n(), ex = n(), ey = n();
        if (cmd == 'q') {
          cx += x;
          cy += y;
          ex += x;
          ey += y;
        }
        path.quadraticBezierTo(cx, cy, ex, ey);
        x = ex;
        y = ey;
      case 'Z' || 'z':
        path.close();
        x = sx;
        y = sy;
    }
  }
  return path;
}
