import 'dart:io';

import 'package:auramath/ui/features/lesson/view_models/lesson_view_model.dart';
import 'package:auramath/ui/features/lesson/view_models/sitting.dart';
import 'package:auramath/ui/features/lesson/views/lesson_flow.dart';
import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/shots.dart';
import 'fakes.dart';

/// @LES-12 on the board: the template's options, a wrong one wobbles.
void main() {
  final template = ComparisonTemplate.fromYaml(
    File('assets/spec/comparison-two-step.yaml').readAsStringSync(),
  );

  Future<LessonViewModel> board(
    WidgetTester tester,
    List<LessonInput> inputs, {
    Set<String> steps = const {},
  }) async {
    final vm = (await tester.runAsync(() async {
      final (sessions, _, _) = await memorySessions();
      final vm = LessonViewModel(
        pack: samplePack().copyWith(template: template),
        problemId: 'lemon',
        sessionId: 's1',
        sessions: sessions,
        voice: FakeVoice(),
        openSession: sessions.open,
        sitting: Sitting(capMs: 30 * 60 * 1000),
        tickEvery: null,
      )..enableSteps(steps);
      await vm.start();
      for (final i in inputs) {
        await vm.send(i);
      }
      return vm;
    }))!;
    addTearDown(vm.dispose);
    return vm;
  }

  Future<void> tap(WidgetTester tester, Finder f) async {
    await tester.runAsync(() async {
      await tester.tap(f);
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pumpAndSettle();
  }

  testWidgets('name_quantities: which number is the lemon tree\'s height', (
    tester,
  ) async {
    final vm = await board(
      tester,
      const [Started()],
      steps: {'name_quantities'},
    );
    Widget flow() => LessonFlow(vm: vm, onHome: () {}, onFinished: (_) {});
    await shotAllSizes(tester, 'lesson_board_name', flow());
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(shotApp(flow()));
    await tester.pumpAndSettle();
    expect(find.text('How tall is the lemon tree?'), findsOneWidget);
    expect(find.byKey(const Key('slotA')), findsNothing);
    await tap(tester, find.byKey(const Key('option-opt_D')));
    expect(vm.wobbles, 1);
    expect(vm.state.step, LessonStep.nameQuantities);
    await tap(tester, find.byKey(const Key('option-opt_A')));
    expect(vm.state.step, LessonStep.drawA);
  });

  testWidgets('choose_operation shows the template\'s sums', (tester) async {
    final vm = await board(tester, const [
      Started(),
      BarADrawn(),
      BarBPlaced(),
      BarBSized(Relation.shorter),
      PieceDropped(Piece.gap, Target.gapSlot),
      PieceDropped(Piece.total, Target.totalSlot),
    ]);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      shotApp(LessonFlow(vm: vm, onHome: () {}, onFinished: (_) {})),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('option-a_plus_d')), findsOneWidget);
    expect(find.byKey(const Key('option-a_minus_d')), findsOneWidget);
    await tap(tester, find.text('186 − 107'));
    expect(vm.state.step, LessonStep.findB);
  });
}
