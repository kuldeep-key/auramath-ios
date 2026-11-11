import 'dart:io';

import 'package:auramath_engine/auramath_engine.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// The template's step order (LES-03, LES-12) and the tutor's hint ladder
/// (TUT-04, TUT-16) together: a lesson that uses both replays from its log.
final policy = Policy.fromYaml(
  File('../../assets/spec/policy.yaml').readAsStringSync(),
);
final template = ComparisonTemplate.fromYaml(
  File('../../assets/spec/comparison-two-step.yaml').readAsStringSync(),
);
final both = pack.copyWith(
  template: template,
  optionalSteps: {'name_quantities'},
  hintLadder: policy.hintLadder,
  hintStart: template.hintStart,
  quietLines: policy.quietLines,
);
const t = (stepMs: 10, problemMs: 100, readingMs: 5);

void main() {
  test('named heights, rungs, a which-it pick, a held drop and its undo, '
      'then solved: the log replays to the same state', () {
    final names = choiceOptions(both, lemon, 'name_quantities');
    final sums = choiceOptions(both, lemon, 'choose_operation');
    final inputs = <LessonInput>[
      const Started(),
      names.firstWhere((o) => !o.right).input('name_quantities'),
      names.firstWhere((o) => o.right).input('name_quantities'),
      const BarADrawn(),
      const BarBPlaced(),
      const HintTaken(),
      const HintTaken(),
      const HintTaken(),
      const ItPicked('b'),
      const BarBSized(Relation.shorter),
      const PieceDropped(Piece.gap, Target.barB),
      const Undo(),
      const PieceDropped(Piece.gap, Target.gapSlot),
      const HintTaken(),
      const PieceDropped(Piece.total, Target.totalSlot),
      sums.firstWhere((o) => o.right).input('choose_operation'),
      NumberEntered(lemon.bValue),
      NumberEntered(lemon.total),
    ];
    var s = initialState();
    final events = <SpecEvent>[];
    final seen = <LessonStep>[];
    final rungs = <String?>[];
    for (final i in inputs) {
      final r = step(both, lemon, s, i);
      events.addAll(eventsFor(lemon, s, i, r, t));
      s = r.state;
      seen.add(s.step);
      rungs.addAll([
        for (final h in r.decisions.whereType<ShowHint>()) h.rung?.id,
      ]);
    }
    expect(seen.first, LessonStep.nameQuantities);
    expect(s.step, LessonStep.solved);
    expect(rungs.take(4), ['H1-3', 'H1-4', 'H1-4a', 'H1-4b']);
    // the which-it pick and the free undo are logged, never charged
    expect(s.wrong, 1);
    final back = inputsFrom(both, lemon, events);
    expect(replay(both, lemon, back), s);
    // and part way: resumed after the held drop
    final cut = events.indexWhere((e) => e.name == 'undo_used');
    final part = replay(
      both,
      lemon,
      inputsFrom(both, lemon, events.take(cut).toList()),
    );
    expect(part.misplaced, Target.barB);
    expect(part.stepHints, 0);
  });
}
