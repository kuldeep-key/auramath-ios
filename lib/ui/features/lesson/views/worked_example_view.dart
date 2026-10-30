import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/board/bar.dart';
import '../../../core/board/brace.dart';
import '../../../core/board/gap_segment.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/lesson_header.dart';
import '../../../core/theme/tokens.dart';
import '../view_models/lesson_view_model.dart';

/// "Show me how": a smaller problem of the same shape, drawn step by step
/// (Figma H2 667:2, H2-1 666:146, H2-2 666:183, H2-3 666:220), then back to
/// the child's own problem. B is shorter or taller as in that problem.
class WorkedExampleView extends StatefulWidget {
  const WorkedExampleView({super.key, required this.vm, required this.onHome});

  final LessonViewModel vm;
  final VoidCallback onHome;

  @override
  State<WorkedExampleView> createState() => _WorkedExampleViewState();
}

class _WorkedExampleViewState extends State<WorkedExampleView> {
  static const _a = 6, _d = 2;
  int _step = 0;

  bool get _shorter => widget.vm.problem.big == BigSide.a;
  int get _b => _shorter ? _a - _d : _a + _d;

  String _line(AppLocalizations l) => switch (_step) {
    0 => l.exampleA(_a),
    1 => l.exampleB(_d, _relation(l)),
    2 => _shorter ? l.exampleTake(_a, _d, _b) : l.exampleAdd(_a, _d, _b),
    _ => l.exampleTogether(_a, _b, _a + _b),
  };

  String _relation(AppLocalizations l) =>
      _shorter ? l.exampleShorter : l.exampleTaller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.vm.autoSay(_line(AppLocalizations.of(context)!));
  }

  void _go(int step) {
    setState(() => _step = step);
    widget.vm.autoSay(_line(AppLocalizations.of(context)!));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final line = _line(l);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LessonHeader(
            big: widget.vm.voice.resting.value,
            line: line,
            onSpeak: () => widget.vm.say(line),
            onHome: widget.onHome,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AuraColors.yellowTint,
              borderRadius: BorderRadius.circular(AuraRadii.small),
            ),
            child: Text(
              l.exampleFacts(_a, _d, _relation(l)),
              textAlign: TextAlign.center,
              style: AuraText.chip.copyWith(color: AuraColors.yellowInk),
            ),
          ),
          Expanded(
            child: _Bars(step: _step, a: _a, b: _b, d: _d),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AuraButton(
                  label: l.exampleAgain,
                  color: AuraButtonColor.white,
                  icon: Icons.replay_rounded,
                  onPressed: () => _go(0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AuraButton(
                  label: _step < 3 ? l.next : l.exampleNowYouTry,
                  color: AuraButtonColor.blue,
                  onPressed: _step < 3
                      ? () => _go(_step + 1)
                      : widget.vm.closeExample,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A and B on a shared baseline, scaled to the space there is.
class _Bars extends StatelessWidget {
  const _Bars({
    required this.step,
    required this.a,
    required this.b,
    required this.d,
  });

  final int step;
  final int a;
  final int b;
  final int d;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      // the labels, the baseline, A/B and the total's brace keep their room
      // on every step, so the bars don't jump when the brace appears
      const barWidth = 90.0, gapBetween = 40.0, labelSpace = 140.0;
      // Figma's tallest bar is 270 pt; smaller phones shrink it to fit
      final tallest = (box.maxHeight - labelSpace).clamp(60.0, 270.0);
      final unit = tallest / (a > b ? a : b);
      final faded = step >= 2;
      Widget label(String text) =>
          SizedBox(height: 36, child: Text(text, style: AuraText.barValue));

      // the gap rides on the shorter bar, up to the taller one's top
      final gapOnB = b < a;
      Widget gap() => SizedBox(
        width: barWidth,
        height: d * unit,
        child: Opacity(
          opacity: faded ? 0.5 : 1,
          child: GapSegment(label: '$d m'),
        ),
      );

      final barB = step == 0
          ? Container(width: barWidth, height: 6, color: AuraColors.blue)
          : SizedBox(
              width: barWidth,
              height: b * unit,
              child: Bar(
                color: AuraColors.blue,
                child: faded
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text('$b m', style: AuraText.barInside),
                      )
                    : null,
              ),
            );

      return Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  label('$a m'),
                  if (!gapOnB && step >= 1) gap(),
                  SizedBox(
                    width: barWidth,
                    height: a * unit,
                    child: const Bar(color: AuraColors.yellow),
                  ),
                ],
              ),
              const SizedBox(width: gapBetween),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (step == 1) label('? m'),
                  if (gapOnB && step >= 1) gap(),
                  barB,
                ],
              ),
            ],
          ),
          Container(
            height: 4,
            width: barWidth * 2 + gapBetween + 40,
            color: AuraColors.line,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: barWidth,
                child: Text(
                  'A',
                  style: AuraText.barName,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: gapBetween),
              SizedBox(
                width: barWidth,
                child: Text(
                  'B',
                  style: AuraText.barName,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: barWidth * 2 + gapBetween,
            // the brace's pill holds a Bold 20 label
            height: 50,
            child: step == 3 ? Brace(label: '${a + b} m') : null,
          ),
        ],
      );
    },
  );
}
