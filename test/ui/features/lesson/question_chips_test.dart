import 'dart:io';

import 'package:auramath/data/services/fake_api.dart';
import 'package:auramath/l10n/app_localizations.dart';
import 'package:auramath/ui/features/lesson/view_models/lesson_view_model.dart';
import 'package:auramath/ui/features/lesson/view_models/sitting.dart';
import 'package:auramath/ui/features/lesson/views/lesson_flow.dart';
import 'package:auramath/ui/features/lesson/views/question_chips.dart';
import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../data/helpers.dart' show expectContract;
import 'fakes.dart';

/// @TUT-13: tap-to-ask question buttons from policy `question_buttons`.
void main() {
  final policy = Policy.fromYaml(
    File('assets/spec/policy.yaml').readAsStringSync(),
  );

  Future<(LessonViewModel, FakeApi)> onSizeB(
    WidgetTester tester, {
    bool flag = true,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final (sessions, _, api) =
        await tester.runAsync(memorySessions) ?? (throw StateError('no db'));
    final vm = LessonViewModel(
      pack: samplePack().copyWith(
        questionButtons: policy.questionButtons,
        policyLines: policy.lines,
      ),
      problemId: 'lemon',
      sessionId: 's1',
      sessions: sessions,
      voice: FakeVoice(),
      openSession: sessions.open,
      sitting: Sitting(capMs: 30 * 60 * 1000),
      tickEvery: null,
    )..childQuestions = flag;
    addTearDown(vm.dispose);
    await tester.runAsync(() async {
      for (final i in const [Started(), BarADrawn(), BarBPlaced()]) {
        await vm.send(i);
      }
    });
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: LessonFlow(vm: vm, onHome: () {}, onFinished: (_) {}),
      ),
    );
    await tester.pumpAndSettle();
    return (vm, api);
  }

  testWidgets('on size_second_bar: "What does taller mean?" shows its '
      'approved answer and logs question_chip_tapped', (tester) async {
    final (vm, api) = await onSizeB(tester);
    expect(find.text('What does taller mean?'), findsOneWidget);
    expect(find.text('What do I do now?'), findsOneWidget);
    for (final id in ['line.q.taller-means', 'line.q.what-now']) {
      final size = tester.getSize(find.byKey(Key('ask-$id')));
      expect(size.height, greaterThanOrEqualTo(56), reason: id);
    }
    await tester.runAsync(() async {
      await tester.tap(find.text('What does taller mean?'));
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pump();
    const answer =
        'Taller means it reaches higher. Show the taller tree with a longer bar.';
    expect(vm.coachText, answer);
    expect(find.text(answer), findsOneWidget);
    // it explains the word; it never says which bar is longer
    expect(answer.toLowerCase(), isNot(contains('fig tree')));
    final tapped = api.received.lastWhere(
      (e) => e.name == 'question_chip_tapped',
    );
    expect(tapped.payload, {
      'chip_id': 'line.q.taller-means',
      'step_id': 'size_second_bar',
      'line_id': 'line.q.taller-means',
    });
    expectContract(api.received);
    // no text box anywhere: the keypad is the only way to type
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('every board step has one to three buttons', (tester) async {
    final (vm, _) = await onSizeB(tester);
    for (final i in const <LessonInput>[
      BarBSized(Relation.shorter),
      PieceDropped(Piece.gap, Target.gapSlot),
      PieceDropped(Piece.total, Target.totalSlot),
      OpChosen(Op.subtract),
    ]) {
      expect(vm.questions.length, inInclusiveRange(1, 3), reason: '$i');
      await tester.runAsync(() => vm.send(i));
    }
    expect(vm.questions.length, inInclusiveRange(1, 3));
  });

  testWidgets('child_questions off: no buttons', (tester) async {
    final (vm, _) = await onSizeB(tester, flag: false);
    expect(vm.questions, isEmpty);
    expect(find.byType(QuestionChips), findsNothing);
  });
}
