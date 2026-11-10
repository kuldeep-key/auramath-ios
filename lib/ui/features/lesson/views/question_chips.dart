import 'package:flutter/material.dart';

import '../../../core/motion/motion.dart';
import '../../../core/theme/tokens.dart';

typedef Question = ({String id, String question, String answer});

/// Tap-to-ask buttons for the step (TUT-13): one to three questions from
/// policy `question_buttons`. No free text anywhere.
// Draft: no Figma frame yet; white pills that scroll sideways.
class QuestionChips extends StatelessWidget {
  const QuestionChips({
    super.key,
    required this.questions,
    required this.onAsk,
  });

  final List<Question> questions;
  final ValueChanged<Question> onAsk;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final (i, q) in questions.indexed) ...[
          if (i > 0) const SizedBox(width: 8),
          _chip(q),
        ],
      ],
    ),
  );

  Widget _chip(Question q) => PressScale(
    child: Material(
      color: AuraColors.white,
      shape: StadiumBorder(
        side: BorderSide(color: AuraColors.blue.withValues(alpha: 0.4)),
      ),
      child: InkWell(
        key: Key('ask-${q.id}'),
        customBorder: const StadiumBorder(),
        onTap: () => onAsk(q),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56, minWidth: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.help_outline_rounded,
                  color: AuraColors.blue,
                  size: 22,
                ),
                const SizedBox(width: 6),
                Text(q.question, style: AuraText.small),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
