import 'package:auramath/ui/features/setup/views/setup_parts.dart';
import 'package:auramath/ui/features/setup/views/welcome_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/shots.dart';
import 'setup_test_helpers.dart';

void main() {
  testWidgets('Welcome fits every size', (tester) async {
    await precacheAssets(tester, [kidBoy, kidGirl]);
    await shotAllSizes(tester, 'setup_welcome', const WelcomeScreen());
  });

  testWidgets('Get started opens Name', (tester) async {
    await show(tester, const WelcomeScreen());
    await tapAndWait(tester, find.text('Get started'));
    expect(find.text('went to /setup/name'), findsOneWidget);
  });

  testWidgets('I already have an account opens SignIn', (tester) async {
    await show(tester, const WelcomeScreen());
    await tapAndWait(tester, find.text('I already have an account'));
    expect(find.text('went to /sign-in'), findsOneWidget);
  });

  testWidgets('the free check is not offered this term', (tester) async {
    await show(tester, const WelcomeScreen());
    expect(find.text('Try a free check first'), findsNothing);
  });
}
