import 'package:auramath/data/services/fake_api.dart';
import 'package:auramath/ui/features/lesson/view_models/lesson_view_model.dart';
import 'package:auramath/ui/features/lesson/view_models/sitting.dart';
import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../data/helpers.dart' show expectContract;
import 'fakes.dart';

/// Practice sums after a side lesson whose own sum was wrong (TUT-08, 18).
void main() {
  Map<String, Object?> sum(int a, int b) => {
    'level': 'A6',
    'skill': 'arith.sub-2d-regroup',
    'op': 'sub',
    'a': a,
    'b': b,
    'answer': a - b,
    'text': '$a - $b = ?',
  };

  Future<(LessonViewModel, FakeApi)> inSideLesson({
    List<Map<String, Object?>> sums = const [],
  }) async {
    final (sessions, _, api) = await memorySessions();
    api.sums.addAll(sums);
    final vm = LessonViewModel(
      pack: samplePack(),
      problemId: 'lemon',
      sessionId: 's1',
      sessions: sessions,
      voice: FakeVoice(),
      openSession: sessions.open,
      sitting: Sitting(capMs: 30 * 60 * 1000),
      tickEvery: null,
    )..childId = 'c1';
    for (final i in const <LessonInput>[
      Started(),
      BarADrawn(),
      BarBPlaced(),
      BarBSized(Relation.shorter),
      PieceDropped(Piece.gap, Target.gapSlot),
      PieceDropped(Piece.total, Target.totalSlot),
      OpChosen(Op.subtract),
      NumberEntered(81),
    ]) {
      await vm.send(i);
    }
    return (vm, api);
  }

  test('the sum right: straight back to the case', () async {
    final (vm, _) = await inSideLesson(sums: [sum(56, 19)]);
    addTearDown(vm.dispose);
    await vm.checkOwnSum(79);
    expect(vm.ownSumRight, isTrue);
    expect(vm.sideStage, SideStage.back);
    expect(vm.practice, isEmpty);
  });

  test('the sum wrong: the policy\'s 3 practice sums, each logged, then a '
      'kind ending when none were right', () async {
    final (vm, api) = await inSideLesson(
      sums: [sum(56, 19), sum(43, 18), sum(72, 35), sum(61, 27)],
    );
    addTearDown(vm.dispose);
    await vm.checkOwnSum(81);
    expect(vm.sideStage, SideStage.practice);
    expect(vm.practice, hasLength(3)); // practice_if_unsure
    for (var i = 0; i < 3; i++) {
      await vm.answerPractice(1);
    }
    expect(vm.sideStage, SideStage.back);
    expect(vm.practiceAllWrong, isTrue);
    final answered = api.received.where((e) => e.name == 'quick_sum_answered');
    expect(answered, hasLength(3));
    expect(answered.first.payload['context'], 'side_lesson');
    expect(answered.first.payload['correct'], isFalse);
    expectContract(api.received);
  });

  test('no sums from the server: the answer, then back', () async {
    final (vm, _) = await inSideLesson();
    addTearDown(vm.dispose);
    await vm.checkOwnSum(81);
    expect(vm.ownSumRight, isFalse);
    expect(vm.sideStage, SideStage.back);
  });
}
