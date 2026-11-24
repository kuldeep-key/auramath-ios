import 'package:auramath/data/models/journey_config.dart';
import 'package:auramath/data/repositories/celebration_repository.dart';
import 'package:auramath/data/repositories/visit_repository.dart';
import 'package:auramath/data/services/api_client.dart';
import 'package:auramath/data/services/key_store.dart';
import 'package:auramath/data/services/sound_effects.dart';
import 'package:auramath/l10n/app_localizations.dart';
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
  // the peak moment (Figma section 15, 17 Nov), level number switch off
  final levelUp = spec(
    'stop_badge',
    title: 'Sapling Row',
    heading: 'You reached the peak!',
    line: 'A new land opens: Orchard Gate.',
    art: const PeakArt(
      medal: BadgeArt(badgeId: 'stop.orchard.l2', size: 96, glint: true),
    ),
    walker: const LookPortrait(lookId: 'look_01', size: 34),
  );
  final levelTop = spec(
    'stop_badge',
    title: 'Twisty Tree',
    heading: 'You reached the top!',
    line: 'You climbed every land in the Orchard!',
    art: const PeakArt(
      last: true,
      medal: BadgeArt(badgeId: 'stop.orchard.l5', size: 96, glint: true),
    ),
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
      ('LevelTop', levelTop),
      ('Habit', habit),
      ('LandTrophy', land),
      ('Streak', streak),
      ('FirstFly', first),
    ]) {
      await shots(tester, 'child_home_reward_$name', view(s));
    }
    await tester.pumpWidget(const SizedBox());
  });

  group('the peak moment (Figma section 15)', () {
    RewardMoments moments() => RewardMoments(
      celebrations: CelebrationRepository(
        MemoryKeyStore(),
        VisitRepository(
          ApiClient(baseUrl: 'http://test', bearer: () => null),
          deviceId: () => 'dv_test',
          appVersion: '0.1.0',
        ),
      ),
      config: const JourneyConfig(),
      childId: null,
      lookId: 'look_01',
    );
    final l = lookupAppLocalizations(const Locale('en'));
    const award = (
      badgeId: 'stop.orchard.l2',
      kind: 'skill_mastered',
      name: 'Sapling Row',
      problemId: null,
      celebration: 'stop_badge',
      queued: false,
      alsoLand: null,
    );

    test('a passed level: the peak, its land, and the next land by name; '
        'never a level number', () async {
      final s = await moments().bigBadge(
        award,
        l: l,
        peak: (next: 'Orchard Gate', last: false, path: 'The Orchard'),
      );
      expect(s.heading, 'You reached the peak!');
      expect(s.title, 'Sapling Row');
      expect(s.line, 'A new land opens: Orchard Gate.');
      expect(s.ribbon, isNull);
      expect(s.art, isA<PeakArt>());
      expect(s.walker, isNotNull);
      // 24 Nov: progress waits for the child
      expect(s.holdFor, 'Keep going');
      for (final t in [s.heading, s.title, s.line]) {
        expect(t, isNot(matches(RegExp(r'\d|[Ll]evel'))));
      }
    });

    test(
      'the last level: the top, every land climbed, nothing promised',
      () async {
        final s = await moments().bigBadge(
          (
            badgeId: 'stop.orchard.l5',
            kind: 'skill_mastered',
            name: 'Twisty Tree',
            problemId: null,
            celebration: 'stop_badge',
            queued: false,
            alsoLand: null,
          ),
          l: l,
          peak: (next: null, last: true, path: 'The Orchard'),
        );
        expect(s.heading, 'You reached the top!');
        expect(s.line, 'You climbed every land in the Orchard!');
        expect(s.walker, isNull);
        expect((s.art as PeakArt).last, isTrue);
      },
    );

    test('offline (no path): the peak and its land, no line', () async {
      final s = await moments().bigBadge(award, l: l);
      expect(s.heading, 'You reached the peak!');
      expect(s.line, isNull);
    });
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

  testWidgets('24 Nov: a moment of progress stays past its time until the '
      'child taps Keep going; a tap elsewhere does not end it', (tester) async {
    var done = 0;
    await show(
      tester,
      CelebrationView(
        spec: const CelebrationSpec(
          moment: 'stop_badge',
          variant: 1,
          title: 'Sapling Row',
          art: SizedBox.square(dimension: 96),
          maxDuration: Duration(milliseconds: 100),
          skippable: true,
          holdFor: 'Keep going',
        ),
        onDone: (_) => done++,
      ),
    );
    await tester.pump(const Duration(seconds: 10));
    await tester.tap(find.text('Sapling Row'));
    await tester.pump();
    expect(done, 0);
    await tester.tap(find.byKey(const Key('celebrationGo')));
    await tester.pump();
    expect(done, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a moment that does not wait ends by itself, no button', (
    tester,
  ) async {
    var done = 0;
    await show(
      tester,
      CelebrationView(
        spec: const CelebrationSpec(
          moment: 'streak_moment',
          variant: 1,
          title: 'You came back!',
          art: SizedBox.square(dimension: 96),
          maxDuration: Duration(milliseconds: 100),
        ),
        onDone: (_) => done++,
      ),
    );
    expect(find.byKey(const Key('celebrationGo')), findsNothing);
    await tester.pump(const Duration(milliseconds: 200));
    expect(done, 1);
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

  testWidgets('B1 with a full cabinet: a name that wraps to two lines '
      '(Orchard detective) fits, and the cabinet scrolls', (tester) async {
    final badges = {
      for (final (id, name) in const [
        ('session.first_case', 'First Case'),
        ('habit.bar_builder', 'Bar builder'),
        ('stop.orchard.l3', 'Orchard Gate'),
        ('stop.orchard.l4', 'Old Oak Bridge'),
        ('habit.careful_reader', 'Careful reader'),
        ('stop.orchard.l5', 'Twisty Tree'),
        ('land.orchard', 'Orchard detective'),
      ])
        id: BadgeInfo(name: name, says: name),
    };
    await shots(
      tester,
      'child_home_reward_B1-full',
      BadgesScreen(earned: badges.keys.toList(), badges: badges),
    );
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
