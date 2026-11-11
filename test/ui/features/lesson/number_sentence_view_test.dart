import 'package:auramath/ui/features/lesson/view_models/lesson_view_model.dart';
import 'package:auramath/ui/features/lesson/view_models/sitting.dart';
import 'package:auramath/ui/features/lesson/views/lesson_flow.dart';
import 'package:auramath/ui/features/lesson/views/number_sentence.dart';
import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/shots.dart';
import 'fakes.dart';

/// @LES-06 on the board: build a number sentence; adding up counts.
void main() {
  final lemon = samplePack().problems['lemon']!;

  testWidgets('tiles fill the boxes; the sign flips; Check sends the form', (
    tester,
  ) async {
    final sent = <SentenceEntered>[];
    await tester.pumpWidget(
      shotApp(
        Scaffold(
          body: Center(
            child: SentenceBuilder(problem: lemon, onSentence: sent.add),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // 107 + ? = 186: adding up
    for (final s in ['D', 'box', 'A']) {
      await tester.tap(find.byKey(Key('sentenceTile-$s')));
      await tester.pump();
    }
    await tester.tap(find.text('Check my sentence'));
    await tester.pump();
    expect(sent.single.form, 'D+box=A');
    // 186 − 107 = ?
    for (final s in ['A', 'D', 'box']) {
      await tester.tap(find.byKey(Key('sentenceTile-$s')));
      await tester.pump();
    }
    await tester.tap(find.byKey(const Key('sentenceOp')));
    // a tapped box empties; its tile goes back
    await tester.tap(find.byKey(const Key('sentenceBox2')));
    await tester.tap(find.byKey(const Key('sentenceTile-box')));
    await tester.pump();
    await tester.tap(find.text('Check my sentence'));
    expect(sent.last.form, 'A-D=box');
  });

  testWidgets('the step on the board, with its targets 56 pt', (tester) async {
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
      )..enableSteps({'number_sentence'});
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
      return vm;
    }))!;
    addTearDown(vm.dispose);
    expect(vm.state.step, LessonStep.numberSentence);
    await shotAllSizes(
      tester,
      'lesson_board_sentence',
      LessonFlow(vm: vm, onHome: () {}, onFinished: (_) {}),
    );
    expect(find.byType(SentenceBuilder), findsOneWidget);
  });
}
