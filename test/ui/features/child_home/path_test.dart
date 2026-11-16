import 'package:auramath/data/repositories/rewards_repository.dart';
import 'package:auramath/data/services/sound_effects.dart';
import 'package:auramath/ui/core/motion/motion.dart';
import 'package:auramath/ui/core/parts/speak_button.dart';
import 'package:auramath/ui/core/parts/journey_art.dart';
import 'package:auramath/ui/features/child_home/views/path_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/shots.dart';
import 'helpers.dart';

/// JRN-03 (journey_avatar_tutor.feature, "The trail drawn as a path"):
/// Aarav at level 2, placed there by the starting check.
void main() {
  final lands = const Rewards({
    'world': 'detective',
    'trail': {
      'lands': [
        {
          'landId': 'orchard',
          'name': 'The Orchard',
          'current': true,
          'stops': [
            {
              'stopId': 'stop.orchard.l1',
              'level': 'L1',
              'name': 'Seedling Path',
              'state': 'explored',
            },
            {
              'stopId': 'stop.orchard.l2',
              'level': 'L2',
              'name': 'Sapling Row',
              'state': 'current',
            },
            {
              'stopId': 'stop.orchard.l3',
              'level': 'L3',
              'name': 'Orchard Gate',
              'state': 'next',
            },
            {
              'stopId': 'stop.orchard.l4',
              'level': 'L4',
              'name': 'Old Oak Bridge',
              'state': 'mist',
            },
            {
              'stopId': 'stop.orchard.l5',
              'level': 'L5',
              'name': 'Twisty Tree',
              'state': 'mist',
            },
          ],
        },
        {
          'landId': 'harbour',
          'name': 'Harbour Scales',
          'teaser': true,
          'open': false,
          'stops': [],
        },
      ],
    },
  }).lands!;

  Widget screen({String? name}) =>
      PathScreen(lands: lands, lookId: 'look_05', childName: name);

  setUp(PathScreen.seen.clear);

  testWidgets('the path fits every size, at 1.3x text too', (tester) async {
    await shots(tester, 'child_home_path', screen(name: 'Aarav'));
  });

  testWidgets('his look at Sapling Row; Seedling Path explored, Orchard Gate '
      'next, the rest in mist; one teaser; no number', (tester) async {
    final handle = tester.ensureSemantics();
    await show(tester, screen(name: 'Aarav'));
    expect(find.text('The Orchard'), findsOneWidget);
    expect(find.text("Aarav's trail"), findsOneWidget);
    expect(find.bySemanticsLabel('Seedling Path, Explored'), findsOneWidget);
    expect(find.bySemanticsLabel('Sapling Row, You are here'), findsOneWidget);
    expect(find.bySemanticsLabel('Orchard Gate, Next stop'), findsOneWidget);
    expect(find.bySemanticsLabel('Still in the mist'), findsOneWidget);
    // nothing named in the mist, and the next land unnamed
    for (final hidden in ['Old Oak Bridge', 'Twisty Tree', 'Harbour Scales']) {
      expect(find.bySemanticsLabel(RegExp(hidden)), findsNothing);
      expect(find.textContaining(hidden), findsNothing);
    }
    final look = tester.widget<LookPortrait>(find.byType(LookPortrait));
    expect(look.lookId, 'look_05');
    // REW-03: no counts, levels or percentages, on screen or read out
    expect(find.textContaining(RegExp(r'\d')), findsNothing);
    expect(find.bySemanticsLabel(RegExp(r'\d')), findsNothing);
    // the first three stops have no Look back below them
    expect(find.byKey(const Key('lookBack')), findsNothing);
    handle.dispose();
  });

  testWidgets('tapping a stop reads its name', (tester) async {
    final said = <String>[];
    await show(tester, ReadAloud(say: said.add, child: screen()));
    await tester.tap(find.byKey(const Key('stop1')));
    expect(said, ['Sapling Row.']);
  });

  testWidgets('Keep going goes to the next case', (tester) async {
    await show(tester, screen());
    await tapAndSettle(tester, find.text('Keep going'));
    expect(find.text('went to /lesson'), findsOneWidget);
  });

  group('the walk (K2 after)', () {
    late RecordingSfxPlayer sfx;
    setUp(() {
      AuraMotion.still = false;
      sfx = RecordingSfxPlayer();
      AuraSound.player = sfx;
    });
    tearDown(() {
      AuraMotion.still = true;
      AuraSound.player = const SilentSfxPlayer();
    });

    Offset walker(WidgetTester tester) =>
        tester.getTopLeft(find.byKey(const Key('walker')));
    Offset stop(WidgetTester tester, int j) =>
        tester.getCenter(find.byKey(Key('stop$j')));

    testWidgets('waits 500 ms, walks up from the stop before for 2.2 s, '
        'snaps, then bobs; the next open stands still', (tester) async {
      tester.view.physicalSize = shotSizes['iphone15']! * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(shotApp(screen()));
      await tester.pump();
      final from = stop(tester, 0), to = stop(tester, 1);
      // the walker's pin (64 wide, its centre 52 above the path)
      Offset centre() => walker(tester) + const Offset(32, 32);
      expect(centre().dx, closeTo(from.dx, 2));
      await tester.pump(const Duration(milliseconds: 450));
      expect(centre().dx, closeTo(from.dx, 2), reason: 'still waiting');
      await tester.pump(const Duration(milliseconds: 1150));
      final mid = centre();
      expect(mid.dy, lessThan(from.dy - 52));
      expect(mid.dy, greaterThan(to.dy - 52 - 8));
      expect(sfx.played, isEmpty);
      await tester.pump(const Duration(milliseconds: 1150));
      expect(centre().dx, closeTo(to.dx, 2));
      expect(centre().dy, closeTo(to.dy - 52, 2));
      expect(sfx.played, [Sfx.snap]);
      // idle: it bobs up to 5 pt, every 2.2 s
      await tester.pump(const Duration(milliseconds: 1100));
      expect(centre().dy, closeTo(to.dy - 52, 1), reason: 'shadow stays');

      // the next time the trail opens, the child is already there
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(shotApp(screen()));
      await tester.pump();
      expect(centre().dx, closeTo(stop(tester, 1).dx, 2));
      await tester.pump(const Duration(seconds: 3));
      expect(sfx.played, [Sfx.snap]);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('reduced motion: the still map, the child at their stop', (
      tester,
    ) async {
      tester.view.physicalSize = shotSizes['iphone15']! * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: shotApp(screen()),
        ),
      );
      await tester.pump();
      final at = walker(tester) + const Offset(32, 32);
      expect(at.dx, closeTo(stop(tester, 1).dx, 2));
      await tester.pump(const Duration(seconds: 3));
      expect(walker(tester) + const Offset(32, 32), at);
      expect(sfx.played, isEmpty);
    });
  });

  testWidgets('far along: Look back shows the older stops', (tester) async {
    final long = Rewards({
      'trail': {
        'lands': [
          {
            'landId': 'orchard',
            'name': 'The Orchard',
            'current': true,
            'stops': [
              for (final (i, n) in [
                'Seedling Path',
                'Sapling Row',
                'Orchard Gate',
                'Old Oak Bridge',
                'Twisty Tree',
                'Sunny Meadow',
              ].indexed)
                {
                  'stopId': 'stop.orchard.$i',
                  'name': n,
                  'state': i < 5 ? 'earned' : 'current',
                },
            ],
          },
        ],
      },
    }).lands!;
    final handle = tester.ensureSemantics();
    await show(tester, PathScreen(lands: long, lookId: 'look_01'));
    expect(find.bySemanticsLabel('Seedling Path, Earned'), findsNothing);
    expect(find.bySemanticsLabel('Sapling Row, Earned'), findsNothing);
    expect(find.bySemanticsLabel('Orchard Gate, Earned'), findsOneWidget);
    expect(find.bySemanticsLabel('Sunny Meadow, You are here'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('lookBack')));
    await tapAndSettle(tester, find.byKey(const Key('lookBack')));
    expect(find.bySemanticsLabel('Seedling Path, Earned'), findsOneWidget);
    expect(find.byKey(const Key('lookBack')), findsNothing);
    handle.dispose();
  });
}
