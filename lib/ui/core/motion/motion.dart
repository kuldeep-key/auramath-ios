import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The prototype's motion (v4.1, 4 Nov): its curves, and the small pieces
/// every screen builds with. With the phone's reduce-motion setting on,
/// everything here holds still at its resting state (the prototype's
/// prefers-reduced-motion rule).
abstract final class AuraCurves {
  /// Screens sliding in and out: cubic-bezier(.2,.9,.25,1).
  static const screen = Cubic(0.2, 0.9, 0.25, 1);

  /// A springy overshoot for things that pop or grow: (.34,1.56,.64,1).
  static const spring = Cubic(0.34, 1.56, 0.64, 1);

  /// Sheets and toasts arriving: (.2,1.1,.3,1).
  static const sheet = Cubic(0.2, 1.1, 0.3, 1);

  /// A badge or emoji bursting in: (.2,1.6,.4,1).
  static const burst = Cubic(0.2, 1.6, 0.4, 1);
}

/// The prototype's keyframe lengths, shared so every area times the same
/// moment the same way (`@keyframes` and their `animation:` lines).
abstract final class AuraDurations {
  /// A screen arriving or leaving (`go()`, every transition): 420 ms.
  static const screen = Duration(milliseconds: 420);

  /// `pop` on a board piece (`.gapseg`, `.brace`): 450 ms.
  static const pop = Duration(milliseconds: 450);

  /// `pop` on the tutor, a ribbon or a tile: 500 ms.
  static const popBig = Duration(milliseconds: 500);

  /// `sheetUp`: a sheet arriving, 420 ms ([AuraCurves.sheet]).
  static const sheetUp = Duration(milliseconds: 420);

  /// `sheetDown` and `fadeOut`: a sheet and its scrim leaving, 250 ms.
  static const sheetDown = Duration(milliseconds: 250);

  /// `fade`: a scrim arriving, 250 ms.
  static const fade = Duration(milliseconds: 250);

  /// `toastIn`: 400 ms ([AuraCurves.sheet]).
  static const toastIn = Duration(milliseconds: 400);

  /// A toast leaving: 300 ms, linear, after [toastStays].
  static const toastOut = Duration(milliseconds: 300);
  static const toastStays = Duration(milliseconds: 2600);

  /// `tipIn`: a tip or a tooltip arriving, 400 ms.
  static const tipIn = Duration(milliseconds: 400);

  /// `float`: one drift up and back, 3 s.
  static const float = Duration(seconds: 3);

  /// `twinkle`: 2.4 s, each sparkle 0.3 s after the one before.
  static const twinkle = Duration(milliseconds: 2400);

  /// `glow`: 1.2 s.
  static const glow = Duration(milliseconds: 1200);

  /// `helpPulse`: 1.2 s, three times.
  static const helpPulse = Duration(milliseconds: 1200);

  /// `speakPulse`: the speak button while a line plays, 1 s.
  static const speakPulse = Duration(seconds: 1);

  /// `burst`: 900 ms ([AuraCurves.burst]).
  static const burst = Duration(milliseconds: 900);

  /// `sparkle`: 350 ms each way.
  static const sparkle = Duration(milliseconds: 350);

  /// `wobble`: a wrong piece or answer, 400 ms.
  static const wobble = Duration(milliseconds: 400);

  /// `shake`: a standing button, 600 ms, twice.
  static const shake = Duration(milliseconds: 600);

  /// `wordIn`: each word of a line, 350 ms, [wordStagger] after the last.
  static const wordIn = Duration(milliseconds: 350);
  static const wordStagger = Duration(milliseconds: 45);
}

/// The value at [t] of CSS keyframes `(offset, value)` with [curve] as the
/// `animation-timing-function`: as in CSS, the curve eases each segment
/// between two keyframes, not the whole run.
double cssFrames(
  double t,
  List<(double, double)> frames, [
  Curve curve = Curves.ease,
]) {
  if (t <= frames.first.$1) return frames.first.$2;
  for (var i = 1; i < frames.length; i++) {
    final (o1, v1) = frames[i];
    if (t <= o1) {
      final (o0, v0) = frames[i - 1];
      final local = o1 == o0 ? 1.0 : (t - o0) / (o1 - o0);
      return v0 + (v1 - v0) * curve.transform(local.clamp(0.0, 1.0));
    }
  }
  return frames.last.$2;
}

const _deg = 3.141592653589793 / 180;

/// True when the phone asks for less motion, or [AuraMotion.still] is set.
bool calmMotion(BuildContext context) =>
    AuraMotion.still || (MediaQuery.maybeDisableAnimationsOf(context) ?? false);

abstract final class AuraMotion {
  /// Holds everything at rest: loops still, entrances at their end. Tests
  /// set it, so screens settle and read the same each run
  /// (`test/flutter_test_config.dart`).
  static bool still = false;
}

/// The prototype's haptics (navigator.vibrate), as the phone's own taps.
abstract final class AuraHaptics {
  /// Any button (10 ms).
  static void tap() => unawaited(HapticFeedback.selectionClick());

  /// A piece snaps into place (15 ms).
  static void snap() => unawaited(HapticFeedback.lightImpact());

  /// A wrong move (30 ms).
  static void wrong() => unawaited(HapticFeedback.mediumImpact());

  /// A big moment: a case solved, a badge (the 40-60-40 pattern).
  static void win() => unawaited(HapticFeedback.heavyImpact());
}

/// Runs [builder] with a value going 0 → 1 once, after [delay], when first
/// built. A new [key] plays it again. Calm motion shows the end state.
class Entrance extends StatefulWidget {
  const Entrance({
    super.key,
    required this.duration,
    required this.builder,
    this.delay = Duration.zero,
    this.child,
  });

  final Duration duration;
  final Duration delay;
  final Widget Function(BuildContext context, double t, Widget? child) builder;
  final Widget? child;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: widget.duration);
  Timer? _wait;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.isAnimating || _c.isCompleted || _wait != null) return;
    if (calmMotion(context)) {
      _c.value = 1;
    } else if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      _wait = Timer(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _wait?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, child) => widget.builder(context, _c.value, child),
    child: widget.child,
  );
}

/// Runs [builder] with a value going 0 → 1 over [period], again and again
/// (or [times] times). Calm motion shows `t = 0`.
class Loop extends StatefulWidget {
  const Loop({
    super.key,
    required this.period,
    required this.builder,
    this.delay = Duration.zero,
    this.times,
    this.child,
  });

  final Duration period;
  final Duration delay;
  final int? times;
  final Widget Function(BuildContext context, double t, Widget? child) builder;
  final Widget? child;

  @override
  State<Loop> createState() => _LoopState();
}

class _LoopState extends State<Loop> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: widget.period);
  Timer? _wait;
  int _runs = 0;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (widget.times == 0 || calmMotion(context)) return;
    _c.addStatusListener((s) {
      if (s != AnimationStatus.completed) return;
      _runs++;
      if (widget.times == null || _runs < widget.times!) {
        _c.forward(from: 0);
      } else {
        _c.value = 0;
      }
    });
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      _wait = Timer(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _wait?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, child) => widget.builder(context, _c.value, child),
    child: widget.child,
  );
}

/// The value at [t] of keyframes `(offset, value)`, eased linearly between
/// them, as CSS keyframes do with a linear timing.
double keyframes(double t, List<(double, double)> frames) {
  if (t <= frames.first.$1) return frames.first.$2;
  for (var i = 1; i < frames.length; i++) {
    final (o1, v1) = frames[i];
    if (t <= o1) {
      final (o0, v0) = frames[i - 1];
      return v0 + (v1 - v0) * ((t - o0) / (o1 - o0));
    }
  }
  return frames.last.$2;
}

/// The prototype's `pop`: grows from 0.6 and fades in. [delay] staggers a
/// row of them. [curve] is the line's timing: springy on a board piece
/// (`.gapseg`), [Curves.ease] where the prototype gives none (the tutor, a
/// ribbon, a tile: `pop .5s both`).
class Pop extends StatelessWidget {
  const Pop({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.from = 0.6,
    this.duration = AuraDurations.pop,
    this.curve = AuraCurves.spring,
  });

  final Widget child;
  final Duration delay;
  final double from;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) => Entrance(
    duration: duration,
    delay: delay,
    child: child,
    builder: (context, t, child) {
      final e = curve.transform(t);
      return Opacity(
        opacity: e.clamp(0.0, 1.0),
        child: Transform.scale(scale: from + (1 - from) * e, child: child),
      );
    },
  );
}

/// The prototype's `burst`: in from nothing, turned −30°, overshooting to
/// 1.15 and +6° at 60 %, then resting (900 ms, [AuraCurves.burst] on each
/// segment).
class Burst extends StatelessWidget {
  const Burst({super.key, required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) => Entrance(
    duration: AuraDurations.burst,
    delay: delay,
    child: child,
    builder: (context, t, child) {
      const c = AuraCurves.burst;
      final scale = cssFrames(t, const [(0, 0), (0.6, 1.15), (1, 1)], c);
      final turn = cssFrames(t, const [(0, -30), (0.6, 6), (1, 0)], c);
      final fade = cssFrames(t, const [(0, 0), (0.6, 1), (1, 1)], c);
      return Opacity(
        opacity: fade.clamp(0.0, 1.0),
        child: Transform.rotate(
          angle: turn * _deg,
          child: Transform.scale(scale: scale.clamp(0, 2), child: child),
        ),
      );
    },
  );
}

/// The prototype's `float`: drifts 8 px up and back, every 3 s.
class Float extends StatelessWidget {
  const Float({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.rise = 8,
  });

  final Widget child;
  final Duration delay;
  final double rise;

  @override
  Widget build(BuildContext context) => Loop(
    period: const Duration(seconds: 3),
    delay: delay,
    child: child,
    builder: (context, t, child) => Transform.translate(
      offset: Offset(0, -rise * Curves.easeInOut.transform(_upDown(t))),
      child: child,
    ),
  );
}

/// 0 → 1 → 0 across one loop.
double _upDown(double t) => t < 0.5 ? t * 2 : (1 - t) * 2;

/// [upDown] for other loops: 0 at the ends, 1 halfway, eased.
double halfway(double t) => Curves.easeInOut.transform(_upDown(t));

/// Presses in when touched and springs back: the prototype's buttons shrink
/// to [scale] (0.97 big, 0.96 small, 0.94 a pad key), 220 ms with overshoot.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.scale = 0.96});

  final Widget child;
  final double scale;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => _set(true),
    onPointerUp: (_) => _set(false),
    onPointerCancel: (_) => _set(false),
    child: AnimatedScale(
      scale: _down && !calmMotion(context) ? widget.scale : 1,
      duration: const Duration(milliseconds: 220),
      curve: AuraCurves.spring,
      child: widget.child,
    ),
  );
}

/// The caret in an empty answer box: blinks once a second.
class BlinkCaret extends StatelessWidget {
  const BlinkCaret({super.key, this.color = const Color(0xFF2F6BFF)});

  final Color color;

  @override
  Widget build(BuildContext context) => Loop(
    period: const Duration(seconds: 1),
    builder: (context, t, child) =>
        Opacity(opacity: t < 0.5 ? 1 : 0, child: child),
    child: Container(width: 3, height: 36, color: color),
  );
}

/// The prototype's `wobble` on a wrong move (`.wobble`, 400 ms
/// ease-in-out): −7 px −3°, +7 px +3°, −4 px −1°, +4 px +1°, rest. Plays
/// each time [count] goes up.
class Wobbly extends StatelessWidget {
  const Wobbly({super.key, required this.count, required this.child});

  final int count;
  final Widget child;

  static const _x = [(0.0, 0.0), (0.2, -7.0), (0.4, 7.0), (0.6, -4.0)];
  static const _r = [(0.0, 0.0), (0.2, -3.0), (0.4, 3.0), (0.6, -1.0)];

  @override
  Widget build(BuildContext context) => count == 0
      ? child
      : Entrance(
          key: ValueKey(count),
          duration: AuraDurations.wobble,
          child: child,
          builder: (context, t, child) {
            const c = Curves.easeInOut;
            final x = cssFrames(t, const [..._x, (0.8, 4), (1, 0)], c);
            final r = cssFrames(t, const [..._r, (0.8, 1), (1, 0)], c);
            return Transform.translate(
              offset: Offset(x, 0),
              child: Transform.rotate(angle: r * _deg, child: child),
            );
          },
        );
}

/// The prototype's `shake` on a standing button (`.sbtn.shake`, 600 ms
/// ease-in-out, twice): −8 px −2°, +8 px +2°, −5 px, +5 px, rest. Plays
/// each time [count] goes up.
class Shake extends StatelessWidget {
  const Shake({
    super.key,
    required this.count,
    required this.child,
    this.times = 2,
  });

  final int count;
  final int times;
  final Widget child;

  @override
  Widget build(BuildContext context) => count == 0
      ? child
      : Entrance(
          key: ValueKey(count),
          duration: AuraDurations.shake * times,
          child: child,
          builder: (context, t, child) {
            // one run of the keyframes per time
            final u = t >= 1 ? 1.0 : (t * times) % 1;
            const c = Curves.easeInOut;
            final x = cssFrames(u, const [
              (0, 0), (0.2, -8), (0.4, 8), (0.6, -5), (0.8, 5), (1, 0), //
            ], c);
            final r = cssFrames(u, const [
              (0, 0), (0.2, -2), (0.4, 2), (0.6, 0), (1, 0), //
            ], c);
            return Transform.translate(
              offset: Offset(x, 0),
              child: Transform.rotate(angle: r * _deg, child: child),
            );
          },
        );
}

/// A ring that swells out of [child]'s rounded box and back, as the
/// prototype's box-shadow pulses: [spread] px of [color] at the middle of
/// each [period]. [on] false (or calm motion) shows no ring. [times] null
/// pulses until [on] goes false.
class PulseRing extends StatelessWidget {
  const PulseRing({
    super.key,
    required this.child,
    required this.color,
    required this.spread,
    required this.period,
    this.radius = 16,
    this.on = true,
    this.times,
  });

  /// `glow`: 10 px of gold at 55 %, every 1.2 s (`.glow`).
  const PulseRing.glow({
    super.key,
    required this.child,
    this.radius = 22,
    this.on = true,
  }) : color = const Color(0x8CFFC531),
       spread = 10,
       period = AuraDurations.glow,
       times = null;

  /// `speakPulse`: 6 px of blue at 25 %, every 1 s, while a line plays.
  const PulseRing.speak({
    super.key,
    required this.child,
    this.radius = 16,
    this.on = true,
  }) : color = const Color(0x402F6BFF),
       spread = 6,
       period = AuraDurations.speakPulse,
       times = null;

  /// `helpPulse`: 8 px of blue at 25 %, 1.2 s, three times.
  const PulseRing.help({
    super.key,
    required this.child,
    this.radius = 20,
    this.on = true,
  }) : color = const Color(0x402F6BFF),
       spread = 8,
       period = AuraDurations.helpPulse,
       times = 3;

  final Widget child;
  final Color color;
  final double spread;
  final Duration period;
  final double radius;
  final bool on;
  final int? times;

  @override
  Widget build(BuildContext context) {
    if (!on) return child;
    return Loop(
      period: period,
      times: times,
      child: child,
      builder: (context, t, child) {
        final h = halfway(t);
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: color.a * h),
                spreadRadius: spread * h,
              ),
            ],
          ),
          child: child,
        );
      },
    );
  }
}

/// The prototype's `fade`: fades in over 250 ms (CSS `ease`).
class FadeIn extends StatelessWidget {
  const FadeIn({
    super.key,
    required this.child,
    this.duration = AuraDurations.fade,
    this.delay = Duration.zero,
  });

  final Widget child;
  final Duration duration;
  final Duration delay;

  @override
  Widget build(BuildContext context) => Entrance(
    duration: duration,
    delay: delay,
    child: child,
    builder: (context, t, child) =>
        Opacity(opacity: Curves.ease.transform(t), child: child),
  );
}

/// The prototype's `tipIn`: up 6 px from above and from 0.96, fading in
/// (400 ms, CSS `ease`).
class TipIn extends StatelessWidget {
  const TipIn({
    super.key,
    required this.child,
    this.duration = AuraDurations.tipIn,
  });

  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) => Entrance(
    duration: duration,
    child: child,
    builder: (context, t, child) {
      final e = Curves.ease.transform(t);
      return Opacity(
        opacity: e,
        child: Transform.translate(
          offset: Offset(0, -6 * (1 - e)),
          child: Transform.scale(scale: 0.96 + 0.04 * e, child: child),
        ),
      );
    },
  );
}

/// The prototype's `sheetUp` and `sheetDown`: [child] rises from 110 % of
/// its own height below (420 ms, [AuraCurves.sheet], a small overshoot);
/// with [closing] it drops back (250 ms, ease-in).
class SheetUp extends StatelessWidget {
  const SheetUp({super.key, required this.child, this.closing = false});

  final Widget child;
  final bool closing;

  @override
  Widget build(BuildContext context) => closing
      ? Entrance(
          key: const ValueKey('down'),
          duration: AuraDurations.sheetDown,
          child: child,
          builder: (context, t, child) => FractionalTranslation(
            translation: Offset(0, 1.1 * Curves.easeIn.transform(t)),
            child: child,
          ),
        )
      : Entrance(
          key: const ValueKey('up'),
          duration: AuraDurations.sheetUp,
          child: child,
          builder: (context, t, child) => FractionalTranslation(
            translation: Offset(0, 1.1 * (1 - AuraCurves.sheet.transform(t))),
            child: child,
          ),
        );
}

/// The prototype's `toastIn`: [child] drops in from 140 % of its height
/// above (400 ms, [AuraCurves.sheet]); with [closing] it leaves up to
/// 150 % (300 ms, linear).
class ToastIn extends StatelessWidget {
  const ToastIn({super.key, required this.child, this.closing = false});

  final Widget child;
  final bool closing;

  @override
  Widget build(BuildContext context) => closing
      ? Entrance(
          key: const ValueKey('out'),
          duration: AuraDurations.toastOut,
          child: child,
          builder: (context, t, child) => FractionalTranslation(
            translation: Offset(0, -1.5 * t),
            child: child,
          ),
        )
      : Entrance(
          key: const ValueKey('in'),
          duration: AuraDurations.toastIn,
          child: child,
          builder: (context, t, child) => FractionalTranslation(
            translation: Offset(0, -1.4 * (1 - AuraCurves.sheet.transform(t))),
            child: child,
          ),
        );
}

/// The prototype's `twinkle`: opacity 0.7 down to 0.15, shrinking to 0.6
/// and turning 30° at the middle of each 2.4 s, ease-in-out. [delay]
/// staggers a field of them (0.3 s apart).
class Twinkle extends StatelessWidget {
  const Twinkle({super.key, required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) => Loop(
    period: AuraDurations.twinkle,
    delay: delay,
    child: child,
    builder: (context, t, child) {
      final h = halfway(t);
      return Opacity(
        opacity: 0.7 - 0.55 * h,
        child: Transform.rotate(
          angle: 30 * h * _deg,
          child: Transform.scale(scale: 1 - 0.4 * h, child: child),
        ),
      );
    },
  );
}

/// The prototype's `sparkles(n)`: [count] white ✦ scattered over the box
/// it fills, each twinkling 0.3 s after the one before. Never takes taps.
class Sparkles extends StatelessWidget {
  const Sparkles({super.key, this.count = 10, this.color = Colors.white});

  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, box) => Stack(
          children: [
            for (var i = 0; i < count; i++)
              Positioned(
                left: box.maxWidth * (((i * 37) % 92) + 4) / 100,
                top: box.maxHeight * (((i * 53) % 70) + 8) / 100,
                child: Twinkle(
                  delay: Duration(milliseconds: i * 300),
                  child: Text(
                    '✦',
                    style: TextStyle(
                      color: color,
                      fontSize: 12.0 + (i % 3) * 6,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

/// The prototype's `sparkle` on the quick-sums fuse: grows to 1.3 and
/// turns 20°, and back, 350 ms each way, ease-in-out.
class SparkleSpin extends StatelessWidget {
  const SparkleSpin({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Loop(
    period: AuraDurations.sparkle * 2,
    child: child,
    builder: (context, t, child) {
      final h = halfway(t);
      return Transform.rotate(
        angle: 20 * h * _deg,
        child: Transform.scale(scale: 1 + 0.3 * h, child: child),
      );
    },
  );
}
