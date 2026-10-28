import 'package:auramath_engine/auramath_engine.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

({LessonState state, List<Decision> decisions}) run(
  ComparisonProblem p,
  List<LessonInput> inputs,
) {
  var s = initialState();
  final all = <Decision>[];
  for (final i in inputs) {
    final r = step(pack, p, s, i);
    s = r.state;
    all.addAll(r.decisions);
  }
  return (state: s, decisions: all);
}

const start = <LessonInput>[Started()];

void main() {
  test('know 265 solves as know', () {
    final r = run(lemon, [...start, const KnowIt(265)]);
    expect(r.state.step, LessonStep.solved);
    expect(r.decisions.whereType<Solved>().single.by, SolvedBy.know);
  });

  test('a checked total after drawing A also solves as partway', () {
    final r = run(lemon, [
      ...start,
      const BarADrawn(),
      const KnowIt(300),
      const PartChecked(79),
      const KnowTotalChecked(265),
    ]);
    expect(r.decisions.whereType<Solved>().single.by, SolvedBy.partway);
  });

  test('know 265 after drawing A solves as partway', () {
    final r = run(lemon, [...start, const BarADrawn(), const KnowIt(265)]);
    expect(r.decisions.whereType<Solved>().single.by, SolvedBy.partway);
  });

  test('know 79 asks what the question asks, then 265 solves', () {
    var r = run(lemon, [...start, const KnowIt(79)]);
    expect(r.decisions.single, isA<AskWhatQuestionAsks>());
    expect(r.state.knowFlow, KnowFlow.askingWhat);
    r = run(lemon, [...start, const KnowIt(79), const KnowIt(265)]);
    expect(r.state.step, LessonStep.solved);
  });

  test('know 268 opens recheck', () {
    final r = run(lemon, [...start, const KnowIt(268)]);
    expect(r.decisions.single, isA<OpenRecheck>());
    expect(r.state.step, LessonStep.drawA);
  });

  test('know 255 (dropped carry) checks one part instead of recheck', () {
    final r = run(lemon, [...start, const KnowIt(255)]);
    expect(r.decisions.single, isA<CheckOnePart>());
  });

  test('know 300 checks one part then 81 opens side lesson', () {
    var r = run(lemon, [...start, const KnowIt(300)]);
    expect(r.decisions.single, isA<CheckOnePart>());
    expect(r.state.knowFlow, KnowFlow.checkingPart);
    r = run(lemon, [...start, const KnowIt(300), const PartChecked(81)]);
    expect(
      r.decisions.whereType<OpenSideLesson>().single.kind,
      SideLesson.takeAcrossTen,
    );
    expect(r.state.step, LessonStep.sideLesson);
    expect(r.state.knowFlow, KnowFlow.none);
  });

  test('part 79 then total 265 solves', () {
    final r = run(lemon, [
      ...start,
      const KnowIt(300),
      const PartChecked(79),
      const KnowTotalChecked(265),
    ]);
    expect(
      r.decisions.whereType<Coach>().map((c) => c.lineId),
      contains('cmp.partRight'),
    );
    expect(r.decisions.whereType<Solved>().single.by, SolvedBy.know);
  });

  test('part right then dropped carry opens add-with-carry', () {
    final r = run(lemon, [
      ...start,
      const KnowIt(300),
      const PartChecked(79),
      const KnowTotalChecked(255),
    ]);
    expect(
      r.decisions.whereType<OpenSideLesson>().single.kind,
      SideLesson.addWithCarry,
    );
  });

  test('part 107 sends to draw with two-bars line', () {
    final r = run(lemon, [
      ...start,
      const BarADrawn(),
      const KnowIt(300),
      const PartChecked(107),
    ]);
    expect(
      r.decisions.whereType<Coach>().map((c) => c.lineId),
      contains('cmp.twoBars'),
    );
    expect(r.decisions, contains(isA<DrawIt>()));
    expect(r.state.step, LessonStep.drawA);
    expect(r.state.barA, isFalse);
    expect(r.state.wrong, 1);
  });

  test('part 293 sends to draw with the draw-it line', () {
    final r = run(lemon, [...start, const KnowIt(300), const PartChecked(293)]);
    expect(
      r.decisions.whereType<Coach>().map((c) => c.lineId),
      contains('cmp.drawIt'),
    );
  });

  test('part 97 (swapped digits) opens recheck', () {
    final r = run(lemon, [...start, const KnowIt(300), const PartChecked(97)]);
    expect(r.decisions, contains(isA<OpenRecheck>()));
    expect(r.state.knowFlow, KnowFlow.checkingPart);
  });

  test('easier know 122 solves, 120 draws it', () {
    var r = run(easier, [...start, const KnowIt(122)]);
    expect(r.decisions.whereType<Solved>().single.by, SolvedBy.know);
    r = run(easier, [...start, const KnowIt(120)]);
    expect(r.decisions.single, isA<DrawIt>());
    expect(r.state.wrong, 1);
  });

  test('know it is ignored on the question screen and when solved', () {
    final s = initialState();
    expect(step(pack, lemon, s, const KnowIt(265)).state, same(s));
  });

  test('part checks are ignored outside checking a part', () {
    final s = run(lemon, start).state;
    expect(step(pack, lemon, s, const PartChecked(79)).state, same(s));
  });
}
