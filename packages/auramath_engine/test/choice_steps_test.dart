import 'dart:io';

import 'package:auramath_engine/auramath_engine.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// @LES-12: choose_operation (R1) and name_quantities (M3) offer the
/// template's options; a wrong option is recorded with its error type.
final template = ComparisonTemplate.fromYaml(
  File('../../assets/spec/comparison-two-step.yaml').readAsStringSync(),
);
const t = (stepMs: 10, problemMs: 100, readingMs: 5);

List<SpecEvent> play(Pack pack, List<LessonInput> inputs) {
  var s = initialState();
  final out = <SpecEvent>[];
  for (final i in inputs) {
    final r = step(pack, lemon, s, i);
    out.addAll(eventsFor(lemon, s, i, r, t));
    s = r.state;
  }
  return out;
}

void main() {
  final withTemplate = pack.copyWith(template: template);
  const toChoose = <LessonInput>[
    Started(),
    BarADrawn(),
    BarBPlaced(),
    BarBSized(Relation.shorter),
    PieceDropped(Piece.gap, Target.gapSlot),
    PieceDropped(Piece.total, Target.totalSlot),
  ];

  test('choose_operation offers the template\'s sums in its order', () {
    final options = choiceOptions(withTemplate, lemon, 'choose_operation');
    expect(options.map((o) => o.id), ['a_plus_d', 'a_minus_d']);
    expect(options.map((o) => o.label), ['186 + 107', '186 − 107']);
    expect(options.map((o) => o.right), [false, true]);
  });

  test('a wrong option is charged with the template\'s error type', () {
    final wrong = choiceOptions(
      withTemplate,
      lemon,
      'choose_operation',
    ).firstWhere((o) => !o.right).input('choose_operation');
    final events = play(withTemplate, [...toChoose, wrong]);
    expect(events.where((e) => e.name == 'choice_selected').single.payload, {
      'step_id': 'choose_operation',
      'option_id': 'a_plus_d',
      'ms_from_step_start': 10,
    });
    expect(
      events.lastWhere((e) => e.name == 'step_committed').payload['error_type'],
      'operation_reversed',
    );
    // and it reads back as the same choice
    final back = inputsFrom(withTemplate, lemon, events).last as OpChosen;
    expect(back.optionId, 'a_plus_d');
  });

  group('name_quantities, turned on (M3)', () {
    final on = withTemplate.copyWith(optionalSteps: {'name_quantities'});

    test('comes first, from the template\'s order', () {
      expect(lessonSteps(on, lemon).first, LessonStep.nameQuantities);
      final options = choiceOptions(on, lemon, 'name_quantities');
      expect(options.map((o) => o.label), ['186 cm', '107 cm']);
      expect(options.map((o) => o.right), [true, false]);
    });

    test('the difference for the height is difference_as_amount', () {
      final options = choiceOptions(on, lemon, 'name_quantities');
      final events = play(on, [
        const Started(),
        options.last.input('name_quantities'),
        options.first.input('name_quantities'),
      ]);
      final commits = [
        for (final e in events)
          if (e.name == 'step_committed') e.payload,
      ];
      expect(commits.first['error_type'], 'difference_as_amount');
      expect(commits.last['correct'], isTrue);
      final s = replay(on, lemon, inputsFrom(on, lemon, events));
      expect(s.step, LessonStep.drawA);
      expect(s.wrong, 1);
    });

    test('the template\'s opt_A and opt_D are sent lower case, as the '
        'events schema asks, and replay either way', () {
      final options = choiceOptions(on, lemon, 'name_quantities');
      final events = play(on, [
        const Started(),
        options.last.input('name_quantities'),
        options.first.input('name_quantities'),
      ]);
      final ids = [
        for (final e in events)
          if (e.name == 'choice_selected') e.payload['option_id'],
      ];
      expect(ids, ['opt_d', 'opt_a']);
      for (final id in ids) {
        expect(RegExp(r'^[a-z0-9][a-z0-9._-]{0,63}$').hasMatch('$id'), isTrue);
      }
      // a phone's events saved before, with the template's own case
      final saved = [
        for (final e in events)
          e.name == 'choice_selected'
              ? SpecEvent(e.name, {
                  ...e.payload,
                  'option_id': '${e.payload['option_id']}'.toUpperCase(),
                })
              : e,
      ];
      expect(
        replay(on, lemon, inputsFrom(on, lemon, saved)).step,
        LessonStep.drawA,
      );
    });
  });
}
