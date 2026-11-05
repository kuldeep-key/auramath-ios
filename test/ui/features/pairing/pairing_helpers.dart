import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/shots.dart';

/// Decodes the portraits for real, so screenshots show faces, not empty
/// rings (a widget test's fake clock never finishes loading an asset).
Future<void> loadPortraits(WidgetTester tester) async {
  await tester.pumpWidget(shotApp(const Placeholder()));
  final context = tester.element(find.byType(Placeholder));
  await tester.runAsync(
    () => Future.wait([
      for (final a in [
        'assets/images/detective_boy.jpg',
        'assets/images/detective_girl.jpg',
      ])
        precacheImage(AssetImage(a), context),
    ]),
  );
}

/// `{"children": [...]}` as `/api/children` answers, ids `c0`, `c1`, ...
Map<String, Object?> familyJson(List<String> names) => {
  'children': [
    for (final (i, n) in names.indexed) {'id': 'c$i', 'displayName': n},
  ],
};
