import 'package:auramath/routing/paths.dart';
import 'package:auramath/ui/features/pairing/views/open_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/shots.dart';
import 'pairing_helpers.dart';

void main() {
  testWidgets('fits every size', (tester) async {
    await loadPortraits(tester);
    await shotAllSizes(tester, 'pairing_open', const OpenScreen());
    expect(find.text("Hi! Who's using Auramath?"), findsOneWidget);
  });

  for (final (tap, to) in [
    ("I'm a kid", Paths.pair),
    ("I'm a grown-up", Paths.welcome),
    ('I already have an account', Paths.signIn),
  ]) {
    testWidgets('$tap goes to $to', (tester) async {
      await tester.pumpWidget(shotApp(const OpenScreen()));
      await tester.tap(find.text(tap));
      await tester.pumpAndSettle();
      expect(find.text('went to $to'), findsOneWidget);
    });
  }
}
