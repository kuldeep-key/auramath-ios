import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/motion/motion.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/aura_card.dart';
import '../../../core/theme/tokens.dart';
import '../view_models/lesson_view_model.dart';
import 'word_meaning.dart';

/// The story with each item's name in its bar's colour (LES-02): lemon in
/// the lemon bar's yellow, fig in the fig bar's blue. The names stay
/// words, so colour is never the only signal (NFR-03).
///
/// [words] (LES-10) are underlined, dotted: a maths word to tap below.
TextSpan storySpan(ComparisonProblem p, {List<String> words = const []}) {
  final names = {
    p.a.name.toLowerCase(): AuraColors.yellowInk,
    p.b.name.toLowerCase(): AuraColors.blueInk,
    for (final w in words) w: null,
  };
  final pattern = RegExp(
    names.keys.map((k) => '\\b${RegExp.escape(k)}\\b').join('|'),
    caseSensitive: false,
  );
  final spans = <TextSpan>[];
  var at = 0;
  for (final m in pattern.allMatches(p.text)) {
    spans
      ..add(TextSpan(text: p.text.substring(at, m.start)))
      ..add(
        TextSpan(
          text: m[0],
          style: switch (names[m[0]!.toLowerCase()]) {
            final Color c => AuraText.storyName.copyWith(color: c),
            // a maths word: dotted underline, the story's own colour
            null => const TextStyle(
              decoration: TextDecoration.underline,
              decorationStyle: TextDecorationStyle.dotted,
              decorationThickness: 2,
            ),
          },
        ),
      );
    at = m.end;
  }
  spans.add(TextSpan(text: p.text.substring(at)));
  return TextSpan(children: spans);
}

/// "See the question": the whole question over the work, which stays as
/// it was underneath (LES-02; Julia's comments on D1, D2, D4, D5, H1·1,
/// H2·2 and T1). No Figma frame of its own yet: drawn like M0's card.
class QuestionOverlay extends StatelessWidget {
  const QuestionOverlay({super.key, required this.vm});

  final LessonViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final p = vm.problem;
    return Positioned.fill(
      child: Material(
        key: const Key('questionOverlay'),
        color: AuraColors.navy.withValues(alpha: 0.35),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Entrance(
              duration: const Duration(milliseconds: 320),
              builder: (context, t, child) => Opacity(
                opacity: t.clamp(0.0, 1.0),
                child: Transform.scale(scale: 0.96 + 0.04 * t, child: child),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: AuraCard(
                      child: Center(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              Text(
                                '${p.a.pic}  ${p.b.pic}',
                                style: const TextStyle(fontSize: 56),
                              ),
                              const SizedBox(height: 12),
                              Text.rich(
                                storySpan(
                                  p,
                                  words: vm.wordMeanings
                                      ? wordsIn(p)
                                      : const [],
                                ),
                                style: AuraText.story,
                              ),
                              if (vm.wordMeanings) ...[
                                const SizedBox(height: 16),
                                WordButtons(vm: vm),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AuraButton(
                    label: l.hearItAgain,
                    color: AuraButtonColor.white,
                    icon: Icons.volume_up_rounded,
                    onPressed: vm.readQuestion,
                  ),
                  const SizedBox(height: 12),
                  AuraButton(
                    label: l.lessonQuestionBack,
                    color: AuraButtonColor.blue,
                    onPressed: vm.closeQuestion,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The eye button that opens the whole question, where a screen has no
/// question strip (a side lesson). 56 pt (NFR-02).
class SeeQuestionButton extends StatelessWidget {
  const SeeQuestionButton({
    super.key = const Key('seeQuestion'),
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    excludeSemantics: true,
    child: GestureDetector(
      onTap: () {
        AuraHaptics.tap();
        onTap();
      },
      child: PressScale(
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AuraColors.blue,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AuraColors.navy, width: 3),
            boxShadow: const [
              BoxShadow(color: AuraColors.navy, offset: Offset(0, 4)),
            ],
          ),
          child: const Icon(Icons.visibility_rounded, color: AuraColors.white),
        ),
      ),
    ),
  );
}
