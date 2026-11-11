import 'package:flutter_test/flutter_test.dart';

import '../../../data/helpers.dart' show expectContract;
import 'tutor_harness.dart';

/// TUT-05: after H2 the problem is closed and scored as solved with help
/// (scoring outcome_rules.show_me_how), and a new variant of the same
/// template opens (Figma 8.6, the mango and guava trees).
void main() {
  testWidgets('Show me how to its end: closed with help, then a new problem '
      'of the same kind', (tester) async {
    final t = await pumpLesson(tester);
    await t.send(toSizeB);
    await t.tap(find.text('Help me'));
    await t.tap(find.text('Show me how'));
    for (var i = 0; i < 3; i++) {
      await t.tap(find.text('Next'));
    }
    await t.tap(find.text('Now try a new one'));
    final done = t.api.received.lastWhere((e) => e.name == 'problem_completed');
    expect(done.payload['problem_id'], 'lemon');
    expect(done.payload['outcome'], 'with_hints');
    expect(t.names, isNot(contains('badge_awarded')));
    expect(find.text('Case cracked!'), findsNothing);
    expect(t.vm.problem.id, 'mango');
    expect(
      t.api.received
          .lastWhere((e) => e.name == 'problem_shown')
          .payload['problem_id'],
      'mango',
    );
    expectContract(t.api.received);
  });
}
