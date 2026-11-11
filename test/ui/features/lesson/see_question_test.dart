import 'package:auramath/l10n/app_localizations.dart';
import 'package:auramath/ui/features/lesson/view_models/lesson_view_model.dart';
import 'package:auramath/ui/features/lesson/view_models/sitting.dart';
import 'package:auramath/ui/features/lesson/views/lesson_flow.dart';
import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

/// @LES-02: "See the question" on the working screens Julia commented on
/// opens the whole question; closing it leaves the work as it was. Each
/// opening is logged as question_reopened.
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

  Future<LessonViewModel> lessonAt(
    WidgetTester tester,
    List<LessonInput> inputs,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final vm = (await tester.runAsync(() async {
      final (sessions, _, _) = await memorySessions();
      final vm = LessonViewModel(
        pack: samplePack(),
        problemId: 'lemon',
        sessionId: 's1',
        sessions: sessions,
        voice: FakeVoice(),
        openSession: sessions.open,
        sitting: Sitting(capMs: 30 * 60 * 1000),
        tickEvery: null,
      );
      await vm.start();
      for (final i in inputs) {
        await vm.send(i);
      }
      return vm;
    }))!;
    addTearDown(vm.dispose);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: LessonFlow(vm: vm, onHome: () {}, onFinished: (_) {}),
      ),
    );
    await tester.pumpAndSettle();
    return vm;
  }

  Future<List<String?>> reopened(
    WidgetTester tester,
    LessonViewModel vm,
  ) async {
    final r = await tester.runAsync(() => vm.sessions.resume(vm.sessionId));
    return [
      for (final e in r!.events)
        if (e.name == 'question_reopened') e.payload['step_id'] as String?,
    ];
  }

  Future<void> seeAndClose(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('seeQuestion')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('questionOverlay')), findsOneWidget);
    expect(
      find.textContaining('186', findRichText: true),
      findsWidgets,
      reason: 'the whole question shows',
    );
    await tester.tap(find.text('Back to my work'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('questionOverlay')), findsNothing);
  }

  for (final (screen, inputs, stepId) in [
    ('D1, drawing the first bar', const [Started()], 'draw_known_bar'),
    (
      'D2, placing the second bar',
      const [Started(), BarADrawn()],
      'size_second_bar',
    ),
    ('D4, choosing the sum', toFindB.take(6).toList(), 'choose_operation'),
    ('D5, finding the fig tree', toFindB, 'find_unknown'),
  ]) {
    testWidgets('$screen: the whole question, then back as it was', (
      tester,
    ) async {
      final vm = await lessonAt(tester, inputs);
      final before = vm.state;
      await seeAndClose(tester);
      expect(vm.state, before);
      expect(await reopened(tester, vm), [stepId]);
    });
  }

  testWidgets('H1·1, a hint on the first bar', (tester) async {
    final vm = await lessonAt(tester, const [Started(), HintTaken()]);
    await seeAndClose(tester);
    expect(await reopened(tester, vm), ['draw_known_bar']);
  });

  testWidgets('H2·2, show me how', (tester) async {
    final vm = await lessonAt(tester, const [Started(), ShowMeHowTaken()]);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await seeAndClose(tester);
    expect(vm.showingExample, isTrue, reason: 'still on the example');
    expect(find.text('Building B is 4 metres shorter.'), findsOneWidget);
    expect(await reopened(tester, vm), ['draw_known_bar']);
  });

  testWidgets('T1, a side lesson: logged with the step it opened from', (
    tester,
  ) async {
    final vm = await lessonAt(tester, [...toFindB, const NumberEntered(81)]);
    expect(vm.state.step, LessonStep.sideLesson);
    await seeAndClose(tester);
    expect(vm.state.step, LessonStep.sideLesson);
    expect(await reopened(tester, vm), ['find_unknown']);
  });
}
