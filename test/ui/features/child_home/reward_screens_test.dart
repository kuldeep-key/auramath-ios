import 'package:auramath/data/services/sound_effects.dart';
import 'package:auramath/ui/core/motion/celebration.dart';
import 'package:auramath/ui/core/motion/celebration_fx.dart';
import 'package:auramath/ui/core/motion/motion.dart';
import 'package:auramath/ui/core/parts/journey_art.dart';
import 'package:auramath/ui/features/child_home/views/badge_screen.dart';
import 'package:auramath/ui/features/child_home/views/badge_shapes.dart';
import 'package:auramath/ui/features/child_home/views/badges_screen.dart';
import 'package:auramath/ui/features/child_home/views/reward_moments.dart';
import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/shots.dart';
import 'helpers.dart';

/// The rewards screens drawn as the 16 Nov prototype draws them: Y3,
/// LevelUp, Habit, LandTrophy, Streak, First Case into the cabinet, B1, B2.
void main() {
  const tutor = TutorFigure(
    tutorId: 'teacher_1',
    size: 104,
    state: TutorState.cheering,
  );

  CelebrationSpec spec(
    String moment, {
    required String title,
    required Widget art,
    String? subtitle,
    String? ribbon,
    String? heading,
    String? line,
    Widget? tutor,
    Widget? walker,
    String? layout,
    Duration max = const Duration(seconds: 30),
  }) => CelebrationSpec(
    moment: moment,
    variant: 1,
    title: title,
    subtitle: subtitle,
    art: art,
    maxDuration: max,
    ribbon: ribbon,
    heading: heading,
    line: line,
    tutor: tutor,
    walker: walker,
    layout: layout,
  );

  Widget view(CelebrationSpec s) => CelebrationView(spec: s, onDone: (_) {});

  final y3 = spec(
    'session_badge',
    title: 'All by myself',
    subtitle: 'Tree Word Problem',
    heading: "Today's badge",
    line: "Remember, I'm a computer helper. You are the lead detective.",
    art: const BadgeArt(badgeId: 'session.all_by_myself', size: 200),
    tutor: tutor,
  );
  final levelUp = spec(
    'stop_badge',
    title: 'Seedling Path',
    ribbon: 'A new medal!',
    line: 'Your trail goes on. Time to try a new skill!',
    art: const BadgeArt(badgeId: 'stop.orchard.l1', size: 176, glint: true),
    walker: const LookPortrait(lookId: 'look_01', size: 34),
  );
  final habit = spec(
    'habit_badge',
    title: 'Bar builder',
    ribbon: 'A new badge!',
    line: 'You draw the bars yourself.',
    art: const BadgeArt(badgeId: 'habit.bar_builder', size: 200),
    tutor: tutor,
  );
  final land = spec(
    'stop_badge',
    layout: 'land_badge',
    title: 'The Orchard',
    ribbon: 'A land trophy!',
    line: 'Every stop, all yours.',
    art: const BadgeArt(badgeId: 'land.orchard', size: 217),
    tutor: tutor,
  );
  final streak = spec(
    'streak_moment',
    title: 'Detectives who keep coming back get really good.',
    ribbon: 'You came back!',
    art: const Text('🌟', style: TextStyle(fontSize: 110)),
  );
  final first = spec(
    'first_badge',
    title: 'Into your badges!',
    subtitle: 'My badges',
    art: const BadgeArt(badgeId: 'session.first_case', size: 133),
    tutor: const TutorFigure(
      tutorId: 'teacher_1',
      size: 170,
      state: TutorState.cheering,
    ),
  );

  testWidgets('the celebrations fit every size, drawn as the prototype', (
    tester,
  ) async {
    for (final (name, s) in [
      ('Y3', y3),
      ('LevelUp', levelUp),
      ('Habit', habit),
      ('LandTrophy', land),
      ('Streak', streak),
      ('FirstFly', first),
    ]) {
      await shots(tester, 'child_home_reward_$name', view(s));
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Y3: the heading, the badge with the tutor, the case and the '
      'AI reminder; no number', (tester) async {
    await show(tester, view(y3));
    expect(find.text("Today's badge"), findsOneWidget);
    expect(find.text('All by myself'), findsOneWidget);
    expect(find.text('Tree Word Problem'), findsOneWidget);
    expect(find.textContaining('computer helper'), findsOneWidget);
    expect(find.byType(TutorFigure), findsOneWidget);
    expect(find.byType(GoldDisc), findsOneWidget);
    expect(find.textContaining(RegExp(r'\d')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('each moment plays the prototype\'s sound as it opens', (
    tester,
  ) async {
    final rec = RecordingSfxPlayer();
    AuraSound.player = rec;
    addTearDown(() => AuraSound.player = const SilentSfxPlayer());
    for (final s in [y3, habit, levelUp, land, streak, first]) {
      await tester.pumpWidget(shotApp(view(s)));
      await tester.pumpAndSettle();
    }
    await tester.pumpWidget(const SizedBox());
    expect(rec.played, [
      Sfx.badge,
      Sfx.badge,
      Sfx.win,
      Sfx.win,
      Sfx.win,
      Sfx.right,
    ]);
  });

  testWidgets('each kind of badge has its own shape', (tester) async {
    await show(
      tester,
      const Wrap(
        children: [
          BadgeArt(badgeId: 'stop.orchard.l1', size: 60),
          BadgeArt(badgeId: 'habit.careful_reader', size: 60),
          BadgeArt(badgeId: 'land.orchard', size: 60),
          BadgeArt(badgeId: 'session.first_case', size: 60),
        ],
      ),
    );
    expect(find.byType(MedalBadge), findsOneWidget);
    expect(find.byType(HabitBadge), findsOneWidget);
    expect(find.byType(TrophyBadge), findsOneWidget);
    expect(find.byType(GoldDisc), findsOneWidget);
    // a medal is 1.05 × as tall as it is wide, a trophy 1.1 ×
    expect(tester.getSize(find.byType(MedalBadge)), const Size(60, 63));
    expect(tester.getSize(find.byType(TrophyBadge)).height, 61);
  });

  group('in motion', () {
    setUp(() => AuraMotion.still = false);
    tearDown(() => AuraMotion.still = true);

    testWidgets('Y3: the badge bursts in over 900 ms and the version\'s '
        'effect plays 500 ms in for 1.5 s', (tester) async {
      await tester.pumpWidget(shotApp(view(y3)));
      await tester.pump();
      final fx = tester.widget<CelebrationFx>(find.byType(CelebrationFx));
      expect(fx.kind, FxKind.confetti); // variant 1
      expect(fx.delay, const Duration(milliseconds: 500));
      expect(fx.length, const Duration(milliseconds: 1500));
      double scale() => tester
          .widget<Transform>(
            find
                .ancestor(
                  of: find.byType(GoldDisc),
                  matching: find.byType(Transform),
                )
                .first,
          )
          .transform
          .storage[0]
          .abs();
      expect(scale(), lessThan(0.05));
      await tester.pump(const Duration(milliseconds: 540));
      expect(scale(), closeTo(1.15, 0.02)); // 60 %: 1.15
      await tester.pump(const Duration(milliseconds: 410));
      expect(scale(), closeTo(1, 0.01));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('LevelUp: the look waits 0.7 s, then walks the path in 2.2 s', (
      tester,
    ) async {
      await tester.pumpWidget(
        shotApp(
          const Center(
            child: LevelPath(walker: LookPortrait(lookId: 'look_01', size: 34)),
          ),
        ),
      );
      await tester.pump();
      Offset walker() =>
          tester.getCenter(find.byType(LookPortrait)) -
          tester.getTopLeft(find.byType(LevelPath));
      expect(walker().dx, closeTo(56, 1));
      expect(walker().dy, closeTo(78, 1));
      await tester.pump(const Duration(milliseconds: 650));
      expect(walker().dx, closeTo(56, 1));
      await tester.pump(const Duration(milliseconds: 1150)); // halfway
      expect(walker().dx, inExclusiveRange(120, 200));
      await tester.pump(const Duration(milliseconds: 1150));
      expect(walker().dx, closeTo(264, 1));
      expect(walker().dy, closeTo(26, 1));
    });

    testWidgets('First Case: pops in by 0.5 s, holds, then drops 470 pt to '
        'the shelf by 2.4 s', (tester) async {
      await tester.pumpWidget(shotApp(view(first)));
      await tester.pump();
      double dy() => tester.getCenter(find.byType(GoldDisc)).dy;
      await tester.pump(const Duration(milliseconds: 700));
      final held = dy();
      await tester.pump(const Duration(milliseconds: 400)); // still held
      expect(dy(), closeTo(held, 1));
      await tester.pump(const Duration(milliseconds: 1400));
      expect(dy() - held, closeTo(470, 2));
      expect(find.text('My badges'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('B1: each badge pops in 60 ms after the one before', (
      tester,
    ) async {
      final badges = {
        'habit.bar_builder': const BadgeInfo(
          name: 'Bar builder',
          says: 'Bar builder',
        ),
        'habit.careful_reader': const BadgeInfo(
          name: 'Careful reader',
          says: 'Careful reader',
        ),
      };
      await tester.pumpWidget(
        shotApp(BadgesScreen(earned: badges.keys.toList(), badges: badges)),
      );
      double opacity(String name) => tester
          .widget<Opacity>(
            find
                .ancestor(of: find.text(name), matching: find.byType(Opacity))
                .first,
          )
          .opacity;
      await tester.pump(const Duration(milliseconds: 40));
      expect(opacity('Bar builder'), greaterThan(0));
      expect(opacity('Careful reader'), 0);
      // its 60 ms wait ends, then it pops in over 400 ms
      await tester.pump(const Duration(milliseconds: 30));
      await tester.pump(const Duration(milliseconds: 410));
      expect(opacity('Careful reader'), 1);
    });
  });

  testWidgets('B1 and B2 fit every size, as the prototype draws them', (
    tester,
  ) async {
    final badges = {
      'session.first_case': const BadgeInfo(
        name: 'First Case',
        says: 'First Case',
      ),
      'habit.bar_builder': const BadgeInfo(
        name: 'Bar builder',
        says: 'Bar builder',
      ),
      'habit.careful_reader': const BadgeInfo(
        name: 'Careful reader',
        says: 'Careful reader',
      ),
    };
    await shots(
      tester,
      'child_home_reward_B1',
      BadgesScreen(earned: badges.keys.toList(), badges: badges),
    );
    await shots(
      tester,
      'child_home_reward_B1-empty',
      BadgesScreen(earned: const [], badges: badges, tutorId: 'teacher_1'),
    );
    await shots(
      tester,
      'child_home_reward_B2',
      BadgeScreen(id: 'habit.bar_builder', badge: badges['habit.bar_builder']!),
    );
    await show(
      tester,
      BadgeScreen(id: 'habit.bar_builder', badge: badges['habit.bar_builder']!),
    );
    // its own line, not its name twice
    expect(find.text('You draw the bars yourself.'), findsOneWidget);
    expect(find.text('Bar builder'), findsOneWidget);
    await show(
      tester,
      const BadgeScreen(
        id: 'stop.orchard.l1',
        badge: BadgeInfo(name: 'Seedling Path', says: 'Seedling Path'),
      ),
    );
    expect(find.text('Your medal for Seedling Path.'), findsOneWidget);
  });
}
