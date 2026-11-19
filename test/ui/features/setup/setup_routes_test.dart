import 'package:auramath/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/app_harness.dart';
import 'setup_test_helpers.dart';

void main() {
  testWidgets('the real router walks Welcome → Name → Age with back', (
    tester,
  ) async {
    final (deps, _) = await setupDeps(tester);
    await tester.pumpWidget(AuraApp(deps: deps, initialLocation: '/welcome'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Aarav');
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('How old is Aarav?'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text("Your child's first name"), findsOneWidget);
  });

  testWidgets('a signed-in grown-up lands on Ready with the child', (
    tester,
  ) async {
    final (deps, _) = await setupDeps(tester, stored: parentPhone);
    await tester.pumpWidget(
      AuraApp(
        deps: deps,
        initialLocation: '/setup/ready?child=child-9&name=Aarav',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Hand over to Aarav'), findsOneWidget);
  });

  testWidgets('H9: a setup backed out of is forgotten on Welcome, Sign in '
      'and sign-out, so a later email sign-in never adds that child', (
    tester,
  ) async {
    final (deps, _) = await setupDeps(tester);
    final draft = deps.account.draft;
    void abandoned() => draft
      ..name = 'Aarav'
      ..age = 8
      ..agreed = true;

    for (final at in ['/sign-in', '/welcome']) {
      abandoned();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(AuraApp(deps: deps, initialLocation: at));
      await tester.pumpAndSettle();
      expect(draft.agreed, isFalse, reason: at);
      expect(draft.name, isNull, reason: at);
    }

    abandoned();
    await tester.runAsync(deps.account.signOut);
    expect(draft.agreed, isFalse);
    expect(draft.age, isNull);
  });
}
