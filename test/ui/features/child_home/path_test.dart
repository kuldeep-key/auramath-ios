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

  Widget screen({String? name, int? seenAt = 5}) => PathScreen(
    lands: lands,
    lookId: 'look_05',
    childName: name,
    seenAt: seenAt,
  );

  testWidgets('the path fits every size, at 1.3x text too', (tester) async {
    await shots(tester, 'child_home_path', screen(name: 'Aarav'));
  });

  testWidgets('23 Nov: the whole track so far, the lands behind named at '
      'their way in with their peak; his stop, the next two by name, the '
      'peak, then mist; no number', (tester) async {
    final handle = tester.ensureSemantics();
    await show(tester, screen(name: 'Aarav'));
    // the header: his land and his trail (the level number switch is off)
    expect(find.text('Sapling Row'), findsOneWidget);
    expect(find.text("Aarav's trail"), findsOneWidget);
    // the land behind, from its way in: named, its peak with a flag
    expect(find.bySemanticsLabel('Seedling Path, Explored'), findsOneWidget);
    expect(find.bySemanticsLabel('The peak, Explored'), findsOneWidget);
    // his land: his stop, the next two by name, its peak
    expect(find.bySemanticsLabel('Sapling Row, You are here'), findsOneWidget);
    expect(find.bySemanticsLabel('Little Fence, Next stop'), findsOneWidget);
    expect(find.bySemanticsLabel('Tall Sprouts'), findsOneWidget);
    expect(find.bySemanticsLabel('The peak'), findsOneWidget);
    expect(find.bySemanticsLabel('Still in the mist'), findsOneWidget);
    // every stop of both lands is drawn; the walked ones and the one
    // ahead of the next two have no sign and nothing to tap
    for (final j in [0, 4, 5, 6, 7, 9]) {
      expect(find.byKey(Key('stop$j')), findsOneWidget, reason: 'stop$j');
    }
    for (final j in [1, 2, 3, 8, 10]) {
      expect(find.byKey(Key('stop$j')), findsNothing, reason: 'stop$j');
    }
    // nothing named in the mist, and the next land unnamed
    for (final hidden in [
      'Bird Bath',
      'Orchard Gate',
      'Old Oak Bridge',
      'Twisty Tree',
      'Harbour Scales',
    ]) {
      expect(find.bySemanticsLabel(RegExp(hidden)), findsNothing);
      expect(find.textContaining(hidden), findsNothing);
    }
    final look = tester.widget<LookPortrait>(find.byType(LookPortrait));
    expect(look.lookId, 'look_05');
    // REW-03: no counts, levels or percentages, on screen or read out
    expect(find.textContaining(RegExp(r'\d')), findsNothing);
    expect(find.bySemanticsLabel(RegExp(r'\d')), findsNothing);
    // the whole track is there: no Look back
    expect(find.byKey(const Key('lookBack')), findsNothing);
    handle.dispose();
  });

  testWidgets("the next stop opens below the title, and the child's stop "
      'above Keep going, on every phone', (tester) async {
    addTearDown(tester.view.reset);
    for (final size in const [Size(390, 844), Size(375, 667), Size(430, 932)]) {
      tester.view.physicalSize = size * 3;
      tester.view.devicePixelRatio = 3;
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(shotApp(screen(name: 'Aarav')));
      await tester.pumpAndSettle();
      final title = tester.getRect(find.text("Aarav's trail"));
      final next = tester.getRect(find.byKey(const Key('stop6')));
      final here = tester.getRect(find.byKey(const Key('stop5')));
      final go = tester.getRect(find.text('Keep going'));
      expect(next.top, greaterThan(title.bottom), reason: '$size: next stop');
      expect(here.bottom, lessThan(go.top), reason: '$size: the child');
    }
  });

  testWidgets('tapping a stop reads its name', (tester) async {
    final said = <String>[];
    await show(tester, ReadAloud(say: said.add, child: screen()));
    await tester.tap(find.byKey(const Key('stop5')));
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

    /// The walker's pin centre (64 wide, 52 above the path).
    Offset centre(WidgetTester tester) => walker(tester) + const Offset(32, 32);

    Future<void> open(WidgetTester tester, Widget w) async {
      tester.view.physicalSize = shotSizes['iphone15']! * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(shotApp(w));
      await tester.pump();
    }

    testWidgets('24 Nov: never seen on this phone (a new sign-in, the app '
        'opened afresh): it stands at its stop, no walk', (tester) async {
      final seen = <(String, int)>[];
      await open(
        tester,
        PathScreen(
          lands: lands,
          lookId: 'look_05',
          onSeen: (land, stop) => seen.add((land, stop)),
        ),
      );
      expect(seen, [('orchard', 5)]);
      expect(centre(tester).dx, closeTo(stop(tester, 5).dx, 2));
      await tester.pump(const Duration(seconds: 8));
      expect(centre(tester).dy, closeTo(stop(tester, 5).dy - 52, 6));
      expect(sfx.played, isEmpty);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('seen there before: it stands at its stop, no walk', (
      tester,
    ) async {
      await open(tester, screen());
      expect(centre(tester).dx, closeTo(stop(tester, 5).dx, 2));
      await tester.pump(const Duration(seconds: 3));
      expect(centre(tester).dy, closeTo(stop(tester, 5).dy - 52, 6));
      expect(sfx.played, isEmpty);
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
          child: shotApp(screen(seenAt: null)),
        ),
      );
      await tester.pump();
      final at = walker(tester) + const Offset(32, 32);
      expect(at.dx, closeTo(stop(tester, 5).dx, 2));
      await tester.pump(const Duration(seconds: 3));
      expect(walker(tester) + const Offset(32, 32), at);
      expect(sfx.played, isEmpty);
    });
  });

  List<PathLand> orchard(List<String> states, {Object? stopInLevel}) =>
      Rewards({
        'trail': {
          'lands': [
            {
              'landId': 'orchard',
              'name': 'The Orchard',
              'current': true,
              'stopInLevel': ?stopInLevel,
              'stops': [
                for (final (i, n) in [
                  'Seedling Path',
                  'Sapling Row',
                  'Orchard Gate',
                  'Old Oak Bridge',
                  'Twisty Tree',
                ].indexed)
                  {
                    'stopId': 'stop.orchard.l${i + 1}',
                    'name': n,
                    'state': states[i],
                  },
              ],
            },
          ],
        },
      }).lands!;

  testWidgets('far along: the lands before on the track, each named at its '
      'way in, a medal on each peak', (tester) async {
    final handle = tester.ensureSemantics();
    await show(
      tester,
      PathScreen(
        lands: orchard(['earned', 'earned', 'current', 'mist', 'mist']),
        lookId: 'look_01',
        seenAt: 10,
      ),
    );
    expect(find.text('Orchard Gate'), findsOneWidget);
    expect(find.bySemanticsLabel('Orchard Gate, You are here'), findsOneWidget);
    expect(find.bySemanticsLabel('Apple Cart, Next stop'), findsOneWidget);
    expect(find.bySemanticsLabel('Pear Arch'), findsOneWidget);
    expect(find.bySemanticsLabel('Seedling Path'), findsOneWidget);
    expect(find.bySemanticsLabel('Sapling Row'), findsOneWidget);
    expect(find.bySemanticsLabel('The peak, Earned'), findsNWidgets(2));
    expect(find.byKey(const Key('lookBack')), findsNothing);
    handle.dispose();
  });

  testWidgets('a child placed at a higher level: the lands before show as '
      'explored, a flag on the peak and no medal', (tester) async {
    final handle = tester.ensureSemantics();
    await show(
      tester,
      PathScreen(
        lands: orchard(['explored', 'explored', 'explored', 'current', 'mist']),
        lookId: 'look_01',
      ),
    );
    // the three lands behind on the track, each peak with a flag
    expect(find.bySemanticsLabel('The peak, Explored'), findsNWidgets(3));
    expect(find.bySemanticsLabel(RegExp('Earned')), findsNothing);
    handle.dispose();
  });

  testWidgets('the end of v1: every land climbed, the child on the top of '
      'Twisty Tree, no fog and nothing promised', (tester) async {
    final handle = tester.ensureSemantics();
    final top = PathScreen(
      lands: orchard(['earned', 'earned', 'earned', 'earned', 'earned']),
      lookId: 'look_01',
      childName: 'Aarav',
    );
    await shots(tester, 'child_home_path_top', top);
    await show(tester, top);
    expect(find.text('Twisty Tree'), findsOneWidget);
    expect(find.bySemanticsLabel('The top, You are here'), findsOneWidget);
    expect(find.bySemanticsLabel('Still in the mist'), findsNothing);
    expect(find.bySemanticsLabel('Next stop'), findsNothing);
    expect(find.bySemanticsLabel('The peak'), findsNothing);
    expect(find.textContaining(RegExp(r'\d')), findsNothing);
    handle.dispose();
  });

  group('inside a level: stops 1 to 4 fill in (stopInLevel)', () {
    const atL2 = ['explored', 'current', 'next', 'mist', 'mist'];

    test('the server\'s stopInLevel is read, 0 when absent, never past 3', () {
      expect(orchard(atL2).first.stopInLevel, 0);
      expect(orchard(atL2, stopInLevel: 2).first.stopInLevel, 2);
      expect(orchard(atL2, stopInLevel: 9).first.stopInLevel, 3);
      expect(orchard(atL2, stopInLevel: -1).first.stopInLevel, 0);
      expect(orchard(atL2, stopInLevel: 'two').first.stopInLevel, 0);
      expect(lands.last.stopInLevel, 0); // the teaser
    });

    Offset walker(WidgetTester tester) =>
        tester.getTopLeft(find.byKey(const Key('walker'))) +
        const Offset(32, 32);

    testWidgets('two stops walked: footprints behind, the child at the '
        'third, the next stop, then the peak; no number', (tester) async {
      final handle = tester.ensureSemantics();
      await show(
        tester,
        PathScreen(
          lands: orchard(atL2, stopInLevel: 2),
          lookId: 'look_01',
          seenAt: 7,
        ),
      );
      expect(find.text('Sapling Row'), findsOneWidget); // the title
      expect(
        find.bySemanticsLabel('Tall Sprouts, You are here'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Bird Bath, Next stop'), findsOneWidget);
      expect(find.bySemanticsLabel('The peak'), findsOneWidget);
      // the land behind, the walked stops unnamed, the child, next, peak
      for (final j in [0, 4, 7, 8, 9]) {
        expect(find.byKey(Key('stop$j')), findsOneWidget, reason: 'stop$j');
      }
      for (final j in [5, 6, 10]) {
        expect(find.byKey(Key('stop$j')), findsNothing, reason: 'stop$j');
      }
      final here = tester.getCenter(find.byKey(const Key('stop7')));
      expect(walker(tester).dx, closeTo(here.dx, 2));
      expect(find.textContaining(RegExp(r'\d')), findsNothing);
      expect(find.bySemanticsLabel(RegExp(r'\d')), findsNothing);
      handle.dispose();
    });

    testWidgets('one stop below the peak: the peak is next, never reached '
        'before the level is passed', (tester) async {
      final handle = tester.ensureSemantics();
      await shots(
        tester,
        'child_home_path_below_peak',
        PathScreen(
          lands: orchard(atL2, stopInLevel: 3),
          lookId: 'look_01',
          childName: 'Aarav',
        ),
      );
      await show(
        tester,
        PathScreen(
          lands: orchard(atL2, stopInLevel: 3),
          lookId: 'look_01',
          seenAt: 8,
        ),
      );
      expect(find.bySemanticsLabel('Bird Bath, You are here'), findsOneWidget);
      expect(find.bySemanticsLabel('Next stop'), findsNothing);
      expect(find.bySemanticsLabel('The peak'), findsOneWidget);
      final here = tester.getCenter(find.byKey(const Key('stop8')));
      expect(walker(tester).dx, closeTo(here.dx, 2));
      handle.dispose();
    });

    Future<RecordingSfxPlayer> walkIn(WidgetTester tester, Widget w) async {
      AuraMotion.still = false;
      final sfx = RecordingSfxPlayer();
      AuraSound.player = sfx;
      addTearDown(() {
        AuraMotion.still = true;
        AuraSound.player = const SilentSfxPlayer();
      });
      tester.view.physicalSize = shotSizes['iphone15']! * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(shotApp(w));
      await tester.pump();
      return sfx;
    }

    /// Where the walker stands at stop [j] once the walk is done.
    Future<void> endsAt(WidgetTester tester, int j) async {
      await tester.pump(const Duration(seconds: 8));
      final now = tester.getCenter(find.byKey(Key('stop$j')));
      expect(walker(tester).dx, closeTo(now.dx, 2));
      expect(walker(tester).dy, closeTo(now.dy - 52, 2));
    }

    testWidgets('24 Nov: two stops further in since the last visit: one '
        'step, from the stop before theirs', (tester) async {
      // last seen at Sapling Row's way in (stop 5); now two stops on (7)
      final sfx = await walkIn(
        tester,
        PathScreen(
          lands: orchard(atL2, stopInLevel: 2),
          lookId: 'look_01',
          seenAt: 5,
        ),
      );
      final there = tester.getCenter(find.byKey(const Key('stop7')));
      expect(walker(tester).dy, greaterThan(there.dy - 52 + 20));
      await endsAt(tester, 7);
      expect(sfx.played, [Sfx.snap]);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('24 Nov: the first step of all, never seen: the first stop '
        'to the second', (tester) async {
      final sfx = await walkIn(
        tester,
        PathScreen(
          lands: orchard([
            'current',
            'next',
            'mist',
            'mist',
            'mist',
          ], stopInLevel: 1),
          lookId: 'look_01',
        ),
      );
      final there = tester.getCenter(find.byKey(const Key('stop1')));
      expect(walker(tester).dy, greaterThan(there.dy - 52 + 20));
      await endsAt(tester, 1);
      expect(sfx.played, [Sfx.snap]);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('24 Nov: a level passed: from the stop below the peak, over '
        'it, to the next land\'s way in', (tester) async {
      final sfx = await walkIn(
        tester,
        PathScreen(
          lands: orchard(atL2, stopInLevel: 0),
          lookId: 'look_01',
          seenAt: 3,
        ),
      );
      await endsAt(tester, 5);
      expect(sfx.played, [Sfx.snap, Sfx.snap]);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('24 Nov: seen at their stop, or somewhere else after a new '
        'sign-in: no walk', (tester) async {
      for (final seenAt in [7, 9]) {
        final sfx = await walkIn(
          tester,
          PathScreen(
            lands: orchard(atL2, stopInLevel: 2),
            lookId: 'look_01',
            seenAt: seenAt,
          ),
        );
        final now = tester.getCenter(find.byKey(const Key('stop7')));
        expect(walker(tester).dx, closeTo(now.dx, 2));
        await tester.pump(const Duration(seconds: 8));
        expect(sfx.played, isEmpty);
        await tester.pumpWidget(const SizedBox());
      }
    });
  });
}
