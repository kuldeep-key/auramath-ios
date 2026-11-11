import 'package:auramath/data/repositories/session_repository.dart';
import 'package:auramath/data/services/api.dart';
import 'package:auramath/data/services/fake_api.dart';
import 'package:auramath/data/services/outbox_db.dart';
import 'package:auramath/ui/features/lesson/view_models/lesson_view_model.dart';
import 'package:auramath/ui/features/lesson/view_models/sitting.dart';
import 'package:auramath/ui/features/lesson/view_models/step_decision.dart';
import 'package:auramath_engine/auramath_engine.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../data/helpers.dart' show expectContract;
import 'fakes.dart';

/// The flag `ai_decisions`: after a wrong step the lesson shows the
/// server's help (AI-04), with the thinking cue at 1 s and the rules' help
/// at 4 s or on an error (NFR-05, app-config `ai`).
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

  /// The evaluator's answer, with its AI-02 record.
  Map<String, Object?> evaluator(
    String help, {
    String next = 'continue',
    String? skill,
    String source = 'evaluator',
  }) => {
    'action': 'continue',
    'source': source,
    'fallbackUsed': false,
    'cueAfterMs': 1000,
    'fallbackAfterMs': 4000,
    'decision': {
      'help': {'action': help, 'rung': null, 'side_lesson_skill': skill},
      'next': {'action': next, 'level': 'L4', 'level_change': 'none'},
      'fallback_used': false,
    },
  };

  late SessionRepository sessions;
  late OutboxDb db;
  late FakeApi api;
  setUp(() async {
    (sessions, db, api) = await memorySessions();
  });
  tearDown(() => db.close());

  /// A lemon lesson acting on decisions, at "find the fig tree"; [body]
  /// runs inside fake time.
  void lesson(void Function(LessonViewModel vm, FakeAsync time) body) =>
      fakeAsync((time) {
        final vm =
            LessonViewModel(
                pack: samplePack(),
                problemId: 'lemon',
                sessionId: 's1',
                sessions: sessions,
                voice: FakeVoice(),
                openSession: sessions.open,
                sitting: Sitting(capMs: 30 * 60 * 1000),
                tickEvery: null,
              )
              ..askDecisions = true
              ..actOnDecisions = true;
        for (final i in toFindB) {
          vm.send(i);
          time.flushMicrotasks();
        }
        body(vm, time);
        vm.dispose();
        time.flushMicrotasks();
      });

  String line(String id) => samplePack().lines[id]!;
  List<String> names() => [for (final e in api.received) e.name];

  test('on time: the server\'s hint shows in place of the rules\' line; '
      'find_unknown has no rung, so it offers show me how (TUT-04)', () {
    api.decideWith = (_) async => evaluator('hint');
    lesson((vm, time) {
      vm.send(const NumberEntered(300)); // the rules: "Not yet. Try ..."
      time.flushMicrotasks();
      expect(vm.thinking, isFalse);
      expect(vm.state.hintsUsed, 0);
      expect(vm.coachText, line('cmp.showMeHow'));
      final opened = api.received.lastWhere((e) => e.name == 'help_opened');
      expect(opened.payload['trigger'], 'after_wrong');
      expect(vm.wobbles, 1); // the phone's own check, once
    });
    expectContract(api.received);
  });

  test('on time: a side lesson the rules opened closes unrun for the '
      'server\'s hint, and the log replays to the same board', () {
    api.decideWith = (_) async => evaluator('hint');
    lesson((vm, time) {
      vm.send(const NumberEntered(81)); // the rules: take across a ten
      time.flushMicrotasks();
      expect(vm.state.step, LessonStep.findB);
      expect(vm.state.sideLessons, 0);
      expect(vm.coachText, line('cmp.showMeHow'));
      expect(
        api.received.lastWhere((e) => e.name == 'side_lesson_ended').payload,
        {'skill_id': 'arith.sub-3d-regroup', 'completed': false},
      );
      final pack = samplePack();
      final events = [for (final e in api.received) e.spec];
      expect(
        replay(pack, vm.problem, inputsFrom(pack, vm.problem, events)),
        vm.state,
      );
    });
    expectContract(api.received);
  });

  test('on time: the server\'s side lesson opens where the rules gave a '
      'line', () {
    api.decideWith = (_) async =>
        evaluator('side_lesson', skill: 'arith.sub-3d-regroup');
    lesson((vm, time) {
      vm.send(const NumberEntered(300));
      time.flushMicrotasks();
      expect(vm.state.step, LessonStep.sideLesson);
      expect(vm.sideLesson, SideLesson.takeAcrossTen);
      expect(names(), contains('side_lesson_started'));
    });
    expectContract(api.received);
  });

  test('TUT-08 (BE-19): a side lesson the server\'s rules open on a score '
      'drop shows, though not the evaluator\'s', () {
    api.decideWith = (_) async => {
      'action': 'side_lesson',
      'source': 'rules',
      'fallbackUsed': false,
      'trigger': 'score_drop',
      'decision': {
        'help': {
          'action': 'side_lesson',
          'rung': null,
          'side_lesson_skill': 'arith.sub-3d-regroup',
        },
        'next': {'action': 'continue'},
        'fallback_used': false,
      },
    };
    lesson((vm, time) {
      vm.send(const NumberEntered(300)); // the rules: only a line
      time.flushMicrotasks();
      expect(vm.state.step, LessonStep.sideLesson);
      expect(vm.sideLesson, SideLesson.takeAcrossTen);
      expect(
        api.received.lastWhere((e) => e.name == 'side_lesson_started').payload,
        {'skill_id': 'arith.sub-3d-regroup', 'error_type': isA<String>()},
      );
    });
    expectContract(api.received);
  });

  test('TUT-08: a score-drop detour on reading the story opens its worked '
      'example from any board step; a plain rules side lesson is not acted '
      'on', () {
    expect(
      aiChoice({
        'action': 'side_lesson',
        'source': 'rules',
        'decision': {
          'help': {
            'action': 'side_lesson',
            'side_lesson_skill': 'cmp.read-relation',
            'trigger': 'score_drop',
          },
        },
      })?.sideSkill,
      'cmp.read-relation',
    );
    expect(aiChoice({'action': 'side_lesson', 'source': 'rules'}), isNull);
    api.decideWith = (_) async => {
      'action': 'side_lesson',
      'source': 'rules',
      'trigger': 'score_drop',
      'skill': 'cmp.read-relation',
    };
    lesson((vm, time) {
      vm.send(const NumberEntered(300));
      time.flushMicrotasks();
      expect(vm.state.step, LessonStep.sideLesson);
      expect(vm.sideLesson, SideLesson.readRelation);
    });
    expectContract(api.received);
  });

  test('every help action maps to something on screen', () {
    final seen = <String, Object?>{};
    for (final help in helpActions) {
      api.decideWith = (_) async => evaluator(help);
      lesson((vm, time) {
        vm.send(const NumberEntered(300));
        time.flushMicrotasks();
        seen[help] = switch (help) {
          'show_me_how' => vm.showingExample,
          'easier' => vm.sessionId != 's1' || !vm.ready,
          'check_again' => vm.coachText == line('cmp.recheck'),
          // find_unknown has no rung: the ladder offers show me how
          'hint' => vm.coachText == line('cmp.showMeHow'),
          'side_lesson' => vm.state.step == LessonStep.sideLesson,
          // shown by their own prompts (AI-09, AI-10); off here: the rules'
          _ => vm.coachText == line('cmp.tryAgain'),
        };
      });
    }
    expect(seen.values, everyElement(isTrue), reason: '$seen');
  });

  test('next actions: a way out offered, or the break sheet; never a '
      'switch the child didn\'t choose', () {
    for (final (next, check) in <(String, bool Function(LessonViewModel))>[
      ('one_easier_then_back', (vm) => vm.tooHard && vm.stillThere),
      ('same_level_new_numbers', (vm) => vm.tooHard && vm.stillThere),
      ('end_session', (vm) => vm.askingBreak),
      ('end_case', (vm) => vm.askingBreak),
      ('next_level', (vm) => !vm.askingBreak && !vm.stillThere),
      ('continue', (vm) => !vm.askingBreak && !vm.stillThere),
    ]) {
      api.decideWith = (_) async => evaluator('none', next: next);
      lesson((vm, time) {
        vm.send(const NumberEntered(300));
        time.flushMicrotasks();
        expect(check(vm), isTrue, reason: next);
        expect(vm.problem.id, 'lemon');
      });
    }
  });

  test('slow: the thinking cue at 1 s, the rules\' help at 4 s, and the '
      'late answer changes nothing', () {
    api.decideWith = (_) =>
        Future.delayed(const Duration(seconds: 6), () => evaluator('hint'));
    lesson((vm, time) {
      vm.send(const NumberEntered(81));
      time.flushMicrotasks();
      // the phone's check shows at once; the help waits
      expect(vm.wobbles, 0); // a side lesson: no wobble, as before
      expect(vm.state.step, LessonStep.findB);
      time.elapse(const Duration(milliseconds: 999));
      expect(vm.thinking, isFalse);
      time.elapse(const Duration(milliseconds: 1));
      expect(vm.thinking, isTrue);
      time.elapse(const Duration(milliseconds: 2999));
      expect(vm.state.step, LessonStep.findB);
      time.elapse(const Duration(milliseconds: 1));
      expect(vm.thinking, isFalse);
      expect(vm.state.step, LessonStep.sideLesson); // the rules' help
      time.elapse(const Duration(seconds: 3));
      expect(vm.state.step, LessonStep.sideLesson);
      expect(vm.state.hintsUsed, 0);
    });
  });

  test('a slow upload: the cue and the rules\' help still count from the '
      'step (NFR-05)', () {
    api.decideWith = (_) =>
        Future.delayed(const Duration(seconds: 6), () => evaluator('hint'));
    lesson((vm, time) {
      api.eventsDelay = const Duration(seconds: 6);
      vm.send(const NumberEntered(81));
      time.flushMicrotasks();
      time.elapse(const Duration(seconds: 1));
      expect(vm.thinking, isTrue);
      time.elapse(const Duration(seconds: 3));
      expect(vm.thinking, isFalse);
      expect(vm.state.step, LessonStep.sideLesson); // the rules' help
      time.elapse(const Duration(seconds: 12));
      expect(vm.state.step, LessonStep.sideLesson);
    });
  });

  test('an error: the rules\' help at once, no cue', () {
    api.decideWith = (_) async =>
        throw const ApiException('throttled', status: 429);
    lesson((vm, time) {
      vm.send(const NumberEntered(300));
      time.flushMicrotasks();
      expect(vm.thinking, isFalse);
      expect(vm.coachText, line('cmp.tryAgain'));
      expect(vm.wobbles, 1);
      time.elapse(const Duration(seconds: 5));
      expect(vm.thinking, isFalse);
    });
  });

  test('the rules decided on the server too (the evaluator off or fell '
      'back): the phone\'s own help', () {
    api.decideWith = (_) async => evaluator('hint', source: 'rules');
    lesson((vm, time) {
      vm.send(const NumberEntered(81));
      time.flushMicrotasks();
      expect(vm.state.step, LessonStep.sideLesson);
      expect(vm.state.hintsUsed, 0);
    });
  });

  test('a move before the answer: the rules\' help, then the move', () {
    api.decideWith = (_) =>
        Future.delayed(const Duration(seconds: 2), () => evaluator('hint'));
    lesson((vm, time) {
      vm.send(const NumberEntered(300));
      time.flushMicrotasks();
      vm.send(const NumberEntered(79));
      time.flushMicrotasks();
      expect(vm.state.step, LessonStep.findTotal);
      time.elapse(const Duration(seconds: 3));
      expect(vm.state.hintsUsed, 0);
      expect(vm.thinking, isFalse);
    });
  });

  test('swapped digits are never the server\'s to change (LES-09)', () {
    api.decideWith = (_) async => evaluator('side_lesson');
    lesson((vm, time) {
      vm.send(const NumberEntered(97));
      time.flushMicrotasks();
      final ask = api.decisions.last.$2;
      expect(ask['allowed'], ['continue']);
      expect(vm.coachText, line('cmp.recheck'));
      expect(vm.state.step, LessonStep.findB);
    });
  });

  test('read_again (AI-09, flag on): the question lit up and read aloud, '
      'before any other help', () {
    api.decideWith = (_) async => evaluator('read_again');
    lesson((vm, time) {
      vm.readAgainPrompt = true;
      final voice = vm.voice as FakeVoice;
      vm.send(const NumberEntered(300));
      time.flushMicrotasks();
      expect(vm.prompt, TutorPrompt.readAgain);
      expect(voice.said.last, vm.problem.say);
      expect(vm.state.hintsUsed, 0);
      expect(
        api.received.lastWhere((e) => e.name == 'prompt_offered').payload,
        {'kind': 'read_again'},
      );
      expect(
        api.received.lastWhere((e) => e.name == 'read_aloud_played').payload,
        {'target': 'question'},
      );
      vm.closePrompt();
      expect(vm.prompt, isNull);
    });
    expectContract(api.received);
  });

  for (final (id, peek) in [
    ('mango', 'mango'),
    ('not-on-this-phone', null),
    (null, null),
  ]) {
    test('seen_before (AI-10, flag on) linking $id: '
        '${peek == null ? 'the prompt alone' : 'a peek at that case'}', () {
      final r = evaluator('seen_before');
      api.decideWith = (_) async => {
        ...r,
        'decision': {
          ...r['decision']! as Map<String, Object?>,
          'help': {
            'action': 'seen_before',
            if (id != null)
              'seen_before': {'problem_id': id, 'level': 'L4', 'solved_at': 1},
          },
        },
      };
      lesson((vm, time) {
        vm.seenBeforeBridge = true;
        vm.send(const NumberEntered(300));
        time.flushMicrotasks();
        expect(vm.prompt, TutorPrompt.seenBefore);
        expect(vm.seenCase?.id, peek);
        expect(
          api.received.lastWhere((e) => e.name == 'prompt_offered').payload,
          {'kind': 'seen_before', 'linked_problem_id': ?peek},
        );
      });
      expectContract(api.received);
    });
  }

  test('aiChoice reads the record; a missing or fallen-back one is the '
      'rules\'', () {
    expect(aiChoice(evaluator('read_again'))?.help, 'read_again');
    expect(aiChoice({'action': 'hint', 'source': 'evaluator'})?.help, 'hint');
    expect(aiChoice({'action': 'hint', 'source': 'rules'}), isNull);
    expect(aiChoice({...evaluator('hint'), 'fallbackUsed': true}), isNull);
    final seen = aiChoice({
      ...evaluator('seen_before'),
      'decision': {
        ...evaluator('seen_before')['decision']! as Map<String, Object?>,
        'help': {
          'action': 'seen_before',
          'seen_before': {
            'problem_id': 'mango',
            'level': 'L4',
            'solved_at': '2026-10-01T09:00:00Z',
          },
        },
      },
    });
    expect(seen?.seenBefore?.problemId, 'mango');
    expect(
      seen?.seenBefore?.solvedAt,
      DateTime.utc(2026, 10, 1, 9).millisecondsSinceEpoch,
    );
    expect(aiChoice(evaluator('seen_before'))?.seenBefore, isNull);
    expect(aiChoice(evaluator('teleport')), isNull);
  });

  test('read again and seen before come from the rules too: the server '
      'answers them as the action, whoever decided', () {
    expect(
      aiChoice({'action': 'read_again', 'source': 'rules'})?.help,
      'read_again',
    );
    final seen = aiChoice({
      'action': 'seen_before',
      'source': 'rules',
      'fallbackUsed': true,
      'decision': {
        'help': {
          'action': 'seen_before',
          'seen_before': {'problem_id': 'mango', 'solved_at': 5},
        },
      },
    });
    expect(seen?.help, 'seen_before');
    expect(seen?.seenBefore, (problemId: 'mango', solvedAt: 5));
  });

  test('a wrong step offers the prompts the app shows, so the server can '
      'give them', () {
    api.decideWith = (_) async => {
      'action': 'read_again',
      'source': 'rules',
      'fallbackUsed': false,
    };
    lesson((vm, time) {
      vm.readAgainPrompt = vm.seenBeforeBridge = true;
      vm.send(const NumberEntered(300));
      time.flushMicrotasks();
      expect(
        api.decisions.last.$2['allowed'],
        containsAll(['read_again', 'seen_before']),
      );
      expect(vm.prompt, TutorPrompt.readAgain);
    });
  });
}
