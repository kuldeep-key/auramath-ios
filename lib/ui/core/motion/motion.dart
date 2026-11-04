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
    _wait = Timer(widget.delay, () {
      if (mounted) _c.forward();
    });
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
/// row of them.
class Pop extends StatelessWidget {
  const Pop({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.from = 0.6,
    this.duration = const Duration(milliseconds: 450),
  });

  final Widget child;
  final Duration delay;
  final double from;
  final Duration duration;

  @override
  Widget build(BuildContext context) => Entrance(
    duration: duration,
    delay: delay,
    child: child,
    builder: (context, t, child) => Opacity(
      opacity: t.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: from + (1 - from) * AuraCurves.spring.transform(t),
        child: child,
      ),
    ),
  );
}

/// The prototype's `burst`: in from nothing, turned −30°, overshooting to
/// 1.15 and +6°, then resting (900 ms).
class Burst extends StatelessWidget {
  const Burst({super.key, required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) => Entrance(
    duration: const Duration(milliseconds: 900),
    delay: delay,
    child: child,
    builder: (context, t, child) {
      final e = AuraCurves.burst.transform(t);
      final scale = keyframes(e, const [(0, 0), (0.6, 1.15), (1, 1)]);
      final turn = keyframes(e, const [(0, -30), (0.6, 6), (1, 0)]);
      return Opacity(
        opacity: keyframes(t, const [(0, 0), (0.6, 1), (1, 1)]),
        child: Transform.rotate(
          angle: turn * 3.14159 / 180,
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

/// The prototype's wobble on a wrong move: ±7 px and ±3°, 600 ms. Plays
/// each time [count] goes up.
class Wobble extends StatelessWidget {
  const Wobble({super.key, required this.count, required this.child});

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) => count == 0
      ? child
      : Entrance(
          key: ValueKey(count),
          duration: const Duration(milliseconds: 600),
          child: child,
          builder: (context, t, child) {
            final e = Curves.easeInOut.transform(t);
            const f = [(0.0, 0.0), (0.2, -1.0), (0.4, 1.0), (0.6, -0.57)];
            final k = keyframes(e, [...f, (0.8, 0.57), (1.0, 0.0)]);
            return Transform.translate(
              offset: Offset(7 * k, 0),
              child: Transform.rotate(
                angle: 3 * k * 3.14159 / 180,
                child: child,
              ),
            );
          },
        );
}
