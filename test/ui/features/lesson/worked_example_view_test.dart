import 'dart:io';

import 'package:auramath/ui/features/lesson/view_models/lesson_view_model.dart';
import 'package:auramath/ui/features/lesson/view_models/sitting.dart';
import 'package:auramath/ui/features/lesson/views/worked_example_view.dart';
import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/shots.dart';
import 'fakes.dart';

void main() {
  testWidgets('Show me how walks a smaller problem, then back to theirs', (
    tester,
  ) async {
    final vm = await tester.runAsync(() async {
      final (sessions, _, _) = await memorySessions();
      final vm = LessonViewModel(
        // Julia's template, with its worked example (CON-05)
        pack: samplePack().copyWith(
          template: ComparisonTemplate.fromYaml(
            File('assets/spec/comparison-two-step.yaml').readAsStringSync(),
          ),
        ),
        problemId: 'lemon', // the fig tree is shorter
        sessionId: 's1',
        sessions: sessions,
        voice: FakeVoice(),
        openSession: sessions.open,
        sitting: Sitting(capMs: 30 * 60 * 1000),
        tickEvery: null,
      );
      await vm.send(const Started());
      await vm.send(const ShowMeHowTaken());
      return vm;
    });
    expect(vm!.showingExample, isTrue);

    Widget screen() => Scaffold(
      body: SafeArea(
        child: WorkedExampleView(vm: vm, onHome: () {}),
      ),
    );
    await shotAllSizes(tester, 'lesson_worked_example', screen());

    // the steps, on the smallest iPhone: the brace must still fit
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(shotApp(screen()));
    expect(find.text('Building A is 6 metres tall.'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pump();
    expect(find.text('? m'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pump();
    // the template's 6 m and 4 m (CON-05), not numbers in the code
    expect(find.text('6 take away 4 is 2.'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pump();
    expect(find.text('8 m'), findsOneWidget);
    await tester.tap(find.text('Now you try'));
    expect(vm.showingExample, isFalse);
    final shown = await tester.runAsync(() => vm.sessions.resume(vm.sessionId));
    expect(
      shown!.events
          .singleWhere((e) => e.name == 'worked_example_shown')
          .payload['example_story_id'],
      'building-a-b',
    );
    vm.dispose();
  });
}
