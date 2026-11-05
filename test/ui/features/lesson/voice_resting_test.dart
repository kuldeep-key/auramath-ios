import 'package:auramath/routing/paths.dart';
import 'package:auramath/ui/features/lesson/view_models/lesson_view_model.dart';
import 'package:auramath/ui/features/lesson/view_models/sitting.dart';
import 'package:auramath/ui/features/lesson/views/lesson_flow.dart';
import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/shots.dart';
import 'fakes.dart';

void main() {
  testWidgets('a failing voice shows "My voice is resting" once', (
    tester,
  ) async {
    final voice = FakeVoice();
    final vm = await tester.runAsync(() async {
      final (sessions, _, _) = await memorySessions();
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
      await vm.send(const Started());
      return vm;
    });
    await tester.pumpWidget(
      shotApp(LessonFlow(vm: vm!, onHome: () {}, onFinished: (_) {})),
    );

    voice.resting.value = true;
    await tester.pumpAndSettle();
    expect(find.text('went to ${Paths.noVoice}'), findsOneWidget);
    expect(vm.askVoiceResting, isFalse);

    voice.resting.value = false;
    voice.resting.value = true; // fails again: not told twice
    expect(vm.askVoiceResting, isFalse);
    vm.dispose();
  });
}
