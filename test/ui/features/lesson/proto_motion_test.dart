// The prototype's timings, frame by frame: what shows at each point of an
// animation (motion on, unlike the rest of the suite).
import 'package:auramath/data/services/sound_effects.dart';
import 'package:auramath/ui/core/motion/fx_burst.dart';
import 'package:auramath/ui/core/motion/motion.dart';
import 'package:auramath/ui/features/lesson/view_models/place_value.dart';
import 'package:auramath/ui/features/lesson/views/side_lesson_view.dart';
import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'tutor_harness.dart';

/// The word lit on the story (a span with the yellow tint behind it).
String? litWord(WidgetTester tester) {
  final rich = tester.widget<RichText>(
    find.descendant(
      of: find.byKey(const Key('story')),
      matching: find.byType(RichText),
    ),
  );
  String? lit;
  rich.text.visitChildren((s) {
    if (s is TextSpan && s.style?.backgroundColor != null) lit = s.text;
    return true;
  });
  return lit;
}

void main() {
  setUp(() => AuraMotion.still = false);
  tearDown(() => AuraMotion.still = true);

  testWidgets('M0 reads along: from 650 ms one word lights every 330 ms', (
    tester,
  ) async {
    final t = await pumpLessonMoving(tester);
    expect(litWord(tester), isNull);
    await tester.pump(const Duration(milliseconds: 450)); // read starts
    await tester.pump(const Duration(milliseconds: 199));
    expect(litWord(tester), isNull, reason: '200 ms lead');
    await tester.pump(const Duration(milliseconds: 11));
    expect(litWord(tester), 'The');
    await tester.pump(const Duration(milliseconds: 330));
    expect(litWord(tester), 'lemon');
    await tester.pump(const Duration(milliseconds: 330));
    expect(litWord(tester), 'tree');
    await tester.pump(const Duration(seconds: 30));
    expect(litWord(tester), isNull, reason: 'cleared at the end');
    // Hear it again runs it again from the first word
    await tester.ensureVisible(find.byKey(const Key('hearItAgain')));
    await tester.tap(find.byKey(const Key('hearItAgain')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 210));
    expect(litWord(tester), 'The');
    expect(t.voice.said, hasLength(2), reason: 'and the story is read');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('W1: a second wrong answer fades in "Can you draw the story '
      'out?" over 420 ms; Let\'s draw opens the board, nothing revealed', (
    tester,
  ) async {
    AuraMotion.still = true;
    final t = await pumpLesson(tester);
    await t.send(const [Started(), KnowIt(256), KnowIt(300)]);
    expect(find.byKey(const Key('drawIt')), findsOneWidget);
    expect(find.text('Can you draw the story out?'), findsOneWidget);
    expect(find.text("Let's do it together."), findsOneWidget);
    expect(find.textContaining('265'), findsNothing, reason: 'never shown');
    await t.tap(find.byKey(const Key('letsDraw')));
    expect(find.byKey(const Key('drawIt')), findsNothing);
    expect(find.byKey(const Key('slotA')), findsOneWidget);

    AuraMotion.still = false;
    final m = await pumpLessonMoving(tester);
    await tester.runAsync(() async {
      for (final i in const [Started(), KnowIt(256), KnowIt(300)]) {
        await m.vm.send(i);
      }
    });
    await tester.pump();
    double fade() => tester
        .widget<Opacity>(
          find
              .ancestor(
                of: find.byKey(const Key('drawIt')),
                matching: find.byType(Opacity),
              )
              .first,
        )
        .opacity;
    expect(fade(), 0);
    await tester.pump(const Duration(milliseconds: 210));
    expect(fade(), inInclusiveRange(.5, .99));
    await tester.pump(const Duration(milliseconds: 220));
    expect(fade(), 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('T1\'s written sum fills in as the blocks are worked: the '
      'broken ten struck with its new tens, then the answer, place by '
      'place, each digit popping in over 350 ms', (tester) async {
    final sum = PlaceValue(left: 186, right: 107, subtract: true);
    Future<void> show() => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: WrittenSum(sum: sum)),
      ),
    );
    await show();
    expect(find.text('9'), findsNothing);
    sum.act(); // break a ten
    await show();
    expect(find.text('7'), findsNWidgets(2), reason: '8 struck, 7 above; 107');
    sum.act(); // take the ones: 16 - 7
    await show();
    final nine = find.text('9');
    expect(nine, findsOneWidget);
    double shown() => tester
        .widget<Opacity>(
          find.ancestor(of: nine, matching: find.byType(Opacity)).first,
        )
        .opacity;
    await tester.pump(const Duration(milliseconds: 100));
    expect(shown(), lessThan(1));
    await tester.pump(const Duration(milliseconds: 300));
    expect(shown(), 1);
    while (sum.step != PlaceStep.done) {
      sum.act();
    }
    await show();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('9'), findsOneWidget);
    expect(find.text('7'), findsNWidgets(3), reason: 'and 79\'s tens');
  });

  testWidgets('the board\'s sounds: snap as a bar lands, snap and right with '
      'the step\'s 300 ms celebration for the gap, boing on a wrong drop, '
      'win on case cracked', (tester) async {
    AuraMotion.still = true;
    final rec = RecordingSfxPlayer();
    AuraSound.player = rec;
    addTearDown(() => AuraSound.player = const SilentSfxPlayer());
    final t = await pumpLesson(tester);
    await t.send(const [Started()]);
    rec.played.clear();
    await t.send(const [BarADrawn()]);
    expect(rec.played, [Sfx.snap]);
    await t.send(const [BarBPlaced(), BarBSized(Relation.shorter)]);
    rec.played.clear();
    await t.send(const [PieceDropped(Piece.gap, Target.barB)]);
    expect(rec.played, [Sfx.boing], reason: 'a wrong move');
    rec.played.clear();
    await t.send(const [Undo(), PieceDropped(Piece.gap, Target.gapSlot)]);
    expect(rec.played, [Sfx.snap, Sfx.right]);
    expect(find.byType(FxBurst), findsOneWidget);
    rec.played.clear();
    for (final i in const [
      PieceDropped(Piece.total, Target.totalSlot),
      OpChosen(Op.subtract),
      NumberEntered(79),
      NumberEntered(265),
    ]) {
      await t.send([i]);
    }
    expect(rec.played.last, Sfx.win);
    expect(rec.played.where((s) => s == Sfx.right), hasLength(3));
  });

  test('a celebration never plays the same version twice running', () {
    for (final m in FxMoment.values) {
      var last = m.pick();
      for (var i = 0; i < 50; i++) {
        final next = m.pick();
        expect(next, isNot(last));
        expect(m.versions, contains(next));
        last = next;
      }
    }
  });
}
