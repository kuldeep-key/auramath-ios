import 'package:auramath_engine/auramath_engine.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// Runs [inputs] from the start and returns the final state and every
/// decision made along the way.
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

const toFindB = <LessonInput>[
  Started(),
  BarADrawn(),
  BarBPlaced(),
  BarBSized(Relation.shorter),
  PieceDropped(Piece.gap, Target.gapSlot),
  PieceDropped(Piece.total, Target.totalSlot),
  OpChosen(Op.subtract),
];

Matcher coach(String lineId) =>
    isA<Coach>().having((c) => c.lineId, 'lineId', lineId);

void main() {
  test('lemon drawn clean reaches solved with tree badge and next shorter', () {
    final r = run(lemon, [
      ...toFindB,
      const NumberEntered(79),
      const NumberEntered(265),
    ]);
    expect(r.state.step, LessonStep.solved);
    final solved = r.decisions.whereType<Solved>().single;
    expect(solved.by, SolvedBy.draw);
    expect(solved.badgeId, 'tree');
    expect(solved.nextProblemId, 'shorter');
  });

  test('right fig tree coaches with the number and slots', () {
    final r = run(lemon, [...toFindB, const NumberEntered(79)]);
    expect(r.state.step, LessonStep.findTotal);
    final c = r.decisions.whereType<Coach>().last;
    expect(c.lineId, 'cmp.right');
    expect(c.slots, {
      'a': 'lemon tree',
      'b': 'fig tree',
      'B': 'Fig tree',
      'av': '186',
      'd': '107',
      'u': 'cm',
      'rel': 'shorter',
      'v': '79',
    });
  });

  test('81 opens take-across-ten side lesson and returns to findB', () {
    var r = run(lemon, [...toFindB, const NumberEntered(81)]);
    expect(r.state.step, LessonStep.sideLesson);
    expect(r.decisions, contains(coach('cmp.regrouping')));
    expect(
      r.decisions.whereType<OpenSideLesson>().single.kind,
      SideLesson.takeAcrossTen,
    );
    r = run(lemon, [
      ...toFindB,
      const NumberEntered(81),
      const SideLessonDone(),
    ]);
    expect(r.state.step, LessonStep.findB);
  });

  test('a side lesson makes the next problem the helped one', () {
    final r = run(lemon, [
      ...toFindB,
      const NumberEntered(81),
      const SideLessonDone(),
      const NumberEntered(79),
      const NumberEntered(265),
    ]);
    final solved = r.decisions.whereType<Solved>().single;
    expect(solved.badgeId, 'asker');
    expect(solved.nextProblemId, 'mango');
  });

  test('255 opens add-with-carry', () {
    final r = run(lemon, [
      ...toFindB,
      const NumberEntered(79),
      const NumberEntered(255),
    ]);
    expect(r.decisions, contains(coach('cmp.carry')));
    expect(
      r.decisions.whereType<OpenSideLesson>().single.kind,
      SideLesson.addWithCarry,
    );
    expect(r.state.returnStep, LessonStep.findTotal);
  });

  test('268 coaches recheck', () {
    final r = run(lemon, [
      ...toFindB,
      const NumberEntered(79),
      const NumberEntered(268),
    ]);
    expect(r.decisions, contains(coach('cmp.recheck')));
    expect(r.state.step, LessonStep.findTotal);
  });

  test('300 for the total coaches add both bars', () {
    final r = run(lemon, [
      ...toFindB,
      const NumberEntered(79),
      const NumberEntered(300),
    ]);
    expect(r.decisions, contains(coach('cmp.addBoth')));
  });

  test('293 coaches opposite', () {
    final r = run(lemon, [...toFindB, const NumberEntered(293)]);
    expect(r.decisions, contains(coach('cmp.opposite')));
    expect(r.decisions, contains(isA<Wobble>()));
    expect(r.state.step, LessonStep.findB);
  });

  test('two misses at findB open the side lesson', () {
    final r = run(lemon, [
      ...toFindB,
      const NumberEntered(50),
      const NumberEntered(60),
    ]);
    expect(r.decisions.whereType<OpenSideLesson>(), hasLength(1));
    expect(r.state.step, LessonStep.sideLesson);
  });

  test('two wrong moves in a row shake help', () {
    final r = run(lemon, [
      const Started(),
      const BarADrawn(),
      const BarBPlaced(),
      const BarBSized(Relation.taller),
      const BarBSized(Relation.taller),
    ]);
    expect(r.decisions.whereType<Wobble>(), hasLength(2));
    expect(r.decisions.whereType<ShakeHelp>(), hasLength(1));
    expect(r.state.wrongRow, 2);
  });

  test('bar B taller on lemon is a wrong move', () {
    final r = run(lemon, [
      const Started(),
      const BarADrawn(),
      const BarBPlaced(),
      const BarBSized(Relation.taller),
    ]);
    expect(r.state.step, LessonStep.sizeB);
    expect(r.decisions, contains(coach('cmp.sizeBWrong')));
    expect(r.state.wrong, 1);
  });

  test('same height coaches without counting a wrong move', () {
    final r = run(lemon, [
      const Started(),
      const BarADrawn(),
      const BarBPlaced(),
      const BarBSized(Relation.same),
    ]);
    expect(r.decisions, [coach('cmp.sizeB')]);
    expect(r.state.wrong, 0);
  });

  test('a right move resets the wrong-move row', () {
    final r = run(lemon, [
      const Started(),
      const BarADrawn(),
      const BarBPlaced(),
      const BarBSized(Relation.taller),
      const BarBSized(Relation.shorter),
    ]);
    expect(r.state.wrongRow, 0);
    expect(r.state.step, LessonStep.placeGap);
  });

  test('gap on a bar and total on a bar are wrong moves', () {
    var r = run(lemon, [
      ...toFindB.take(4),
      const PieceDropped(Piece.gap, Target.barB),
    ]);
    expect(r.decisions, contains(coach('cmp.gapWrong')));
    r = run(lemon, [
      ...toFindB.take(5),
      const PieceDropped(Piece.total, Target.barA),
    ]);
    expect(r.decisions, contains(coach('cmp.totalWrong')));
  });

  test('adding to find the fig tree is a wrong move', () {
    final r = run(lemon, [...toFindB.take(6), const OpChosen(Op.add)]);
    expect(r.decisions, contains(coach('cmp.opWrong')));
    expect(r.state.step, LessonStep.chooseOp);
  });

  test('shorter problem: fig is taller, so add', () {
    final r = run(shorter, [
      const Started(),
      const BarADrawn(),
      const BarBPlaced(),
      const BarBSized(Relation.taller),
      const PieceDropped(Piece.gap, Target.gapSlot),
      const PieceDropped(Piece.total, Target.totalSlot),
      const OpChosen(Op.add),
      const NumberEntered(293),
      const NumberEntered(479),
    ]);
    expect(r.state.step, LessonStep.solved);
  });

  test('283 on shorter (forgot the carry) opens add-with-carry', () {
    final r = run(shorter, [
      const Started(),
      const BarADrawn(),
      const BarBPlaced(),
      const BarBSized(Relation.taller),
      const PieceDropped(Piece.gap, Target.gapSlot),
      const PieceDropped(Piece.total, Target.totalSlot),
      const OpChosen(Op.add),
      const NumberEntered(283),
    ]);
    expect(r.decisions, contains(coach('cmp.carry')));
    expect(
      r.decisions.whereType<OpenSideLesson>().single.kind,
      SideLesson.addWithCarry,
    );
    expect(r.state.step, LessonStep.sideLesson);
  });

  test('undo from placeGap returns to sizeB', () {
    final r = run(lemon, [...toFindB.take(4), const Undo()]);
    expect(r.state.step, LessonStep.sizeB);
  });

  test('undo from chooseOp lifts the total back off', () {
    final r = run(lemon, [...toFindB.take(6), const Undo()]);
    expect(r.state.step, LessonStep.placeTotal);
    expect(r.state.totalPlaced, isFalse);
  });

  test('input not valid for step is ignored', () {
    final s = run(lemon, [const Started()]).state;
    final r = step(pack, lemon, s, const NumberEntered(79));
    expect(r.state, same(s));
    expect(r.decisions, isEmpty);
  });

  test('easier solved at findB', () {
    final r = run(easier, [
      const Started(),
      const BarADrawn(),
      const BarBPlaced(),
      const BarBSized(Relation.shorter),
      const PieceDropped(Piece.gap, Target.gapSlot),
      const OpChosen(Op.subtract),
      const NumberEntered(122),
    ]);
    expect(r.state.step, LessonStep.solved);
    expect(r.decisions.whereType<Solved>().single.by, SolvedBy.draw);
  });
}
