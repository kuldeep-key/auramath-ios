import 'dart:io';

import 'package:auramath_engine/auramath_engine.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// @LES-03: the step order comes from the template; reordering it in
/// content reorders the lesson.
final yaml = File(
  '../../assets/spec/comparison-two-step.yaml',
).readAsStringSync();

ComparisonTemplate templateWith(String yaml) =>
    ComparisonTemplate.fromYaml(yaml);

/// The template with `place_total` moved before `place_difference`.
String totalFirst(String yaml) {
  final lines = yaml.split('\n');
  final total = lines.indexWhere((l) => l.contains('{id: place_total,'));
  final gap = lines.indexWhere((l) => l.contains('{id: place_difference,'));
  final moved = lines.removeAt(total);
  lines.insert(gap, moved);
  return lines.join('\n');
}

List<LessonStep> walk(Pack pack, ComparisonProblem p) {
  final seen = <LessonStep>[];
  var s = initialState();
  const inputs = <LessonInput>[
    Started(),
    BarADrawn(),
    BarBPlaced(),
    BarBSized(Relation.shorter),
    PieceDropped(Piece.gap, Target.gapSlot),
    PieceDropped(Piece.total, Target.totalSlot),
    OpChosen(Op.subtract),
    NumberEntered(79),
    NumberEntered(265),
  ];
  // each input in turn until none moves the lesson on: the order it took
  for (var tries = 0; tries < 20 && s.step != LessonStep.solved; tries++) {
    for (final i in inputs) {
      final r = step(pack, p, s, i);
      if (r.state.step != s.step) {
        s = r.state;
        seen.add(s.step);
        break;
      }
    }
  }
  return seen;
}

void main() {
  test('the template lists the steps the engine runs, in its order', () {
    final t = templateWith(yaml);
    expect(t.stepsFor('L4'), [
      'draw_known_bar',
      'size_second_bar',
      'place_difference',
      'place_total',
      'choose_operation',
      'find_unknown',
      'find_total',
    ]);
    // levels 1 and 2 skip place_total and end at the unknown
    expect(t.stepsFor('L1'), isNot(contains('place_total')));
    expect(t.stepsFor('L1'), isNot(contains('find_total')));
    // optional steps only where they are turned on
    expect(t.stepsFor('L4'), isNot(contains('name_quantities')));
  });

  test('with the bundled template the lesson runs as before', () {
    final p = pack.copyWith(template: templateWith(yaml));
    expect(walk(p, lemon), [
      LessonStep.drawA,
      LessonStep.placeB,
      LessonStep.sizeB,
      LessonStep.placeGap,
      LessonStep.placeTotal,
      LessonStep.chooseOp,
      LessonStep.findB,
      LessonStep.findTotal,
      LessonStep.solved,
    ]);
  });

  test('place_total moved before place_difference: the total comes first', () {
    final p = pack.copyWith(template: templateWith(totalFirst(yaml)));
    final order = walk(p, lemon);
    expect(
      order.indexOf(LessonStep.placeTotal),
      lessThan(order.indexOf(LessonStep.placeGap)),
    );
    expect(order.last, LessonStep.solved);
    // and Undo takes back the step before, in that order
    var s = replay(p, lemon, const [
      Started(),
      BarADrawn(),
      BarBPlaced(),
      BarBSized(Relation.shorter),
      PieceDropped(Piece.total, Target.totalSlot),
    ]);
    expect(s.step, LessonStep.placeGap);
    s = step(p, lemon, s, const Undo()).state;
    expect(s.step, LessonStep.placeTotal);
    expect(s.totalPlaced, isFalse);
  });

  test('a problem with no template keeps the engine\'s own order', () {
    expect(lessonSteps(pack, lemon).first, LessonStep.drawA);
    expect(lessonSteps(pack, easier), isNot(contains(LessonStep.findTotal)));
  });
}
