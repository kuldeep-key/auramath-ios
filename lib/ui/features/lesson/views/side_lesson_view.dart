import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/lesson_header.dart';
import '../../../core/theme/tokens.dart';
import '../view_models/lesson_view_model.dart';
import '../view_models/place_value.dart';

/// A short lesson on the one skill a wrong answer showed: the child works
/// the sum on hundreds, tens and ones, breaking a ten (or making one) by
/// tapping the blocks, then goes back to the problem. Figma: T1 (649:239).
class SideLessonView extends StatefulWidget {
  const SideLessonView({super.key, required this.vm, required this.onHome});

  final LessonViewModel vm;
  final VoidCallback onHome;

  @override
  State<SideLessonView> createState() => _SideLessonViewState();
}

class _SideLessonViewState extends State<SideLessonView> {
  late final _sum = () {
    final s = widget.vm.sideSum;
    return PlaceValue(left: s.left, right: s.right, subtract: s.subtract);
  }();

  String get _sign => _sum.subtract ? '−' : '+';
  String get _sumText => '${_sum.left} $_sign ${_sum.right}';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.vm.autoSay(_lines(AppLocalizations.of(context)!).join(' '));
  }

  void _act() {
    setState(_sum.act);
    widget.vm.autoSay(_lines(AppLocalizations.of(context)!).join(' '));
  }

  /// What to do now: the situation, then the instruction (Figma: black,
  /// then blue).
  List<String> _lines(AppLocalizations l) => switch (_sum.step) {
    PlaceStep.breakTen => [
      l.lessonNotEnoughOnes(_sum.rightOnes, _sum.ones),
      l.lessonTapATen,
    ],
    PlaceStep.breakHundred => [
      _sum.ones < _sum.rightOnes
          ? l.lessonNotEnoughOnes(_sum.rightOnes, _sum.ones)
          : l.lessonNotEnoughTens(_sum.rightTens, _sum.tens),
      l.lessonTapAHundred,
    ],
    PlaceStep.takeOnes => [l.lessonTakeOnes(_sum.rightOnes)],
    PlaceStep.takeTens => [l.lessonTakeTens(_sum.rightTens)],
    PlaceStep.takeHundreds => [l.lessonTakeHundreds(_sum.rightHundreds)],
    PlaceStep.addOnes => [l.lessonAddOnes(_sum.rightOnes)],
    PlaceStep.addTens => [l.lessonAddTens(_sum.rightTens)],
    PlaceStep.addHundreds => [l.lessonAddHundreds(_sum.rightHundreds)],
    PlaceStep.makeTen => [l.lessonMakeATen(_sum.ones)],
    PlaceStep.makeHundred => [l.lessonMakeAHundred(_sum.tens)],
    PlaceStep.done => [l.lessonSideDone(_sumText, _sum.answer)],
  };

  /// Steps done by tapping the blocks; the others have a button.
  PlaceStep? get _tapStep => switch (_sum.step) {
    PlaceStep.breakTen ||
    PlaceStep.breakHundred ||
    PlaceStep.makeTen ||
    PlaceStep.makeHundred => _sum.step,
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final lines = _lines(l);
    final tap = _tapStep;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LessonHeader(
            line: lines.last,
            onSpeak: () => widget.vm.say(lines.join(' ')),
            onHome: widget.onHome,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AuraColors.navy,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _sumText,
                style: AuraText.title.copyWith(
                  color: AuraColors.white,
                  fontSize: 26,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AuraColors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AuraColors.line, width: 2),
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Column(
                            label: l.lessonHundreds,
                            count: _sum.hundreds,
                            block: _Block.hundred,
                            onTap: tap == PlaceStep.breakHundred ? _act : null,
                          ),
                          const SizedBox(width: 6),
                          _Column(
                            label: l.lessonTens,
                            count: _sum.tens,
                            block: _Block.ten,
                            onTap:
                                tap == PlaceStep.breakTen ||
                                    tap == PlaceStep.makeHundred
                                ? _act
                                : null,
                          ),
                          const SizedBox(width: 6),
                          _Column(
                            label: l.lessonOnes,
                            count: _sum.ones,
                            block: _Block.one,
                            onTap: tap == PlaceStep.makeTen ? _act : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Semantics(
                    liveRegion: true,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          for (final (i, line) in lines.indexed)
                            TextSpan(
                              text: i == 0 ? line : '\n$line',
                              style: TextStyle(
                                color: i == lines.length - 1 && lines.length > 1
                                    ? AuraColors.blueInk
                                    : AuraColors.ink,
                              ),
                            ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      style: AuraText.chip.copyWith(fontSize: 22),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_sum.step == PlaceStep.done)
            AuraButton(
              label: l.backToProblem,
              color: AuraButtonColor.blue,
              onPressed: () => widget.vm.send(const SideLessonDone()),
            )
          else if (tap == null)
            AuraButton(
              label: l.lessonDoIt,
              color: AuraButtonColor.blue,
              onPressed: _act,
            ),
        ],
      ),
    );
  }
}

enum _Block { hundred, ten, one }

/// One place-value column: its name, its digit, and its blocks. Tappable
/// columns get a blue edge so the child sees where to tap (plus the words).
class _Column extends StatelessWidget {
  const _Column({
    required this.label,
    required this.count,
    required this.block,
    required this.onTap,
  });

  final String label;
  final int count;
  final _Block block;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final live = onTap != null;
    return Expanded(
      child: Semantics(
        button: live,
        label: '$label: $count',
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            constraints: const BoxConstraints(minHeight: 120),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: live ? AuraColors.blueTint : AuraColors.soft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: live ? AuraColors.blue : AuraColors.soft,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Text(
                  label,
                  style: AuraText.chip.copyWith(
                    fontSize: 17,
                    color: AuraColors.mute,
                  ),
                ),
                Text('$count', style: AuraText.title.copyWith(fontSize: 34)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: block == _Block.one ? 5 : 4,
                  runSpacing: 4,
                  alignment: WrapAlignment.center,
                  children: [for (var i = 0; i < count; i++) _piece(block)],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _piece(_Block b) => switch (b) {
    _Block.hundred => Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: AuraColors.yellowTint,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AuraColors.yellow, width: 2),
      ),
    ),
    _Block.ten => Container(
      width: 16,
      height: 52,
      decoration: BoxDecoration(
        color: AuraColors.yellow,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AuraColors.yellowLip, width: 2),
      ),
    ),
    _Block.one => Container(
      width: 14,
      height: 14,
      decoration: const BoxDecoration(
        color: AuraColors.blue,
        shape: BoxShape.circle,
      ),
    ),
  };
}
