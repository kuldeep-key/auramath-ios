import 'package:auramath/deps.dart';
import 'package:auramath/routing/paths.dart';
import 'package:auramath/ui/features/pairing/views/kids_screen.dart';
import 'package:auramath/ui/core/parts/ribbon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/app_harness.dart';
import '../../../helpers/shots.dart';
import 'pairing_helpers.dart';

const _children = 'GET /api/children';
const _passcode = 'GET /api/family/passcode';

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
    server.on(_passcode, {'set': true, 'length': 4});
    await tester.pumpWidget(shotApp(screen(deps)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ari'));
    await tester.pumpAndSettle();
    expect(deps.account.childId, 'c1');
    expect(find.text('went to ${Paths.home}'), findsOneWidget);
  });

  testWidgets('one child: no picker, straight to their home (DEV-01)', (
    tester,
  ) async {
    final (deps, server) = await setUp(tester);
    server.on(_children, familyJson(['Sam']));
    server.on(_passcode, {'set': true, 'length': 4});
    await tester.pumpWidget(shotApp(screen(deps)));
    await tester.pumpAndSettle();
    expect(deps.account.childId, 'c0');
    expect(find.text('went to ${Paths.home}'), findsOneWidget);
  });

  testWidgets('H10: no family passcode yet (setup left at Ready, Lock or '
      'Passcode): not handed over; the grown-up sets one first', (
    tester,
  ) async {
    final (deps, server) = await setUp(tester);
    server.on(_children, familyJson(['Sam']));
    server.on(_passcode, {'set': false, 'length': 4});
    await tester.pumpWidget(shotApp(screen(deps)));
    await tester.pumpAndSettle();
    expect(deps.account.childId, isNull);
    expect(find.text('went to /setup/lock?child=c0&name=Sam'), findsOneWidget);

    // two children, one tapped: the same
    final (two, server2) = await setUp(tester);
    server2.on(_children, familyJson(['Sam', 'Ari']));
    server2.on(_passcode, {'set': false, 'length': 4});
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(shotApp(screen(two)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ari'));
    await tester.pumpAndSettle();
    expect(two.account.childId, isNull);
    expect(find.text('went to /setup/lock?child=c1&name=Ari'), findsOneWidget);
  });

  testWidgets('one child already chosen: the picker stays, so the Family '
      'area can be reached from Home', (tester) async {
    final (deps, server) = await setUp(tester);
    server.on(_children, familyJson(['Sam']));
    await tester.runAsync(() => deps.account.chooseChild('c0'));
    await tester.pumpWidget(shotApp(screen(deps)));
    await tester.pumpAndSettle();
    expect(find.text('went to ${Paths.home}'), findsNothing);
    await tester.tap(find.text('Family area'));
    await tester.pumpAndSettle();
    expect(find.text('went to ${Paths.grownUps}'), findsOneWidget);
  });

  testWidgets('two children show their own chosen avatars (ACC-12)', (
    tester,
  ) async {
    final (deps, server) = await setUp(tester);
    server.on(_children, {
      'children': [
        {'id': 'c0', 'displayName': 'Sam', 'avatar': 'print'},
        {'id': 'c1', 'displayName': 'Ari', 'avatar': 'key'},
        {'id': 'c2', 'displayName': 'Jo', 'avatar': 'not-in-this-build'},
      ],
    });
    await loadPortraits(tester);
    await shotAllSizes(tester, 'pairing_kids_avatars', screen(deps));
    expect(find.byIcon(Icons.fingerprint_rounded), findsOneWidget);
    expect(find.byIcon(Icons.key_rounded), findsOneWidget);
    // one this build doesn't know: the detective picture
    expect(find.byType(Portrait), findsOneWidget);
  });

  testWidgets('Family area goes to the grown-up area', (tester) async {
    final (deps, server) = await setUp(tester);
    server.on(_children, familyJson(['Sam', 'Ari']));
    await tester.pumpWidget(shotApp(screen(deps)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Family area'));
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

  testWidgets('a name changed in the grown-up area shows when the grown-up '
      'comes back (the picker under it reads the children again)', (
    tester,
  ) async {
    final (deps, server) = await setUp(tester);
    server.on(_children, familyJson(['Sam', 'Ari']));
    await tester.pumpWidget(shotApp(screen(deps)));
    await tester.pumpAndSettle();
    expect(find.text('Ari'), findsOneWidget);

    // the grown-up renames Ari to Ava and saves; the server now lists Ava
    server.on('PATCH /api/children/c1', {'id': 'c1', 'displayName': 'Ava'});
    server.on(_children, familyJson(['Sam', 'Ava']));
    final saved = deps.family.editChild('c1', {'displayName': 'Ava'});
    await tester.pumpAndSettle();
    await saved;
    expect(find.text('Ava'), findsOneWidget);
    expect(find.text('Ari'), findsNothing);
    // and a reread never sends the phone anywhere
    expect(find.textContaining('went to'), findsNothing);
  });

  testWidgets('a failure shows the message and tries again', (tester) async {
    final (deps, server) = await setUp(tester);
    server.on(_children, {'error': 'database is down'}, status: 500);
    await tester.pumpWidget(shotApp(screen(deps)));
    await tester.pumpAndSettle();
    expect(find.text("That didn't work: database is down"), findsOneWidget);

    server.on(_children, familyJson(['Sam', 'Ari']));
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Sam'), findsOneWidget);
  });
}
