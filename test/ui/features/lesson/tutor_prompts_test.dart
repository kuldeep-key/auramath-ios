import 'package:auramath/l10n/app_localizations.dart';
import 'package:auramath/ui/core/parts/aura_button.dart';
import 'package:auramath/ui/features/lesson/view_models/lesson_view_model.dart';
import 'package:auramath/ui/features/lesson/view_models/sitting.dart';
import 'package:auramath/ui/features/lesson/views/tutor_prompts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

/// The prompts a tutor decision opens: read it again (AI-09) and you've
/// solved one like this (AI-10).
void main() {
  Future<(LessonViewModel, FakeVoice)> show(
    WidgetTester tester,
    void Function(LessonViewModel vm) set,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final (sessions, _, _) =
        await tester.runAsync(memorySessions) ?? (throw StateError('no db'));
    final voice = FakeVoice();
    final vm = LessonViewModel(
      pack: samplePack(),
      problemId: 'lemon',
      sessionId: 's1',
      sessions: sessions,
      voice: voice,
      openSession: sessions.open,
      sitting: Sitting(capMs: 30 * 60 * 1000),
      tickEvery: null,
    );
    addTearDown(vm.dispose);
    set(vm);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ListenableBuilder(
            listenable: vm,
            builder: (_, _) => TutorPromptSheet(vm: vm),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (vm, voice);
  }

  void bigEnough(WidgetTester tester, String label) => expect(
    tester
        .getSize(
          find.ancestor(
            of: find.text(label),
            matching: find.byType(AuraButton),
          ),
        )
        .height,
    greaterThanOrEqualTo(56),
    reason: label,
  );

  testWidgets("Let's read it again: the question lit up, Hear it again "
      'reads it, Back closes', (tester) async {
    final (vm, voice) = await show(tester, (vm) {
      vm.prompt = TutorPrompt.readAgain;
    });
    expect(find.text("Let's read it again"), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('readAgainQuestion')),
        matching: find.text(vm.problem.text),
      ),
      findsOneWidget,
    );
    bigEnough(tester, 'Hear it again');
    bigEnough(tester, 'Back to my drawing');
    await tester.tap(find.text('Hear it again'));
    expect(voice.said.last, vm.problem.say);
    await tester.tap(find.text('Back to my drawing'));
    await tester.pumpAndSettle();
    expect(vm.prompt, isNull);
    expect(find.text("Let's read it again"), findsNothing);
  });

  testWidgets("You've solved one like this: a peek at the earlier case", (
    tester,
  ) async {
    final (vm, _) = await show(tester, (vm) {
      vm
        ..prompt = TutorPrompt.seenBefore
        ..seenCase = vm.pack.problems['mango'];
    });
    expect(find.text("You've solved one like this"), findsOneWidget);
    expect(find.byKey(const Key('seenBeforePeek')), findsOneWidget);
    expect(find.text(vm.pack.problems['mango']!.text), findsOneWidget);
    bigEnough(tester, 'Back to my case');
    await tester.tap(find.text('Back to my case'));
    await tester.pumpAndSettle();
    expect(vm.prompt, isNull);
  });

  testWidgets('no earlier case named: the prompt alone', (tester) async {
    await show(tester, (vm) => vm.prompt = TutorPrompt.seenBefore);
    expect(find.byKey(const Key('seenBeforePeek')), findsNothing);
    expect(
      find.text("You've cracked a case like this before. How did you draw it?"),
      findsOneWidget,
    );
  });
}
