import 'package:auramath/ui/features/lesson/views/solved_view.dart';
import 'package:auramath/l10n/app_localizations.dart';
import 'package:auramath/ui/features/lesson/view_models/lesson_view_model.dart';
import 'package:auramath/ui/features/lesson/view_models/sitting.dart';
import 'package:auramath/ui/features/lesson/views/lesson_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../data/helpers.dart' show expectContract;
import 'fakes.dart';

void main() {
  testWidgets('lemon lesson from question to solved by taps', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final (sessions, _, api) =
        await tester.runAsync(memorySessions) ?? (throw StateError('no db'));
    final voice = FakeVoice();
    final vm = LessonViewModel(
      pack: samplePack(),
      problemId: 'lemon',
      sessionId: '5b0c3f0e-8a51-4c2e-9d3e-2f1a6c7b9e10',
      sessions: sessions,
      voice: voice,
      newSessionId: () => 's2',
      sitting: Sitting(capMs: 30 * 60 * 1000),
      tickEvery: null,
    );
    await tester.runAsync(vm.start);
    String? finishedWith;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: LessonFlow(
          vm: vm,
          onHome: () {},
          onFinished: (next) => finishedWith = next,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(voice.said.first, startsWith('The lemon tree is 186 centimetres'));

    Future<void> tap(Finder f) async {
      await tester.runAsync(() async {
        await tester.tap(f);
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
      await tester.pumpAndSettle();
    }

    Future<void> type(String digits) async {
      for (final d in digits.split('')) {
        await tap(find.text(d).last);
      }
      await tap(find.byIcon(Icons.check_rounded));
    }

    await tap(find.text("Got it, let's draw"));
    expect(find.text('Drag a bar up here.'), findsOneWidget);
    await tap(find.byKey(const Key('slotA')));
    await tap(find.byKey(const Key('piece')));
    await tap(find.byKey(const Key('slotB')));
    await tap(find.text('Shorter'));
    await tap(find.byKey(const Key('piece')));
    await tap(find.byKey(const Key('gapSlot')));
    await tap(find.byKey(const Key('piece')));
    await tap(find.byKey(const Key('totalSlot')));
    await tap(find.text('186 − 107'));
    await type('79');
    expect(find.text('Yes! 79 cm!'), findsOneWidget);
    await type('265');
    expect(find.text('Case cracked!'), findsOneWidget);
    // a wide screen shows whether the background fills it or hugs the text
    tester.view.physicalSize = const Size(1000, 844);
    await tester.pump();
    final bg = find.descendant(
      of: find.byType(SolvedView),
      matching: find.byType(DecoratedBox),
    );
    expect(tester.getSize(bg.first).width, 1000);
    tester.view.physicalSize = const Size(390, 844);
    // under a notch the celebration still runs to the top edge
    tester.view.padding = const FakeViewPadding(top: 47);
    await tester.pump();
    expect(tester.getTopLeft(bg.first).dy, 0);
    expect(tester.getTopLeft(find.text('Next')).dy, greaterThan(47));
    tester.view.resetPadding();
    await tester.pump();
    await tap(find.text('Next'));
    expect(find.text('Tree Detective'), findsOneWidget);
    await tap(find.text('Add to my sash'));
    expect(finishedWith, 'shorter');
    final seqs = api.received.map((e) => e.seq).toList();
    expect(seqs, List.generate(seqs.length, (i) => i));
    expectContract(api.received);
    final names = api.received.map((e) => e.name).toList();
    expect(names.take(2), ['session_started', 'problem_shown']);
    expect(names.skip(names.length - 2), [
      'problem_completed',
      'badge_awarded',
    ]);

    vm.dispose();
  });
}
