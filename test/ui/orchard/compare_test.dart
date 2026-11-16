import 'dart:io';

import 'package:auramath/data/repositories/rewards_repository.dart';
import 'package:auramath/ui/core/parts/journey_art.dart';
import 'package:auramath/ui/features/child_home/views/path_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/child_home/helpers.dart';

/// The prototype's K2 as it opens (level 3: Orchard Gate, two explored
/// stops behind, Old Oak Bridge next), for the side-by-side check.
/// Writes only with COMPARE_DIR set.
void main() {
  testWidgets('K2', (tester) async {
    final dir = Platform.environment['COMPARE_DIR'];
    if (dir == null) return;
    final lands = const Rewards({
      'trail': {
        'lands': [
          {
            'landId': 'orchard',
            'name': 'The Orchard',
            'current': true,
            'stops': [
              {'stopId': 'a', 'name': 'Seedling Path', 'state': 'explored'},
              {'stopId': 'b', 'name': 'Sapling Row', 'state': 'explored'},
              {'stopId': 'c', 'name': 'Orchard Gate', 'state': 'current'},
              {'stopId': 'd', 'name': 'Old Oak Bridge', 'state': 'next'},
              {'stopId': 'e', 'name': 'Twisty Tree', 'state': 'mist'},
            ],
          },
          {'landId': 'harbour', 'name': 'Harbour', 'teaser': true, 'stops': []},
        ],
      },
    }).lands!;
    await tester.runAsync(ArtAssets.load);
    await tester.pumpWidget(const SizedBox());
    final context = tester.element(find.byType(SizedBox));
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/proto/look_01_detective.jpg'),
        context,
      ),
    );
    await shots(
      tester,
      'compare_K2',
      PathScreen(lands: lands, lookId: 'look_01', childName: 'Aarav'),
    );
    File('build/shots/compare_K2@iphone15.png').copySync('$dir/K2-app.png');
  });
}
