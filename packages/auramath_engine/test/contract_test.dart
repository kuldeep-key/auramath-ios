import 'dart:convert';
import 'dart:io';

import 'package:auramath_engine/auramath_engine.dart';
import 'package:json_schema/json_schema.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// The backend's event contract, copied from spec pack v0.5.4
/// (`auramath-backend/spec/contracts/events.schema.json`), with the
/// problem_id fields D-54 and D-55 add (search the copy for "App copy only").
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
    // the server writes badge_awarded (D-54): never the phone
    expect(names.last, 'problem_completed');
    expect(names, isNot(contains('badge_awarded')));
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
      'problem_id': 'lemon',
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

  test('an easier one offered for no progress says so, and reads back', () {
    final inputs = [...toFindB, const EasierTaken(noProgress: true)];
    final events = play(lemon, inputs);
    final chosen = events.singleWhere((e) => e.name == 'easier_chosen');
    expect(chosen.payload['trigger'], 'no_progress');
    expect(
      inputsFrom(pack, lemon, events).map(inputToJson).toList(),
      inputs.map(inputToJson).toList(),
    );
  });

  group('v0.5.4 (D-54, D-55, JRN-07, TTR-03, REW-11 to REW-20)', () {
    bool valid(SpecEvent e) => schema.validate(envelope(e, 0)).isValid;
    const look = (
      avatarId: 'look_03',
      tutorId: 'robot',
      voiceId: 'voice_c',
      world: 'detective',
    );

    test('no lesson ever writes badge_awarded', () {
      for (final MapEntry(key: name, value: inputs) in lessons.entries) {
        expect(
          play(lemon, inputs).map((e) => e.name),
          isNot(contains('badge_awarded')),
          reason: name,
        );
      }
    });

    test('session_started carries the look and is_test, and passes', () {
      final e = sessionStarted(
        launchSource: 'child_opened',
        contentVersions: const {'policy': '0.5.4'},
        isDemo: false,
        look: look,
      );
      expect(e.payload['is_test'], isFalse);
      expect(e.payload['look'], {
        'avatar_id': 'look_03',
        'tutor_id': 'robot',
        'voice_id': 'voice_c',
        'world': 'detective',
      });
      expect(valid(e), isTrue);
      // without its look the backend refuses it (required from v0.5.4)
      expect(
        valid(
          const SpecEvent('session_started', {
            'launch_source': 'child_opened',
            'content_versions': {},
            'is_demo': false,
          }),
        ),
        isFalse,
      );
    });

    test('an unknown world is sent as Detective, the one the child sees', () {
      final e = sessionStarted(
        launchSource: 'unknown',
        contentVersions: const {},
        isDemo: true,
        look: (
          avatarId: 'look_01',
          tutorId: 'teacher_1',
          voiceId: 'voice_a',
          world: 'pirates',
        ),
      );
      expect((e.payload['look']! as Map)['world'], 'detective');
      expect(valid(e), isTrue);
    });

    test('read_aloud_played says how it started and if it was cut short', () {
      final auto = readAloudPlayed(
        target: 'line',
        trigger: ReadTrigger.auto,
        stoppedEarly: true,
        lineId: 'line.home.greeting',
      );
      expect(auto.payload, {
        'target': 'line',
        'trigger': 'auto',
        'stopped_early': true,
        'line_id': 'line.home.greeting',
      });
      expect(valid(auto), isTrue);
      // an app line has no library id: none is sent
      final tap = readAloudPlayed(
        target: 'hint',
        trigger: ReadTrigger.tap,
        stoppedEarly: false,
        lineId: 'cmp.welcomeBack',
      );
      expect(tap.payload.containsKey('line_id'), isFalse);
      expect(valid(tap), isTrue);
      expect(
        valid(const SpecEvent('read_aloud_played', {'target': 'question'})),
        isFalse,
      );
    });

    test('badge_shown, badge_opened, cabinet_opened, trail_opened pass', () {
      final shown = badgeShown(
        'stop.orchard.l1',
        queued: true,
        problemId: 'lemon',
      );
      expect(shown.payload, {
        'badge_id': 'stop.orchard.l1',
        'queued': true,
        'problem_id': 'lemon',
      });
      expect(badgeShown('session.all_by_myself').payload, {
        'badge_id': 'session.all_by_myself',
        'queued': false,
      });
      for (final e in [
        shown,
        badgeShown('session.all_by_myself'),
        badgeOpened('first_case', from: BadgeOpenedFrom.cabinet),
        badgeOpened(
          'land.orchard',
          from: BadgeOpenedFrom.celebration,
          openedCase: false,
        ),
        cabinetOpened(3),
        trailOpened,
      ]) {
        expect(valid(e), isTrue, reason: e.name);
      }
    });

    test('celebration_shown passes for every moment, kept in range', () {
      for (final m in celebrationMoments) {
        final e = celebrationShown(
          moment: m,
          variant: 2,
          world: 'detective',
          ms: 1200,
          skipped: false,
          reducedMotion: true,
        );
        expect(valid(e), isTrue, reason: m);
      }
      final odd = celebrationShown(
        moment: 'case_solved',
        variant: 99,
        world: 'nowhere',
        ms: -5,
        skipped: true,
        reducedMotion: false,
      );
      expect(odd.payload['variant'], 20);
      expect(odd.payload['world'], 'detective');
      expect(odd.payload['ms'], 0);
    });

    test('celebration versions rotate and never repeat the last', () {
      var last = nextVariant(null, 3);
      expect(last, 1);
      final seen = [last];
      for (var i = 0; i < 6; i++) {
        final next = nextVariant(last, 3);
        expect(next, isNot(last));
        seen.add(last = next);
      }
      expect(seen, [1, 2, 3, 1, 2, 3, 1]);
      expect(nextVariant(1, 1), 1);
      expect(nextVariant(7, 3), 1); // fewer versions than before
    });

    test('D-55: problem_shown always has its level and variant', () {
      final e = play(lemon, const []).single;
      expect(e.payload['level'], 'L4');
      expect(e.payload['variant'], 'standard');
    });

    test('D-55: side lessons name their case, started and ended', () {
      final events = play(lemon, lessons['regrouping slip']!);
      final side = events.where((e) => e.name.startsWith('side_lesson_'));
      expect(side.map((e) => e.name), [
        'side_lesson_started',
        'side_lesson_ended',
      ]);
      for (final e in side) {
        expect(e.payload['problem_id'], 'lemon', reason: e.name);
      }
      final abandoned = play(lemon, [
        ...toFindB,
        const NumberEntered(81),
        const SideLessonAbandoned(),
      ]).lastWhere((e) => e.name == 'side_lesson_ended');
      expect(abandoned.payload['problem_id'], 'lemon');
    });

    test('D-55: help_opened always says why, idle prompts their step', () {
      final events = play(lemon, lessons['quiet, hint, undo']!);
      for (final e in events.where((e) => e.name == 'help_opened')) {
        expect(e.payload['trigger'], isNotNull);
      }
      final idle = events.where((e) => e.name == 'idle_prompt_shown');
      expect(idle, isNotEmpty);
      for (final e in idle) {
        expect(e.payload['step_id'], isNotNull);
      }
    });

    test('D-55: show me how fills the steps in with no step_committed, and '
        'the case reports via_i_know_it', () {
      final events = play(lemon, const [
        Started(),
        BarADrawn(),
        ShowMeHowTaken(),
        ExampleDone(),
      ]);
      final afterHow = events.skipWhile(
        (e) => e.name != 'worked_example_shown',
      );
      expect(afterHow.map((e) => e.name), isNot(contains('step_committed')));
      final done = events.singleWhere((e) => e.name == 'problem_completed');
      expect(done.payload['via_i_know_it'], isFalse);
    });
  });
}
