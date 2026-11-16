import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../motion/motion.dart';
import '../theme/tokens.dart';

/// Which number a chip holds, for its colours (the prototype's `.chip`,
/// `.chip.b`, `.chip.on`, `.chip.on.a`).
enum StripChipKind {
  /// Bar A's number: pale yellow, then yellow once used.
  a,

  /// The gap: pale yellow, then blue once used.
  gap,

  /// Bar B's number: pale blue, then blue once used.
  b,
}

class StripChip {
  const StripChip({
    required this.label,
    required this.lit,
    this.kind = StripChipKind.a,
  });

  final String label;

  /// Lit once the child has used that number.
  final bool lit;
  final StripChipKind kind;
}

/// The question's numbers, pinned above the board, with a button to see the
/// whole question again. Figma: Prototype parts › Question strip. As the
/// prototype's `.qstrip`: a white strip with a pale edge and lip, the
/// chips 4 pt apart, and the blue "See" button at the end. A chip that
/// lights grows to 1.04 and changes colour over 300 ms.
class QuestionStrip extends StatelessWidget {
  const QuestionStrip({
    super.key,
    required this.chips,
    required this.onSeeQuestion,
    this.seeQuestionLabel = 'See the question',
    this.seeLabel,
  });

  final List<StripChip> chips;

  /// Opens the whole question (LES-02).
  final VoidCallback onSeeQuestion;
  final String seeQuestionLabel;

  /// The word on the button; null: the app's ("See").
  final String? seeLabel;

  @override
  Widget build(BuildContext context) {
    final see = seeLabel ?? AppLocalizations.of(context)?.lessonSee ?? 'See';
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AuraColors.white,
        borderRadius: BorderRadius.circular(AuraRadii.panel),
        border: Border.all(color: AuraColors.line, width: 2),
        boxShadow: const [
          BoxShadow(color: AuraColors.line, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [for (final c in chips) _Chip(c)],
              ),
            ),
          ),
          const SizedBox(width: 4),
          Semantics(
            button: true,
            label: seeQuestionLabel,
            excludeSemantics: true,
            child: GestureDetector(
              key: const Key('seeQuestion'),
              behavior: HitTestBehavior.opaque,
              onTap: onSeeQuestion,
              // a child's target: 56 pt (NFR-02); the button drawn 40 high
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
                child: Center(
                  child: PressScale(
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AuraColors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.visibility_rounded,
                            size: 16,
                            color: AuraColors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            see,
                            style: AuraText.chip.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AuraColors.white,
                            ),
                          ),
                        ],
                      ),
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
}

class _Chip extends StatelessWidget {
  const _Chip(this.chip);

  final StripChip chip;

  static const _tintInk = Color(0xFF8B7A4A);
  static const _blueTintInk = Color(0xFF7D8BB8);
  static const _litYellowInk = Color(0xFF3B2800);

  @override
  Widget build(BuildContext context) {
    final (fill, ink) = switch ((chip.kind, chip.lit)) {
      (StripChipKind.a, true) => (AuraColors.yellow, _litYellowInk),
      (_, true) => (AuraColors.blue, AuraColors.white),
      (StripChipKind.b, false) => (AuraColors.blueTint, _blueTintInk),
      (_, false) => (AuraColors.yellowTint, _tintInk),
    };
    const lightUp = Duration(milliseconds: 300);
    return AnimatedScale(
      // a chip lighting up grows a touch (the prototype's .chip.on)
      scale: chip.lit && !calmMotion(context) ? 1.04 : 1,
      duration: lightUp,
      curve: Curves.ease,
      child: AnimatedContainer(
        duration: lightUp,
        curve: Curves.ease,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(999),
        ),
        child: AnimatedDefaultTextStyle(
          duration: lightUp,
          curve: Curves.ease,
          style: AuraText.chip.copyWith(color: ink),
          child: Text(chip.label, softWrap: false),
        ),
      ),
    );
  }
}
