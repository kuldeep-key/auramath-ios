import 'package:auramath/data/repositories/progress_repository.dart';
import 'package:auramath/ui/core/motion/motion.dart';
import 'package:auramath/ui/features/child_home/views/after_case_screen.dart';
import 'package:auramath/ui/features/child_home/views/badge_screen.dart';
import 'package:auramath/ui/features/child_home/views/badges_screen.dart';
import 'package:auramath/ui/features/child_home/views/check_screen.dart';
import 'package:auramath/ui/features/child_home/views/home_screen.dart';
import 'package:auramath/ui/features/child_home/views/meet_partner_screen.dart';
import 'package:auramath/ui/features/child_home/views/trail_screen.dart';
import 'package:auramath/ui/features/child_home/views/trail_top_screen.dart';
import 'package:auramath/ui/features/child_home/views/voice_screens.dart';
import 'package:auramath/ui/features/child_home/views/welcome_back_screen.dart';
import 'package:auramath/ui/features/lesson/views/break_views.dart';
import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/shots.dart';
import '../features/lesson/fakes.dart';
import '../features/lesson/tutor_harness.dart';

/// NFR-04: the child's screens at 1.3 times the text size (the most the
/// app honours, app.dart) on the smallest iPhone and the Figma frame, with
/// nothing clipped (an overflow fails the test), and at rest when the
/// phone asks for reduced motion.
void main() {
  final pack = samplePack();
  const sizes = {'iphoneSE': Size(375, 667), 'iphone15': Size(390, 844)};

  final screens = <String, Widget>{
    'home': const HomeScreen(
      name: 'Mia',
      grownUps: '/',
      trail: true,
      badges: true,
    ),
    'badges': BadgesScreen(earned: const ['tree'], badges: pack.badges),
    'badges_none': BadgesScreen(earned: const [], badges: pack.badges),
    'badge': BadgeScreen(id: 'tree', badge: pack.badges['tree']!),
    'trail': const TrailScreen(here: TrailStop.trickyWords),
    'trail_top': const TrailTopScreen(),
    'check': const CheckScreen(),
    'welcome_back': const WelcomeBackScreen(name: 'Mia'),
    'sound': const SoundScreen(),
    'no_voice': const NoVoiceScreen(),
    'meet_partner': MeetPartnerScreen(
      served: const [],
      onSay: (_) {},
      onStart: () {},
      readAloud: false,
    ),
    'after_case_sent': AfterCaseScreen(
      after: (
        solved: pack.problems['lemon'],
        next: pack.problems['shorter']!,
        sentBadge: 'tree',
        streak: false,
        opened: null,
      ),
    ),
    'after_case_up': AfterCaseScreen(
      after: (
        solved: pack.problems['lemon'],
        next: pack.problems['shorter']!,
        sentBadge: null,
        streak: false,
        opened: TrailStop.trickyWords,
      ),
    ),
    'time_up': TimeUpView(onStop: () {}, onFinish: () {}),
    'kept': KeptForNextTimeView(onOk: () {}),
    'need_internet': NeedInternetView(onRetry: () {}, onGoHome: () {}),
  };

  for (final MapEntry(key: name, value: screen) in screens.entries) {
    testWidgets('$name fits at 1.3x text', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      for (final size in sizes.values) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(shotApp(screen));
        await tester.pumpAndSettle();
        final text = tester.widget<Text>(find.byType(Text).first);
        expect(text, isNotNull);
        expect(
          MediaQuery.textScalerOf(
            tester.element(find.byType(Text).first),
          ).scale(10),
          13,
        );
      }
      tester.view.reset();
    });
  }

  // the lesson's own screens, at each step a child sees
  final lessonStates = <String, List<LessonInput>>{
    'question': const [],
    'board_draw': const [Started()],
    'board_size_b': toSizeB,
    'board_choose_op': [
      ...toSizeB,
      const BarBSized(Relation.shorter),
      const PieceDropped(Piece.gap, Target.gapSlot),
      const PieceDropped(Piece.total, Target.totalSlot),
    ],
    'board_find_b': toFindB,
    'which_it': [...toSizeB, for (var i = 0; i < 3; i++) const HintTaken()],
    'still_there': const [Started(), QuietFor(60000)],
    'everyday_example': const [
      Started(),
      HintTaken(),
      HintTaken(),
      HintTaken(),
    ],
    'side_lesson': [...toFindB, const NumberEntered(81)],
    'worked_example': const [Started(), ShowMeHowTaken()],
    'solved': [...toFindB, const NumberEntered(79), const NumberEntered(265)],
  };

  for (final MapEntry(key: name, value: inputs) in lessonStates.entries) {
    testWidgets('lesson $name fits at 1.3x text on the smallest iPhone', (
      tester,
    ) async {
      final t = await pumpLesson(
        tester,
        textScale: 1.3,
        size: const Size(375, 667),
      );
      await t.send(inputs);
      // an overflow anywhere fails the test on its own
      await tester.pumpAndSettle();
    });
  }

  testWidgets('help me at 1.3x text: the sheet fits', (tester) async {
    final t = await pumpLesson(
      tester,
      textScale: 1.3,
      size: const Size(375, 667),
    );
    await t.send(toSizeB);
    // the board scrolls at this size: Help me is below the fold
    await tester.ensureVisible(find.text('Help me'));
    await t.tap(find.text('Help me'));
    expect(find.text('Show me how'), findsOneWidget);
  });

  group('reduced motion', () {
    setUp(() => AuraMotion.still = false);
    tearDown(() => AuraMotion.still = true);

    /// The phone's "reduce motion" switch.
    void reduceMotion(WidgetTester tester) {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
    }

    Future<int> running(WidgetTester tester) async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      return tester.binding.transientCallbackCount;
    }

    testWidgets('without it, Home floats (so the check below means '
        'something)', (tester) async {
      await tester.pumpWidget(shotApp(screens['home']!));
      expect(await running(tester), greaterThan(0));
      await tester.pumpWidget(const SizedBox());
    });

    for (final name in ['home', 'badge', 'trail_top', 'sound', 'time_up']) {
      testWidgets('$name is at rest at once: nothing floats or loops', (
        tester,
      ) async {
        reduceMotion(tester);
        await tester.pumpWidget(shotApp(screens[name]!));
        expect(await running(tester), 0, reason: name);
      });
    }

    testWidgets('the board: a wrong sum doesn\'t shake, the help button '
        'doesn\'t pulse', (tester) async {
      reduceMotion(tester);
      final t = await pumpLesson(tester);
      await t.send(toFindB);
      await tester.runAsync(() => t.vm.send(const NumberEntered(300)));
      await tester.runAsync(() => t.vm.send(const NumberEntered(300)));
      expect(t.vm.wobbles, 2);
      expect(await running(tester), 0);
    });
  });
}
