import 'dart:io';

import 'package:auramath/ui/features/child_home/views/orchard/stop_names.dart';
import 'package:flutter_test/flutter_test.dart';

/// 23 Nov: each stop in a land has its own name, so the child's stop and
/// the next never read the same; never a number (numbers_shown: none).
void main() {
  test('every land in the catalogue has three names, all different, no '
      'number, none the land\'s own', () {
    final catalogue = File('assets/spec/catalogue.yaml').readAsStringSync();
    final lands = [
      for (final m in RegExp(
        r'id: stop\.(?:orchard|harbour)\.\w+.*names: \{detective: ([^,]+),\s+'
        r'space: ([^,]+),\s+wildlife: ([^}]+)\}',
      ).allMatches(catalogue))
        for (final g in [1, 2, 3]) m[g]!.trim(),
    ];
    expect(lands, hasLength(24));
    for (final land in lands) {
      final names = draftStopNames[land];
      expect(names, hasLength(3), reason: land);
      expect({land, ...names!}, hasLength(4), reason: land);
      expect(names.any((n) => RegExp(r'\d').hasMatch(n)), isFalse);
    }
  });

  test('a stop by its place in the land: the first is the land', () {
    expect(stopNameIn('Sapling Row', 0), 'Sapling Row');
    expect(stopNameIn('Sapling Row', 1), 'Little Fence');
    expect(stopNameIn('Sapling Row', 3), 'Bird Bath');
    expect(stopNameIn('Sapling Row', 4), isNull);
    expect(stopNameIn('Somewhere new', 1), isNull);
  });
}
