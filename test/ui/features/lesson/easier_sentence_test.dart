import 'package:auramath/data/services/fake_api.dart';
import 'package:auramath/l10n/app_localizations.dart';
import 'package:auramath/ui/features/lesson/view_models/lesson_view_model.dart';
import 'package:auramath/ui/features/lesson/view_models/sitting.dart';
import 'package:auramath/ui/features/lesson/views/lesson_flow.dart';
import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../data/helpers.dart' show expectContract;
import 'fakes.dart';

/// TUT-09: an easier number sentence, beside the bars.
void main() {
  Future<(LessonViewModel, FakeApi)> at(
    WidgetTester tester,
    List<LessonInput> inputs,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final (sessions, _, api) =
        await tester.runAsync(memorySessions) ?? (throw StateError('no db'));
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
    addTearDown(vm.dispose);
    await tester.runAsync(() async {
      for (final i in inputs) {
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

  const toFindB = <LessonInput>[
    Started(),
    BarADrawn(),
    BarBPlaced(),
    BarBSized(Relation.shorter),
    PieceDropped(Piece.gap, Target.gapSlot),
    PieceDropped(Piece.total, Target.totalSlot),
    OpChosen(Op.subtract),
  ];

  Future<void> openHelp(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Help me'));
    await tester.pumpAndSettle();
  }

  testWidgets('on find the fig tree: Help me, Show the sum in words; the '
      'sentence is this problem\'s, with each name under its number', (
    tester,
  ) async {
    final (vm, api) = await at(tester, toFindB);
    await openHelp(tester);
    await tester.runAsync(() async {
      await tester.tap(find.text('Show the sum in words'));
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pumpAndSettle();
    final sentence = find.byKey(const Key('easierSentence'));
    expect(sentence, findsOneWidget);
    for (final t in ['186', '107', '🍋 lemon tree', 'gap', '🌳 fig tree']) {
      expect(
        find.descendant(of: sentence, matching: find.text(t)),
        findsOneWidget,
        reason: t,
      );
    }
    // beside the bars: just under the board, above the keypad
    expect(
      tester.getTopLeft(sentence).dy,
      lessThan(tester.getTopLeft(find.text('7')).dy),
    );
    expect(
      api.received
          .lastWhere((e) => e.name == 'easier_number_sentence_shown')
          .payload,
      {'step_id': 'find_unknown'},
    );
    expectContract(api.received);
    // the next step starts plain again
    await tester.runAsync(() => vm.send(const NumberEntered(79)));
    await tester.pump();
    expect(vm.easierSentence, isFalse);
  });

  testWidgets('not offered while drawing', (tester) async {
    await at(tester, toFindB.take(2).toList());
    await tester.tap(find.text('Help me'));
    await tester.pumpAndSettle();
    expect(find.text('A hint'), findsOneWidget);
    expect(find.text('Show the sum in words'), findsNothing);
  });
}
