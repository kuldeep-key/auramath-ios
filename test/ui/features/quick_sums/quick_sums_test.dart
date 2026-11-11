import 'package:auramath/ui/features/quick_sums/view_models/quick_sums_view_model.dart';
import 'package:auramath/ui/features/quick_sums/views/quick_sums_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../data/helpers.dart' show expectContract;
import '../../../helpers/shots.dart';
import '../lesson/fakes.dart';

Map<String, Object?> sum(int a, int b, {bool take = true}) => {
  'text': '$a ${take ? '-' : '+'} $b = ?',
  'answer': take ? a - b : a + b,
  'level': take ? 'A6' : 'A5',
};

/// @LES-16: a run of five from the arithmetic generator, every answer and
/// its time logged as quick_sum_answered.
void main() {
  Future<(QuickSumsViewModel, dynamic)> started() async {
    final (sessions, db, api) = await memorySessions();
    api.sums.addAll([
      sum(56, 19),
      sum(47, 25, take: false),
      sum(80, 33),
      sum(18, 7, take: false),
      sum(62, 8),
      sum(90, 45),
    ]);
    var now = 0;
    final vm = QuickSumsViewModel(
      sessions: sessions,
      childId: 'kid12345',
      nowMs: () => now += 900,
    );
    await vm.start();
    return (vm, db);
  }

  test('five sums; a wrong one wobbles and gets one more try', () async {
    final (vm, db) = await started();
    expect(vm.sums, hasLength(5));
    expect(vm.stage, QuickStage.sum);
    await vm.answer(37); // 56 - 19
    expect(vm.at, 1);
    await vm.answer(62); // 47 + 25 = 72: carry dropped
    expect(vm.stage, QuickStage.sideLesson, reason: 'the side lesson first');
    expect(vm.side, (left: 47, right: 25, subtract: false));
    expect(vm.regroupSlip, isTrue);
    expect(vm.wobbles, 1);
    await vm.backFromSide();
    expect(vm.stage, QuickStage.secondTry);
    await vm.answer(70); // wrong again: on to the next
    expect(vm.at, 2);
    expect(vm.stage, QuickStage.sum);
    await vm.answer(53); // 80 - 33 = 47: smaller from larger
    expect(vm.regroupSlip, isTrue);
    await vm.backFromSide();
    await vm.answer(47);
    await vm.answer(25);
    await vm.answer(54);
    expect(vm.stage, QuickStage.done);

    final events = await db.forSession('s2');
    expectContract(events);
    final answers = [
      for (final e in events)
        if (e.name == 'quick_sum_answered') e.payload,
    ];
    expect(answers, hasLength(7));
    expect(answers.every((a) => a['context'] == 'quick_sums'), isTrue);
    expect(answers.map((a) => a['attempt']), [1, 1, 2, 1, 2, 1, 1]);
    expect(answers.first['ms_from_item_start'], greaterThan(0));
    expect(events.last.name, 'session_ended');
    // LES-16: each regrouping slip opened the side lesson, by the lesson's
    // skills and error types (TUT-08)
    expect(
      [
        for (final e in events)
          if (e.name.startsWith('side_lesson_')) [e.name, ...e.payload.values],
      ],
      [
        ['side_lesson_started', 'arith.add-3d-regroup', 'carry_dropped'],
        ['side_lesson_ended', 'arith.add-3d-regroup', true],
        [
          'side_lesson_started',
          'arith.sub-3d-regroup',
          'sub_smaller_from_larger',
        ],
        ['side_lesson_ended', 'arith.sub-3d-regroup', true],
      ],
    );
    vm.dispose();
  });

  test('LES-16: past max_per_session a slip only says where to look; '
      'leaving mid side lesson ends it unfinished', () async {
    final (vm, db) = await started();
    await vm.answer(37);
    await vm.answer(62); // a slip: side lesson 1
    await vm.backFromSide();
    await vm.answer(72);
    await vm.answer(53); // a slip: side lesson 2
    await vm.backFromSide();
    await vm.answer(47);
    await vm.answer(15); // 18 + 7 = 25: carry dropped, past the limit
    expect(vm.stage, QuickStage.secondTry);
    expect(vm.regroupSlip, isTrue);
    vm.dispose();

    final (vm2, db2) = await started();
    await vm2.answer(37);
    await vm2.answer(62);
    expect(vm2.stage, QuickStage.sideLesson);
    await vm2.leave();
    final events = await db2.forSession('s2');
    expectContract(events);
    expect(events.map((e) => e.name).skip(events.length - 2), [
      'side_lesson_ended',
      'session_ended',
    ]);
    expect(events[events.length - 2].payload['completed'], isFalse);
    vm2.dispose();
  });

  testWidgets('LES-16: the side lesson works the slipped sum on blocks, then '
      'back for one more go', (tester) async {
    final vm = (await tester.runAsync(() async => (await started()).$1))!;
    addTearDown(vm.dispose);
    await tester.runAsync(() async {
      await vm.answer(37);
      await vm.answer(62);
    });
    await shotAllSizes(
      tester,
      'lesson_quick_sums_side',
      QuickSumsScreen(vm: vm, onHome: () {}, onStory: () {}),
    );
    await tester.pumpWidget(
      shotApp(QuickSumsScreen(vm: vm, onHome: () {}, onStory: () {})),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('quickSide')), findsOneWidget);
    expect(find.text('47 + 25'), findsOneWidget);
    // work the blocks: each step's button or tap until "Back to my sums"
    for (
      var i = 0;
      i < 8 && find.text('Back to my sums').evaluate().isEmpty;
      i++
    ) {
      final doIt = find.text('Do it');
      await tester.tap(
        doIt.evaluate().isNotEmpty ? doIt : find.text('Ones').first,
      );
      await tester.pumpAndSettle();
    }
    expect(find.text('72'), findsNothing, reason: 'the answer is not given');
    await tester.runAsync(() async {
      await tester.tap(find.text('Back to my sums'));
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pumpAndSettle();
    expect(vm.stage, QuickStage.secondTry);
    expect(find.text('47 + 25 ='), findsOneWidget);
  });

  test('regrouping slips are told apart from other wrong answers', () {
    expect(isRegroupSlip('56 - 19 = ?', 43), isTrue);
    expect(isRegroupSlip('56 - 19 = ?', 36), isFalse);
    expect(isRegroupSlip('47 + 25 = ?', 62), isTrue);
    expect(isRegroupSlip('41 + 25 = ?', 56), isFalse);
  });

  testWidgets('the Quick sums screen fits every size, with no count shown', (
    tester,
  ) async {
    final vm = (await tester.runAsync(() async => (await started()).$1))!;
    addTearDown(vm.dispose);
    await shotAllSizes(
      tester,
      'lesson_quick_sums',
      QuickSumsScreen(vm: vm, onHome: () {}, onStory: () {}),
    );
    await tester.pumpWidget(
      shotApp(QuickSumsScreen(vm: vm, onHome: () {}, onStory: () {})),
    );
    await tester.pumpAndSettle();
    expect(find.text('56 − 19 ='), findsOneWidget);
    expect(find.textContaining('of 5'), findsNothing);
    for (final d in '37'.split('')) {
      await tester.tap(find.text(d).last);
    }
    await tester.runAsync(() async {
      await tester.tap(find.byIcon(Icons.check_rounded));
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pumpAndSettle();
    expect(find.text('47 + 25 ='), findsOneWidget);
  });
}
