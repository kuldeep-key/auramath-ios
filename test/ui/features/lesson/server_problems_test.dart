import 'package:auramath/data/models/server_problem.dart';
import 'package:auramath/ui/features/lesson/view_models/lesson_view_model.dart';
import 'package:auramath/ui/features/lesson/view_models/sitting.dart';
import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

/// `problems/next` as the dev server answered it (integration guide, 4 Nov).
Map<String, Object?> served({
  String id = 'g_1',
  String level = 'L4',
  String relation = 'taller',
  int a = 186,
  int d = 107,
}) => {
  'problemId': id,
  'templateId': 'cmp.comparison',
  'templateVersion': '0.3.0',
  'storyId': 'lemon-fig',
  'relation': relation,
  'level': level,
  'variant': 'standard',
  'numbers': {'A': a, 'D': d},
  'story': {
    'a': 'lemon tree',
    'b': 'fig tree',
    'kind': 'tree',
    'plural': 'trees',
    'unit': 'cm',
    'quantity': 'height',
  },
  'questionText':
      'The lemon tree is $a cm tall. It is $d cm $relation than the fig '
      'tree. What is the total height of the two trees?',
  'expected': {'B': relation == 'taller' ? a - d : a + d, 'total': 0},
  'hints': <Object>[],
  'source': 'code',
};

void main() {
  test("a served problem becomes the engine's, its fields kept", () {
    final p = problemFromServer(served());
    expect(p.id, 'g_1');
    expect((p.a.name, p.a.pic, p.b.name, p.b.pic), (
      'Lemon tree',
      '🍋',
      'Fig tree',
      '🌳',
    ));
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

  test('easierLevel goes one rung down, never below L1', () {
    expect(easierLevel('L4'), 'L3');
    expect(easierLevel('L1'), 'L1');
    expect(easierLevel(null), isNull);
  });

  group('a lesson on the server problems', () {
    Future<(LessonViewModel, List<(String, String?)>)> makeVm({
      String? checkLevel,
      List<Map<String, Object?>>? problems,
    }) async {
      final pack = samplePack();
      final (sessions, _, api) = await memorySessions();
      api
        ..checkLevel = checkLevel
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

    test('a spaced check due asks its level for the first problem', () async {
      final (vm, asked) = await makeVm(
        checkLevel: 'L2',
        problems: [served(), served(id: 'g_2')],
      );
      await vm.start();
      expect(asked.single.$2, 'L2');
      vm.dispose();
    });

    test('something easier asks one level down, in a new session', () async {
      final (vm, asked) = await makeVm(
        problems: [served(), served(id: 'g_easy', level: 'L3')],
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
        problems: [served(), served(id: 'g_next')],
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
