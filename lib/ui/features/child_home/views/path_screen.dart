import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/repositories/rewards_repository.dart';
import '../../../../data/services/sound_effects.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/motion/motion.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/journey_art.dart';
import '../../../core/parts/speak_button.dart';
import '../../../core/theme/tokens.dart';
import 'orchard/mini_svg.dart';
import 'orchard/orchard_kit.dart';
import 'play_icon_button.dart';

/// The trail drawn as a path (JRN-03, REW-04): the prototype's endless
/// Orchard path (K2, 16 Nov). One drawn country edge to edge, a land per
/// stop (orchard_kit), from the server's `trail.lands`: the stops behind
/// the child (explored, or with a medal when earned), the child's look
/// standing at their stop, the next stop clear, and then fog with one
/// glimpse of the next land in it. No other land, and never a number
/// about the child (REW-03). It scrolls, so nothing clips (NFR-04).
///
/// When the child has moved on since they last looked, their look walks
/// up the path from the stop before (500 ms wait, 2.2 s, hopping) and the
/// gold line follows; then it bobs where it stands. Tap a stop to hear
/// its name. Reduced motion: the still map.
class PathScreen extends StatefulWidget {
  const PathScreen({
    super.key,
    required this.lands,
    required this.lookId,
    this.world = 'detective',
    this.childName,
  });

  final List<PathLand> lands;
  final String lookId;
  final String world;

  /// For the title's second line ("Aarav's trail"); null says "My trail".
  final String? childName;

  /// The stop each land last showed the child at, so the walk plays once
  /// per move (the prototype's `S.oseen`).
  static final seen = <String, String>{};

  /// How many cases bloom the child's land before the stretch is done. The
  /// server doesn't say yet, so the prototype's resting value.
  static const bloom = 2;

  @override
  State<PathScreen> createState() => _PathScreenState();
}

/// The walk's timing (the prototype's K2 `after`).
const walkDelay = Duration(milliseconds: 500);
const walkDuration = Duration(milliseconds: 2200);

class _PathScreenState extends State<PathScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  final _t = ValueNotifier<double>(0);
  final _scroll = ScrollController();
  int _back = 0;
  bool _lookBack = false;
  bool _snapped = false;

  // the drawn stretch, rebuilt when the child looks back
  late _Stretch _s;
  late bool _fresh;

  @override
  void initState() {
    super.initState();
    _s = _Stretch.of(widget.lands, 0);
    final land = _s.landId;
    final hereId = _s.hereStopId;
    _fresh = PathScreen.seen[land] != hereId && _s.j > 0;
    if (hereId != null) PathScreen.seen[land] = hereId;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _s.build(AppLocalizations.of(context)!);
    final still = calmMotion(context);
    if (still) {
      _fresh = false;
      if (_ticker.isActive) _ticker.stop();
    } else if (!_ticker.isActive) {
      _ticker.start();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _jump());
  }

  void _tick(Duration d) {
    _t.value = d.inMicroseconds / 1e6;
    if (_fresh && !_snapped && d >= walkDelay + walkDuration) {
      _snapped = true;
      AuraSound.snap();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _t.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// The child's stop a little above the middle; after Look back, the
  /// older lands.
  void _jump() {
    if (!mounted || !_scroll.hasClients) return;
    final pos = _scroll.position;
    final k = pos.viewportDimension > 0 ? context.size!.width / opW : 1.0;
    final view = pos.viewportDimension;
    final st = _s;
    final y = _lookBack
        ? pos.maxScrollExtent +
              view -
              math.min(4, st.here - 3 - st.lo) * opSTEP * k -
              view * 1.1
        : st.scene!.geom.P[st.j][1] * k - view * .56;
    _lookBack = false;
    _scroll.jumpTo(y.clamp(0, pos.maxScrollExtent));
  }

  void _onLookBack() {
    setState(() {
      _back += 4;
      _lookBack = true;
      _fresh = false;
      _s = _Stretch.of(widget.lands, _back)
        ..build(AppLocalizations.of(context)!);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _jump());
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final still = calmMotion(context);
    final pad = MediaQuery.paddingOf(context);
    final s = _s;
    final scene = s.scene;
    final say = ReadAloud.maybeOf(context)?.say;
    return Scaffold(
      backgroundColor: const Color(0xFFB6E98F),
      body: Stack(
        children: [
          if (scene != null)
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, box) {
                  final k = box.maxWidth / opW;
                  return SingleChildScrollView(
                    key: const Key('path'),
                    controller: _scroll,
                    child: SizedBox(
                      width: box.maxWidth,
                      height: scene.height * k,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: ExcludeSemantics(
                              child: CustomPaint(
                                key: const Key('orchard'),
                                painter: _OrchardPainter(
                                  s.svg!,
                                  _t,
                                  still,
                                  s,
                                  _fresh,
                                ),
                              ),
                            ),
                          ),
                          // the stops: tap to hear the name
                          for (var j = 0; j < s.stops.length; j++)
                            Positioned(
                              left: (scene.geom.P[j][0] - 50) * k,
                              top: (scene.geom.P[j][1] - 30) * k,
                              width: 100 * k,
                              height: 60 * k,
                              child: Semantics(
                                button: true,
                                label: [
                                  s.stops[j].name,
                                  ?s.tag(l, j),
                                ].join(', '),
                                excludeSemantics: true,
                                child: GestureDetector(
                                  key: Key('stop$j'),
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    AuraHaptics.tap();
                                    say?.call('${s.stops[j].name}.');
                                  },
                                ),
                              ),
                            ),
                          // the fog and the next land's glimpse: nothing named
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 0,
                            height:
                                math.max(46.0, scene.geom.P.last[1] - 118) * k,
                            child: Semantics(
                              label: l.kidTrailMist,
                              child: const SizedBox.expand(),
                            ),
                          ),
                          if (s.lo > 0)
                            Positioned(
                              left: (_lookBackX(scene) - 78) * k,
                              top: (scene.height - 112) * k,
                              width: 156 * k,
                              height: 44 * k,
                              child: Semantics(
                                button: true,
                                label: l.kidTrailLookBack,
                                excludeSemantics: true,
                                child: GestureDetector(
                                  key: const Key('lookBack'),
                                  behavior: HitTestBehavior.opaque,
                                  onTap: _onLookBack,
                                ),
                              ),
                            ),
                          _Walker(
                            stretch: s,
                            t: _t,
                            k: k,
                            fresh: _fresh,
                            still: still,
                            lookId: widget.lookId,
                            world: widget.world,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          // the title over the top of the map
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: _Veil(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xC70F2A73),
                    Color(0x800F2A73),
                    Color(0x000F2A73),
                  ],
                  stops: [0, .55, 1],
                ),
              ),
              padding: EdgeInsets.fromLTRB(16, pad.top + 6, 16, 26),
              child: Row(
                children: [
                  PlayIconButton(
                    icon: Icons.home_rounded,
                    tooltip: l.kidHome,
                    onPressed: () => context.go(Paths.home),
                  ),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            s.landName,
                            textAlign: TextAlign.center,
                            style: _title,
                          ),
                          Text(
                            widget.childName == null ||
                                    widget.childName!.isEmpty
                                ? l.kidMyTrail
                                : l.kidTrailOf(widget.childName!),
                            textAlign: TextAlign.center,
                            style: _sub,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 56,
                    child: SpeakButton(
                      text: [
                        s.landName,
                        for (var j = 0; j < s.stops.length; j++)
                          if (s.stops[j].state == 'here')
                            '${l.kidYouAreHere}: ${s.stops[j].name}',
                      ].join('. '),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Keep going, over the bottom of the map
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _Veil(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Color(0x990F2A73),
                    Color(0x470F2A73),
                    Color(0x000F2A73),
                  ],
                  stops: [0, .6, 1],
                ),
              ),
              padding: EdgeInsets.fromLTRB(16, 44, 16, 22 + pad.bottom),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: SizedBox(
                    width: double.infinity,
                    child: AuraButton(
                      label: l.keepGoing,
                      leading: const Icon(
                        Icons.play_arrow_rounded,
                        size: 25.6,
                        color: AuraColors.buttonYellowText,
                      ),
                      onPressed: () => context.go(Paths.lessonNext),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static double _lookBackX(OrchardScene s) =>
      math.max(84.0, math.min(opW - 84, s.geom.P[0][0]));

  static const _shadow = [
    Shadow(color: Color(0x8C0F2A73), offset: Offset(0, 2)),
  ];
  static final _title = AuraText.playTitle.copyWith(
    fontSize: 26,
    fontWeight: FontWeight.w900,
    color: AuraColors.white,
    height: 1.1,
    shadows: _shadow,
  );
  static final _sub = AuraText.playTitle.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w800,
    color: AuraColors.white.withValues(alpha: .95),
    height: 1.1,
    shadows: _shadow,
  );
}

/// The stretch of the trail on the map: from three stops behind the child
/// (more after Look back) to the next stop.
class _Stretch {
  _Stretch._(this.landId, this.landName, this.all, this.lo, this.here, this.hi);

  factory _Stretch.of(List<PathLand> lands, int back) {
    final land =
        lands.where((x) => x.current).firstOrNull ??
        lands.where((x) => !x.teaser).firstOrNull;
    final all = land?.stops ?? const <PathStop>[];
    var here = all.indexWhere((s) => s.state == 'current');
    if (here < 0) {
      // no current stop: stand at the last one walked
      here = all.lastIndexWhere(
        (s) => s.state == 'earned' || s.state == 'explored',
      );
      if (here < 0) here = 0;
    }
    final hi = here + 1 < all.length && all[here + 1].state != 'mist'
        ? here + 1
        : here;
    final lo = math.max(0, here - 3 - back);
    return _Stretch._(
      land?.landId ?? '',
      land?.name ?? '',
      all,
      lo,
      here,
      all.isEmpty ? -1 : hi,
    );
  }

  final String landId;
  final String landName;
  final List<PathStop> all;
  final int lo;
  final int here;
  final int hi;

  int get j => here - lo;
  String? get hereStopId => here < all.length ? all[here].stopId : null;

  List<OrchardStop> stops = const [];
  OrchardScene? scene;
  MiniSvg? svg;

  String? tag(AppLocalizations l, int j) => switch (stops[j].state) {
    'earned' => l.kidTrailEarned,
    'explored' => l.kidTrailExplored,
    'here' => l.kidYouAreHere,
    'next' => l.kidNextStop,
    _ => null,
  };

  void build(AppLocalizations l) {
    if (scene != null || hi < lo) return;
    stops = [
      for (var i = lo; i <= hi; i++)
        OrchardStop(all[i].name, switch (all[i].state) {
          'current' => 'here',
          'earned' => 'earned',
          'explored' => 'explored',
          _ => i < here ? 'explored' : 'next',
        }),
    ];
    scene = orchardSVG(
      lo: lo,
      here: here,
      stops: stops,
      bloom: PathScreen.bloom,
      words: OrchardWords(
        explored: l.kidTrailExplored,
        here: l.kidYouAreHere,
        next: l.kidNextStop,
        lookBack: l.kidTrailLookBack,
      ),
    );
    svg = MiniSvg.parse(scene!.svg);
    final path = svg!.pathOf('opath');
    if (path != null) {
      final m = path.computeMetrics().first;
      double near(List<double> p) {
        var best = 0.0, bd = 1e18;
        for (double d = 0; d <= m.length; d += 3) {
          final q = m.getTangentForOffset(d)!.position;
          final dd =
              (q.dx - p[0]) * (q.dx - p[0]) + (q.dy - p[1]) * (q.dy - p[1]);
          if (dd < bd) {
            bd = dd;
            best = d;
          }
        }
        return best;
      }

      metric = m;
      l1 = near(scene!.geom.P[j]);
      l0 = near(scene!.geom.P[math.max(0, j - 1)]);
    }
  }

  PathMetric? metric;
  double l0 = 0;
  double l1 = 0;

  /// Where the walker is at [t] seconds: its length along the path and
  /// its hop; with [fresh] it walks from the stop before.
  ({double l, double hop}) walkAt(double t, {required bool fresh}) {
    if (!fresh) return (l: l1, hop: 0);
    final q =
        ((t * 1000 - walkDelay.inMilliseconds) / walkDuration.inMilliseconds)
            .clamp(0.0, 1.0);
    final e = easeInOutQuad(q);
    return (l: l0 + (l1 - l0) * e, hop: (math.sin(q * math.pi * 7)).abs() * 7);
  }
}

class _OrchardPainter extends CustomPainter {
  _OrchardPainter(this.svg, this.t, this.still, this.s, this.fresh)
    : super(repaint: t);

  final MiniSvg svg;
  final ValueNotifier<double> t;
  final bool still;
  final _Stretch s;
  final bool fresh;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / svg.width;
    canvas.save();
    canvas.scale(k);
    final w = s.walkAt(still ? 1e9 : t.value, fresh: fresh && !still);
    svg.paint(canvas, t: t.value, still: still, walked: w.l);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_OrchardPainter old) =>
      old.svg != svg || old.still != still || old.fresh != fresh;
}

/// The child's look on the path (the prototype's `#owalker`): a shadow,
/// a navy pin with their face, walking, then bobbing (`oBob` 2.2 s).
class _Walker extends StatelessWidget {
  const _Walker({
    required this.stretch,
    required this.t,
    required this.k,
    required this.fresh,
    required this.still,
    required this.lookId,
    required this.world,
  });

  final _Stretch stretch;
  final ValueNotifier<double> t;
  final double k;
  final bool fresh;
  final bool still;
  final String lookId;
  final String world;

  @override
  Widget build(BuildContext context) {
    final m = stretch.metric;
    if (m == null) return const SizedBox.shrink();
    final face = ClipOval(
      child: SizedBox.square(
        dimension: 54,
        child: FittedBox(
          fit: BoxFit.cover,
          child: LookPortrait(
            lookId: lookId,
            world: world,
            size: 54,
            framed: false,
          ),
        ),
      ),
    );
    final pin = SizedBox(
      width: 64,
      height: 77,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          const Positioned.fill(child: CustomPaint(painter: _PinPainter())),
          Positioned(top: 5, child: face),
        ],
      ),
    );
    return ValueListenableBuilder<double>(
      valueListenable: t,
      child: pin,
      builder: (context, time, pin) {
        final w = stretch.walkAt(still ? 1e9 : time, fresh: fresh && !still);
        final p = m.getTangentForOffset(w.l)!.position;
        final walking =
            fresh &&
            !still &&
            time * 1000 < (walkDelay + walkDuration).inMilliseconds;
        // idle: the pin bobs 5 px every 2.2 s, from the end of the walk
        final idleT = fresh
            ? time - (walkDelay + walkDuration).inMicroseconds / 1e6
            : time;
        final bob = still || walking ? 0.0 : 5 * halfway((idleT % 2.2) / 2.2);
        // the pin's centre stands 52 above the path, plus its hop
        final cx = p.dx, cy = p.dy - 52 - w.hop;
        return Positioned(
          key: const Key('walker'),
          left: (cx - 32) * k,
          top: (cy - 32) * k,
          child: IgnorePointer(
            child: Transform.scale(
              scale: k,
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 64,
                height: 77,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // the shadow stays on the ground
                    Positioned(
                      left: 10,
                      top: 59,
                      child: Container(
                        width: 44,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: Color(0x470F2A73),
                          borderRadius: BorderRadius.all(
                            Radius.elliptical(22, 7),
                          ),
                        ),
                      ),
                    ),
                    Transform.translate(offset: Offset(0, -bob), child: pin),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The walker's pin: a navy ring r32 with a white face r29 and a point
/// below (`M-9 24 l9 13 l9 -13 z`), drawn about (32, 32).
class _PinPainter extends CustomPainter {
  const _PinPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const navy = Color(0xFF0F2A73);
    final c = const Offset(32, 32);
    final p = Paint()..color = navy;
    canvas.drawPath(
      Path()
        ..moveTo(c.dx - 9, c.dy + 24)
        ..lineTo(c.dx, c.dy + 37)
        ..lineTo(c.dx + 9, c.dy + 24)
        ..close(),
      p,
    );
    canvas.drawCircle(c, 32, p);
    canvas.drawCircle(c, 29, Paint()..color = const Color(0xFFFFFFFF));
  }

  @override
  bool shouldRepaint(_PinPainter old) => false;
}

/// The navy shade behind the title and the button: taps go through it to
/// the map (the prototype's `pointer-events:none`), only its [child] takes
/// them.
class _Veil extends StatelessWidget {
  const _Veil({
    required this.decoration,
    required this.padding,
    required this.child,
  });

  final Decoration decoration;
  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: IgnorePointer(child: DecoratedBox(decoration: decoration)),
      ),
      Padding(padding: padding, child: child),
    ],
  );
}
