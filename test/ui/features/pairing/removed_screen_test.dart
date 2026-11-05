import 'package:auramath/data/repositories/account_repository.dart';
import 'package:auramath/routing/paths.dart';
import 'package:auramath/ui/features/pairing/views/removed_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/app_harness.dart';
import '../../../helpers/shots.dart';

void main() {
  testWidgets('fits every size', (tester) async {
    final (deps, _) = (await tester.runAsync(
      () => testDeps(stored: pairedChildPhone),
    ))!;
    await shotAllSizes(
      tester,
      'pairing_removed',
      RemovedScreen(account: deps.account),
    );
    expect(find.text('This phone was removed'), findsOneWidget);
  });

  testWidgets('OK forgets the pairing and starts again', (tester) async {
    final (deps, _) = (await tester.runAsync(
      () => testDeps(stored: pairedChildPhone),
    ))!;
    deps.account.unauthorized(); // the grown-up removed it
    expect(deps.account.removed, isTrue);

    await tester.pumpWidget(shotApp(RemovedScreen(account: deps.account)));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(deps.account.role, Role.none);
    expect(deps.account.removed, isFalse);
    expect(deps.account.childId, isNull);
    expect(find.text('went to ${Paths.open}'), findsOneWidget);
  });
}
