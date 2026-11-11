import 'package:auramath/ui/features/lesson/view_models/lesson_view_model.dart';
import 'package:auramath/ui/features/lesson/view_models/sitting.dart';
import 'package:auramath/ui/features/lesson/views/lesson_flow.dart';
import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/shots.dart';
import 'fakes.dart';

/// @LES-01: M0 shows I know it, Help me and a way to leave, and no bars.
void main() {
  Future<LessonViewModel> m0(WidgetTester tester) async {
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
      return vm;
    }))!;
    addTearDown(vm.dispose);
    await tester.pumpWidget(
      shotApp(LessonFlow(vm: vm, onHome: () {}, onFinished: (_) {})),
    );
    await tester.pumpAndSettle();
    return vm;
  }

  Future<void> tap(WidgetTester tester, Finder f) async {
    await tester.runAsync(() async {
      await tester.tap(f);
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pumpAndSettle();
  }

  testWidgets('I know it, Help me and home on M0; no bars', (tester) async {
    await m0(tester);
    expect(find.text('I know it'), findsOneWidget);
    expect(find.text('Help me'), findsOneWidget);
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    expect(find.byKey(const Key('slotA')), findsNothing);
    expect(find.byKey(const Key('barA')), findsNothing);
  });

  testWidgets('I know it on M0: the answer sheet; 265 cracks the case', (
    tester,
  ) async {
    final vm = await m0(tester);
    await tap(tester, find.byKey(const Key('m0KnowIt')));
    expect(vm.knowPrompt, KnowPrompt.answer);
    for (final d in '265'.split('')) {
      await tap(tester, find.text(d).last);
    }
    await tap(tester, find.byIcon(Icons.check_rounded));
    expect(vm.state.step, LessonStep.solved);
  });

  testWidgets('Help me on M0: a hint, on the board', (tester) async {
    final vm = await m0(tester);
    await tap(tester, find.byKey(const Key('m0HelpMe')));
    await tap(tester, find.text('A hint'));
    expect(vm.state.step, LessonStep.drawA);
    expect(vm.state.hintsUsed, 1);
  });
}
