import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/animation.dart' show Cubic, Curve;
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart' show Matrix4;

/// A small SVG painter for the Orchard path's own markup (orchard_kit):
/// path, circle, ellipse, rect, line, text and g, with transforms,
/// opacity, dashes, linear gradients and a blur, plus the prototype's
/// CSS animations by class (`oSway`, `oFlow`, `oRing`, `oGlint`, `oFlag`,
/// `oBob`, `oPop`, `oFly`, `oFlap`, `oCloud`, `oDrift`, `oDuck`, `oBee`,
/// `oSwing`, `oKite`, `oSpin`, `oFall`), timed as in orchard.html.
///
/// Parsed once; the parts that never move are recorded into pictures, so
/// a frame only redraws what animates.
class MiniSvg {
  MiniSvg._(this._root, this.width, this.height, this._ids);

  factory MiniSvg.parse(String svg) {
    final p = _Parser(svg)..run();
    final vb = (p.svgAttrs['viewBox'] ?? '0 0 100 100')
        .split(RegExp(r'[\s,]+'))
        .map(double.parse)
        .toList();
    return MiniSvg._(p.root, vb[2], vb[3], p.ids);
  }

  final _Node _root;
  final double width;
  final double height;
  final Map<String, _Node> _ids;

  /// The path of the element with [id], in map units.
  Path? pathOf(String id) => _ids[id]?.path;

  /// Paints the map at [t] seconds. With [still] (reduced motion) nothing
  /// moves: every animation shows its resting state. [walked] is how far
  /// along `#owalked` the gold line is drawn.
  void paint(
    Canvas canvas, {
    double t = 0,
    bool still = false,
    double walked = 0,
  }) {
    _root.draw(canvas, _Frame(still ? null : t, walked));
  }
}

class _Frame {
  _Frame(this.t, this.walked);
  final double? t;
  final double walked;
}

// ---------------------------------------------------------------- style

class _Style {
  const _Style({
    this.fill = 'black',
    this.stroke = 'none',
    this.strokeWidth = 1,
    this.cap = StrokeCap.butt,
    this.join = StrokeJoin.miter,
    this.dash,
    this.fontSize = 16,
    this.fontWeight = 400,
    this.anchor = 'start',
    this.swayDelay = 0,
    this.blur,
  });

  final String fill;
  final String stroke;
  final double strokeWidth;
  final StrokeCap cap;
  final StrokeJoin join;
  final List<double>? dash;
  final double fontSize;
  final int fontWeight;
  final String anchor;
  final double swayDelay;
  final double? blur;

  _Style inherit(
    Map<String, String> a,
    Map<String, String> css,
    Map<String, double> blurs,
  ) {
    double? n(String k) => a[k] == null ? null : double.tryParse(a[k]!);
    final dashA = a['stroke-dasharray'];
    final f = a['filter'];
    return _Style(
      fill: a['fill'] ?? fill,
      stroke: a['stroke'] ?? stroke,
      strokeWidth: n('stroke-width') ?? strokeWidth,
      cap: switch (a['stroke-linecap']) {
        'round' => StrokeCap.round,
        'square' => StrokeCap.square,
        null => cap,
        _ => StrokeCap.butt,
      },
      join: switch (a['stroke-linejoin']) {
        'round' => StrokeJoin.round,
        'bevel' => StrokeJoin.bevel,
        null => join,
        _ => StrokeJoin.miter,
      },
      dash: dashA == null
          ? dash
          : dashA
                .split(RegExp(r'[\s,]+'))
                .where((s) => s.isNotEmpty)
                .map(double.parse)
                .toList(),
      fontSize: n('font-size') ?? fontSize,
      fontWeight: int.tryParse(a['font-weight'] ?? '') ?? fontWeight,
      anchor: a['text-anchor'] ?? anchor,
      swayDelay: _secs(css['--d']) ?? swayDelay,
      blur: f == null ? blur : blurs[_urlId(f)],
    );
  }
}

double? _secs(String? s) {
  if (s == null) return null;
  final v = s.trim();
  if (v.endsWith('ms')) {
    return double.tryParse(v.substring(0, v.length - 2))! / 1000;
  }
  if (v.endsWith('s')) return double.tryParse(v.substring(0, v.length - 1));
  return double.tryParse(v);
}

String? _urlId(String v) => RegExp(r'url\(#([^)]+)\)').firstMatch(v)?.group(1);

Color? _color(String v, [double alpha = 1]) {
  v = v.trim();
  if (v == 'none' || v.isEmpty) return null;
  Color c;
  if (v.startsWith('#')) {
    var h = v.substring(1);
    if (h.length == 3) h = h.split('').map((x) => '$x$x').join();
    c = Color(0xFF000000 | int.parse(h, radix: 16));
  } else if (v.startsWith('rgb')) {
    final p = RegExp(
      r'[\d.]+',
    ).allMatches(v).map((m) => double.parse(m.group(0)!)).toList();
    c = Color.fromRGBO(
      p[0].round(),
      p[1].round(),
      p[2].round(),
      p.length > 3 ? p[3] : 1,
    );
  } else if (v == 'white') {
    c = const Color(0xFFFFFFFF);
  } else {
    c = const Color(0xFF000000);
  }
  return c.withValues(alpha: c.a * alpha);
}

// ---------------------------------------------------------------- animation

const _easeInOut = Cubic(0.42, 0, 0.58, 1);
const _easeOut = Cubic(0, 0, 0.58, 1);
const _pop = Cubic(.2, 1.4, .4, 1);

/// One CSS animation: [dur] seconds, [delay], [alternate] (and
/// [reverse]), [once] (fill both), and how a progress 0 to 1 eases.
class _Anim {
  const _Anim(
    this.kind,
    this.dur, {
    this.delay = 0,
    this.alternate = false,
    this.reverse = false,
    this.once = false,
  });
  final String kind;
  final double dur;
  final double delay;
  final bool alternate;
  final bool reverse;
  final bool once;

  /// Progress 0 to 1 at [t] seconds, before easing; null before a delayed
  /// infinite animation starts.
  double phase(double t) {
    final e = t - delay;
    if (once) return (e / dur).clamp(0.0, 1.0);
    if (e < 0 && delay > 0) return 0;
    final n = (e / dur).floor();
    var p = e / dur - n;
    if (alternate && n.isOdd) p = 1 - p;
    if (reverse) p = 1 - p;
    return p;
  }
}

double _ease(Curve c, double p) => c.transform(p.clamp(0.0, 1.0));

/// A keyframe pair 0 -> 50% -> 100% that returns to rest, eased per half.
double _there(double p) =>
    p < .5 ? _ease(_easeInOut, p * 2) : 1 - _ease(_easeInOut, (p - .5) * 2);

// ---------------------------------------------------------------- nodes

enum _Box { origin, fillCenter, fillLeftCenter, fillCenterBottom }

class _Node {
  _Node(this.tag, this.attrs, this.css);

  final String tag;
  final Map<String, String> attrs;
  final Map<String, String> css;
  final List<_Node> children = [];
  String text = '';

  late _Style style;
  List<void Function(Canvas)> xf = const [];
  Matrix4 matrix = Matrix4.identity();
  Path? path;
  _Anim? anim;
  _Box box = _Box.origin;
  Offset origin = Offset.zero;
  double opacity = 1;
  Path? offsetPath;
  _Gradient? fillGrad;
  Rect? _bounds;
  List<Object>? _runs;

  bool get animated =>
      anim != null ||
      attrs['id'] == 'owalked' ||
      children.any((c) => c.animated);

  Rect get bounds => _bounds ??= _measure();

  Rect _measure() {
    Rect? r = path?.getBounds();
    for (final c in children) {
      final b = MatrixUtils.transformRect(c.matrix, c.bounds);
      if (b.isEmpty && b.width == 0 && b.height == 0) continue;
      r = r == null ? b : r.expandToInclude(b);
    }
    return r ?? Rect.zero;
  }

  void draw(Canvas canvas, _Frame f) {
    if (tag == 'defs' ||
        tag == 'linearGradient' ||
        tag == 'stop' ||
        tag == 'filter') {
      return;
    }
    final needsSave = xf.isNotEmpty || anim != null;
    var alpha = opacity;
    if (needsSave) canvas.save();
    for (final op in xf) {
      op(canvas);
    }
    final a = anim;
    if (a != null && f.t != null) alpha *= _apply(canvas, a, f.t!);
    final layer =
        alpha < 1 && (children.isNotEmpty || (_hasFill && _hasStroke));
    if (layer) {
      canvas.saveLayer(
        null,
        Paint()..color = Color.fromRGBO(0, 0, 0, alpha.clamp(0, 1)),
      );
    }
    if (alpha > 0) {
      _self(canvas, f, layer ? 1 : alpha);
      _drawChildren(canvas, f);
    }
    if (layer) canvas.restore();
    if (needsSave) canvas.restore();
  }

  void _drawChildren(Canvas canvas, _Frame f) {
    if (children.isEmpty) return;
    final runs = _runs ??= _makeRuns();
    for (final r in runs) {
      if (r is _Node) {
        r.draw(canvas, f);
      } else {
        canvas.drawPicture((r as _Run).picture);
      }
    }
  }

  List<Object> _makeRuns() {
    final out = <Object>[];
    List<_Node>? cur;
    for (final c in children) {
      if (c.animated) {
        if (cur != null) out.add(_Run(cur));
        cur = null;
        out.add(c);
      } else {
        (cur ??= []).add(c);
      }
    }
    if (cur != null) out.add(_Run(cur));
    return out;
  }

  bool get _hasFill => _color(style.fill) != null || fillGrad != null;
  bool get _hasStroke => _color(style.stroke) != null && style.strokeWidth > 0;

  /// Applies the animation's transform; returns its opacity.
  double _apply(Canvas canvas, _Anim a, double t) {
    final p = a.phase(t);
    final b = bounds;
    final o = switch (box) {
      _Box.origin => origin,
      _Box.fillCenter => b.center,
      _Box.fillLeftCenter => b.centerLeft,
      _Box.fillCenterBottom => b.bottomCenter,
    };
    void around(void Function() f) {
      canvas.translate(o.dx, o.dy);
      f();
      canvas.translate(-o.dx, -o.dy);
    }

    switch (a.kind) {
      case 'sway':
        around(() => canvas.rotate(_there(p) * 1.6 * math.pi / 180));
      case 'ring':
        final e = _ease(_easeOut, p);
        around(() => canvas.scale(1 + .55 * e));
        return .95 * (1 - e);
      case 'glint':
        final e = _there(p);
        around(() => canvas.scale(.3 + .7 * e));
        return e;
      case 'flag':
        final e = _there(p);
        around(() {
          canvas.transform(
            (Matrix4.identity()
                  ..setEntry(1, 0, math.tan(6 * e * math.pi / 180)))
                .storage,
          );
          canvas.scale(1 - .06 * e, 1);
        });
      case 'bob':
        canvas.translate(0, -5 * _there(p));
      case 'pop':
        final e = _ease(_pop, p);
        around(() => canvas.scale(.2 + .8 * e));
        return e.clamp(0.0, 1.0);
      case 'fly':
        final path = offsetPath;
        if (path != null) {
          final m = path.computeMetrics().toList();
          if (m.isNotEmpty) {
            final len = m.fold<double>(0, (s, x) => s + x.length);
            var d = p * len;
            for (final x in m) {
              if (d <= x.length) {
                final tg = x.getTangentForOffset(d);
                if (tg != null) {
                  canvas.translate(tg.position.dx, tg.position.dy);
                }
                break;
              }
              d -= x.length;
            }
          }
        }
      case 'flap':
        around(() => canvas.scale(1 - .55 * _ease(_easeInOut, p), 1));
      case 'cloud':
        canvas.translate(640 * p, 0);
      case 'drift':
        canvas.translate(26 * _ease(_easeInOut, p), 0);
      case 'duck':
        final e = _ease(_easeInOut, p);
        canvas.translate(16 * e, 3 * e);
      case 'bee':
        final e = _ease(_easeInOut, p);
        canvas.translate(7 * e, -6 * e);
      case 'swing':
        final e = _ease(_easeInOut, p);
        around(() => canvas.rotate((-7 + 14 * e) * math.pi / 180));
      case 'kite':
        final e = _ease(_easeInOut, p);
        around(() => canvas.rotate((-5 + 11 * e) * math.pi / 180));
      case 'spin':
        around(() => canvas.rotate(p * 2 * math.pi));
      case 'fall':
        canvas.translate(20 * p, -34 + 98 * p);
        return p < .15
            ? .95 * p / .15
            : p > .85
            ? .95 * (1 - p) / .15
            : .95;
    }
    return 1;
  }

  void _self(Canvas canvas, _Frame f, double alpha) {
    if (tag == 'text') {
      _text(canvas, alpha);
      return;
    }
    var path = this.path;
    if (path == null) return;
    final s = style;
    final blur = s.blur;
    final fillC = _color(s.fill, alpha);
    if (fillGrad != null || fillC != null) {
      final paint = Paint()..isAntiAlias = true;
      if (fillGrad != null) {
        paint.shader = fillGrad!.shader(path.getBounds(), alpha);
      } else {
        paint.color = fillC!;
      }
      if (blur != null) {
        paint.maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
      }
      canvas.drawPath(path, paint);
    }
    final strokeC = _color(s.stroke, alpha);
    if (strokeC != null && s.strokeWidth > 0) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..color = strokeC
        ..strokeWidth = s.strokeWidth
        ..strokeCap = s.cap
        ..strokeJoin = s.join
        ..isAntiAlias = true;
      if (attrs['id'] == 'owalked') {
        if (f.walked <= 0) return;
        path = _extract(path, 0, f.walked);
      } else if (s.dash != null && s.dash!.isNotEmpty) {
        final a = anim;
        final off = a != null && a.kind == 'flow' && f.t != null
            ? -120 * a.phase(f.t!)
            : 0.0;
        path = _dashed(path, s.dash!, off);
      }
      canvas.drawPath(path, paint);
    }
  }

  TextPainter? _tp;

  void _text(Canvas canvas, double alpha) {
    final s = style;
    final tp = _tp ??= TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: s.fontSize,
          fontWeight:
              FontWeight.values[((s.fontWeight / 100).round() - 1).clamp(0, 8)],
          color: _color(s.fill) ?? const Color(0xFF000000),
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final x = double.tryParse(attrs['x'] ?? '0') ?? 0,
        y = double.tryParse(attrs['y'] ?? '0') ?? 0;
    final maxW = double.tryParse(attrs['max-width'] ?? '');
    final k = maxW != null && tp.width > maxW ? maxW / tp.width : 1.0;
    final base = tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    canvas.save();
    canvas.translate(x, y);
    canvas.scale(k);
    final dx = switch (s.anchor) {
      'middle' => -tp.width / 2,
      'end' => -tp.width,
      _ => 0.0,
    };
    if (alpha < 1) {
      canvas.saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, alpha));
    }
    tp.paint(canvas, Offset(dx, -base));
    if (alpha < 1) canvas.restore();
    canvas.restore();
  }
}

class _Run {
  _Run(this.nodes);
  final List<_Node> nodes;
  ui.Picture? _picture;

  ui.Picture get picture {
    final p = _picture;
    if (p != null) return p;
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    final f = _Frame(null, 0);
    for (final n in nodes) {
      n.draw(c, f);
    }
    return _picture = rec.endRecording();
  }
}

Path _extract(Path p, double from, double to) {
  final out = Path();
  var at = 0.0;
  for (final m in p.computeMetrics()) {
    final a = math.max(from, at), b = math.min(to, at + m.length);
    if (b > a) out.addPath(m.extractPath(a - at, b - at), Offset.zero);
    at += m.length;
  }
  return out;
}

Path _dashed(Path p, List<double> dash, double offset) {
  final d = dash.length.isOdd ? [...dash, ...dash] : dash;
  final period = d.fold<double>(0, (s, x) => s + x);
  if (period <= 0) return p;
  final out = Path();
  for (final m in p.computeMetrics()) {
    // start where the offset puts the pattern
    var pos = -(offset % period);
    var i = 0;
    while (pos < m.length) {
      final len = d[i % d.length];
      if (i.isEven) {
        final a = math.max(0.0, pos), b = math.min(m.length, pos + len);
        if (b > a) {
          out.addPath(m.extractPath(a, b), Offset.zero);
        } else if (b == a && len == 0 && a >= 0) {
          // a zero-length dash with a round cap is a dot
          final tg = m.getTangentForOffset(a);
          if (tg != null) {
            out.moveTo(tg.position.dx, tg.position.dy);
            out.lineTo(
              tg.position.dx + tg.vector.dx * .01,
              tg.position.dy + tg.vector.dy * .01,
            );
          }
        }
      }
      pos += len;
      i++;
    }
  }
  return out;
}

class _Gradient {
  _Gradient(this.user, this.x1, this.y1, this.x2, this.y2, this.stops);
  final bool user;
  final double x1, y1, x2, y2;
  final List<(double, Color)> stops;

  Shader shader(Rect b, double alpha) {
    final from = user
        ? Offset(x1, y1)
        : Offset(b.left + x1 * b.width, b.top + y1 * b.height);
    final to = user
        ? Offset(x2, y2)
        : Offset(b.left + x2 * b.width, b.top + y2 * b.height);
    return ui.Gradient.linear(
      from,
      to,
      [for (final s in stops) s.$2.withValues(alpha: s.$2.a * alpha)],
      [for (final s in stops) s.$1],
    );
  }
}

// ---------------------------------------------------------------- parser

class _Parser {
  _Parser(this.src);
  final String src;
  final ids = <String, _Node>{};
  final grads = <String, _Gradient>{};
  final blurs = <String, double>{};
  Map<String, String> svgAttrs = {};
  late _Node root;

  static final _tagRe = RegExp(
    r'<(/?)([\w:-]+)((?:\s+[\w:-]+="[^"]*")*)\s*(/?)>',
  );
  static final _attrRe = RegExp(r'([\w:-]+)="([^"]*)"');

  void run() {
    root = _Node('svg', {}, {});
    final stack = <_Node>[root];
    var last = 0;
    _Node? lastOpen;
    for (final m in _tagRe.allMatches(src)) {
      if (m.start > last && lastOpen != null && lastOpen.tag == 'text') {
        lastOpen.text += _unesc(src.substring(last, m.start));
      }
      last = m.end;
      final close = m.group(1) == '/',
          tag = m.group(2)!,
          selfClose = m.group(4) == '/';
      if (close) {
        if (stack.length > 1) stack.removeLast();
        lastOpen = null;
        continue;
      }
      final attrs = {
        for (final a in _attrRe.allMatches(m.group(3)!))
          a.group(1)!: _unesc(a.group(2)!),
      };
      if (tag == 'svg') {
        svgAttrs = attrs;
        continue;
      }
      final css = <String, String>{};
      final style = attrs['style'];
      if (style != null) {
        for (final decl in _splitCss(style)) {
          final i = decl.indexOf(':');
          if (i > 0) {
            css[decl.substring(0, i).trim()] = decl.substring(i + 1).trim();
          }
        }
      }
      final n = _Node(tag, attrs, css);
      stack.last.children.add(n);
      if (attrs['id'] != null) ids[attrs['id']!] = n;
      if (!selfClose) {
        stack.add(n);
        lastOpen = n;
      } else {
        lastOpen = null;
      }
    }
    _defs(root);
    _compile(root, const _Style(), null, 0);
  }

  static List<String> _splitCss(String s) {
    final out = <String>[];
    var depth = 0, start = 0;
    for (var i = 0; i < s.length; i++) {
      final c = s[i];
      if (c == '(') depth++;
      if (c == ')') depth--;
      if (c == ';' && depth == 0) {
        out.add(s.substring(start, i));
        start = i + 1;
      }
    }
    out.add(s.substring(start));
    return out;
  }

  static String _unesc(String s) => s
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&amp;', '&');

  void _defs(_Node n) {
    for (final c in n.children) {
      if (c.tag == 'linearGradient') {
        double v(String k, double d) {
          final s = c.attrs[k];
          if (s == null) return d;
          return s.endsWith('%')
              ? double.parse(s.substring(0, s.length - 1)) / 100
              : double.parse(s);
        }

        grads[c.attrs['id']!] = _Gradient(
          c.attrs['gradientUnits'] == 'userSpaceOnUse',
          v('x1', 0),
          v('y1', 0),
          v('x2', 1),
          v('y2', 0),
          [
            for (final s in c.children.where((s) => s.tag == 'stop'))
              (
                double.parse(s.attrs['offset'] ?? '0'),
                _color(
                  s.attrs['stop-color'] ?? '#000',
                  double.parse(s.attrs['stop-opacity'] ?? '1'),
                )!,
              ),
          ],
        );
      } else if (c.tag == 'filter') {
        final blur = c.children
            .where((x) => x.tag == 'feGaussianBlur')
            .firstOrNull;
        if (blur != null) {
          blurs[c.attrs['id']!] = double.parse(
            blur.attrs['stdDeviation'] ?? '0',
          );
        }
      } else {
        _defs(c);
      }
    }
  }

  void _compile(_Node n, _Style parent, _Node? up, int index) {
    n.style = parent.inherit(n.attrs, n.css, blurs);
    final a = n.attrs;
    double d(String k, [double z = 0]) => double.tryParse(a[k] ?? '') ?? z;
    n.opacity = d('opacity', 1);
    final fill = a['fill'];
    final gid = fill == null ? null : _urlId(fill);
    if (gid != null) n.fillGrad = grads[gid];
    final tr = a['transform'];
    if (tr != null) {
      final (ops, m) = _transform(tr);
      n.xf = ops;
      n.matrix = m;
    }
    switch (n.tag) {
      case 'path':
        n.path = _pathData(a['d'] ?? '');
      case 'circle':
        n.path = Path()
          ..addOval(
            Rect.fromCircle(center: Offset(d('cx'), d('cy')), radius: d('r')),
          );
      case 'ellipse':
        n.path = Path()
          ..addOval(
            Rect.fromCenter(
              center: Offset(d('cx'), d('cy')),
              width: 2 * d('rx'),
              height: 2 * d('ry'),
            ),
          );
      case 'rect':
        final r = Rect.fromLTWH(d('x'), d('y'), d('width'), d('height'));
        final rx = d('rx', d('ry')), ry = d('ry', rx);
        n.path = Path()
          ..addRRect(
            RRect.fromRectXY(
              r,
              math.min(rx, r.width / 2),
              math.min(ry, r.height / 2),
            ),
          );
      case 'line':
        n.path = Path()
          ..moveTo(d('x1'), d('y1'))
          ..lineTo(d('x2'), d('y2'));
    }
    _animate(n, up, index);
    for (var i = 0; i < n.children.length; i++) {
      _compile(n.children[i], n.style, n, i);
    }
  }

  void _animate(_Node n, _Node? up, int index) {
    final cls = (n.attrs['class'] ?? '')
        .split(' ')
        .where((s) => s.isNotEmpty)
        .toSet();
    final delay = _secs(n.css['animation-delay']) ?? 0;
    final o = n.css['transform-origin'];
    if (o != null) {
      final p = RegExp(
        r'-?[\d.]+',
      ).allMatches(o).map((m) => double.parse(m.group(0)!)).toList();
      if (p.length >= 2) n.origin = Offset(p[0], p[1]);
    }
    _Anim? a;
    if (cls.contains('sway')) {
      a = _Anim(
        'sway',
        6,
        delay: n.css['animation-delay'] != null ? delay : n.style.swayDelay,
      );
    } else if (cls.contains('shimmer')) {
      a = _Anim('flow', cls.contains('s2') ? 4.6 : 3.2, delay: delay);
    } else if (cls.contains('ring')) {
      a = _Anim('ring', 1.8, delay: delay);
      n.box = _Box.fillCenter;
    } else if (cls.contains('glint')) {
      a = _Anim('glint', 2.4, delay: delay);
      n.box = _Box.fillCenter;
    } else if (cls.contains('twinkle')) {
      a = _Anim('glint', 3, delay: delay);
      n.box = _Box.fillCenter;
    } else if (cls.contains('flag')) {
      a = _Anim('flag', 2.2, delay: delay);
      n.box = _Box.fillLeftCenter;
    } else if (cls.contains('bob')) {
      a = _Anim('bob', 1.4, delay: delay);
    } else if (cls.contains('ostop-up')) {
      a = _Anim('pop', .5, delay: delay, once: true);
      n.box = _Box.fillCenterBottom;
    } else if (cls.contains('bfly')) {
      a = _Anim('fly', cls.contains('b2') ? 21 : 16, delay: delay);
      final op = n.css['offset-path'];
      final m = op == null ? null : RegExp(r"path\('([^']*)'\)").firstMatch(op);
      if (m != null) n.offsetPath = _pathData(m.group(1)!);
    } else if (up != null &&
        (up.attrs['class'] ?? '').split(' ').contains('bfly') &&
        n.tag == 'path') {
      a = const _Anim('flap', .35, alternate: true);
      n.box = _Box.fillCenter;
    } else if (cls.contains('cloud')) {
      a = cls.contains('c2')
          ? const _Anim('cloud', 54, delay: -20)
          : const _Anim('cloud', 38);
    } else if (cls.contains('drift')) {
      a = cls.contains('d2')
          ? const _Anim('drift', 15, alternate: true, reverse: true)
          : const _Anim('drift', 11, alternate: true);
    } else if (cls.contains('duck')) {
      a = _Anim('duck', 9, delay: delay, alternate: true);
    } else if (up != null &&
        (up.attrs['class'] ?? '').split(' ').contains('bees') &&
        n.tag == 'circle') {
      a = _Anim('bee', const [2.6, 3.4, 2.1][index % 3], alternate: true);
    } else if (cls.contains('swing')) {
      a = const _Anim('swing', 3.2, alternate: true);
    } else if (cls.contains('kite')) {
      a = const _Anim('kite', 5, alternate: true);
    } else if (cls.contains('spin')) {
      a = const _Anim('spin', 9);
    } else if (cls.contains('fall')) {
      a = _Anim('fall', 7, delay: delay);
    }
    n.anim = a;
  }

  (List<void Function(Canvas)>, Matrix4) _transform(String s) {
    final ops = <void Function(Canvas)>[];
    final m = Matrix4.identity();
    for (final t in RegExp(r'(\w+)\s*\(([^)]*)\)').allMatches(s)) {
      final v = RegExp(
        r'-?[\d.]+(?:e-?\d+)?',
      ).allMatches(t.group(2)!).map((x) => double.parse(x.group(0)!)).toList();
      switch (t.group(1)) {
        case 'translate':
          final x = v[0], y = v.length > 1 ? v[1] : 0.0;
          ops.add((c) => c.translate(x, y));
          m.translateByDouble(x, y, 0, 1);
        case 'scale':
          final x = v[0], y = v.length > 1 ? v[1] : v[0];
          ops.add((c) => c.scale(x, y));
          m.scaleByDouble(x, y, 1, 1);
        case 'rotate':
          final r = v[0] * math.pi / 180;
          if (v.length >= 3) {
            final cx = v[1], cy = v[2];
            ops.add((c) {
              c.translate(cx, cy);
              c.rotate(r);
              c.translate(-cx, -cy);
            });
            m
              ..translateByDouble(cx, cy, 0, 1)
              ..rotateZ(r)
              ..translateByDouble(-cx, -cy, 0, 1);
          } else {
            ops.add((c) => c.rotate(r));
            m.rotateZ(r);
          }
      }
    }
    return (ops, m);
  }
}

/// SVG path data to a [Path].
Path _pathData(String d) {
  final p = Path();
  final tokens = RegExp(
    r'[MmLlHhVvCcSsQqTtAaZz]|[-+]?(?:\d*\.\d+|\d+\.?)(?:[eE][-+]?\d+)?',
  ).allMatches(d).map((m) => m.group(0)!).toList();
  var i = 0;
  var cmd = '';
  double x = 0, y = 0, sx = 0, sy = 0;
  double? cx, cy; // last control point, for S and T
  String prev = '';
  double num() => double.parse(tokens[i++]);
  bool isNum() =>
      i < tokens.length && !RegExp(r'^[A-Za-z]$').hasMatch(tokens[i]);
  while (i < tokens.length) {
    if (!isNum()) {
      cmd = tokens[i++];
    } else if (cmd == 'M') {
      cmd = 'L';
    } else if (cmd == 'm') {
      cmd = 'l';
    }
    final rel = cmd == cmd.toLowerCase();
    final ox = rel ? x : 0.0, oy = rel ? y : 0.0;
    switch (cmd.toUpperCase()) {
      case 'M':
        x = ox + num();
        y = oy + num();
        sx = x;
        sy = y;
        p.moveTo(x, y);
        cx = null;
      case 'L':
        x = ox + num();
        y = oy + num();
        p.lineTo(x, y);
        cx = null;
      case 'H':
        x = ox + num();
        p.lineTo(x, y);
        cx = null;
      case 'V':
        y = (rel ? y : 0) + num();
        p.lineTo(x, y);
        cx = null;
      case 'C':
        final x1 = ox + num(),
            y1 = oy + num(),
            x2 = ox + num(),
            y2 = oy + num();
        x = ox + num();
        y = oy + num();
        p.cubicTo(x1, y1, x2, y2, x, y);
        cx = x2;
        cy = y2;
      case 'S':
        final x1 = (prev == 'C' || prev == 'S') && cx != null ? 2 * x - cx : x;
        final y1 = (prev == 'C' || prev == 'S') && cy != null ? 2 * y - cy : y;
        final x2 = ox + num(), y2 = oy + num();
        x = ox + num();
        y = oy + num();
        p.cubicTo(x1, y1, x2, y2, x, y);
        cx = x2;
        cy = y2;
      case 'Q':
        final x1 = ox + num(), y1 = oy + num();
        x = ox + num();
        y = oy + num();
        p.quadraticBezierTo(x1, y1, x, y);
        cx = x1;
        cy = y1;
      case 'T':
        final x1 = (prev == 'Q' || prev == 'T') && cx != null ? 2 * x - cx : x;
        final y1 = (prev == 'Q' || prev == 'T') && cy != null ? 2 * y - cy : y;
        x = ox + num();
        y = oy + num();
        p.quadraticBezierTo(x1, y1, x, y);
        cx = x1;
        cy = y1;
      case 'A':
        final rx = num(),
            ry = num(),
            rot = num(),
            large = num() != 0,
            sweep = num() != 0;
        x = ox + num();
        y = oy + num();
        p.arcToPoint(
          Offset(x, y),
          radius: Radius.elliptical(rx, ry),
          rotation: rot,
          largeArc: large,
          clockwise: sweep,
        );
        cx = null;
      case 'Z':
        p.close();
        x = sx;
        y = sy;
        cx = null;
    }
    prev = cmd.toUpperCase();
  }
  return p;
}

/// The prototype's walk easing (`easeInOutQuad`).
double easeInOutQuad(double q) =>
    q < .5 ? 2 * q * q : 1 - math.pow(-2 * q + 2, 2) / 2;
