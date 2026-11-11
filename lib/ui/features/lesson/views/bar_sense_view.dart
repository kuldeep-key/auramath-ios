import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/motion/motion.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/lesson_header.dart';
import '../../../core/theme/tokens.dart';
import '../view_models/lesson_view_model.dart';

/// Julia's bar-sense side lessons (TUT-17, slide 8), behind the flag
/// `bar_sense_side_lessons`, for a child who keeps sizing the bars the
/// wrong way round: first "a longer bar represents a greater number" (3
/// and 5 on two bars); still unsure, "Let's compare 3 stars and 5 stars",
/// then the bars again, then back to the case. Nothing is red.
///
/// DRAFT for Design and Julia: two new child screens with no Figma frame
/// (Apoorv designs them after the committed M3 work, D-28). The numbers are
/// her 3 and 5.
class BarSenseView extends StatefulWidget {
  const BarSenseView({super.key, required this.vm, required this.onHome});

  final LessonViewModel vm;
  final VoidCallback onHome;

  @override
  State<BarSenseView> createState() => _BarSenseViewState();
}

enum _Stage { bars, stars, starsRight, done }

class _BarSenseViewState extends State<BarSenseView> {
  static const small = 3, big = 5;
  var _stage = _Stage.bars;
  int _wobbles = 0;

  /// The bigger number is drawn second on the first try, first after the
  /// stars, so the place isn't the clue.
  bool get _bigFirst => _stage != _Stage.bars || _starsSeen;
  bool _starsSeen = false;

  String _line(AppLocalizations l) => switch (_stage) {
    _Stage.bars => '${l.lessonBarSenseLine} ${l.lessonBarSenseAsk(big)}',
    _Stage.stars => l.lessonStarsAsk(small, big),
    _Stage.starsRight => l.lessonStarsRight,
    _Stage.done => l.lessonBarSenseRight,
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.vm.autoSay(_line(AppLocalizations.of(context)!));
  }

  void _go(_Stage s) {
    setState(() => _stage = s);
    widget.vm.autoSay(_line(AppLocalizations.of(context)!));
  }

  void _pick(int n) {
    final right = n == big;
    if (!right) setState(() => _wobbles++);
    switch ((_stage, right)) {
      case (_Stage.bars, true):
        _go(_Stage.done);
      case (_Stage.bars, false):
        // unsure about single items on a bar: the stars (Julia, slide 8)
        _starsSeen = true;
        _go(_Stage.stars);
      case (_Stage.stars, true):
        _go(_Stage.starsRight);
      default:
        break; // a wobble; ask again
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final line = _line(l);
    final order = _bigFirst ? [big, small] : [small, big];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LessonHeader(
            big: widget.vm.voice.resting.value,
            line: line,
            onSpeak: () => widget.vm.say(line),
            speaking: widget.vm.voice.speaking,
            muted: !widget.vm.readAloud,
            onSound: widget.vm.sound,
            onHome: widget.onHome,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Wobbly(
              count: _wobbles,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 24,
                children: [
                  for (final (i, n) in order.indexed)
                    _stage == _Stage.stars || _stage == _Stage.starsRight
                        ? _Row(
                            key: Key('stars$n'),
                            label: l.lessonStarRow(i + 1),
                            count: n,
                            onTap: _stage == _Stage.stars
                                ? () => _pick(n)
                                : null,
                          )
                        : _Bar(
                            key: Key('bar$n'),
                            label: l.lessonBarLabel(i + 1),
                            units: n,
                            of: big,
                            onTap: _stage == _Stage.bars
                                ? () => _pick(n)
                                : null,
                          ),
                ],
              ),
            ),
          ),
          if (_stage == _Stage.starsRight)
            AuraButton(
              label: l.next,
              color: AuraButtonColor.blue,
              onPressed: () => _go(_Stage.bars),
            )
          else if (_stage == _Stage.done)
            AuraButton(
              label: l.backToProblem,
              color: AuraButtonColor.blue,
              onPressed: () => widget.vm.send(const SideLessonDone()),
            ),
        ],
      ),
    );
  }
}

/// A bar of [units] equal blocks, as long as [units] of [of] across the
/// screen; at least 56 pt tall to tap (NFR-02).
class _Bar extends StatelessWidget {
  const _Bar({
    super.key,
    required this.label,
    required this.units,
    required this.of,
    this.onTap,
  });

  final String label;
  final int units;
  final int of;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    label: label,
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: units / of,
        child: Row(
          children: [
            for (var i = 0; i < units; i++)
              Expanded(
                child: Container(
                  height: 64,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: AuraColors.yellow,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AuraColors.yellowLip, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

/// A row of [count] stars, each the same size, so more stars make a
/// longer row.
class _Row extends StatelessWidget {
  const _Row({super.key, required this.label, required this.count, this.onTap});

  final String label;
  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    label: label,
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            for (var i = 0; i < count; i++)
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Icon(
                  Icons.star_rounded,
                  size: 52,
                  color: AuraColors.yellow,
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
