import 'package:auramath/routing/paths.dart';
import 'package:auramath/ui/features/pairing/views/phone_joined_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/shots.dart';

void main() {
  testWidgets('fits every size', (tester) async {
    await shotAllSizes(
      tester,
      'pairing_phone_joined',
      const PhoneJoinedScreen(name: 'Sam'),
    );
    expect(find.text("You're in, Sam!"), findsOneWidget);
  });

  testWidgets("Let's go goes home", (tester) async {
    await tester.pumpWidget(shotApp(const PhoneJoinedScreen(name: 'Sam')));
    await tester.tap(find.text("Let's go"));
    await tester.pumpAndSettle();
    expect(find.text('went to ${Paths.home}'), findsOneWidget);
  });
}
