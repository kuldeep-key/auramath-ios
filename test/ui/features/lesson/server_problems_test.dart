import 'package:auramath/data/models/server_problem.dart';
import 'package:auramath/ui/features/lesson/view_models/lesson_view_model.dart';
import 'package:auramath/ui/features/lesson/view_models/sitting.dart';
import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../data/helpers.dart' show expectContract;
import 'fakes.dart';

void main() {
  test("a served problem becomes the engine's, its fields kept", () {
    final p = problemFromServer(served());
    expect(p.id, 'g_1');
    expect(
      (p.a.name, p.a.pic, p.b.name, p.b.pic),
      ('Lemon tree', '🍋', 'Fig tree', '🌳'),
    );
    expect((p.aValue, p.diff, p.big, p.bValue), (186, 107, BigSide.a, 79));
    expect(p.ask, Ask.total);
    expect(p.say, contains('186 centimetres tall'));
    // problem_shown carries what the server sent, so it isn't repeated
    expect(problemShown(p).payload, {
      'problem_id': 'g_1',
      'template_id': 'cmp.comparison',
      'template_version': '0.3.0',
      'story_id': 'lemon-fig',
      'relation': 'taller',
      'level': 'L4',
      'variant': 'standard',
      'numbers': {'A': 186, 'D': 107},
    });
    expect(problemFromServer(served(relation: 'shorter')).big, BigSide.b);
  });

  test('a template this app has no board for is refused, not drawn', () {
    expect(
      () => problemFromServer({...served(), 'templateId': 'td.total'}),
      throwsA(isA<Exception>()),
    );
  });

  test('a served problem is kept on the phone for a resume', () async {
    final (sessions, _, api) = await memorySessions();
    api.problems.add(served());
    await sessions.nextProblem(samplePack(), 's1');
    final restarted = samplePack();
    expect(restarted.problems['g_1'], isNull);
    await sessions.loadProblems(restarted);
    expect(restarted.problems['g_1']!.aValue, 186);
  });

  test('signing out forgets the served problems too (DEV-06)', () async {
    final (sessions, db, api) = await memorySessions();
    api.problems.add(served());
    final pack = samplePack();
    await sessions.nextProblem(pack, 's1');
    await sessions.forget();
    expect(pack.problems['g_1'], isNull);
    expect(pack.problems['lemon'], isNotNull); // the bundled ones stay
    expect(await db.problems(), isEmpty);
  });

  test('easierLevel goes one rung down, never below L1', () {
    expect(easierLevel('L4'), 'L3');
    expect(easierLevel('L1'), 'L1');
    expect(easierLevel(null), isNull);
  });

  group('a lesson on the server problems', () {
    Future<(LessonViewModel, List<(String, String?)>)> makeVm({
      String? checkLevel,
      List<Map<String, Object?>>? problems,
      Map<String, Object?>? left,
    }) async {
      final pack = samplePack();
      final (sessions, _, api) = await memorySessions(withTemplate: true);
      api
        ..checkLevel = checkLevel
        ..leftProblem = left
        ..problems.addAll(problems ?? [served()]);
      final vm = LessonViewModel(
        pack: pack,
        problemId: LessonViewModel.newProblem,
        sessions: sessions,
        voice: FakeVoice(),
        nowMs: () => 0,
        openSession: sessions.open,
        nextProblem: (s, {level}) =>
            sessions.nextProblem(pack, s, level: level),
        sitting: Sitting(capMs: 30 * 60 * 1000),
        tickEvery: null,
      );
      return (vm, api.asked);
    }

    test('opens a session, then shows the problem the server sends', () async {
      final (vm, asked) = await makeVm();
      expect(vm.ready, isFalse);
      await vm.start();
      expect(vm.ready, isTrue);
      expect(vm.problem.id, 'g_1');
      expect(asked, [(vm.sessionId, null)]);
      expect(vm.recorded, 2); // session_started, problem_shown
      vm.dispose();
    });

    /// `leftProblem` as the server sends it: `problem` is the case's
    /// `problem_shown` payload, ids and numbers only (backend, 5 Nov).
    Map<String, Object?> left({String version = '0.3.0'}) => {
      'id': 'lp_1',
      'problemId': 'g_left',
      'problem': {
        'problem_id': 'g_left',
        'template_id': 'cmp.comparison',
        'template_version': version,
        'story_id': 'lemon-fig',
        'relation': 'taller',
        'level': 'L4',
        'variant': 'standard',
        'numbers': {'A': 150, 'D': 40},
      },
      'stepId': 'find_unknown',
    };

    test('a case left on another phone is drawn from the template, offered '
        'back, and taken without asking for another (SES-06)', () async {
      final (vm, asked) = await makeVm(left: left());
      addTearDown(vm.dispose);
      await vm.start();
      expect(vm.ready, isFalse);
      expect(vm.offerLeft?.id, 'g_left');
      await vm.takeLeft(again: true);
      expect(vm.ready, isTrue);
      expect(vm.problem.aValue, 150);
      expect(vm.problem.text, contains('The lemon tree is 150 cm tall'));
      expect(asked, isEmpty);
    });

    test('"something new" instead asks the server', () async {
      final (vm, asked) = await makeVm(left: left());
      addTearDown(vm.dispose);
      await vm.start();
      await vm.takeLeft(again: false);
      expect(vm.problem.id, 'g_1');
      expect(asked, hasLength(1));
    });

    test('a left case from another template version is not offered', () async {
      final (vm, _) = await makeVm(left: left(version: '0.4.1'));
      addTearDown(vm.dispose);
      await vm.start();
      expect(vm.offerLeft, isNull);
      expect(vm.problem.id, 'g_1');
    });

    test('a spaced check due asks its level for the first problem, shown '
        'as the check', () async {
      final (vm, asked) = await makeVm(
        checkLevel: 'L2',
        problems: [
          served(),
          served(id: 'g_2'),
        ],
      );
      await vm.start();
      expect(asked.single.$2, 'L2');
      expect(vm.problem.variant, 'check');
      vm.dispose();
    });

    test('a case fetched ahead last session gives way to the check due now; '
        'the next fetch ahead is standard', () async {
      final pack = samplePack();
      final (sessions, _, api) = await memorySessions(withTemplate: true);
      api.problems.addAll([
        served(),
        served(id: 'g_2'),
        served(id: 'g_3'),
        served(id: 'g_4'),
      ]);
      // session 1, no check: its case, then the next fetched ahead
      final s1 = await sessions.open();
      await sessions.nextProblem(pack, s1);
      final ahead = await sessions.nextProblem(pack, s1);
      // session 2 opens with a check due and the case fetched ahead
      api.checkLevel = 'L2';
      final vm = LessonViewModel(
        pack: pack,
        problemId: ahead.id,
        sessions: sessions,
        voice: FakeVoice(),
        nowMs: () => 0,
        openSession: sessions.open,
        nextProblem: (s, {level}) =>
            sessions.nextProblem(pack, s, level: level),
        sitting: Sitting(capMs: 30 * 60 * 1000),
        tickEvery: null,
      );
      addTearDown(vm.dispose);
      await vm.start();
      expect(vm.problem.variant, 'check');
      expect(api.asked.last.$2, 'L2');
      // the end-of-case fetch ahead in this session isn't a check
      final next = await sessions.nextProblem(pack, vm.sessionId);
      expect(next.variant, 'standard');
    });

    test(
      'offline fetching the check: Try again still gets the check',
      () async {
        final pack = samplePack();
        final (sessions, _, api) = await memorySessions(withTemplate: true);
        api
          ..checkLevel = 'L2'
          ..problems.add(served());
        final sessionId = await sessions.open();
        api.failNext = 1; // the problem fetch, not the session
        final vm = LessonViewModel(
          pack: pack,
          problemId: LessonViewModel.newProblem,
          sessionId: sessionId,
          sessions: sessions,
          voice: FakeVoice(),
          nowMs: () => 0,
          openSession: sessions.open,
          nextProblem: (s, {level}) =>
              sessions.nextProblem(pack, s, level: level),
          sitting: Sitting(capMs: 30 * 60 * 1000),
          tickEvery: null,
        );
        addTearDown(vm.dispose);
        await vm.start();
        expect(vm.startError, isNotNull);
        await vm.start();
        expect(vm.problem.variant, 'check');
        expect(api.asked.last.$2, 'L2');
      },
    );

    test('a re-test due (retestDue) makes the first problem a check at the '
        "child's level, logged as variant check; the next is standard "
        '(SKL-06)', () async {
      final pack = samplePack();
      final (sessions, _, api) = await memorySessions(withTemplate: true);
      api
        ..retestDueAt = 1791000000000
        ..problems.addAll([served(), served(id: 'g_2')]);
      final vm = LessonViewModel(
        pack: pack,
        problemId: LessonViewModel.newProblem,
        sessions: sessions,
        voice: FakeVoice(),
        nowMs: () => 0,
        openSession: sessions.open,
        nextProblem: (s, {level}) =>
            sessions.nextProblem(pack, s, level: level),
        sitting: Sitting(capMs: 30 * 60 * 1000),
        tickEvery: null,
      );
      addTearDown(vm.dispose);
      await vm.start();
      expect(api.asked.single.$2, isNull); // the server's own level
      final shown = api.received.where((e) => e.name == 'problem_shown');
      expect(shown.single.payload['variant'], 'check');
      expectContract(api.received);
      final next = await sessions.nextProblem(pack, vm.sessionId);
      expect(next.variant, 'standard');
    });

    test('something easier asks one level down, in a new session', () async {
      final (vm, asked) = await makeVm(
        problems: [
          served(),
          served(id: 'g_easy', level: 'L3'),
        ],
      );
      await vm.start();
      final first = vm.sessionId;
      await vm.send(const Started());
      await vm.send(const EasierTaken());
      expect(vm.problem.id, 'g_easy');
      expect(vm.sessionId, isNot(first));
      expect(asked.last, (vm.sessionId, 'L3'));
      vm.dispose();
    });

    test('a solved case asks the server for the next one', () async {
      final (vm, asked) = await makeVm(
        problems: [
          served(),
          served(id: 'g_next'),
        ],
      );
      await vm.start();
      for (final i in const <LessonInput>[
        Started(),
        BarADrawn(),
        BarBPlaced(),
        BarBSized(Relation.shorter),
        PieceDropped(Piece.gap, Target.gapSlot),
        PieceDropped(Piece.total, Target.totalSlot),
        OpChosen(Op.subtract),
        NumberEntered(79),
        NumberEntered(265),
      ]) {
        await vm.send(i);
      }
      expect(vm.state.step, LessonStep.solved);
      await pumpEventQueue();
      expect(vm.nextProblemId, 'g_next');
      expect(vm.pack.problems['g_next'], isNotNull);
      vm.dispose();
    });

    test('unreachable for the next case, the next lesson asks again', () async {
      final (vm, _) = await makeVm(problems: [served()]);
      await vm.start();
      for (final i in const <LessonInput>[
        Started(),
        BarADrawn(),
        BarBPlaced(),
        BarBSized(Relation.shorter),
        PieceDropped(Piece.gap, Target.gapSlot),
        PieceDropped(Piece.total, Target.totalSlot),
        OpChosen(Op.subtract),
        NumberEntered(79),
        NumberEntered(265),
      ]) {
        await vm.send(i);
      }
      await pumpEventQueue();
      expect(vm.nextProblemId, LessonViewModel.newProblem);
      vm.dispose();
    });
  });
}
