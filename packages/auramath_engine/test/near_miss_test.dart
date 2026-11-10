import 'package:auramath_engine/auramath_engine.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// @LES-09: swapped digits are a check, not a lesson. The recheck line
/// only: no wrong count, no side lesson, the next problem unchanged.
void main() {
  const toFindB = <LessonInput>[
    Started(),
    BarADrawn(),
    BarBPlaced(),
    BarBSized(Relation.shorter),
    PieceDropped(Piece.gap, Target.gapSlot),
    PieceDropped(Piece.total, Target.totalSlot),
    OpChosen(Op.subtract),
  ];

  /// Runs [inputs], with every decision and every event they write.
  ({LessonState state, List<Decision> decisions, List<SpecEvent> events}) run(
    List<LessonInput> inputs,
  ) {
    var s = initialState();
    final decisions = <Decision>[];
    final events = <SpecEvent>[];
    for (final i in inputs) {
      final r = step(pack, lemon, s, i);
      events.addAll(
        eventsFor(lemon, s, i, r, (stepMs: 0, problemMs: 0, readingMs: 0)),
      );
      s = r.state;
      decisions.addAll(r.decisions);
    }
    return (state: s, decisions: decisions, events: events);
  }

  Matcher coach(String id) => isA<Coach>().having((c) => c.lineId, 'id', id);

  test('97 for the fig tree (79): the recheck line, nothing counted', () {
    final r = run([...toFindB, const NumberEntered(97)]);
    expect(r.decisions, [coach('cmp.recheck')]);
    expect(r.state.step, LessonStep.findB);
    expect(r.state.wrong, 0);
    expect(r.state.wrongRow, 0);
    expect(r.state.findBWrong, 0);
  });

  test('97 twice still opens no side lesson', () {
    final r = run([
      ...toFindB,
      const NumberEntered(97),
      const NumberEntered(97),
    ]);
    expect(r.decisions.whereType<OpenSideLesson>(), isEmpty);
    expect(r.decisions.whereType<ShakeHelp>(), isEmpty);
    expect(r.state.sideLessons, 0);
  });

  test('256 for the total (265): "Check your sum again.", then 265 is a '
      'clean solve with the usual next problem', () {
    final r = run([
      ...toFindB,
      const NumberEntered(79),
      const NumberEntered(256),
    ]);
    expect(r.decisions.last, coach('cmp.recheck'));
    expect(r.state.wrong, 0);

    final fixed = run([
      ...toFindB,
      const NumberEntered(97),
      const NumberEntered(79),
      const NumberEntered(256),
      const NumberEntered(265),
    ]);
    final solved = fixed.decisions.whereType<Solved>().single;
    expect(solved.badgeId, 'tree');
    expect(solved.nextProblemId, lemon.next.fast);
    final done = fixed.events.lastWhere((e) => e.name == 'problem_completed');
    expect(done.payload['outcome'], 'solved_alone');
    expect(done.payload['wrong_count'], 0);
    // the log still says what was typed, as a transposition
    expect(
      fixed.events
          .where((e) => e.name == 'step_committed')
          .map((e) => e.payload['error_type'])
          .whereType<String>(),
      ['transposition', 'transposition'],
    );
  });

  test('on the answer sheet: swapped digits recheck without counting', () {
    final part = run([
      const Started(),
      const KnowIt(300),
      const PartChecked(97),
    ]);
    expect(part.decisions.last, isA<OpenRecheck>());
    expect(part.state.wrong, 0);

    final total = run([const Started(), const KnowIt(562)]);
    expect(total.decisions.single, isA<OpenRecheck>());
    expect(total.state.wrong, 0);
    expect(total.state.step, LessonStep.drawA);
  });

  test('a near miss that is not swapped digits still counts', () {
    final r = run([
      ...toFindB,
      const NumberEntered(79),
      const NumberEntered(268),
    ]);
    expect(r.decisions, contains(coach('cmp.recheck')));
    expect(r.state.wrong, 1);
  });
}
