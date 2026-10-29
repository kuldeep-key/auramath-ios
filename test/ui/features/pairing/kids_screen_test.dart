import 'package:auramath/deps.dart';
import 'package:auramath/routing/paths.dart';
import 'package:auramath/ui/features/pairing/views/kids_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/app_harness.dart';
import '../../../helpers/shots.dart';
import 'pairing_helpers.dart';

const _children = 'GET /api/children';

void main() {
  Future<(Deps, FakeServer)> setUp(WidgetTester tester) async =>
      (await tester.runAsync(() => testDeps(stored: parentPhone)))!;

  KidsScreen screen(Deps d) => KidsScreen(account: d.account, family: d.family);

  testWidgets('fits every size', (tester) async {
    final (deps, server) = await setUp(tester);
    server.on(_children, familyJson(['Sam', 'Ari', 'Jo']));
    await loadPortraits(tester);
    await shotAllSizes(tester, 'pairing_kids', screen(deps));
    expect(find.text('Jo'), findsOneWidget);
  });

  testWidgets('a child taps their picture and goes home', (tester) async {
    final (deps, server) = await setUp(tester);
    server.on(_children, familyJson(['Sam', 'Ari']));
    await tester.pumpWidget(shotApp(screen(deps)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ari'));
    await tester.pumpAndSettle();
    expect(deps.account.childId, 'c1');
    expect(find.text('went to ${Paths.home}'), findsOneWidget);
  });

  testWidgets('Grown-ups goes to the grown-up area', (tester) async {
    final (deps, server) = await setUp(tester);
    server.on(_children, familyJson(['Sam']));
    await tester.pumpWidget(shotApp(screen(deps)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Grown-ups'));
    await tester.pumpAndSettle();
    expect(find.text('went to ${Paths.grownUps}'), findsOneWidget);
  });

  testWidgets('no children: add one', (tester) async {
    final (deps, server) = await setUp(tester);
    server.on(_children, familyJson([]));
    await shotAllSizes(tester, 'pairing_kids_empty', screen(deps));
    await tester.tap(find.text('Add a child'));
    await tester.pumpAndSettle();
    expect(find.text('went to ${Paths.addChild}'), findsOneWidget);
  });

  testWidgets('a failure shows the message and tries again', (tester) async {
    final (deps, server) = await setUp(tester);
    server.on(_children, {'error': 'database is down'}, status: 500);
    await tester.pumpWidget(shotApp(screen(deps)));
    await tester.pumpAndSettle();
    expect(find.text("That didn't work: database is down"), findsOneWidget);

    server.on(_children, familyJson(['Sam']));
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Sam'), findsOneWidget);
  });
}
