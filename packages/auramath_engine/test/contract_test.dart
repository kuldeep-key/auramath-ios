import 'dart:convert';
import 'dart:io';

import 'package:auramath_engine/auramath_engine.dart';
import 'package:json_schema/json_schema.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// The backend's event contract, copied from spec pack v0.3.0
/// (`auramath-backend/spec/contracts/events.schema.json`).
final schema = JsonSchema.create(
  jsonDecode(File('test/contract/events.schema.json').readAsStringSync()),
);

const t = (stepMs: 1200, problemMs: 9000, readingMs: 3000);

/// Plays [inputs] and collects the spec events each one writes.
List<SpecEvent> play(ComparisonProblem p, List<LessonInput> inputs) {
  var s = initialState();
  final out = [problemShown(p)];
  for (final i in inputs) {
    final r = step(pack, p, s, i);
    out.addAll(eventsFor(p, s, i, r, t));
    s = r.state;
  }
  return out;
}

Map<String, Object?> envelope(SpecEvent e, int seq) => {
  'event_id': '00000000-0000-4000-8000-${seq.toString().padLeft(12, '0')}',
  'session_id': '5b0c3f0e-8a51-4c2e-9d3e-2f1a6c7b9e10',
  'seq': seq,
  'at': 1791400000000 + seq,
  'name': e.name,
  'child_ref': 'ch_test1234',
  'device_id': 'dv_test1234',
  'app_version': '0.1.0',
  'payload': e.payload,
};

const toFindB = <LessonInput>[
  Started(),
  BarADrawn(),
  BarBPlaced(),
  BarBSized(Relation.shorter),
  PieceDropped(Piece.gap, Target.gapSlot),
  PieceDropped(Piece.total, Target.totalSlot),
  OpChosen(Op.subtract),
];

final lessons = <String, List<LessonInput>>{
  'clean': [...toFindB, const NumberEntered(79), const NumberEntered(265)],
  'regrouping slip': [
    ...toFindB,
    const NumberEntered(81),
    const SideLessonDone(),
    const NumberEntered(79),
    const NumberEntered(265),
  ],
  'wrong moves everywhere': const [
    Started(),
    BarADrawn(),
    BarBPlaced(),
    BarBSized(Relation.taller),
    BarBSized(Relation.shorter),
    PieceDropped(Piece.gap, Target.barB),
    PieceDropped(Piece.gap, Target.gapSlot),
    PieceDropped(Piece.total, Target.barA),
    PieceDropped(Piece.total, Target.totalSlot),
    OpChosen(Op.add),
    OpChosen(Op.subtract),
    NumberEntered(107),
    NumberEntered(79),
    NumberEntered(79),
    NumberEntered(255),
    SideLessonDone(),
    NumberEntered(265),
  ],
  'I know it, checked part by part': const [
    Started(),
    KnowIt(300),
    PartChecked(79),
    KnowTotalChecked(265),
  ],
  'I know it, then drawn': const [
    Started(),
    KnowIt(300),
    PartChecked(293),
    BarADrawn(),
  ],
  'quiet, hint, undo': const [
    Started(),
    QuietFor(16000),
    HintTaken(),
    BarADrawn(),
    BarBPlaced(),
    BarBSized(Relation.shorter),
    Undo(),
    BarBSized(Relation.shorter),
  ],
};

void main() {
  test('every event a lesson writes passes the backend schema', () {
    for (final MapEntry(key: name, value: inputs) in lessons.entries) {
      final events = play(lemon, inputs);
      for (final (i, e) in events.indexed) {
        final r = schema.validate(envelope(e, i));
        expect(r.isValid, isTrue, reason: '$name: ${e.name} ${r.errors}');
      }
    }
  });

  test('the schema check rejects a broken event', () {
    final bad = envelope(
      const SpecEvent('step_committed', {'step_id': 'find_unknown'}),
      0,
    );
    expect(schema.validate(bad).isValid, isFalse);
    final unknown = envelope(const SpecEvent('bar_a_drawn', {}), 0);
    expect(schema.validate(unknown).isValid, isFalse);
  });

  test('a clean solve writes the spec sequence', () {
    final names = play(lemon, lessons['clean']!).map((e) => e.name).toList();
    expect(names.first, 'problem_shown');
    expect(names.sublist(1, 3), ['step_entered', 'object_placed']);
    expect(names.where((n) => n == 'step_committed'), hasLength(7));
    expect(names.sublist(names.length - 2), [
      'problem_completed',
      'badge_awarded',
    ]);
  });

  test('81 for the fig tree is charged to the take-away and opens its side '
      'lesson', () {
    final events = play(lemon, [...toFindB, const NumberEntered(81)]);
    final committed = events.lastWhere((e) => e.name == 'step_committed');
    expect(committed.payload, containsPair('step_id', 'find_unknown'));
    expect(committed.payload, containsPair('correct', false));
    expect(
      committed.payload,
      containsPair('error_type', 'sub_smaller_from_larger'),
    );
    expect(
      committed.payload,
      containsPair('skill_charged', 'arith.sub-3d-regroup'),
    );
    expect(events.last.name, 'side_lesson_started');
    expect(events.last.payload, {
      'skill_id': 'arith.sub-3d-regroup',
      'error_type': 'sub_smaller_from_larger',
    });
  });

  test('bar B sized taller is relation_reversed', () {
    final events = play(lemon, const [
      Started(),
      BarADrawn(),
      BarBPlaced(),
      BarBSized(Relation.taller),
    ]);
    final placed = events.lastWhere((e) => e.name == 'object_placed');
    expect(placed.payload, containsPair('relative_to_bar_a', 'longer'));
    expect(
      events.last.payload,
      containsPair('error_type', 'relation_reversed'),
    );
  });

  test(
    'on the answer sheet 293 for the fig tree is relation_reversed, drawn',
    () {
      final events = play(lemon, const [
        Started(),
        KnowIt(300),
        PartChecked(293),
      ]);
      final answered = events.lastWhere((e) => e.name == 'i_know_it_answered');
      expect(answered.payload, containsPair('stage', 'unknown'));
      expect(answered.payload, containsPair('error_type', 'relation_reversed'));
      expect(answered.payload, containsPair('route', 'draw_it'));
    },
  );

  test('a solve reports its outcome for the parent note', () {
    final done = play(
      lemon,
      lessons['regrouping slip']!,
    ).singleWhere((e) => e.name == 'problem_completed');
    expect(done.payload, {
      'problem_id': 'lemon',
      'outcome': 'with_hints',
      'working_ms': 6000,
      'reading_ms': 3000,
      'wrong_count': 0,
      'hints_used': 0,
      'drew_model': true,
      'via_i_know_it': false,
    });
  });

  test('reading the events back replays the same inputs', () {
    for (final MapEntry(key: name, value: inputs) in lessons.entries) {
      final back = inputsFrom(pack, lemon, play(lemon, inputs));
      expect(
        back.map(inputToJson).toList(),
        inputs.map(inputToJson).toList(),
        reason: name,
      );
    }
  });
}
