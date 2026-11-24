import 'dart:async';
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
import 'orchard/stop_names.dart';
import 'play_icon_button.dart';

/// The trail drawn as a path (JRN-03, REW-04), as Figma section 15
/// (17 Nov, "Levels are finite"): one level is one land of five stops,
/// the fifth its peak. From the server's `trail.lands` (a stop per level)
/// the screen draws the whole track so far (23 Nov), from the first
/// level's land up to the child's (orchard_kit): each land behind named
/// at its way in with its peak's medal (or a flag when the child was
/// placed past it), the stops the child has walked in their own land (the
/// server's `stopInLevel`, 0 to 3), the child's look at their stop, the
/// next two stops by name, the stops ahead and the peak with its summit
/// flag; then fog with one glimpse of the next land. After the last
/// level's peak the path ends at the top under open sky and nothing more
/// is promised. Never a level number or count on the child's side
/// (REW-03; Figma's `level_numbers` switch stays off). It scrolls, so
/// nothing clips (NFR-04).
///
/// The walk, as a game moves a piece (24 Nov): only when the child has
/// moved on since this phone last showed them ([seenAt]), one step, from
/// the stop before theirs (from the last stop below the peak when they
/// have just passed a level), the map following it; their first step of
/// all (the first stop to the second) walks even if never seen. Otherwise,
/// whatever came before (a new sign-in, the app opened again), they stand
/// at their stop. The gold line follows; then it bobs where it stands.
/// Tap a stop to hear its name. Reduced motion: the still map.
class PathScreen extends StatefulWidget {
  const PathScreen({
    super.key,
    required this.lands,
    required this.lookId,
    this.world = 'detective',
    this.childName,
    this.seenAt,
    this.onSeen,
  });

  final List<PathLand> lands;
  final String lookId;
  final String world;

  /// For the title's second line ("Aarav's trail"); null says "My trail".
  final String? childName;

  /// The stop of the track ([PathLand.landId]'s) this phone last showed
  /// the child at; null: never, so no walk (but the first step of all).
  final int? seenAt;

  /// The stop the child is shown at now, to keep for next time.
  final void Function(String landId, int stop)? onSeen;

  /// How many cases bloom the child's land before the stretch is done. The
  /// server doesn't say yet, so the prototype's resting value.
  static const bloom = 2;

  @override
  State<PathScreen> createState() => _PathScreenState();
}

/// The walk's timing: a wait before it starts, each stop-to-stop step
/// (shorter when there are many, so a long way stays short), and a pause
/// at each stop on the way.
const walkDelay = Duration(milliseconds: 500);
const stepLongest = Duration(milliseconds: 1500);
const stepShortest = Duration(milliseconds: 650);
const walkLongest = Duration(milliseconds: 7000);
const stopPause = Duration(milliseconds: 250);

class _PathScreenState extends State<PathScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  final _t = ValueNotifier<double>(0);
  final _scroll = ScrollController();

  /// Stops the walk has reached, for each one's snap.
  int _arrived = 0;

  /// The map has moved to rest after the walk.
  bool _settled = false;

  // the drawn track
  late final _Stretch _s = _Stretch.of(widget.lands);
  bool _fresh = false;

  @override
  void initState() {
    super.initState();
    final here = _s.here;
    if (_s.landId.isNotEmpty) widget.onSeen?.call(_s.landId, here);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = calmMotion(context);
    _s.build(AppLocalizations.of(context)!);
    _s.plan(still ? _s.here : widget.seenAt);
    _fresh = !still && _s.walks;
    if (still) {
      if (_ticker.isActive) _ticker.stop();
    } else if (!_ticker.isActive) {
      _ticker.start();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _jump());
  }

  void _tick(Duration d) {
    _t.value = d.inMicroseconds / 1e6;
    if (!_fresh) return;
    final reached = _s.reachedBy(_t.value);
    while (_arrived < reached) {
      _arrived++;
      AuraSound.snap();
    }
    if (_s.walkingAt(_t.value)) {
      _follow();
    } else if (!_settled) {
      // at the stop: the map eases to rest, the next stops' signs clear of
      // the title
      _settled = true;
      if (mounted && _scroll.hasClients) {
        unawaited(
          _scroll.animateTo(
            _restY(),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOut,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _t.dispose();
    _scroll.dispose();
    super.dispose();
  }

  double get _k => context.size!.width / opW;

  /// Where the map scrolls to show the walker at path length [l] a little
  /// below the middle.
  double _yFor(double l) {
    final pos = _scroll.position;
    final p = _s.metric!.getTangentForOffset(l)!.position;
    return (p.dy * _k - pos.viewportDimension * .6).clamp(
      0.0,
      pos.maxScrollExtent,
    );
  }

  /// The map follows the walker.
  void _follow() {
    if (!mounted || !_scroll.hasClients || _s.metric == null) return;
    _scroll.jumpTo(_yFor(_s.walkAt(_t.value).l));
  }

  /// Before a walk: where it starts. Else where the map rests.
  void _jump() {
    if (!mounted || !_scroll.hasClients) return;
    if (_fresh && _s.metric != null) {
      _scroll.jumpTo(_yFor(_s.walkAt(0).l));
      return;
    }
    _scroll.jumpTo(_restY());
  }

  /// The child's stop a little above the middle, with the next stops'
  /// signs clear of the title (they sat under it on most phones); the
  /// child's stop always stays above Keep going.
  double _restY() {
    final pos = _scroll.position;
    final k = pos.viewportDimension > 0 ? _k : 1.0;
    final view = pos.viewportDimension;
    final st = _s;
    final p = st.scene!.geom.P;
    final hereY = p[st.j][1] * k;
    var y = hereY - view * .56;
    // the title's veil, then the next stop's sign above its stop
    final titleBottom = MediaQuery.paddingOf(context).top + 104;
    if (st.j + 1 < p.length) {
      final signTop = (p[st.j + 1][1] - 100) * k;
      if (signTop - y < titleBottom) y = signTop - titleBottom;
    }
    // Keep going and the stop chip along the bottom
    final aboveBar = view - 110;
    if (hereY + 70 * k - y > aboveBar) y = hereY + 70 * k - aboveBar;
    return y.clamp(0, pos.maxScrollExtent);
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
                                painter: _OrchardPainter(s.svg!, _t, still, s),
                              ),
                            ),
                          ),
                          // the stops: tap to hear the name
                          for (var j = 0; j < s.stops.length; j++)
                            if (s.stops[j].name.isNotEmpty)
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
                          if (!s.top)
                            Positioned(
                              left: 0,
                              right: 0,
                              top: 0,
                              height:
                                  math.max(46.0, scene.geom.P.last[1] - 118) *
                                  k,
                              child: Semantics(
                                label: l.kidTrailMist,
                                child: const SizedBox.expand(),
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

/// The track on the map (Figma section 15, 23 Nov): every level so far,
/// each one land of [stopsPerLand] stops, from the first up to the
/// child's. Stop `g` of the whole path is stop `g % stopsPerLand` of
/// level `g ~/ stopsPerLand`.
class _Stretch {
  _Stretch._(
    this.landId,
    this.pathName,
    this.levels,
    this.level,
    this.top,
    this.lo,
    this.here,
    this.hi,
    this.walked,
  );

  factory _Stretch.of(List<PathLand> lands) {
    final land =
        lands.where((x) => x.current).firstOrNull ??
        lands.where((x) => !x.teaser).firstOrNull;
    final levels = land?.stops ?? const <PathStop>[];
    var level = levels.indexWhere((s) => s.state == 'current');
    var top = false;
    if (level < 0) {
      // no current level: past the last one passed, or at the top
      final passed = levels.lastIndexWhere(
        (s) => s.state == 'earned' || s.state == 'explored',
      );
      top = passed >= 0 && passed == levels.length - 1;
      level = passed < 0 ? 0 : (top ? passed : passed + 1);
    }
    final first = level * stopsPerLand;
    // how far into the level the child is, as the server's move-up gate
    // says (0 to 3); the peak only comes by passing the level
    final walked = top
        ? 0
        : (land?.stopInLevel ?? 0).clamp(0, stopsPerLand - 2);
    return _Stretch._(
      land?.landId ?? '',
      land?.name ?? '',
      levels,
      level,
      top,
      // the whole track, from the first level's first stop
      0,
      // on the top once every land is done
      top ? first + stopsPerLand - 1 : first + walked,
      levels.isEmpty ? -1 : first + stopsPerLand - 1,
      walked,
    );
  }

  final String landId;

  /// The whole path's name ("The Orchard").
  final String pathName;
  final List<PathStop> levels;

  /// The child's level: the land drawn.
  final int level;

  /// Every land climbed: the child on the last peak, no fog.
  final bool top;
  final int lo;
  final int here;
  final int hi;

  /// The stops of the child's land already walked (before [here]).
  final int walked;

  /// The title: the child's land ("Orchard Gate").
  String get landName => level < levels.length ? levels[level].name : '';

  int get j => here - lo;
  String? get hereStopId => level < levels.length
      ? '${levels[level].stopId}${top ? ':top' : ''}'
            '${walked > 0 ? ':$walked' : ''}'
      : null;

  List<OrchardStop> stops = const [];
  OrchardScene? scene;
  MiniSvg? svg;

  String? tag(AppLocalizations l, int j) {
    final t = switch (stops[j].state) {
      'earned' || 'peakEarned' => l.kidTrailEarned,
      'explored' || 'peakExplored' => l.kidTrailExplored,
      'here' => l.kidYouAreHere,
      'next' => l.kidNextStop,
      _ => null,
    };
    return t == stops[j].name ? null : t;
  }

  /// Stop [g] of the path, as drawn.
  OrchardStop _stop(AppLocalizations l, int g) {
    final lv = g ~/ stopsPerLand, k = g % stopsPerLand;
    final name = lv < levels.length ? levels[lv].name : '';
    final peak = k == stopsPerLand - 1;
    if (lv < level || (top && !peak)) {
      // a land behind the child: walked, its peak with the land's medal,
      // or a flag where the child was placed past it
      final past = levels[lv].state == 'explored';
      if (peak) {
        return OrchardStop(
          l.kidThePeak,
          past ? 'peakExplored' : 'peakEarned',
          sub: '',
        );
      }
      return k == 0
          ? OrchardStop(name, past ? 'explored' : 'walked', sub: '')
          : const OrchardStop('', 'walked');
    }
    if (top) return OrchardStop(l.kidTheTop, 'here', sub: '');
    // the child's land: the stops walked (footprints), their stop, the
    // next, the stops ahead, the peak. Each stop by its own name (23 Nov,
    // DRAFT names until the content has them, stop_names.dart), so the
    // child's stop and the next differ; a land with none yet keeps its
    // name on the child's stop and "Next stop" alone on the next
    return switch (k) {
      _ when peak => OrchardStop(l.kidThePeak, 'peak', sub: ''),
      _ when k < walked => const OrchardStop('', 'walked'),
      _ when k == walked => OrchardStop(stopNameIn(name, k) ?? name, 'here'),
      _ when k == walked + 1 => switch (stopNameIn(name, k)) {
        final own? => OrchardStop(own, 'next'),
        null => OrchardStop(l.kidNextStop, 'next', sub: ''),
      },
      // the stop after the next by name too (23 Nov); the rest unnamed
      _ when k == walked + 2 => OrchardStop(stopNameIn(name, k) ?? '', 'ahead'),
      _ => const OrchardStop('', 'ahead'),
    };
  }

  void build(AppLocalizations l) {
    if (scene != null || hi < lo) return;
    stops = [for (var g = lo; g <= hi; g++) _stop(l, g)];
    scene = orchardSVG(
      lo: lo,
      here: here,
      stops: stops,
      bloom: PathScreen.bloom,
      landAt: olandInLevel,
      wayIn: wayInBelow,
      top: top,
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
      at = [for (final q in scene!.geom.P) near(q)];
    }
  }

  PathMetric? metric;

  /// Each stop's length along the path.
  List<double> at = const [];

  /// The walk: the path lengths it passes, from where it starts through
  /// each stop on the way to the child's; one length: no walk.
  List<double> _way = const [];
  double _stepS = 0;

  /// Whether there is a walk.
  bool get walks => _way.length > 1;

  /// Plans the walk from stop [from] (null: never seen) to the child's
  /// stop: one step, from the stop before theirs, and only when they have
  /// moved on since [from]; their first step of all (0 to 1) walks even
  /// unseen. A stop after a peak walks from the stop below the peak, over
  /// it. None otherwise: they stand at their stop.
  void plan(int? from) {
    if (metric == null || at.isEmpty) return;
    final seen = from ?? (here == 1 ? 0 : here);
    var start = here - 1;
    if (start % stopsPerLand == stopsPerLand - 1) start--; // over the peak
    if (seen < here && start >= lo) {
      _way = [for (var i = start - lo; i <= j; i++) at[i]];
    } else {
      _way = [at[j]];
    }
    final steps = _way.length - 1;
    _stepS = steps == 0
        ? 0
        : (walkLongest.inMilliseconds / steps).clamp(
                stepShortest.inMilliseconds.toDouble(),
                stepLongest.inMilliseconds.toDouble(),
              ) /
              1000;
  }

  static final double _delayS = walkDelay.inMilliseconds / 1000;
  static final double _pauseS = stopPause.inMilliseconds / 1000;

  /// When the walk ends, in seconds from the screen opening.
  double get walkEnd =>
      _delayS + (_way.length - 1) * (_stepS + _pauseS) - _pauseS;

  bool walkingAt(double t) => walks && t < walkEnd;

  /// How many stops the walk has reached by [t].
  int reachedBy(double t) {
    if (!walks || t < _delayS) return 0;
    return (((t - _delayS) + _pauseS) / (_stepS + _pauseS)).floor().clamp(
      0,
      _way.length - 1,
    );
  }

  /// Where the walker is at [t] seconds: its length along the path and
  /// its hop. Stop to stop, a short pause at each, hopping as it goes.
  ({double l, double hop}) walkAt(double t) {
    if (!walks) return (l: at.isEmpty ? 0 : at[j], hop: 0);
    final s = t - _delayS;
    if (s <= 0) return (l: _way.first, hop: 0);
    final i = (s / (_stepS + _pauseS)).floor();
    if (i >= _way.length - 1) return (l: _way.last, hop: 0);
    final into = s - i * (_stepS + _pauseS);
    if (into >= _stepS) return (l: _way[i + 1], hop: 0);
    final q = into / _stepS;
    final e = easeInOutQuad(q);
    return (
      l: _way[i] + (_way[i + 1] - _way[i]) * e,
      hop: (math.sin(q * math.pi * 4)).abs() * 7,
    );
  }
}

class _OrchardPainter extends CustomPainter {
  _OrchardPainter(this.svg, this.t, this.still, this.s) : super(repaint: t);

  final MiniSvg svg;
  final ValueNotifier<double> t;
  final bool still;
  final _Stretch s;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / svg.width;
    canvas.save();
    canvas.scale(k);
    final w = s.walkAt(still ? 1e9 : t.value);
    svg.paint(canvas, t: t.value, still: still, walked: w.l);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_OrchardPainter old) =>
      old.svg != svg || old.still != still;
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
        final w = stretch.walkAt(still ? 1e9 : time);
        final p = m.getTangentForOffset(w.l)!.position;
        final walking = fresh && !still && stretch.walkingAt(time);
        // idle: the pin bobs 5 px every 2.2 s, from the end of the walk
        final idleT = fresh ? time - stretch.walkEnd : time;
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
