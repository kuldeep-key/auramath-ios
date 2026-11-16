import 'dart:io';
import 'dart:ui' as ui;

import 'package:auramath/ui/core/motion/motion.dart';
import 'package:auramath/ui/core/parts/journey_art.dart';
import 'package:auramath/ui/core/parts/tutor_art.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// The tutor as the prototype draws and moves it (16 Nov): every state's
/// pose, and its keyframes' timings.
void main() {
  Widget host(Widget child) => Directionality(
    textDirection: TextDirection.ltr,
    child: Align(alignment: Alignment.topLeft, child: child),
  );

  TutorPose poseOf(WidgetTester t) => t
      .widget<CustomPaint>(
        find.descendant(
          of: find.byType(TutorFigure),
          matching: find.byType(CustomPaint),
        ),
      )
      .painter
      .let((p) => (p! as TutorPainter).pose.value);

  testWidgets('every state of both teachers and the robot, still', (t) async {
    // the prototype's gallery: five states, then their heads, per teacher
    t.view.physicalSize = const Size(840, 710) * 2;
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    Widget row(String id, String kind, {bool head = false}) => Row(
      children: [
        for (final s in TutorState.values)
          SizedBox(
            width: 164,
            height: head ? 68 : 160,
            child: Center(
              child: TutorFigure(
                tutorId: id,
                kind: kind,
                state: s,
                size: head ? 60 : 160,
              ),
            ),
          ),
      ],
    );
    await t.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('shot'),
        child: ColoredBox(
          color: Colors.white,
          child: host(
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  row('teacher_1', 'grown_up_teacher'),
                  row('teacher_1', 'grown_up_teacher', head: true),
                  row('teacher_2', 'grown_up_teacher'),
                  row('teacher_2', 'grown_up_teacher', head: true),
                  row('robot', 'robot'),
                  row('robot', 'robot', head: true),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.byType(TutorFigure), findsNWidgets(30));
    final boundary = t.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('shot')),
    );
    await t.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('build/shots/tutor_states.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  });

  testWidgets('64 pt or smaller is the head alone; bigger the whole '
      'figure, 228 by 220', (t) async {
    await t.pumpWidget(host(const TutorFigure(tutorId: 'teacher_1', size: 56)));
    expect(
      t.getSize(find.byKey(const ValueKey('tutor.idle'))),
      const Size(56, 56 * 124 / 120),
    );
    await t.pumpWidget(
      host(const TutorFigure(tutorId: 'teacher_1', size: 228)),
    );
    expect(
      t.getSize(find.byKey(const ValueKey('tutor.idle'))),
      const Size(228, 220),
    );
  });

  group('moves, as the prototype keyframes', () {
    setUp(() => AuraMotion.still = false);
    tearDown(() => AuraMotion.still = true);

    testWidgets('idle: bobs 4 up at 1.4 s, back at 2.8 s; blinks at 4.85 s', (
      t,
    ) async {
      await t.pumpWidget(
        host(const TutorFigure(tutorId: 'teacher_1', size: 190)),
      );
      expect(poseOf(t).bob, 0);
      await t.pump(const Duration(milliseconds: 1400));
      expect(poseOf(t).bob, closeTo(-4, 0.01));
      await t.pump(const Duration(milliseconds: 1400));
      expect(poseOf(t).bob, closeTo(0, 0.01));
      expect(poseOf(t).blink, 1);
      await t.pump(const Duration(milliseconds: 2050)); // 4.85 s: 97 %
      expect(poseOf(t).blink, closeTo(0.1, 0.01));
      await t.pump(const Duration(milliseconds: 150)); // 5 s: open again
      expect(poseOf(t).blink, closeTo(1, 0.01));
    });

    testWidgets('talking: the mouth closes to 0.35 at 300 ms, opens at '
        '600 ms', (t) async {
      await t.pumpWidget(
        host(
          const TutorFigure(
            tutorId: 'teacher_2',
            size: 60,
            state: TutorState.talking,
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 300));
      expect(poseOf(t).talk, closeTo(0.35, 0.01));
      await t.pump(const Duration(milliseconds: 300));
      expect(poseOf(t).talk, closeTo(1, 0.01));
    });

    testWidgets('cheering: jumps 8 up at 500 ms; sparks full at 550 ms, '
        'the second at 900 ms', (t) async {
      await t.pumpWidget(
        host(
          const TutorFigure(
            tutorId: 'teacher_1',
            size: 190,
            state: TutorState.cheering,
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 500));
      expect(poseOf(t).bob, closeTo(-8, 0.01));
      await t.pump(const Duration(milliseconds: 50));
      expect(poseOf(t).sparkScale[0], closeTo(1, 0.01));
      expect(poseOf(t).sparkOpacity[0], closeTo(1, 0.01));
      await t.pump(const Duration(milliseconds: 350));
      expect(poseOf(t).sparkScale[1], closeTo(1, 0.01));
      expect(poseOf(t).sparkScale[0], lessThan(0.6));
    });

    testWidgets('thinking: stands still; the dots peak 0.2 s apart', (t) async {
      await t.pumpWidget(
        host(
          const TutorFigure(
            tutorId: 'teacher_1',
            size: 190,
            state: TutorState.thinking,
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 600));
      expect(poseOf(t).bob, 0);
      expect(poseOf(t).dots[0], closeTo(1, 0.01));
      await t.pump(const Duration(milliseconds: 200));
      expect(poseOf(t).dots[1], closeTo(1, 0.01));
      await t.pump(const Duration(milliseconds: 200));
      expect(poseOf(t).dots[2], closeTo(1, 0.01));
      expect(poseOf(t).dots[0], lessThan(0.6));
    });

    testWidgets('a new state starts its moves from the beginning', (t) async {
      await t.pumpWidget(
        host(const TutorFigure(tutorId: 'teacher_1', size: 190)),
      );
      await t.pump(const Duration(milliseconds: 700));
      await t.pumpWidget(
        host(
          const TutorFigure(
            tutorId: 'teacher_1',
            size: 190,
            state: TutorState.cheering,
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 500));
      expect(poseOf(t).bob, closeTo(-8, 0.01));
    });

    testWidgets('the whole figure pops in over 500 ms', (t) async {
      await t.pumpWidget(
        host(const TutorFigure(tutorId: 'teacher_1', size: 190)),
      );
      double o() => t.widget<Opacity>(find.byType(Opacity)).opacity;
      expect(o(), 0);
      await t.pump(const Duration(milliseconds: 250));
      expect(o(), closeTo(Curves.ease.transform(0.5), 0.02));
      await t.pump(const Duration(milliseconds: 250));
      expect(o(), 1);
    });

    testWidgets('reduced motion: a still pose for every state', (t) async {
      await t.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: host(
            const TutorFigure(
              tutorId: 'teacher_1',
              size: 190,
              state: TutorState.cheering,
            ),
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 500));
      expect(poseOf(t).bob, 0);
      expect(t.hasRunningAnimations, isFalse);
    });
  });
}

extension<T> on T {
  R let<R>(R Function(T) f) => f(this);
}
