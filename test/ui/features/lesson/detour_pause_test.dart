import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'tutor_harness.dart';

/// TUT-18: a detour pauses the case with its board kept, and comes back to
/// the same step with a one-line bridge.
void main() {
  testWidgets('the side lesson says the case is waiting; back, the same '
      'step and the bridge', (tester) async {
    final t = await pumpLesson(tester);
    await t.send([...toFindB, const NumberEntered(81)]);
    expect(t.vm.state.step, LessonStep.sideLesson);
    expect(find.byKey(const Key('caseWaiting')), findsOneWidget);
    expect(
      find.text('Your case is waiting. Your drawing is kept.'),
      findsOneWidget,
    );
    await t.send([const SideLessonDone()]);
    expect(t.vm.state.step, LessonStep.findB);
    expect(t.vm.state.gapPlaced, isTrue, reason: 'the board as it was');
    expect(
      find.text('Now you know that trick. Back to the case!'),
      findsOneWidget,
    );
  });
}
