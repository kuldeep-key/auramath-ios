import 'package:auramath/data/repositories/progress_repository.dart';
import 'package:auramath/data/repositories/rewards_repository.dart';
import 'package:auramath/routing/paths.dart';
import 'package:auramath/ui/features/child_home/views/check_screen.dart';
import 'package:auramath/ui/features/child_home/views/trail_screen.dart';
import 'package:auramath/ui/features/child_home/views/trail_top_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  testWidgets('K2 fits every size', (tester) async {
    await shots(
      tester,
      'child_home_trail',
      const TrailScreen(here: TrailStop.trees),
    );
  });

  testWidgets('K2: two stops behind, here, and only the next', (tester) async {
    await show(tester, const TrailScreen(here: TrailStop.trees));
    expect(find.text('Adding to 1000'), findsOneWidget);
    expect(find.text('Taking away to 1000'), findsOneWidget);
    expect(find.text('Done'), findsNWidgets(2));
    expect(find.text('Tree cases'), findsOneWidget);
    expect(find.text('You are here'), findsOneWidget);
    expect(find.text('Tricky word cases'), findsOneWidget);
    expect(find.text('Next stop'), findsOneWidget);
    // nothing further: the child never sees how much is left
    expect(find.text('Burger cases'), findsNothing);

    await show(tester, const TrailScreen(here: TrailStop.totalAndDifference));
    expect(find.text('Next stop'), findsNothing);
    expect(find.text('Adding to 1000'), findsNothing);
  });

  group('REW-04: the trail the server serves', () {
    Map<String, Object?> served5(List<String> states) => {
      'questionTypes': [
        {
          'templateId': 'cmp.comparison',
          'skill': 'cmp.compare-bars',
          'stops': [
            for (final (i, n) in [
              'Cave',
              'Bridge',
              'Lighthouse',
              'Tower',
              'Peak',
            ].indexed)
              {
                'stopId': 'cmp.comparison.L${i + 1}',
                'level': 'L${i + 1}',
                'name': n,
                'state': states[i],
              },
          ],
        },
      ],
      'draftNames': true,
    };
    final served = RewardsRepository.trailFrom(
      served5(['passed', 'passed', 'here', 'next', 'mist']),
    )!;

    testWidgets('fits every size', (tester) async {
      await shots(
        tester,
        'child_home_trail_served',
        TrailScreen(here: TrailStop.trees, served: served),
      );
    });

    testWidgets('names and place from the server, the next in mist', (
      tester,
    ) async {
      await show(tester, TrailScreen(here: TrailStop.addBig, served: served));
      expect(find.text('Cave'), findsOneWidget);
      expect(find.text('Bridge'), findsOneWidget);
      expect(find.text('Lighthouse'), findsOneWidget);
      expect(find.text('You are here'), findsOneWidget);
      expect(find.text('Tower'), findsOneWidget);
      expect(find.text('Peak'), findsNothing);
      expect(find.text('Tree cases'), findsNothing);
    });

    test('the comparison type, its here; all passed is the top; nothing '
        'usable is null', () {
      expect((served.here, served.atTop), (2, false));
      expect(served.stops.first.skillId, 'cmp.compare-bars');
      final top = RewardsRepository.trailFrom(
        served5(List.filled(5, 'passed')),
      )!;
      expect((top.here, top.atTop), (4, true));
      expect(
        RewardsRepository.trailFrom({'questionTypes': <Object>[]}),
        isNull,
      );
      expect(RewardsRepository.trailFrom(null), isNull);
    });
  });

  testWidgets('K2 Keep going opens the next case; home goes home', (
    tester,
  ) async {
    await show(tester, const TrailScreen(here: TrailStop.trees));
    await tapAndSettle(tester, find.text('Keep going'));
    expect(find.text('went to ${Paths.lessonNext}'), findsOneWidget);

    await show(tester, const TrailScreen(here: TrailStop.trees));
    await tapAndSettle(tester, find.byTooltip('Home'));
    expect(find.text('went to ${Paths.home}'), findsOneWidget);
  });

  testWidgets('TrailTop fits every size, without Quick sums', (tester) async {
    await shots(tester, 'child_home_trail_top', const TrailTopScreen());
    await show(tester, const TrailTopScreen());
    expect(find.text('Play Quick sums'), findsNothing);
    await tapAndSettle(tester, find.text('Home'));
    expect(find.text('went to ${Paths.home}'), findsOneWidget);
  });

  testWidgets('Check fits every size and opens the next case', (tester) async {
    await shots(tester, 'child_home_check', const CheckScreen());
    await show(tester, const CheckScreen());
    await tapAndSettle(tester, find.text("Let's play"));
    expect(find.text('went to ${Paths.lessonNext}'), findsOneWidget);
  });
}
