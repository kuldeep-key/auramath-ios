import 'package:auramath/data/repositories/account_repository.dart';
import 'package:auramath/routing/paths.dart';
import 'package:auramath/ui/features/pairing/views/is_this_you_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/app_harness.dart';
import '../../../helpers/shots.dart';
import 'pairing_helpers.dart';

void main() {
  Future<AccountRepository> account(WidgetTester tester) async =>
      (await tester.runAsync(
        () => testDeps(stored: {'deviceToken': 't', 'deviceId': 'd'}),
      ))!.$1.account;

  testWidgets('fits every size', (tester) async {
    final a = await account(tester);
    await loadPortraits(tester);
    await shotAllSizes(
      tester,
      'pairing_is_this_you',
      IsThisYouScreen(account: a, childId: 'c0', name: 'Sam'),
    );
    expect(find.text('Sam'), findsOneWidget);
  });

  testWidgets("Yes chooses the child and says you're in", (tester) async {
    final a = await account(tester);
    await tester.pumpWidget(
      shotApp(IsThisYouScreen(account: a, childId: 'c0', name: 'Sam')),
    );
    await tester.tap(find.text("Yes, that's me!"));
    await tester.pumpAndSettle();
    expect(a.childId, 'c0');
    expect(find.text('went to ${Paths.pairJoined}?name=Sam'), findsOneWidget);
  });

  testWidgets('No asks which child again', (tester) async {
    final a = await account(tester);
    await tester.pumpWidget(
      shotApp(IsThisYouScreen(account: a, childId: 'c0', name: 'Sam')),
    );
    await tester.tap(find.text('No'));
    await tester.pumpAndSettle();
    expect(a.childId, isNull);
    expect(find.text('went to ${Paths.pairWhichChild}'), findsOneWidget);
  });
}
