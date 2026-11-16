import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'motion.dart';

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
  });

  final String moment;
  final int variant;
  final String title;
  final String? subtitle;
  final Widget art;

  /// A picture beside the art: the child's look beside the session badge
  /// (AVT-02).
  final Widget? side;

  /// rules.yaml `celebrations.moments.<moment>.max_ms`: it ends by itself
  /// by then.
  final Duration maxDuration;

  /// The child has seen this moment before: a tap skips it (`tap_to_skip:
  /// after_first_view`).
  final bool skippable;

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
/// before. Gold, blue and white only: never red (NFR-03); nothing flashes.
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
    _end ??= Timer(widget.spec.maxDuration, () => _finish(skipped: false));
  }

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

  @override
  Widget build(BuildContext context) {
    final s = widget.spec;
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
    return Semantics(
      liveRegion: true,
      label: [s.title, ?s.subtitle].join('. '),
      button: s.skippable,
      excludeSemantics: true,
      child: GestureDetector(
        key: const Key('celebration'),
        behavior: HitTestBehavior.opaque,
        onTap: s.skippable ? () => _finish(skipped: true) : null,
        child: Material(
          color: AuraColors.blue,
          child: SafeArea(
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
                    Text(
                      s.title,
                      textAlign: TextAlign.center,
                      style: AuraText.playTitle.copyWith(
                        color: AuraColors.white,
                      ),
                    ),
                    if (s.subtitle != null)
                      Text(
                        s.subtitle!,
                        textAlign: TextAlign.center,
                        style: AuraText.play,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
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
