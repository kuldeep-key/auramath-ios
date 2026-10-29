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
}
