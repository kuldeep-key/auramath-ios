import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../data/helpers.dart' show expectContract;
import 'tutor_harness.dart';

/// TUT-07, Figma journey 16: the quiet child's lines are Julia's policy
/// lines, and after "Want a hand?" the first hint follows.
void main() {
  testWidgets('25 s, 40 s and 60 s say the policy lines; still thinking '
      'gives the first hint', (tester) async {
    final t = await pumpLesson(tester);
    await t.send([const Started()]);
    await t.send([const QuietFor(25000)]);
    expect(find.text('Can you draw the story out?'), findsOneWidget);
    await t.send([const QuietFor(40000)]);
    expect(find.text('Watch me, then you try.'), findsOneWidget);
    await t.send([const QuietFor(60000)]);
    // the sheet asks it, and the coach says it
    expect(find.text('Want a hand?'), findsNWidgets(2));
    expect(find.text('Still there?'), findsNothing);
    await t.tap(find.text("I'm still thinking"));
    expect(t.vm.stillThere, isFalse);
    // draw_known_bar's first rung, H1-1
    expect(find.text('What height is the lemon tree?'), findsOneWidget);
    final opened = t.api.received.lastWhere((e) => e.name == 'help_opened');
    expect(opened.payload['trigger'], 'after_quiet');
    final shown = t.api.received.lastWhere((e) => e.name == 'hint_shown');
    expect(shown.payload['rung_id'], 'H1-1');
    expectContract(t.api.received);
  });
}
