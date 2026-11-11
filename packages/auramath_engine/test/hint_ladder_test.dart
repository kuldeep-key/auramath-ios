import 'dart:io';

import 'package:auramath_engine/auramath_engine.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// Julia's ladder, as the app bundles it.
final policy = Policy.fromYaml(
  File('../../assets/spec/policy.yaml').readAsStringSync(),
);
final template = ComparisonTemplate.fromYaml(
  File('../../assets/spec/comparison-two-step.yaml').readAsStringSync(),
);
final laddered = pack.copyWith(
  hintLadder: policy.hintLadder,
  hintStart: template.hintStart,
);

({LessonState state, List<Decision> decisions, List<SpecEvent> events}) run(
  List<LessonInput> inputs, {
  ComparisonProblem? p,
}) {
  final problem = p ?? lemon;
  var s = initialState();
  final all = <Decision>[];
  final events = <SpecEvent>[];
  for (final i in inputs) {
    final r = step(laddered, problem, s, i);
    events.addAll(
      eventsFor(problem, s, i, r, (stepMs: 0, problemMs: 0, readingMs: 0)),
    );
    s = r.state;
    all.addAll(r.decisions);
  }
  return (state: s, decisions: all, events: events);
}

List<String?> rungs(List<Decision> d) => [
  for (final h in d.whereType<ShowHint>()) h.rung?.id,
];

const _toSizeB = [Started(), BarADrawn(), BarBPlaced()];

void main() {
  test("the template's start rungs are the policy's first rung per step", () {
    expect(template.hintStart, {
      'draw_known_bar': 'H1-1',
      'size_second_bar': 'H1-3',
      'place_difference': 'H1-5',
      'choose_operation': 'D4w',
    });
    for (final MapEntry(:key, :value) in template.hintStart.entries) {
      expect(laddered.rungsFor(key).first.id, value);
    }
  });

  test('on draw_known_bar: H1-1, H1-2, the everyday example, then show me '
      'how', () {
    final r = run([
      const Started(),
      for (var i = 0; i < 4; i++) const HintTaken(),
    ]);
    expect(rungs(r.decisions), ['H1-1', 'H1-2', 'H1-6']);
    expect(r.decisions.last, isA<SuggestShowMeHow>());
    expect(r.state.hintsUsed, 3);
  });

  test('size_second_bar starts at H1-3, not H1-1 (TUT-04 acceptance)', () {
    final r = run([..._toSizeB, const HintTaken()]);
    expect(rungs(r.decisions), ['H1-3']);
    final shown = r.events.singleWhere((e) => e.name == 'hint_shown');
    expect(shown.payload, {
      'step_id': 'size_second_bar',
      'rung_id': 'H1-3',
      'line_id': 'line.hint.now-b',
      'model_used': false,
    });
  });

  test('a new step starts its own ladder', () {
    final r = run([
      const Started(),
      const HintTaken(),
      const BarADrawn(),
      const BarBPlaced(),
      const HintTaken(),
      const BarBSized(Relation.shorter),
      const HintTaken(),
    ]);
    expect(rungs(r.decisions), ['H1-1', 'H1-3', 'H1-5']);
  });

  test('a step with no rung offers show me how, and charges no hint', () {
    final r = run([
      ..._toSizeB,
      const BarBSized(Relation.shorter),
      const PieceDropped(Piece.gap, Target.gapSlot),
      const HintTaken(),
    ]);
    expect(r.state.step, LessonStep.placeTotal);
    expect(r.decisions.last, isA<SuggestShowMeHow>());
    expect(r.state.hintsUsed, 0);
    expect(r.events.where((e) => e.name == 'hint_shown'), isEmpty);
    expect(hasHint(laddered, LessonStep.placeTotal), isFalse);
    expect(hasHint(laddered, LessonStep.findB), isFalse);
    expect(hasHint(laddered, LessonStep.sizeB), isTrue);
    expect(hasHint(pack, LessonStep.findB), isTrue, reason: 'flat list');
  });

  test('choose_operation starts at D4w', () {
    final r = run([
      ..._toSizeB,
      const BarBSized(Relation.shorter),
      const PieceDropped(Piece.gap, Target.gapSlot),
      const PieceDropped(Piece.total, Target.totalSlot),
      const HintTaken(),
    ]);
    expect(rungs(r.decisions), ['D4w']);
  });

  test('a resumed lesson replays its rungs from the log', () {
    final inputs = [..._toSizeB, const HintTaken(), const HintTaken()];
    final r = run(inputs);
    final back = replay(laddered, lemon, inputsFrom(laddered, lemon, r.events));
    expect(back, r.state);
    expect(back.stepHints, 2);
  });
}
