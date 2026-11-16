import 'package:auramath/data/repositories/rewards_repository.dart';
import 'package:auramath/ui/core/parts/journey_art.dart';
import 'package:auramath/ui/features/child_home/views/path_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
            {'stopId': 'stop.orchard.l1', 'level': 'L1', 'name': 'Seedling Path', 'state': 'explored'},
            {'stopId': 'stop.orchard.l2', 'level': 'L2', 'name': 'Sapling Row', 'state': 'current'},
            {'stopId': 'stop.orchard.l3', 'level': 'L3', 'name': 'Orchard Gate', 'state': 'next'},
            {'stopId': 'stop.orchard.l4', 'level': 'L4', 'name': 'Old Oak Bridge', 'state': 'mist'},
            {'stopId': 'stop.orchard.l5', 'level': 'L5', 'name': 'Twisty Tree', 'state': 'mist'},
          ],
        },
        {'landId': 'harbour', 'name': 'Harbour Scales', 'teaser': true, 'open': false, 'stops': []},
      ],
    },
  }).lands!;

  Widget screen() => PathScreen(lands: lands, lookId: 'look_05');

  testWidgets('the path fits every size, at 1.3x text too', (tester) async {
    await shots(tester, 'child_home_path', screen());
  });

  testWidgets('his look at Sapling Row; Seedling Path explored, Orchard Gate '
      'next, the rest in mist; one teaser; no number', (tester) async {
    await show(tester, screen());
    expect(find.text('The Orchard'), findsOneWidget);
    expect(find.text('Seedling Path'), findsOneWidget);
    expect(find.text('EXPLORED'), findsOneWidget);
    expect(find.text('Sapling Row'), findsOneWidget);
    expect(find.text('YOU ARE HERE'), findsOneWidget);
    expect(find.text('Orchard Gate'), findsOneWidget);
    expect(find.text('NEXT STOP'), findsOneWidget);
    // nothing named in the mist, and the next land unnamed
    expect(find.text('Old Oak Bridge'), findsNothing);
    expect(find.text('Twisty Tree'), findsNothing);
    expect(find.text('Harbour Scales'), findsNothing);
    final look = tester.widget<LookPortrait>(find.byType(LookPortrait));
    expect(look.lookId, 'look_05');
    // REW-03: no counts, levels or percentages
    expect(find.textContaining(RegExp(r'\d')), findsNothing);
  });
}
