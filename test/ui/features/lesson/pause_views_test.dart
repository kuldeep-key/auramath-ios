import 'package:auramath/data/services/fake_api.dart';
import 'package:auramath/data/services/outbox_db.dart';
import 'package:auramath/l10n/app_localizations.dart';
import 'package:auramath/ui/features/lesson/view_models/lesson_view_model.dart';
import 'package:auramath/ui/features/lesson/view_models/sitting.dart';
import 'package:auramath/ui/features/lesson/views/lesson_flow.dart';
import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

/// Figma M1-pause ("Take a break?") and TU ("That's today's time!").
void main() {
  var now = 0;
  var wentHome = 0;
  late LessonViewModel vm;
  late OutboxDb db;
  late FakeApi api;

  Future<void> pumpLesson(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    now = 0;
    wentHome = 0;
    final (sessions, outbox, fake) =
        await tester.runAsync(memorySessions) ?? (throw StateError('no db'));
    db = outbox;
    api = fake;
    vm = LessonViewModel(
      pack: samplePack(),
      problemId: 'lemon',
      sessionId: 's1',
      sessions: sessions,
      voice: FakeVoice(),
      sitting: Sitting(capMs: 30 * 60 * 1000),
      nowMs: () => now,
      newSessionId: () => 's2',
      tickEvery: null,
    );
    await tester.runAsync(() async {
      await vm.start();
      await vm.send(const Started());
    });
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: LessonFlow(vm: vm, onHome: () => wentHome++, onFinished: (_) {}),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder f) async {
    await tester.runAsync(() async {
      await tester.tap(f);
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pumpAndSettle();
  }

  testWidgets('home mid-lesson asks to take a break before leaving', (
    tester,
  ) async {
    await pumpLesson(tester);
    await tap(tester, find.byIcon(Icons.home_rounded));
    expect(find.text('Take a break?'), findsOneWidget);
    expect(find.text('Your drawing is saved.'), findsOneWidget);
    expect(wentHome, 0);

    await tap(tester, find.text('Keep going'));
    expect(find.text('Take a break?'), findsNothing);

    await tap(tester, find.byIcon(Icons.home_rounded));
    await tap(tester, find.text('Go home'));
    expect(wentHome, 1);
    vm.dispose();
  });

  testWidgets("time's up offers to finish this one or stop", (tester) async {
    await pumpLesson(tester);
    await tester.runAsync(() async {
      now += 30 * 60 * 1000;
      await vm.tick();
    });
    await tester.pumpAndSettle();
    expect(find.text("That's today's time!"), findsOneWidget);
    expect(find.textContaining('saved for next time'), findsOneWidget);

    await tap(tester, find.text('Finish this one'));
    expect(find.text("That's today's time!"), findsNothing);
    expect(wentHome, 0);
    vm.dispose();
  });

  testWidgets("OK on time's up goes home with the work kept", (tester) async {
    await pumpLesson(tester);
    await tester.runAsync(() async {
      now += 30 * 60 * 1000;
      await vm.tick();
    });
    await tester.pumpAndSettle();
    await tap(tester, find.text('OK'));
    expect(wentHome, 1);
    vm.dispose();
  });

  testWidgets('a lost connection shows a gentle notice and is logged', (
    tester,
  ) async {
    await pumpLesson(tester);
    expect(find.textContaining('Lost the internet'), findsNothing);
    await tester.runAsync(() async {
      api.failNext = 1000;
      await vm.send(const BarADrawn()); // its send fails: offline
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(find.textContaining('Lost the internet'), findsOneWidget);
    // the lesson carries on underneath (SES-04)
    expect(find.text('Bar'), findsOneWidget);
    expect(vm.state.step, LessonStep.placeB);
    final names = await tester.runAsync(
      () async => [for (final e in await db.forSession('s1')) e.name],
    );
    expect(names!.last, 'connectivity_changed');

    await tester.runAsync(() async {
      api.failNext = 0;
      await vm.sessions.syncNow();
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(find.textContaining('Lost the internet'), findsNothing);
    vm.dispose();
  });
}
