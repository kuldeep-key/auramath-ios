import 'package:auramath/ui/features/lesson/view_models/lesson_view_model.dart';
import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../data/helpers.dart' show expectContract;
import 'tutor_harness.dart';

/// TUT-10: five minutes without progress on one step offers two ways out,
/// something easier or leave it for now (E1).
void main() {
  testWidgets('the too-hard sheet offers Something easier and Leave it for '
      'now; leaving logs problem_left', (tester) async {
    var now = 1000;
    final t = await pumpLesson(tester, nowMs: () => now);
    await t.send([const Started(), const BarADrawn()]);
    now += 5 * 60 * 1000;
    await tester.runAsync(t.vm.tick);
    await tester.pumpAndSettle();
    expect(find.text("This one's tricky. Want a hand?"), findsOneWidget);
    expect(find.text('Something easier'), findsOneWidget);
    expect(find.text('Leave it for now'), findsOneWidget);
    expect(find.text('Help me'), findsOneWidget, reason: 'the board\'s own');
    await t.tap(find.text('Leave it for now'));
    final left = t.api.received.lastWhere((e) => e.name == 'problem_left');
    expect(left.payload, {'problem_id': 'lemon', 'step_id': 'size_second_bar'});
    expect(t.names.last, 'session_ended');
    expect(t.finishedWith, LessonViewModel.newProblem);
    expectContract(t.api.received);
  });
}
