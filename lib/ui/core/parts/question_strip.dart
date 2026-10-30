import 'package:flutter/material.dart';

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
  });

  final List<StripChip> chips;
  final VoidCallback onSeeQuestion;

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
          label: 'See the question',
          child: GestureDetector(
            onTap: onSeeQuestion,
            child: Container(
              width: 44,
              height: 44,
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
      ],
    ),
  );
}

class _Chip extends StatelessWidget {
  const _Chip(this.chip);

  final StripChip chip;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
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
  );
}
