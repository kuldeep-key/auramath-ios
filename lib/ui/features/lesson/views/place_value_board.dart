import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/motion/motion.dart';
import '../../../core/theme/tokens.dart';
import '../view_models/place_value.dart';

/// What to do now on [sum]'s blocks: the situation, then the instruction
/// (Figma T1: black, then blue); [done] once the blocks are worked.
List<String> placeValueLines(
  AppLocalizations l,
  PlaceValue sum, {
  required String Function() done,
}) => switch (sum.step) {
  PlaceStep.breakTen => [
    l.lessonNotEnoughOnes(sum.rightOnes, sum.ones),
    l.lessonTapATen,
  ],
  PlaceStep.breakHundred => [
    sum.ones < sum.rightOnes
        ? l.lessonNotEnoughOnes(sum.rightOnes, sum.ones)
        : l.lessonNotEnoughTens(sum.rightTens, sum.tens),
    l.lessonTapAHundred,
  ],
  PlaceStep.takeOnes => [l.lessonTakeOnes(sum.rightOnes)],
  PlaceStep.takeTens => [l.lessonTakeTens(sum.rightTens)],
  PlaceStep.takeHundreds => [l.lessonTakeHundreds(sum.rightHundreds)],
  PlaceStep.addOnes => [l.lessonAddOnes(sum.rightOnes)],
  PlaceStep.addTens => [l.lessonAddTens(sum.rightTens)],
  PlaceStep.addHundreds => [l.lessonAddHundreds(sum.rightHundreds)],
  PlaceStep.makeTen => [l.lessonMakeATen(sum.ones)],
  PlaceStep.makeHundred => [l.lessonMakeAHundred(sum.tens)],
  PlaceStep.done => [done()],
};

/// The regrouping side lesson's hundreds, tens and ones as blocks (Figma
/// T1 649:239): the columns to tap for this step are edged blue, and
/// [onAct] does it. Shared by the lesson's side lesson and Quick sums'
/// (LES-16).
class PlaceValueBoard extends StatelessWidget {
  const PlaceValueBoard({super.key, required this.sum, required this.onAct});

  final PlaceValue sum;
  final VoidCallback onAct;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tap = sum.step;
    return Container(
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
              count: sum.hundreds,
              block: _Block.hundred,
              onTap: tap == PlaceStep.breakHundred ? onAct : null,
            ),
            const SizedBox(width: 6),
            _Column(
              label: l.lessonTens,
              count: sum.tens,
              block: _Block.ten,
              pulse: tap == PlaceStep.breakTen,
              onTap: tap == PlaceStep.breakTen || tap == PlaceStep.makeHundred
                  ? onAct
                  : null,
            ),
            const SizedBox(width: 6),
            _Column(
              label: l.lessonOnes,
              count: sum.ones,
              block: _Block.one,
              onTap: tap == PlaceStep.makeTen ? onAct : null,
            ),
          ],
        ),
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
