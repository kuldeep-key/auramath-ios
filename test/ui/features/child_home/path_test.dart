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

  testWidgets('section 15: his level is one land, Sapling Row, his look at '
      'its way in, the last land\'s peak below with a flag, the next stop, '
      'its peak, then mist; no number', (tester) async {
    final handle = tester.ensureSemantics();
    await show(tester, screen(name: 'Aarav'));
    // the header: his land and his trail (the level number switch is off)
    expect(find.text('Sapling Row'), findsOneWidget);
    expect(find.text("Aarav's trail"), findsOneWidget);
    expect(find.bySemanticsLabel('The peak, Explored'), findsOneWidget);
    expect(find.bySemanticsLabel('Sapling Row, You are here'), findsOneWidget);
    expect(find.bySemanticsLabel('Little Fence, Next stop'), findsOneWidget);
    expect(find.bySemanticsLabel('The peak'), findsOneWidget);
    expect(find.bySemanticsLabel('Still in the mist'), findsOneWidget);
    // five stops in the land and the last land's peak; the stops ahead
    // have no sign and nothing to tap
    for (final j in [0, 1, 2, 5]) {
      expect(find.byKey(Key('stop$j')), findsOneWidget, reason: 'stop$j');
    }
    for (final j in [3, 4, 6]) {
      expect(find.byKey(Key('stop$j')), findsNothing, reason: 'stop$j');
    }
    // nothing named in the mist, and the next land unnamed
    for (final hidden in [
      'Seedling Path',
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
    // Look back opens the first land below
    expect(find.byKey(const Key('lookBack')), findsOneWidget);
    handle.dispose();
  });

  testWidgets("the next stop opens below the title, and the child's stop "
      'above Keep going, on every phone', (tester) async {
    addTearDown(tester.view.reset);
    for (final size in const [Size(390, 844), Size(375, 667), Size(430, 932)]) {
      tester.view.physicalSize = size * 3;
      tester.view.devicePixelRatio = 3;
      PathScreen.seen.clear();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(shotApp(screen(name: 'Aarav')));
      await tester.pumpAndSettle();
      final title = tester.getRect(find.text("Aarav's trail"));
      final next = tester.getRect(find.byKey(const Key('stop2')));
      final here = tester.getRect(find.byKey(const Key('stop1')));
      final go = tester.getRect(find.text('Keep going'));
      expect(next.top, greaterThan(title.bottom), reason: '$size: next stop');
      expect(here.bottom, lessThan(go.top), reason: '$size: the child');
    }
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
      expect(centre().dy, closeTo(to.dy - 52, 2), reason: 'shadow stays');

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

  testWidgets('far along: Look back shows the land before, walked, with its '
      'medal on its peak', (tester) async {
    final handle = tester.ensureSemantics();
    await show(
      tester,
      PathScreen(
        lands: orchard(['earned', 'earned', 'current', 'mist', 'mist']),
        lookId: 'look_01',
      ),
    );
    expect(find.text('Orchard Gate'), findsOneWidget);
    expect(find.bySemanticsLabel('Orchard Gate, You are here'), findsOneWidget);
    expect(find.bySemanticsLabel('The peak, Earned'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Sapling Row')), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('lookBack')));
    await tapAndSettle(tester, find.byKey(const Key('lookBack')));
    // Sapling Row's land: its way in named, its peak with its medal
    expect(find.bySemanticsLabel('Sapling Row'), findsOneWidget);
    expect(find.bySemanticsLabel('The peak, Earned'), findsNWidgets(2));
    expect(find.byKey(const Key('lookBack')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('lookBack')));
    await tapAndSettle(tester, find.byKey(const Key('lookBack')));
    expect(find.bySemanticsLabel('Seedling Path'), findsOneWidget);
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
    expect(find.bySemanticsLabel('The peak, Explored'), findsOneWidget);
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
        PathScreen(lands: orchard(atL2, stopInLevel: 2), lookId: 'look_01'),
      );
      expect(find.text('Sapling Row'), findsOneWidget); // the title
      expect(
        find.bySemanticsLabel('Tall Sprouts, You are here'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Bird Bath, Next stop'), findsOneWidget);
      expect(find.bySemanticsLabel('The peak'), findsOneWidget);
      // the last land's peak, the walked stops unnamed, the child, next, peak
      for (final j in [0, 3, 4, 5]) {
        expect(find.byKey(Key('stop$j')), findsOneWidget, reason: 'stop$j');
      }
      for (final j in [1, 2, 6]) {
        expect(find.byKey(Key('stop$j')), findsNothing, reason: 'stop$j');
      }
      final here = tester.getCenter(find.byKey(const Key('stop3')));
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
      PathScreen.seen.clear();
      await show(
        tester,
        PathScreen(lands: orchard(atL2, stopInLevel: 3), lookId: 'look_01'),
      );
      expect(find.bySemanticsLabel('Bird Bath, You are here'), findsOneWidget);
      expect(find.bySemanticsLabel('Next stop'), findsNothing);
      expect(find.bySemanticsLabel('The peak'), findsOneWidget);
      final here = tester.getCenter(find.byKey(const Key('stop4')));
      expect(walker(tester).dx, closeTo(here.dx, 2));
      handle.dispose();
    });

    testWidgets('a stop further in since the last visit: the child walks '
        'up from the stop before, once', (tester) async {
      AuraMotion.still = false;
      addTearDown(() => AuraMotion.still = true);
      tester.view.physicalSize = shotSizes['iphone15']! * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      Widget at(int k) => shotApp(
        PathScreen(
          lands: orchard(atL2, stopInLevel: k),
          lookId: 'look_01',
        ),
      );
      await tester.pumpWidget(at(0));
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpWidget(const SizedBox());
      // the next visit: the engine has moved the child one stop on
      await tester.pumpWidget(at(1));
      await tester.pump();
      final there = tester.getCenter(find.byKey(const Key('stop2')));
      final from = walker(tester);
      expect(from.dy, greaterThan(there.dy - 52 + 20), reason: 'below');
      await tester.pump(walkDelay + walkDuration);
      expect(walker(tester).dx, closeTo(there.dx, 2));
      expect(walker(tester).dy, closeTo(there.dy - 52, 2));
      // and the time after, they are already there
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(at(1));
      await tester.pump();
      expect(walker(tester).dx, closeTo(there.dx, 2));
      await tester.pumpWidget(const SizedBox());
    });
  });
}
