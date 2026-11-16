import 'dart:io';

import 'package:auramath/ui/features/lesson/view_models/repeat_triggers.dart';
import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../data/helpers.dart' show expectContract;
import 'tutor_harness.dart';

/// TUT-08: detours beyond regrouping, on the policy's repeat triggers.
void main() {
  test('the on-repeat side lessons are the skill map\'s on_repeat error '
      'types', () {
    final text = File('assets/spec/skill-map.yaml').readAsStringSync();
    final types = text.substring(text.indexOf('\nerror_types:'));
    final onRepeat = {
      for (final block in types.split('\n  - id: ').skip(1))
        if (block.contains('side_lesson: on_repeat') &&
            !block.startsWith('reference_changed'))
          block.split('\n').first.trim(): RegExp(
            r'\n    skill: (\S+)',
          ).firstMatch(block)![1]!,
    };
    expect(repeatSideLessons.keys.toSet(), onRepeat.keys.toSet());
    // reference_changed has no detector yet (skill map detection_note)
    for (final MapEntry(:key, :value) in repeatSideLessons.entries) {
      if (key == 'keyword_strategy') continue; // taught with choosing the sum
      expect(sideSkill[value], onRepeat[key], reason: key);
    }
  });

  test('the same mistake in two problems is due; in one problem, not', () {
    final r = RepeatTriggers();
    expect(r.charge('p1', 'relation_reversed'), isNull);
    expect(r.charge('p1', 'relation_reversed'), isNull);
    expect(r.charge('p2', 'relation_reversed'), SideLesson.readRelation);
    expect(r.charge('p3', 'relation_reversed'), isNull, reason: 'it ran');
  });

  test('the same operation wrong twice in a sitting is due', () {
    final r = RepeatTriggers();
    expect(r.charge('p1', null, op: Op.subtract), isNull);
    expect(r.charge('p2', null, op: Op.add), isNull);
    expect(r.charge('p2', null, op: Op.subtract), SideLesson.takeAcrossTen);
  });

  testWidgets('a wrong-way-round bar in a second problem opens the '
      '"which is taller" detour; it walks the example and comes back to '
      'the same step', (tester) async {
    final t = await pumpLesson(tester);
    // the first problem: sized the wrong way, once
    await t.send([...toSizeB, const BarBSized(Relation.taller)]);
    expect(t.vm.state.step, LessonStep.sizeB);
    // the same sitting, the next problem
    t.vm.goTo('mango');
    await tester.runAsync(t.vm.start);
    await t.send([...toSizeB, const BarBSized(Relation.taller)]);
    expect(t.vm.state.step, LessonStep.sideLesson);
    expect(t.vm.sideLesson, SideLesson.readRelation);
    final started = t.api.received.lastWhere(
      (e) => e.name == 'side_lesson_started',
    );
    expect(started.payload, {
      'skill_id': 'cmp.read-relation',
      'error_type': 'relation_reversed',
    });
    // the smaller example, then back to the bar
    expect(find.text('Building A is 6 metres tall.'), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      await t.tap(find.text('Next'));
    }
    await t.tap(find.text('Back to the problem'));
    expect(t.vm.state.step, LessonStep.sizeB);
    expect(
      t.api.received.lastWhere((e) => e.name == 'side_lesson_ended').payload,
      {'skill_id': 'cmp.read-relation', 'completed': true},
    );
    expectContract(t.api.received);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
