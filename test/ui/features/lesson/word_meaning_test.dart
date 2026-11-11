import 'package:auramath/ui/features/lesson/view_models/lesson_view_model.dart';
import 'package:auramath/ui/features/lesson/view_models/sitting.dart';
import 'package:auramath/ui/features/lesson/views/lesson_flow.dart';
import 'package:auramath/ui/features/lesson/views/word_meaning.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/shots.dart';
import 'fakes.dart';

/// @LES-10: tapping "taller" opens J09 with a drawing that teaches it.
void main() {
  Future<LessonViewModel> lesson(WidgetTester tester, {bool on = true}) async {
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
      )..wordMeanings = on;
      await vm.start();
      return vm;
    }))!;
    addTearDown(vm.dispose);
    return vm;
  }

  test('the maths words in a question, in order', () {
    final p = samplePack().problems['lemon']!;
    expect(wordsIn(p), ['taller']);
  });

  testWidgets('tap taller: its meaning, drawn; logged; Got it closes', (
    tester,
  ) async {
    final vm = await lesson(tester);
    Widget flow() => LessonFlow(vm: vm, onHome: () {}, onFinished: (_) {});
    await shotAllSizes(tester, 'lesson_question_words', flow());
    await tester.pumpWidget(shotApp(flow()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('word-taller')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('wordMeaning')), findsOneWidget);
    expect(find.textContaining('longer bar'), findsOneWidget);
    await shotAllSizes(tester, 'lesson_word_meaning', flow());
    await tester.pumpWidget(shotApp(flow()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('wordMeaning')), findsNothing);
    final r = await tester.runAsync(() => vm.sessions.resume(vm.sessionId));
    expect(
      r!.events.where((e) => e.name == 'word_meaning_opened').single.payload,
      {'word_id': 'taller'},
    );
  });

  testWidgets('off by its flag: no word buttons', (tester) async {
    final vm = await lesson(tester, on: false);
    await tester.pumpWidget(
      shotApp(LessonFlow(vm: vm, onHome: () {}, onFinished: (_) {})),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('word-taller')), findsNothing);
  });
}
