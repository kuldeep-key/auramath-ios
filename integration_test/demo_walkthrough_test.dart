import 'dart:convert';

import 'package:auramath/main.dart' as app;
import 'package:auramath/ui/features/lesson/views/lesson_flow.dart';
import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';

/// A demo walkthrough for a screen recording, on a real build against a dev
/// backend: a grown-up sets up and hands over; the child picks a look and a
/// tutor, meets the tutor, solves a case (sent to the lesson the way the
/// board sends a child's moves), sees the celebrations and the session
/// badge, then opens the Orchard path and the badge cabinet.
///
/// Fresh install, then `flutter test integration_test/demo_walkthrough_test.dart
/// -d DEVICE --dart-define-from-file=ENV_FILE` (DEMO false, PROBLEMS bundled).
const _api = 'http://localhost:8080';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('demo walkthrough', (tester) async {
    final email = 'demo+${DateTime.now().millisecondsSinceEpoch}@example.com';
    final invited = await http.post(
      Uri.parse('$_api/api/admin/parents'),
      headers: {
        'Authorization': 'Bearer demo-operator-token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'email': email}),
    );
    expect(invited.statusCode, 200, reason: invited.body);

    // ignore: avoid_print
    print('DEMO start ${DateTime.now().millisecondsSinceEpoch}');
    app.main();
    await tester.pump(const Duration(seconds: 2));

    List<String> onScreen() => [
      for (final e in find.byType(Text).evaluate()) ?(e.widget as Text).data,
    ];

    Future<void> hold(int ms) async {
      for (var i = 0; i < ms ~/ 100; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    /// Waits for the first of [labels] to show; returns it.
    Future<String> seeAny(List<String> labels, {int seconds = 20}) async {
      for (var i = 0; i < seconds * 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        for (final l in labels) {
          if (find.text(l).evaluate().isNotEmpty) return l;
        }
      }
      // ignore: avoid_print
      print('DEMO never saw $labels; on screen: ${onScreen()}');
      fail('never saw $labels');
    }

    Future<void> tapAny(List<String> labels, {int seconds = 20}) async {
      final l = await seeAny(labels, seconds: seconds);
      final f = find.text(l).last;
      await tester.ensureVisible(f);
      await hold(600); // let the viewer see the screen before the tap
      await tester.tap(f);
      await hold(900);
    }

    Future<void> keypad(String digits) async {
      for (final d in digits.split('')) {
        await tester.tap(find.text(d).last);
        await hold(250);
      }
    }

    /// Taps the first of [labels] if it shows within [seconds].
    Future<bool> maybeTap(List<String> labels, {int seconds = 4}) async {
      for (var i = 0; i < seconds * 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        for (final l in labels) {
          if (find.text(l).evaluate().isNotEmpty) {
            await hold(500);
            await tester.tap(find.text(l).last);
            await hold(900);
            return true;
          }
        }
      }
      return false;
    }

    await hold(2500); // the opening screen

    // ---- a grown-up sets up
    await tapAny(['Parents and carers', "I'm a grown-up"]);
    await maybeTap(['Get started', 'Set up', 'Continue']);
    await seeAny([
      "Your child's first name",
      "What's your child's first name?",
    ]);
    await tester.enterText(find.byType(TextField).first, 'Mia');
    await hold(700);
    await tapAny(['Continue', 'Next']);
    await tapAny(['7']);
    await tapAny(['Continue', 'Next']);
    await maybeTap(['Continue', 'Next']); // school year
    await maybeTap(["I'm not sure"]);
    await maybeTap(['Continue', 'Next']);
    await maybeTap(['Catch up']);
    await maybeTap(['Continue', 'Next']);
    // the consent tick, then I agree
    final tick = find.textContaining("parent or guardian");
    if (tick.evaluate().isNotEmpty) {
      await tester.ensureVisible(tick.first);
      await hold(1500);
      await tester.tap(tick.first);
      await hold(700);
    }
    await tapAny(['I agree', 'Agree and continue']);
    await seeAny(['Email me a sign-in link', 'Use my email']);
    await maybeTap(['Use my email'], seconds: 1);
    await tester.enterText(find.byType(TextField).first, email);
    await hold(600);
    await tapAny(['Email me a sign-in link', 'Email me a link']);
    await tapAny(['Open the link (dev only)']);
    await seeAny(["Mia's work is ready.", 'All set!'], seconds: 30);
    await hold(2500);
    await tapAny(['Hand over to Mia']);
    await maybeTap(['Use a passcode']);
    await seeAny(['Lock the Family area', 'Choose a passcode']);
    await keypad('2468');
    await seeAny(['Type it once more to be sure.', 'Type it again']);
    await keypad('2468');

    // ---- the child's first run: look, tutor, meet
    for (var i = 0; i < 8; i++) {
      final s = onScreen().join(' | ');
      if (s.contains('Keep going')) break;
      // a look or tutor tile: tap the first one, then go on
      if (await maybeTap(['Surprise me'], seconds: 3)) {
        await maybeTap([
          'This is me!',
          'This is my teacher!',
          'Choose this one',
        ]);
        continue;
      }
      if (await maybeTap([
        "Let's start",
        'Choose this one',
        'This is me!',
        'This is my teacher!',
        "Let's go",
        'Continue',
      ], seconds: 6)) {
        continue;
      }
      await hold(1000);
    }

    // ---- Home, then a case
    await hold(3000); // Home with the tutor greeting
    await tapAny(['Keep going']);
    await maybeTap(["Let's start"], seconds: 6); // the first meeting
    await hold(4000); // the story is read along
    await tapAny(["Let's draw it", "Got it, let's draw", "Let's draw"]);
    await hold(1500);

    final vm = tester.widget<LessonFlow>(find.byType(LessonFlow)).vm;
    final p = vm.problem;
    final bShorter = p.bValue < p.aValue;
    Future<void> move(LessonInput input) async {
      await vm.send(input);
      await hold(1800); // each move's animation and the tutor's line
    }

    for (var guard = 0; guard < 20; guard++) {
      final step = vm.state.step;
      if (step == LessonStep.solved) break;
      switch (step) {
        case LessonStep.question:
          await move(const Started());
        case LessonStep.drawA:
          await move(const BarADrawn());
        case LessonStep.placeB:
          await move(const BarBPlaced());
        case LessonStep.sizeB:
          await move(BarBSized(bShorter ? Relation.shorter : Relation.taller));
        case LessonStep.placeGap:
          await move(const PieceDropped(Piece.gap, Target.gapSlot));
        case LessonStep.placeTotal:
          await move(const PieceDropped(Piece.total, Target.totalSlot));
        case LessonStep.chooseOp:
          await move(OpChosen(bShorter ? Op.subtract : Op.add));
        case LessonStep.findB:
          await move(NumberEntered(p.bValue));
        case LessonStep.findTotal:
          await move(NumberEntered(p.total));
        case LessonStep.numberSentence:
          await move(SentenceEntered(bShorter ? 'D+box=A' : 'A+D=box'));
        case LessonStep.nameQuantities ||
            LessonStep.sideLesson ||
            LessonStep.solved:
          await hold(1000);
      }
    }
    expect(vm.state.step, LessonStep.solved);

    // ---- the case's celebrations, then end the session
    await hold(6000);
    for (var i = 0; i < 6; i++) {
      if (await maybeTap([
        'Add to my sash',
        'Next',
        'Skip',
        'Done',
        'Finish',
      ], seconds: 3)) {
        continue;
      }
      break;
    }
    // home from the lesson: the session ends and its badge shows
    await maybeTap(['Call it a day', "That's all for today", 'Stop here']);
    await hold(6000);

    // ---- the Orchard path and the cabinet
    if (await maybeTap(['See my trail', 'My trail'], seconds: 6)) {
      await hold(9000); // the path, the walk to the new stop
      final home = find.byIcon(Icons.home_rounded);
      final back = find.byTooltip('Back');
      if (back.evaluate().isNotEmpty) {
        await tester.tap(back.first);
      } else if (home.evaluate().isNotEmpty) {
        await tester.tap(home.first);
      }
      await hold(2500);
    }
    await maybeTap(['Add to my sash', 'Next', 'Skip', 'Done'], seconds: 3);
    if (await maybeTap(['My badges', 'Badges'], seconds: 8)) {
      await hold(6000);
    }
    // ignore: avoid_print
    print('DEMO end ${DateTime.now().millisecondsSinceEpoch}');
    // ignore: avoid_print
    print('DEMO done; on screen: ${onScreen()}');
  });
}
