import 'dart:io';

import 'package:auramath_engine/auramath_engine.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// @LES-03 @LES-12: a problem the server serves with its steps runs them
/// in the server's order and offers the server's options; without them,
/// the template's.
final template = ComparisonTemplate.fromYaml(
  File('../../assets/spec/comparison-two-step.yaml').readAsStringSync(),
);

ComparisonProblem withSteps(ComparisonProblem p, List<ServedStep> steps) =>
    ComparisonProblem(
      id: p.id,
      a: p.a,
      b: p.b,
      aValue: p.aValue,
      diff: p.diff,
      big: p.big,
      unit: p.unit,
      ask: p.ask,
      text: p.text,
      say: p.say,
      next: p.next,
      templateId: p.templateId,
      templateVersion: p.templateVersion,
      storyId: p.storyId,
      variant: p.variant,
      level: p.level,
      steps: steps,
    );

const nameIt = ServedStep(
  id: 'name_quantities',
  optional: true,
  options: [
    ServedOption(id: 'opt_D', text: '107 cm', correct: false),
    ServedOption(id: 'opt_A', text: '186 cm', correct: true),
  ],
);

/// As `problems/next` serves it, with place_total moved first.
final served = [
  nameIt,
  const ServedStep(id: 'draw_known_bar'),
  const ServedStep(id: 'size_second_bar'),
  const ServedStep(id: 'place_total'),
  const ServedStep(id: 'place_difference'),
  const ServedStep(
    id: 'choose_operation',
    options: [
      ServedOption(id: 'a_minus_d', text: 'A - D', correct: true),
      ServedOption(id: 'a_plus_d', text: 'A + D', correct: false),
    ],
  ),
  const ServedStep(id: 'find_unknown'),
  const ServedStep(id: 'find_total'),
  const ServedStep(id: 'a_step_from_later', optional: false),
];

void main() {
  final withTemplate = pack.copyWith(template: template);

  test('the server\'s step order wins over the template\'s', () {
    final p = withSteps(lemon, served);
    expect(lessonSteps(withTemplate, p), [
      LessonStep.drawA,
      LessonStep.placeB,
      LessonStep.sizeB,
      LessonStep.placeTotal,
      LessonStep.placeGap,
      LessonStep.chooseOp,
      LessonStep.findB,
      LessonStep.findTotal,
    ]);
    // the template's own order without the server's steps
    expect(
      lessonSteps(withTemplate, lemon).indexOf(LessonStep.placeGap),
      lessThan(lessonSteps(withTemplate, lemon).indexOf(LessonStep.placeTotal)),
    );
  });

  test('a served optional step runs only where the pack turns it on', () {
    final p = withSteps(lemon, served);
    final on = withTemplate.copyWith(optionalSteps: {'name_quantities'});
    expect(lessonSteps(on, p).first, LessonStep.nameQuantities);
    expect(
      lessonSteps(withTemplate, p),
      isNot(contains(LessonStep.nameQuantities)),
    );
  });

  test('a problem that asks only for b still skips the total', () {
    final p = withSteps(easier, served);
    expect(
      lessonSteps(withTemplate, p),
      isNot(contains(LessonStep.placeTotal)),
    );
    expect(lessonSteps(withTemplate, p), isNot(contains(LessonStep.findTotal)));
  });

  test('choices are the server\'s, in its order, with its right one', () {
    final p = withSteps(lemon, served);
    final ops = choiceOptions(withTemplate, p, 'choose_operation');
    expect(ops.map((o) => o.id), ['a_minus_d', 'a_plus_d']);
    expect(ops.map((o) => o.label), ['186 − 107', '186 + 107']);
    expect(ops.map((o) => o.right), [true, false]);
    expect(ops.map((o) => o.op), [Op.subtract, Op.add]);
    // a wrong pick is still charged as the template names it
    expect(ops.last.errorType, 'operation_reversed');

    final names = choiceOptions(withTemplate, p, 'name_quantities');
    expect(names.map((o) => (o.id, o.label, o.right)), [
      ('opt_D', '107 cm', false),
      ('opt_A', '186 cm', true),
    ]);
  });

  test('the server\'s right option is what the engine accepts', () {
    final p = withSteps(lemon, served);
    var s = initialState();
    for (final i in const <LessonInput>[
      Started(),
      BarADrawn(),
      BarBPlaced(),
      BarBSized(Relation.shorter),
      PieceDropped(Piece.total, Target.totalSlot),
      PieceDropped(Piece.gap, Target.gapSlot),
    ]) {
      s = step(withTemplate, p, s, i).state;
    }
    expect(s.step, LessonStep.chooseOp);
    final right = choiceOptions(
      withTemplate,
      p,
      'choose_operation',
    ).firstWhere((o) => o.right);
    s = step(withTemplate, p, s, right.input('choose_operation')).state;
    expect(s.step, LessonStep.findB);
  });
}
