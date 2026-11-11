import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/motion/motion.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/keypad.dart';
import '../../../core/parts/lesson_header.dart';
import '../../../core/theme/tokens.dart';
import '../view_models/lesson_view_model.dart';
import '../view_models/place_value.dart';
import 'question_overlay.dart';

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
    PlaceStep.done => [_doneLine(l)],
  };

  /// Once the blocks are worked: type the sum, practise, then back.
  String _doneLine(AppLocalizations l) {
    final vm = widget.vm;
    return switch (vm.sideStage) {
      SideStage.ownSum => l.sideTypeIt(_sumText),
      SideStage.practice => l.sidePractice(vm.practice[vm.practiceAt].text),
      SideStage.back when vm.ownSumRight => l.lessonSideDone(
        _sumText,
        _sum.answer,
      ),
      SideStage.back when vm.sideAbandoned => l.sideKindEnd,
      SideStage.back when vm.practice.isNotEmpty => l.sidePracticeDone,
      SideStage.back => l.sideAnswerIs(_sumText, _sum.answer),
    };
  }

  /// Digits typed so far on the side lesson's keypad.
  String _typed = '';

  Future<void> _typedIn(String digits) async {
    final value = int.tryParse(digits);
    setState(() => _typed = '');
    if (value == null) return;
    final vm = widget.vm;
    await (vm.sideStage == SideStage.ownSum
        ? vm.checkOwnSum(value)
        : vm.answerPractice(value));
    if (mounted) vm.autoSay(_lines(AppLocalizations.of(context)!).join(' '));
  }

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
            big: widget.vm.voice.resting.value,
            line: lines.last,
            onSpeak: () => widget.vm.say(lines.join(' ')),
            speaking: widget.vm.voice.speaking,
            onHome: widget.onHome,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // large text (NFR-04, 1.3x): the sum shrinks beside the button
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
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
              ),
              const SizedBox(width: 8),
              // the whole question, from the side lesson too (LES-02, T1)
              SeeQuestionButton(
                label: l.lessonSeeQuestion,
                onTap: widget.vm.seeQuestion,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // DRAFT for Design (TUT-18): the detour pause; the case waits
                  const _CaseWaiting(),
                  const SizedBox(height: 10),
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
                            pulse: tap == PlaceStep.breakTen,
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
          if (_sum.step == PlaceStep.done &&
              widget.vm.sideStage != SideStage.back) ...[
            Text(
              _typed.isEmpty ? '?' : _typed,
              textAlign: TextAlign.center,
              style: AuraText.title.copyWith(fontSize: 30),
            ),
            const SizedBox(height: 8),
            Keypad(
              keyHeight: widget.vm.biggerPad ? 64 : 56,
              onChanged: (s) => setState(() => _typed = s),
              onCheck: _typedIn,
            ),
          ] else if (_sum.step == PlaceStep.done)
            AuraButton(
              label: l.backToProblem,
              color: AuraButtonColor.blue,
              onPressed: widget.vm.endSideLesson,
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

/// "Your case is waiting": the detour pauses the case, its board kept
/// (TUT-08, TUT-18). Draft: no Figma frame.
class _CaseWaiting extends StatelessWidget {
  const _CaseWaiting();

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('caseWaiting'),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: AuraColors.yellowTint,
      borderRadius: BorderRadius.circular(AuraRadii.small),
    ),
    child: Row(
      children: [
        const Icon(Icons.pause_circle_rounded, color: AuraColors.yellowInk),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            AppLocalizations.of(context)!.lessonDetourPaused,
            style: AuraText.chip.copyWith(color: AuraColors.yellowInk),
          ),
        ),
      ],
    ),
  );
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
    this.pulse = false,
  });

  final String label;
  final int count;
  final _Block block;
  final VoidCallback? onTap;

  /// The blocks breathe, to show which ones to tap (the prototype's tenpulse).
  final bool pulse;

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
                // each digit pops when it changes, as the prototype's written sum
                Pop(
                  key: ValueKey(count),
                  duration: const Duration(milliseconds: 350),
                  child: Text(
                    '$count',
                    style: AuraText.title.copyWith(fontSize: 34),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: block == _Block.one ? 5 : 4,
                  runSpacing: 4,
                  alignment: WrapAlignment.center,
                  // blocks that are new (a ten broken into ones) pop in
                  children: [
                    for (var i = 0; i < count; i++)
                      Pop(
                        key: ValueKey(i),
                        child: pulse
                            ? Loop(
                                period: const Duration(seconds: 1),
                                child: _piece(block),
                                builder: (context, t, child) => Transform.scale(
                                  scale: 1 + 0.08 * halfway(t),
                                  child: child,
                                ),
                              )
                            : _piece(block),
                      ),
                  ],
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
