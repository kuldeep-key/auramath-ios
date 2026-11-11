import 'package:flutter/material.dart';

import '../motion/motion.dart';
import '../theme/tokens.dart';

class StripChip {
  const StripChip({required this.label, required this.lit});

  final String label;

  /// Lit once the child has used that number.
  final bool lit;
}

/// The question's numbers, pinned above the board, with a button to see the
/// whole question again. Figma: Prototype parts › Question strip.
class QuestionStrip extends StatelessWidget {
  const QuestionStrip({
    super.key,
    required this.chips,
    required this.onSeeQuestion,
    this.seeQuestionLabel = 'See the question',
  });

  final List<StripChip> chips;

  /// Opens the whole question (LES-02).
  final VoidCallback onSeeQuestion;
  final String seeQuestionLabel;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: AuraColors.white,
      borderRadius: BorderRadius.circular(AuraRadii.panel),
      border: Border.all(color: AuraColors.line, width: 2),
      boxShadow: const [
        BoxShadow(color: AuraColors.line, offset: Offset(0, 4)),
      ],
    ),
    child: Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [for (final c in chips) _Chip(c)],
          ),
        ),
        Semantics(
          button: true,
          label: seeQuestionLabel,
          child: GestureDetector(
            key: const Key('seeQuestion'),
            onTap: onSeeQuestion,
            child: PressScale(
              child: Container(
                // a child's target: 56 pt (NFR-02)
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AuraColors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.visibility_rounded,
                  color: AuraColors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _Chip extends StatelessWidget {
  const _Chip(this.chip);

  final StripChip chip;

  @override
  Widget build(BuildContext context) => AnimatedScale(
    // a chip lighting up grows a touch (the prototype's .chip.on)
    scale: chip.lit && !calmMotion(context) ? 1.04 : 1,
    duration: const Duration(milliseconds: 300),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: chip.lit ? AuraColors.yellow : AuraColors.yellowTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        chip.label,
        style: AuraText.chip.copyWith(
          color: chip.lit ? AuraColors.yellowFg : AuraColors.yellowInk,
        ),
      ),
    ),
  );
}
