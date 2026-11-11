import 'package:flutter_test/flutter_test.dart';

import '../../../data/helpers.dart' show expectContract;
import 'tutor_harness.dart';

/// TUT-04: the policy's hint ladder, one rung per request, from the rung
/// for the child's step; a step with no rung offers show me how and
/// something easier instead.
void main() {
  testWidgets('on size_second_bar the first hint is H1-3, from the policy '
      'line library', (tester) async {
    final t = await pumpLesson(tester);
    await t.send(toSizeB);
    await t.tap(find.text('Help me'));
    expect(find.text('A hint'), findsOneWidget);
    await t.tap(find.text('A hint'));
    expect(
      find.text('Good! Now, what is the height of the fig tree?'),
      findsOneWidget,
    );
    final shown = t.api.received.lastWhere((e) => e.name == 'hint_shown');
    expect(shown.payload['rung_id'], 'H1-3');
    expect(shown.payload['line_id'], 'line.hint.now-b');
    expectContract(t.api.received);
  });

  testWidgets('on find_unknown Help me offers show me how and something '
      'easier, no hint', (tester) async {
    final t = await pumpLesson(tester);
    await t.send(toFindB);
    await t.tap(find.byTooltip('Help me'));
    expect(find.text('A hint'), findsNothing);
    expect(find.text('Show me how'), findsOneWidget);
    expect(find.text('Something easier'), findsOneWidget);
    expect(t.vm.canHint, isFalse);
  });
}
