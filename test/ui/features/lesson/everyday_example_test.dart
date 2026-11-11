import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../data/helpers.dart' show expectContract;
import '../../../helpers/shots.dart';
import 'tutor_harness.dart';

/// TUT-06: the last rung, H1-6, is a picture of a grown-up and a child
/// with the policy line, then back to the same step.
void main() {
  testWidgets('H1-6 shows the picture and the policy line, then back to '
      'the step', (tester) async {
    final t = await pumpLesson(tester);
    // draw_known_bar: H1-1, H1-2, then H1-6
    await t.send(const [Started(), HintTaken(), HintTaken()]);
    expect(find.byKey(const Key('everydayPicture')), findsNothing);
    await t.send([const HintTaken()]);
    expect(find.byKey(const Key('everydayPicture')), findsOneWidget);
    expect(
      find.text('Think of a grown-up and you. Who is taller?'),
      findsWidgets,
    );
    final shown = t.api.received.lastWhere((e) => e.name == 'hint_shown');
    expect(shown.payload['rung_id'], 'H1-6');
    expect(shown.payload['line_id'], 'line.hint.grown-up-and-you');
    await t.tap(find.text('Back to the problem'));
    expect(find.byKey(const Key('everydayPicture')), findsNothing);
    expect(t.vm.state.step, LessonStep.drawA);
    expectContract(t.api.received);
  });

  testWidgets('the picture sheet fits every size', (tester) async {
    final t = await pumpLesson(tester);
    await t.send(const [Started(), HintTaken(), HintTaken(), HintTaken()]);
    for (final size in shotSizes.values) {
      tester.view.physicalSize = size;
      await tester.pumpAndSettle();
    }
    expect(find.byKey(const Key('everydayPicture')), findsOneWidget);
  });
}
