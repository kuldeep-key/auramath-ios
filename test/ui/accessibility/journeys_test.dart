import 'package:auramath/data/repositories/recent_notes_repository.dart';
import 'package:auramath/data/repositories/report_email_repository.dart';
import 'package:auramath/ui/core/theme/app_theme.dart';
import 'package:auramath/ui/features/child_home/views/choose_today_screen.dart';
import 'package:auramath/ui/features/child_home/views/home_screen.dart';
import 'package:auramath/ui/features/grown_ups/views/book_screen.dart';
import 'package:auramath/ui/features/grown_ups/views/email_frequency_screen.dart';
import 'package:auramath/ui/features/grown_ups/views/recent_notes_screen.dart';
import 'package:auramath/ui/features/grown_ups/views/report_screen.dart';
import 'package:auramath/ui/features/grown_ups/views/settings_screen.dart';
import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/shots.dart';
import '../features/grown_ups/gu_fakes.dart';
import '../features/lesson/tutor_harness.dart';

/// NFR-04 (automated part): the accessibility review's journeys, 4 (first
/// lesson, drawing it out), 7 (a hint, one small question at a time), 12
/// (a wrong answer straight away) and 27 (after each session, the
/// grown-up), screen by screen at the Figma size, against Flutter's
/// guidelines: WCAG AA text contrast, Apple's 44 pt and Android's 48 dp
/// targets (56 pt on a child's screen, NFR-02), and a label on everything
/// tappable. What a person still has to check (screen reader order,
/// focus, meaning) is the manual review's.
void main() {
  setUpAll(() => TestWidgetsFlutterBinding.ensureInitialized());

  /// A lesson in the app's theme, at [inputs], checked as a child's screen.
  Future<TutorLesson> lessonAt(
    WidgetTester tester,
    List<LessonInput> inputs, {
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    await tester.runAsync(loadAppFonts);
    final t = await pumpLesson(
      tester,
      theme: buildAuraTheme(),
      size: size,
      textScale: textScale,
    );
    await t.send(inputs);
    return t;
  }

  Future<void> childScreen(WidgetTester tester, Widget screen) async {
    await tester.runAsync(loadAppFonts);
    tester.view.physicalSize = shotSizes['iphone15']!;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(shotApp(screen));
    await tester.pumpAndSettle();
  }

  group('journey 4: first lesson, drawing it out', () {
    testWidgets('A3 Choose today', (tester) async {
      await childScreen(tester, const ChooseTodayScreen());
      await expectAccessible(tester, child: true);
    });

    final steps = <String, List<LessonInput>>{
      'M1 the question': const [],
      'D1 draw the known bar': const [Started()],
      'D2-D3 the second bar': toSizeB,
      'D4 choose the operation': [
        ...toSizeB,
        const BarBSized(Relation.shorter),
        const PieceDropped(Piece.gap, Target.gapSlot),
        const PieceDropped(Piece.total, Target.totalSlot),
      ],
      'D5 find the unknown': toFindB,
      'Y2 solved': [
        ...toFindB,
        const NumberEntered(79),
        const NumberEntered(265),
      ],
    };
    for (final MapEntry(key: name, value: inputs) in steps.entries) {
      testWidgets(name, (tester) async {
        await lessonAt(tester, inputs);
        await expectAccessible(tester, child: true);
      });
      testWidgets('$name, smallest iPhone at 1.3x text', (tester) async {
        await lessonAt(
          tester,
          inputs,
          size: const Size(375, 667),
          textScale: 1.3,
        );
        await expectAccessible(tester, child: true);
      });
    }

    testWidgets('Home after the lesson', (tester) async {
      await childScreen(
        tester,
        const HomeScreen(name: 'Mia', grownUps: '/', avatar: 'key'),
      );
      await expectAccessible(tester, child: true);
    });
  });

  group('journey 7: a hint, one small question at a time', () {
    testWidgets('H0 Help me', (tester) async {
      final t = await lessonAt(tester, toSizeB);
      await tester.ensureVisible(find.text('Help me'));
      await t.tap(find.text('Help me'));
      await expectAccessible(tester, child: true);
    });

    for (final (name, hints) in [('H1-3', 1), ('H1-4 which is it', 3)]) {
      testWidgets(name, (tester) async {
        await lessonAt(tester, [
          ...toSizeB,
          for (var i = 0; i < hints; i++) const HintTaken(),
        ]);
        await expectAccessible(tester, child: true);
      });
    }
  });

  group('journey 12: a wrong answer straight away', () {
    testWidgets('S1 the answer sheet', (tester) async {
      final t = await lessonAt(tester, const [Started()]);
      // its event is written to the outbox, which needs real time
      await tester.runAsync(() async {
        t.vm.openKnowIt();
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
      // the answer box's caret blinks for ever: a few frames, not settle
      await tester.pump(const Duration(milliseconds: 500));
      await expectAccessible(tester, child: true);
    });

    testWidgets('W1 a wrong answer, and what comes next', (tester) async {
      final t = await lessonAt(tester, const [Started()]);
      // its event is written to the outbox, which needs real time
      await tester.runAsync(() async {
        t.vm.openKnowIt();
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
      await tester.runAsync(() => t.vm.answer(300));
      await tester.pump(const Duration(milliseconds: 500));
      await expectAccessible(tester, child: true);
    });
  });

  group("journey 27: after each session, the grown-up's side", () {
    Future<void> grownUp(WidgetTester tester, Widget Function(Gu) at) async {
      final g = await Gu.make(tester);
      await tester.runAsync(loadAppFonts);
      tester.view.physicalSize = shotSizes['iphone15']!;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(shotApp(at(g)));
      await tester.pumpAndSettle();
      await expectAccessible(tester);
    }

    testWidgets('Settings', (tester) async {
      await grownUp(
        tester,
        (g) => SettingsScreen(
          family: g.deps.family,
          repo: g.repo,
          email: ReportEmailRepository(g.deps.client),
        ),
      );
    });

    testWidgets('How often the email comes', (tester) async {
      await grownUp(
        tester,
        (g) =>
            EmailFrequencyScreen(email: ReportEmailRepository(g.deps.client)),
      );
    });

    testWidgets("The child's book: each session's note", (tester) async {
      await grownUp(
        tester,
        (g) =>
            BookScreen(childId: 'child-1', family: g.deps.family, repo: g.repo),
      );
    });

    testWidgets('Recent notes', (tester) async {
      await grownUp(
        tester,
        (g) => RecentNotesScreen(
          childId: 'child-1',
          family: g.deps.family,
          notes: RecentNotesRepository(g.deps.client, g.repo),
        ),
      );
    });

    testWidgets('The report', (tester) async {
      await grownUp(
        tester,
        (g) => ReportScreen(
          childId: 'child-1',
          family: g.deps.family,
          repo: g.repo,
        ),
      );
    });
  });
}
