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
    expect(vm.stage, QuickStage.secondTry);
    expect(vm.regroupSlip, isTrue);
    expect(vm.wobbles, 1);
    await vm.answer(70); // wrong again: on to the next
    expect(vm.at, 2);
    expect(vm.stage, QuickStage.sum);
    await vm.answer(53); // 80 - 33 = 47: smaller from larger
    expect(vm.regroupSlip, isTrue);
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
    vm.dispose();
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
