import 'dart:async';

import 'package:flutter/material.dart';

import '../../../data/services/sound_effects.dart';

import '../parts/aura_button.dart';
import '../parts/ribbon.dart';
import '../theme/tokens.dart';
import 'celebration_fx.dart';
import 'confetti.dart';
import 'motion.dart';
import 'play_backdrop.dart';
import '../parts/max_width.dart';

/// One celebration to play (rewards/rules.yaml `celebrations`, REW-16):
/// its moment id, the version to play, and what it shows.
class CelebrationSpec {
  const CelebrationSpec({
    required this.moment,
    required this.variant,
    required this.title,
    required this.art,
    required this.maxDuration,
    this.subtitle,
    this.skippable = false,
    this.badgeId,
    this.queued = false,
    this.problemId,
    this.side,
    this.ribbon,
    this.heading,
    this.line,
    this.tutor,
    this.walker,
    this.layout,
    this.holdFor,
  });

  final String moment;
  final int variant;
  final String title;
  final String? subtitle;
  final Widget art;

  /// A picture beside the art: the child's look beside the session badge
  /// (AVT-02).
  final Widget? side;

  /// The yellow ribbon over the art ("A new medal!", Habit, LandTrophy).
  final String? ribbon;

  /// A plain heading at the top (Y3's "Today's badge").
  final String? heading;

  /// A last line under the title and subtitle (Y3's AI reminder, a habit's
  /// line, "Your trail goes on").
  final String? line;

  /// The tutor cheering beside the badge (Y3, Habit, LandTrophy).
  final Widget? tutor;

  /// The child's look walking the little path to the next stop (LevelUp).
  final Widget? walker;

  /// Which prototype screen draws it, when not its [moment]'s own: a last
  /// stop with its land is a `stop_badge` moment drawn as `land_badge`.
  final String? layout;

  /// rules.yaml `celebrations.moments.<moment>.max_ms`: it ends by itself
  /// by then.
  final Duration maxDuration;

  /// The child has seen this moment before: a tap skips it (`tap_to_skip:
  /// after_first_view`).
  final bool skippable;

  /// A moment of progress (a stop, a peak, a land, 24 Nov): it stays, not
  /// ending at [maxDuration], until the child taps the button with this
  /// label, as "Ready for a new case?" waits, so they see how far they
  /// came. Null: it ends by itself.
  final String? holdFor;

  /// The badge it shows, logged as `badge_shown` (REW-11).
  final String? badgeId;
  final bool queued;
  final String? problemId;
}

/// How one celebration ended: played [ms], [skipped] by a tap, and still
/// for reduced motion.
typedef CelebrationResult = ({int ms, bool skipped, bool reducedMotion});

/// Plays [spec] full screen on the play background: the art pops in (a
/// still picture and its words with reduced motion), then it ends by
/// itself within its length, or on a tap once the child has seen it
/// before. Laid out as the prototype draws each moment (Y3, LevelUp,
/// Habit, LandTrophy, Streak, First Case into the cabinet). Never red
/// (NFR-03); nothing flashes.
/// Never shown during a step: the screens that use it come after one.
class CelebrationView extends StatefulWidget {
  const CelebrationView({super.key, required this.spec, required this.onDone});

  final CelebrationSpec spec;
  final ValueChanged<CelebrationResult> onDone;

  @override
  State<CelebrationView> createState() => _CelebrationViewState();
}

class _CelebrationViewState extends State<CelebrationView> {
  final _clock = Stopwatch()..start();
  Timer? _end;
  bool _done = false;
  late bool _still;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = calmMotion(context);
    if (_end == null) _sound();
    if (widget.spec.holdFor != null) return;
    _end ??= Timer(widget.spec.maxDuration, () => _finish(skipped: false));
  }

  /// The prototype's sound as the moment opens: `SFX.badge` for a session
  /// or habit badge, `SFX.win` for a medal, a trophy or the streak, and
  /// `SFX.right` as First Case flies to the cabinet.
  void _sound() => switch (widget.spec.layout ?? widget.spec.moment) {
    'session_badge' || 'habit_badge' => AuraSound.badge(),
    'stop_badge' || 'land_badge' || 'streak_moment' => AuraSound.celebrate(),
    'first_badge' => AuraSound.right(),
    _ => null,
  };

  void _finish({required bool skipped}) {
    if (_done) return;
    _done = true;
    _end?.cancel();
    widget.onDone((
      ms: _clock.elapsedMilliseconds,
      skipped: skipped,
      reducedMotion: _still,
    ));
  }

  @override
  void dispose() {
    _end?.cancel();
    super.dispose();
  }

  /// Three versions of the placeholder (rules.yaml: at least three per
  /// world): the rays around the art differ.
  static const _rays = [
    [AuraColors.yellow, AuraColors.badgeGoldLight],
    [AuraColors.badgeBlueLight, AuraColors.white],
    [AuraColors.badgeGold, AuraColors.blueTint],
  ];

  static final _title = AuraText.playTitle.copyWith(color: AuraColors.white);

  Widget _burst(Widget art) => _still ? art : Burst(child: art);

  /// The art with the tutor cheering at its lower right, the prototype's
  /// `position:relative` box ([box], the tutor [off] past its corner).
  Widget _withTutor(Widget art, Size box, Offset off, {double left = 0}) {
    final s = widget.spec;
    return SizedBox.fromSize(
      size: box,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(left: left, top: 0, child: _burst(art)),
          if (s.tutor != null)
            Positioned(right: off.dx, bottom: off.dy, child: s.tutor!),
        ],
      ),
    );
  }

  Text _words(String text, TextStyle style) =>
      Text(text, textAlign: TextAlign.center, style: style);

  /// The moment's own screen, as the prototype draws it; null for one it
  /// doesn't (the plain placeholder).
  (List<Widget>, double gap, List<Widget> fx)? _layout() {
    final s = widget.spec;
    final play = AuraText.play;
    final sub = s.subtitle;
    final line = s.line;
    switch (s.layout ?? s.moment) {
      // Y3: "Today's badge", the badge with the tutor beside it, its name,
      // the case, and the tutor's AI reminder; the version's effect 500 ms in
      case 'session_badge':
        return (
          [
            _withTutor(s.art, const Size(230, 216), const Offset(-34, -22)),
            const SizedBox(height: 8),
            _words(s.title, _title),
            if (sub != null)
              Opacity(
                opacity: 0.92,
                child: _words(sub, play.copyWith(fontSize: 20)),
              ),
            if (line != null)
              MaxWidth(
                maxWidth: 300,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Opacity(
                    opacity: 0.9,
                    child: _words(line, play.copyWith(fontSize: 17)),
                  ),
                ),
              ),
          ],
          14,
          [
            CelebrationFx(
              kind: CelebrationFx.badgeVersion(s.variant),
              length: const Duration(milliseconds: 1500),
              delay: const Duration(milliseconds: 500),
            ),
          ],
        );
      // LevelUp, the peak moment (Figma section 15): "You reached the
      // peak!" (the heading, at the top), the land's medal on its peak,
      // the land's name, and the look walking on along the path into the
      // next land; confetti at once
      case 'stop_badge':
        return (
          [
            if (s.ribbon != null) Ribbon(text: s.ribbon!),
            _burst(s.art),
            _words(s.title, _title.copyWith(fontSize: 28, height: 1.1)),
            if (sub != null) _words(sub, play.copyWith(fontSize: 20)),
            if (s.walker != null) LevelPath(walker: s.walker!),
            if (line != null)
              MaxWidth(maxWidth: 290, child: _words(line, play)),
          ],
          12,
          const [Confetti(count: 80)],
        );
      // Habit: "A new badge!", the hexagon with the tutor, its name and line;
      // confetti 400 ms in
      case 'habit_badge':
        return (
          [
            if (s.ribbon != null) Ribbon(text: s.ribbon!),
            _withTutor(s.art, const Size(250, 216), const Offset(-22, -18)),
            const SizedBox(height: 10),
            _words(s.title, _title),
            if (line != null)
              MaxWidth(maxWidth: 290, child: _words(line, play)),
          ],
          12,
          const [Confetti(count: 90, delay: Duration(milliseconds: 400))],
        );
      // LandTrophy (big): "A land trophy!", the cup with the tutor, the
      // land's name, "Every stop, all yours."; fireworks, then stars at 2.6 s
      case 'land_badge':
        return (
          [
            if (s.ribbon != null) Ribbon(text: s.ribbon!),
            _withTutor(
              s.art,
              const Size(250, 230),
              const Offset(-26, -12),
              left: 14,
            ),
            const SizedBox(height: 6),
            _words(s.title, _title.copyWith(height: 1.1)),
            if (sub != null) _words(sub, play.copyWith(fontSize: 20)),
            if (line != null)
              MaxWidth(
                maxWidth: 290,
                child: _words(line, play.copyWith(fontSize: 20)),
              ),
          ],
          10,
          const [
            CelebrationFx(
              kind: FxKind.fireworks,
              length: Duration(milliseconds: 3200),
            ),
            CelebrationFx(
              kind: FxKind.stars,
              length: Duration(milliseconds: 1500),
              delay: Duration(milliseconds: 2600),
              origin: Offset(0.5, 0.3),
            ),
          ],
        );
      // Streak: the star bursts in, "You came back!", one kind line
      case 'streak_moment':
        return (
          [
            _burst(s.art),
            if (s.ribbon != null) Ribbon(text: s.ribbon!),
            _words(
              s.title,
              s.ribbon == null ? _title : play.copyWith(fontSize: 22),
            ),
            if (sub != null) _words(sub, play.copyWith(fontSize: 22)),
          ],
          20,
          const [],
        );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.spec;
    final Widget body;
    if ((s.layout ?? s.moment) == 'first_badge') {
      body = _IntoTheCabinet(spec: s, still: _still);
    } else if (_layout() case (final content, final gap, final fx)) {
      body = PlayBackdrop(
        child: Stack(
          fit: StackFit.expand,
          children: [
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: Column(
                      children: [
                        if (s.heading != null)
                          _words(s.heading!, _title.copyWith(fontSize: 24)),
                        Expanded(
                          child: Center(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                spacing: gap,
                                children: content,
                              ),
                            ),
                          ),
                        ),
                        // where the prototype's button sits: the art stays
                        // where it stands there; a moment that waits for
                        // the child has it
                        if (s.holdFor case final label?)
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 12),
                            child: FadeIn(
                              child: AuraButton(
                                key: const Key('celebrationGo'),
                                label: label,
                                onPressed: () => _finish(skipped: false),
                              ),
                            ),
                          )
                        else
                          const SizedBox(height: 76),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (!_still) ...fx,
          ],
        ),
      );
    } else {
      body = _plain(s);
    }
    return Semantics(
      liveRegion: true,
      label: [?s.heading, s.title, ?s.subtitle, ?s.line].join('. '),
      button: s.skippable && s.holdFor == null,
      // a moment that waits keeps its button for screen readers
      excludeSemantics: s.holdFor == null,
      child: GestureDetector(
        key: const Key('celebration'),
        behavior: HitTestBehavior.opaque,
        onTap: s.skippable && s.holdFor == null
            ? () => _finish(skipped: true)
            : null,
        child: Material(color: AuraColors.blue, child: body),
      ),
    );
  }

  /// A moment the prototype doesn't draw: the art in its rays, the title
  /// and the subtitle.
  Widget _plain(CelebrationSpec s) {
    final rays = _rays[(s.variant - 1) % _rays.length];
    Widget art = Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [rays[0], rays[1].withValues(alpha: 0)],
        ),
      ),
      child: s.art,
    );
    if (!_still) {
      art = Pop(duration: const Duration(milliseconds: 500), child: art);
    }
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 16,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 12,
                children: [?s.side, art],
              ),
              _words(s.title, _title),
              if (s.subtitle != null) _words(s.subtitle!, AuraText.play),
            ],
          ),
        ),
      ),
    );
  }
}

/// The prototype's `firstFly` (2.5 s, one version): on the moment's blue,
/// First Case pops in over the cheering tutor and "Into your badges!", then
/// drops down into the My badges shelf at the bottom, so the child knows
/// where it lives (`toCab` 2.3 s from 0.1 s: in by 18 %, held to 48 %, then
/// down 470 pt to 22 %).
class _IntoTheCabinet extends StatelessWidget {
  const _IntoTheCabinet({required this.spec, required this.still});

  final CelebrationSpec spec;
  final bool still;

  static const _fly = Cubic(0.5, 0, 0.6, 1);

  @override
  Widget build(BuildContext context) {
    final l = spec;
    Widget badge = l.art;
    if (!still) {
      badge = Entrance(
        duration: const Duration(milliseconds: 2400),
        child: badge,
        builder: (context, t, child) {
          // 0.1 s of nothing, then 2.3 s of toCab
          final u = ((t * 2400 - 100) / 2300).clamp(0.0, 1.0);
          if (t * 2400 < 100) return Opacity(opacity: 0, child: child);
          final e = _fly.transform(u);
          final (scale, dy, opacity) = u <= 0.18
              ? (
                  0.4 + 0.6 * e / _fly.transform(0.18),
                  0.0,
                  e / _fly.transform(0.18),
                )
              : u <= 0.48
              ? (1.0, 0.0, 1.0)
              : () {
                  final k = (u - 0.48) / 0.52;
                  return (1 - 0.78 * k, 470 * k, 1 - 0.1 * k);
                }();
          return Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, dy),
              child: Transform.scale(scale: scale, child: child),
            ),
          );
        },
      );
    }
    Widget words = Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 14,
      children: [
        badge,
        ?l.tutor,
        Ribbon(text: l.title),
      ],
    );
    if (!still) {
      // `.moin`: oPop 0.45 s cubic-bezier(.2,1.4,.4,1) from 0.2
      words = Entrance(
        duration: const Duration(milliseconds: 450),
        child: words,
        builder: (context, t, child) => Opacity(
          opacity: t,
          child: Transform.scale(
            scale: 0.2 + 0.8 * const Cubic(0.2, 1.4, 0.4, 1).transform(t),
            child: child,
          ),
        ),
      );
    }
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.2),
          radius: 0.75,
          colors: [Color(0xFF4B7DFF), Color(0xFF1D4FD6)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(child: words),
          Positioned(
            left: 0,
            right: 0,
            bottom: 54,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AuraColors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AuraColors.navy, width: 3),
                  boxShadow: const [
                    BoxShadow(color: AuraColors.navy, offset: Offset(0, 4)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: [
                    const Icon(
                      Icons.military_tech_rounded,
                      size: 30,
                      color: AuraColors.navy,
                    ),
                    Text(
                      l.subtitle ?? '',
                      style: AuraText.ribbon.copyWith(
                        fontSize: 18,
                        color: AuraColors.navy,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// LevelUp's little path (`.lvpath`, 320 × 132): the stop just passed and
/// the next, the gold line drawing between them while the child's look
/// walks it (`spWalk` and `lvGold`, 2.2 s from 0.7 s, ease-in-out). Still
/// with reduced motion: the look at the next stop, the line drawn.
class LevelPath extends StatelessWidget {
  const LevelPath({super.key, required this.walker});

  final Widget walker;

  static final _road = Path()
    ..moveTo(56, 96)
    ..cubicTo(140, 96, 180, 44, 264, 44);

  /// The walker's own line, 18 above the road.
  static final _walk = Path()
    ..moveTo(56, 78)
    ..cubicTo(140, 78, 180, 26, 264, 26);

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 320,
    height: 132,
    child: Entrance(
      duration: const Duration(milliseconds: 2900),
      builder: (context, t, child) {
        final u = Curves.easeInOut.transform(
          ((t * 2900 - 700) / 2200).clamp(0.0, 1.0),
        );
        final m = _walk.computeMetrics().first;
        final at = m.getTangentForOffset(m.length * u)!.position;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: CustomPaint(painter: _LevelPainter(u))),
            Positioned(left: at.dx - 21, top: at.dy - 21, child: child!),
          ],
        );
      },
      child: Container(
        width: 42,
        height: 42,
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AuraColors.white,
          border: Border.fromBorderSide(
            BorderSide(color: AuraColors.navy, width: 3),
          ),
        ),
        child: ClipOval(child: walker),
      ),
    ),
  );
}

class _LevelPainter extends CustomPainter {
  _LevelPainter(this.u);

  final double u;

  @override
  void paint(Canvas canvas, Size size) {
    Paint line(Color c, double w) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = c
      ..strokeWidth = w;
    final road = LevelPath._road;
    canvas
      ..drawPath(road, line(AuraColors.navy.withValues(alpha: 0.35), 34))
      ..drawPath(road, line(const Color(0xFFF3DCA6), 26));
    if (u > 0) {
      final m = road.computeMetrics().first;
      canvas.drawPath(
        m.extractPath(0, m.length * u),
        line(AuraColors.yellow, 6),
      );
    }
    final from = Rect.fromCenter(
      center: const Offset(56, 98),
      width: 60,
      height: 34,
    );
    final to = Rect.fromCenter(
      center: const Offset(264, 46),
      width: 60,
      height: 34,
    );
    canvas
      ..drawOval(from, Paint()..color = const Color(0xFFFFEFB8))
      ..drawOval(from, line(AuraColors.navy.withValues(alpha: 0.5), 2.5))
      ..drawOval(to, Paint()..color = const Color(0xFFFFE38A))
      ..drawOval(to, line(AuraColors.navy, 3));
    // the little medal left at the stop passed
    canvas
      ..save()
      ..translate(56, 78);
    final ribbon = Path()
      ..moveTo(-6, -16)
      ..lineTo(-2, -6)
      ..lineTo(2, -6)
      ..lineTo(6, -16)
      ..close();
    canvas
      ..drawPath(ribbon, Paint()..color = AuraColors.blue)
      ..drawPath(ribbon, line(AuraColors.navy, 1.5))
      ..drawCircle(Offset.zero, 10, Paint()..color = AuraColors.yellow)
      ..drawCircle(Offset.zero, 10, line(AuraColors.navy, 2.4))
      ..restore();
  }

  @override
  bool shouldRepaint(_LevelPainter old) => old.u != u;
}

/// Plays [moments] one after another, in the order given (rules.yaml
/// `end_of_case_order`, `session_badge.end_of_session_order`), reporting
/// each through [onShown], then shows [child]. Nothing to play: [child]
/// at once.
class CelebrationQueue extends StatefulWidget {
  const CelebrationQueue({
    super.key,
    required this.moments,
    required this.onShown,
    required this.child,
  });

  final List<CelebrationSpec> moments;
  final void Function(CelebrationSpec spec, CelebrationResult result) onShown;
  final Widget child;

  @override
  State<CelebrationQueue> createState() => _CelebrationQueueState();
}

class _CelebrationQueueState extends State<CelebrationQueue> {
  int _at = 0;

  @override
  Widget build(BuildContext context) {
    if (_at >= widget.moments.length) return widget.child;
    final spec = widget.moments[_at];
    return CelebrationView(
      key: ValueKey(_at),
      spec: spec,
      onDone: (r) {
        widget.onShown(spec, r);
        if (mounted) setState(() => _at++);
      },
    );
  }
}
