import 'package:auramath_engine/auramath_engine.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// The inputs that carry out a server decision the rules didn't take
/// (AI-04): each writes contract events, and a resume replays them.
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

  ({LessonState state, List<SpecEvent> events}) run(List<LessonInput> inputs) {
    var s = initialState();
    final events = <SpecEvent>[];
    for (final i in inputs) {
      final r = step(pack, lemon, s, i);
      events.addAll(
        eventsFor(lemon, s, i, r, (stepMs: 0, problemMs: 0, readingMs: 0)),
      );
      s = r.state;
    }
    return (state: s, events: events);
  }

  test('a side lesson the server chose opens on the step, and replays', () {
    final r = run([
      ...toFindB,
      const NumberEntered(300), // the rules: a wrong-move line
      const SideLessonChosen(SideLesson.takeAcrossTen),
    ]);
    expect(r.state.step, LessonStep.sideLesson);
    expect(r.state.returnStep, LessonStep.findB);
    expect(r.state.sideLessons, 1);
    final started = r.events.lastWhere((e) => e.name == 'side_lesson_started');
    expect(started.payload['skill_id'], 'arith.sub-3d-regroup');
    expect(replay(pack, lemon, inputsFrom(pack, lemon, r.events)), r.state);
  });

  test('a side lesson the rules opened, closed unrun: back on the step, not '
      'counted, and it replays', () {
    final r = run([
      ...toFindB,
      const NumberEntered(81), // the rules open the side lesson
      const SideLessonDone(completed: false),
      const HintTaken(afterWrong: true),
    ]);
    expect(r.state.step, LessonStep.findB);
    expect(r.state.sideLessons, 0);
    expect(r.state.hintsUsed, 1);
    final ended = r.events.singleWhere((e) => e.name == 'side_lesson_ended');
    expect(ended.payload['completed'], isFalse);
    final opened = r.events.lastWhere((e) => e.name == 'help_opened');
    expect(opened.payload['trigger'], 'after_wrong');
    expect(replay(pack, lemon, inputsFrom(pack, lemon, r.events)), r.state);
  });

  test('no side lesson past the limit, or off the board', () {
    final s = run(const [Started()]).state;
    final r = step(
      pack,
      lemon,
      s,
      const SideLessonChosen(SideLesson.addWithCarry),
    );
    expect(r.decisions, contains(isA<OpenSideLesson>()));
    final q = step(
      pack,
      lemon,
      initialState(),
      const SideLessonChosen(SideLesson.addWithCarry),
    );
    expect(q.state, same(initialState()));
    final full = s.copyWith(sideLessons: pack.maxSideLessons);
    expect(
      step(
        pack,
        lemon,
        full,
        const SideLessonChosen(SideLesson.addWithCarry),
      ).decisions,
      isEmpty,
    );
  });

  test('the codec keeps the new fields', () {
    for (final i in const <LessonInput>[
      SideLessonDone(completed: false),
      SideLessonChosen(SideLesson.addWithCarry),
      HintTaken(afterWrong: true),
      EasierTaken(afterWrong: true),
    ]) {
      expect(inputToJson(inputFromJson(inputToJson(i))), inputToJson(i));
    }
    expect(inputToJson(const SideLessonDone()), {'type': 'sideLessonDone'});
  });
}
