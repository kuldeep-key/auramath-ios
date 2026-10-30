import 'package:auramath/ui/features/lesson/view_models/lesson_view_model.dart';
import 'package:auramath/ui/features/lesson/view_models/sitting.dart';
import 'package:auramath/ui/features/lesson/views/side_lesson_view.dart';
import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/shots.dart';
import 'fakes.dart';

void main() {
  testWidgets('81 for 186 − 107: break a ten, take away, back to the problem', (
    tester,
  ) async {
    final vm = await tester.runAsync(() async {
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
      for (final i in const <LessonInput>[
        Started(),
        BarADrawn(),
        BarBPlaced(),
        BarBSized(Relation.shorter),
        PieceDropped(Piece.gap, Target.gapSlot),
        PieceDropped(Piece.total, Target.totalSlot),
        OpChosen(Op.subtract),
        NumberEntered(81), // forgot to break a ten
      ]) {
        await vm.send(i);
      }
      return vm;
    });
    expect(vm!.state.step, LessonStep.sideLesson);

    Widget screen() => Scaffold(
      body: SafeArea(
        child: SideLessonView(vm: vm, onHome: () {}),
      ),
    );
    await shotAllSizes(tester, 'lesson_side_board', screen());

    await tester.pumpWidget(shotApp(screen()));
    expect(find.text('186 − 107'), findsOneWidget);
    expect(
      find.text('Take 7 ones from 6? Not enough!\nTap a ten to break it.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Tens'));
    await tester.pump();
    expect(find.text('16'), findsOneWidget); // ten ones joined the six
    await tester.tap(find.text('Do it')); // take away 7 ones
    await tester.pump();
    await tester.tap(find.text('Do it')); // take away 1 hundred
    await tester.pump();
    // in the coach's bubble and under the board, as Figma does
    expect(find.text('186 − 107 = 79. You did it!'), findsNWidgets(2));

    await tester.runAsync(() async {
      await tester.tap(find.text('Back to the problem'));
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    expect(vm.state.step, LessonStep.findB);
    vm.dispose();
  });
}
