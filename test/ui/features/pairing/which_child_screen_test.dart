import 'package:auramath/data/repositories/family_repository.dart';
import 'package:auramath/routing/paths.dart';
import 'package:auramath/ui/features/pairing/views/which_child_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/app_harness.dart';
import '../../../helpers/shots.dart';
import 'pairing_helpers.dart';

const _children = 'GET /api/children';

void main() {
  Future<(FamilyRepository, FakeServer)> setUp(WidgetTester tester) async {
    final (deps, server) = (await tester.runAsync(
      () => testDeps(stored: {'deviceToken': 't', 'deviceId': 'd'}),
    ))!;
    return (deps.family, server);
  }

  testWidgets('fits every size', (tester) async {
    final (family, server) = await setUp(tester);
    server.on(_children, familyJson(['Sam', 'Ari']));
    await loadPortraits(tester);
    await shotAllSizes(
      tester,
      'pairing_which_child',
      WhichChildScreen(family: family),
    );
    expect(find.text('Ari'), findsOneWidget);
  });

  testWidgets('tapping a child asks "is this you?"', (tester) async {
    final (family, server) = await setUp(tester);
    server.on(_children, familyJson(['Sam', 'Ari']));
    await tester.pumpWidget(shotApp(WhichChildScreen(family: family)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ari'));
    await tester.pumpAndSettle();
    expect(
      find.text('went to ${Paths.pairIsThisYou}?id=c1&name=Ari'),
      findsOneWidget,
    );
  });

  testWidgets('a failure shows the message and tries again', (tester) async {
    final (family, server) = await setUp(tester);
    server.on(_children, {'error': 'database is down'}, status: 500);
    await tester.pumpWidget(shotApp(WhichChildScreen(family: family)));
    await tester.pumpAndSettle();
    expect(find.text("That didn't work: database is down"), findsOneWidget);

    server.on(_children, familyJson(['Sam']));
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Sam'), findsOneWidget);
    expect(server.calls.length, 2);
  });

  testWidgets('no children yet says ask your grown-up', (tester) async {
    final (family, server) = await setUp(tester);
    server.on(_children, familyJson([]));
    await tester.pumpWidget(shotApp(WhichChildScreen(family: family)));
    await tester.pumpAndSettle();
    expect(find.textContaining('Ask your grown-up to add you'), findsOneWidget);
  });
}
