import 'dart:io';

import 'package:auramath/ui/features/lesson/view_models/lesson_view_model.dart';
import 'package:auramath/ui/features/lesson/view_models/sitting.dart';
import 'package:auramath/ui/features/lesson/views/lesson_flow.dart';
import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/shots.dart';
import 'fakes.dart';

/// @LES-04 and @CON-11: the bowl and mug (456 g, 128 g more) renders with
/// horizontal bars and is solved with 328 for the mug and 784 in total.
void main() {
  final template = ComparisonTemplate.fromYaml(
    File('assets/spec/comparison-two-step.yaml').readAsStringSync(),
  );
  final bowl = template.problem(
    'L3',
    'bowl-mug',
    a: 456,
    d: 128,
    relation: 'taller',
    pics: const {'bowl': '🥣', 'mug': '☕'},
    next: const NextProblems(fast: 'lemon', helped: 'lemon', easier: 'lemon'),
  );

  Future<LessonViewModel> lesson(
    WidgetTester tester, {
    bool weights = true,
    List<LessonInput> inputs = const [],
  }) async {
    final vm = (await tester.runAsync(() async {
      final (sessions, _, _) = await memorySessions();
      final pack = samplePack().copyWith(template: template);
      pack.problems[bowl.id] = bowl;
      final vm = LessonViewModel(
        pack: pack,
        problemId: bowl.id,
        sessionId: 's1',
        sessions: sessions,
        voice: FakeVoice(),
        openSession: sessions.open,
        sitting: Sitting(capMs: 30 * 60 * 1000),
        tickEvery: null,
      )..weightStories = weights;
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

  testWidgets('the bars lie across, and the case solves by taps', (
    tester,
  ) async {
    expect(bowl.isMass, isTrue);
    final vm = await lesson(tester, inputs: const [Started()]);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      shotApp(LessonFlow(vm: vm, onHome: () {}, onFinished: (_) {})),
    );
    await tester.pumpAndSettle();
    await tap(tester, find.byKey(const Key('slotA')));
    final a = tester.getRect(find.byKey(const Key('barA')));
    expect(a.width, greaterThan(a.height), reason: 'across, not upright');
    await tap(tester, find.byKey(const Key('piece')));
    await tap(tester, find.byKey(const Key('slotB')));
    expect(find.text('Lighter'), findsOneWidget);
    await tap(tester, find.text('Lighter'));
    final b = tester.getRect(find.byKey(const Key('barB')));
    expect(b.width, lessThan(a.width), reason: 'the mug is lighter');
    expect(b.top, greaterThan(a.top), reason: 'B under A');
    await tap(tester, find.byKey(const Key('piece')));
    await tap(tester, find.byKey(const Key('gapSlot')));
    await tap(tester, find.byKey(const Key('piece')));
    await tap(tester, find.byKey(const Key('totalSlot')));
    await tap(tester, find.text('456 − 128'));
    for (final n in ['328', '784']) {
      for (final d in n.split('')) {
        await tap(tester, find.text(d).last);
      }
      await tap(tester, find.byIcon(Icons.check_rounded));
    }
    expect(vm.state.step, LessonStep.solved);
  });

  for (final (name, inputs) in [
    ('lesson_board_across_size', const [Started(), BarADrawn(), BarBPlaced()]),
    (
      'lesson_board_across_total',
      const [
        Started(),
        BarADrawn(),
        BarBPlaced(),
        BarBSized(Relation.shorter),
        PieceDropped(Piece.gap, Target.gapSlot),
      ],
    ),
  ]) {
    testWidgets('$name fits every size, 56 pt targets', (tester) async {
      final vm = await lesson(tester, inputs: inputs);
      await shotAllSizes(
        tester,
        name,
        LessonFlow(vm: vm, onHome: () {}, onFinished: (_) {}),
      );
    });
  }

  testWidgets('weight_stories off: upright, as before', (tester) async {
    final vm = await lesson(
      tester,
      weights: false,
      inputs: const [Started(), BarADrawn()],
    );
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      shotApp(LessonFlow(vm: vm, onHome: () {}, onFinished: (_) {})),
    );
    await tester.pumpAndSettle();
    final a = tester.getRect(find.byKey(const Key('barA')));
    expect(a.height, greaterThan(a.width));
  });
}
