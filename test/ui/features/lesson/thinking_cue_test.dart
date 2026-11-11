import 'package:auramath/l10n/app_localizations.dart';
import 'package:auramath/ui/features/lesson/view_models/lesson_view_model.dart';
import 'package:auramath/ui/features/lesson/view_models/sitting.dart';
import 'package:auramath/ui/features/lesson/views/lesson_flow.dart';
import 'package:auramath/ui/features/lesson/views/thinking_cue.dart';
import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  testWidgets('a late decision shows the thinking cue over the board, '
      'which taps pass through, and it goes once the answer is in', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final (sessions, _, api) =
        await tester.runAsync(memorySessions) ?? (throw StateError('no db'));
    api.decideWith = (_) => Future.delayed(
      const Duration(milliseconds: 600),
      () => {'action': 'continue', 'source': 'rules'},
    );
    final vm =
        LessonViewModel(
            pack: samplePack(),
            problemId: 'lemon',
            sessionId: 's1',
            sessions: sessions,
            voice: FakeVoice(),
            openSession: sessions.open,
            sitting: Sitting(capMs: 30 * 60 * 1000),
            tickEvery: null,
          )
          ..askDecisions = true
          ..actOnDecisions = true
          ..cueAfterMs = 200;
    addTearDown(vm.dispose);
    await tester.runAsync(() async {
      for (final i in const <LessonInput>[
        Started(),
        BarADrawn(),
        BarBPlaced(),
        BarBSized(Relation.shorter),
        PieceDropped(Piece.gap, Target.gapSlot),
        PieceDropped(Piece.total, Target.totalSlot),
        OpChosen(Op.subtract),
      ]) {
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
    await tester.runAsync(() => vm.send(const NumberEntered(300)));
    await tester.pump();
    expect(find.byType(ThinkingCue), findsNothing);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();
    expect(find.text('Hmm, let me think.'), findsOneWidget);
    // never blocking: the keypad still takes a tap under it
    expect(
      find.ancestor(
        of: find.text('Hmm, let me think.'),
        matching: find.byType(IgnorePointer),
      ),
      findsWidgets,
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    await tester.pump();
    expect(find.byType(ThinkingCue), findsNothing);
    expect(vm.coachText, 'Not yet. Try that sum again.');
  });
}
