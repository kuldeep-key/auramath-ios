import 'dart:io';

import 'package:auramath_engine/auramath_engine.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// @LES-06: any right number is accepted at number entry, and every
/// equivalent form is accepted in the number sentence step.
final template = ComparisonTemplate.fromYaml(
  File('../../assets/spec/comparison-two-step.yaml').readAsStringSync(),
);
const t = (stepMs: 10, problemMs: 100, readingMs: 5);
const toTotal = <LessonInput>[
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

void main() {
  final on = pack.copyWith(
    template: template,
    optionalSteps: {'number_sentence'},
  );

  test('the step runs where the template lists it', () {
    final s = replay(on, lemon, toTotal);
    expect(s.step, LessonStep.numberSentence);
    expect(replay(pack, lemon, toTotal).step, LessonStep.solved);
  });

  test('every form right for "taller" is accepted, none of the others', () {
    for (final form in ['A-D=box', 'D+box=A', 'box+D=A', 'A-box=D']) {
      expect(sentenceRight(on, lemon, form), isTrue, reason: form);
      expect(sentenceRight(on, shorter, form), isFalse, reason: form);
    }
    for (final form in ['A+D=box', 'D+A=box', 'box-D=A', 'box-A=D']) {
      expect(sentenceRight(on, shorter, form), isTrue, reason: form);
    }
  });

  test('adding up solves; it is logged as number_sentence_entered', () {
    var s = replay(on, lemon, toTotal);
    final r = step(on, lemon, s, const SentenceEntered('D+box=A'));
    expect(r.state.step, LessonStep.solved);
    final e = eventsFor(lemon, s, const SentenceEntered('D+box=A'), r, t);
    expect(e.first.payload, {
      'form': 'D+box=A',
      'numbers': [107, 186],
      'correct': true,
      'ms_from_step_start': 10,
    });
    s = r.state;
  });

  test('a reversed sentence wobbles and is charged', () {
    final s = replay(on, lemon, toTotal);
    final r = step(on, lemon, s, const SentenceEntered('A+D=box'));
    expect(r.decisions, contains(isA<Wobble>()));
    expect(r.state.wrong, 1);
    final e = eventsFor(lemon, s, const SentenceEntered('A+D=box'), r, t);
    expect(e.last.payload['error_type'], 'operation_reversed');
    expect(inputsFrom(on, lemon, e).single, isA<SentenceEntered>());
  });

  test('the adding-up option at choose_operation, where turned on', () {
    final up = pack.copyWith(template: template, addingUp: true);
    final options = choiceOptions(up, lemon, 'choose_operation');
    final addUp = options.singleWhere((o) => o.id == 'd_plus_box');
    expect(addUp.label, '107 + ? = 186');
    expect(addUp.right, isTrue);
    final s = replay(up, lemon, toTotal.take(6));
    expect(
      step(up, lemon, s, addUp.input('choose_operation')).state.step,
      LessonStep.findB,
    );
    expect(
      choiceOptions(
        pack.copyWith(template: template),
        lemon,
        'choose_operation',
      ).map((o) => o.id),
      isNot(contains('d_plus_box')),
    );
  });
}
