import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/board/bar.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/theme/tokens.dart';
import '../view_models/lesson_view_model.dart';
import 'help_sheet.dart';

/// The maths words a child can tap in the question (LES-10): the relation
/// words of a height story and of a weight story.
const meaningWords = ['taller', 'shorter', 'more', 'less'];

/// The maths words in [p]'s question, in the order they appear.
List<String> wordsIn(ComparisonProblem p) {
  final text = p.text.toLowerCase();
  final found = [
    for (final w in meaningWords)
      if (RegExp('\\b$w\\b').firstMatch(text) case final m?) (m.start, w),
  ]..sort((a, b) => a.$1.compareTo(b.$1));
  return [for (final (_, w) in found) w];
}

/// A button under the question for each maths word in it (LES-10), 56 pt
/// (NFR-02): the word itself, with a book. DRAFT design: Figma J09 has no
/// way in yet; the word is also underlined in the story.
class WordButtons extends StatelessWidget {
  const WordButtons({super.key, required this.vm});

  final LessonViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final w in wordsIn(vm.problem))
          Semantics(
            button: true,
            label: l.kidWordWhat(w),
            excludeSemantics: true,
            child: InkWell(
              key: Key('word-$w'),
              onTap: () => vm.openWord(w),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                constraints: const BoxConstraints(minHeight: 56, minWidth: 56),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: AuraColors.blueTint,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AuraColors.blue, width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.menu_book_rounded, color: AuraColors.navy),
                    const SizedBox(width: 8),
                    Text(w, style: AuraText.chip),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// What a word means, shown with a drawing, not a definition only
/// (LES-10, Figma J09). DRAFT drawing, for Julia to confirm: two of a kind
/// and their bars, the taller (or heavier) one with the longer bar. Never
/// the problem's own two things, so it gives nothing of the answer away.
class WordMeaningSheet extends StatelessWidget {
  const WordMeaningSheet({super.key, required this.vm, required this.word});

  final LessonViewModel vm;
  final String word;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final mass = word == 'more' || word == 'less';
    final line = switch (word) {
      'taller' => l.kidWordTaller,
      'shorter' => l.kidWordShorter,
      'more' => l.kidWordMore,
      _ => l.kidWordLess,
    };
    // the word's own one is lit: the taller or heavier for taller / more
    final litBig = word == 'taller' || word == 'more';
    return AuraSheet(
      onClose: vm.closeWord,
      children: [
        Text(
          word[0].toUpperCase() + word.substring(1),
          key: const Key('wordMeaning'),
          style: AuraText.title,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 170,
          child: _Drawing(mass: mass, litBig: litBig),
        ),
        const SizedBox(height: 12),
        Text(line, style: AuraText.body, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        AuraButton(
          label: l.kidWordGotIt,
          color: AuraButtonColor.blue,
          onPressed: vm.closeWord,
        ),
      ],
    );
  }
}

class _Drawing extends StatelessWidget {
  const _Drawing({required this.mass, required this.litBig});

  final bool mass;
  final bool litBig;

  @override
  Widget build(BuildContext context) {
    Color color(bool big) =>
        big == litBig ? AuraColors.yellow : AuraColors.blueTint;
    // two of a kind: a big and a small tree, or a big and a small bag
    final (bigPic, smallPic) = mass ? ('🎒', '👜') : ('🌳', '🌱');
    Widget thing(String pic, double size) => ExcludeSemantics(
      child: Text(pic, style: TextStyle(fontSize: size)),
    );
    if (mass) {
      Widget row(String pic, double k, bool big) => Row(
        children: [
          SizedBox(width: 48, child: thing(pic, big ? 34 : 24)),
          Expanded(
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: k,
              child: SizedBox(height: 40, child: Bar(color: color(big))),
            ),
          ),
        ],
      );
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 16,
        children: [row(bigPic, 0.95, true), row(smallPic, 0.5, false)],
      );
    }
    Widget column(String pic, double k, bool big) => Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: FractionallySizedBox(
            alignment: Alignment.bottomCenter,
            heightFactor: k,
            child: SizedBox(width: 56, child: Bar(color: color(big))),
          ),
        ),
        thing(pic, big ? 34 : 24),
      ],
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 40,
      children: [column(bigPic, 1, true), column(smallPic, 0.5, false)],
    );
  }
}
