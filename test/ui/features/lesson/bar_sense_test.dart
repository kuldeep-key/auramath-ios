import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../data/helpers.dart' show expectContract;
import 'tutor_harness.dart';

/// TUT-17 (tentative, flag `bar_sense_side_lessons`): two wrong-way-round
/// second bars in two problems start "a longer bar, a greater number"; a
/// wrong pick there leads to the stars; both end back on the bar step.
void main() {
  Future<TutorLesson> twiceReversed(
    WidgetTester tester, {
    bool on = true,
  }) async {
    final t = await pumpLesson(tester);
    t.vm.barSenseLessons = on;
    await t.send([...toSizeB, const BarBSized(Relation.taller)]);
    t.vm.goTo('mango');
    await tester.runAsync(t.vm.start);
    await t.send([...toSizeB, const BarBSized(Relation.taller)]);
    expect(t.vm.sideLesson, SideLesson.readRelation);
    return t;
  }

  testWidgets('flag on: the bars lesson; a wrong bar, the stars; then the '
      'bars again and back to the bar step', (tester) async {
    final t = await twiceReversed(tester);
    expect(
      find.text('A longer bar shows a bigger number. Which bar shows 5?'),
      findsOneWidget,
    );
    await t.tap(find.byKey(const Key('bar3')));
    expect(
      find.text("Let's compare 3 stars and 5 stars. Which row has more?"),
      findsOneWidget,
    );
    await t.tap(find.byKey(const Key('stars3')));
    expect(find.byKey(const Key('stars5')), findsOneWidget, reason: 'again');
    await t.tap(find.byKey(const Key('stars5')));
    await t.tap(find.text('Next'));
    await t.tap(find.byKey(const Key('bar5')));
    await t.tap(find.text('Back to the problem'));
    expect(t.vm.state.step, LessonStep.sizeB);
    final ended = t.api.received.lastWhere(
      (e) => e.name == 'side_lesson_ended',
    );
    expect(ended.payload, {'skill_id': 'cmp.read-relation', 'completed': true});
    expectContract(t.api.received);
  });

  testWidgets('the bars and rows are 56 pt or more to tap', (tester) async {
    await twiceReversed(tester);
    for (final k in ['bar3', 'bar5']) {
      expect(
        tester.getSize(find.byKey(Key(k))).height,
        greaterThanOrEqualTo(56),
      );
    }
  });

  testWidgets('flag off: Show me how stays the side lesson', (tester) async {
    await twiceReversed(tester, on: false);
    expect(find.text('Building A is 6 metres tall.'), findsOneWidget);
    expect(find.byKey(const Key('bar5')), findsNothing);
  });
}
