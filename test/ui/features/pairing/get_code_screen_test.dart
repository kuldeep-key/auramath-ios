import 'dart:io';

import 'package:auramath/data/repositories/account_repository.dart';
import 'package:auramath/l10n/app_localizations.dart';
import 'package:auramath/routing/paths.dart';
import 'package:auramath/routing/router.dart';
import 'package:auramath/ui/core/parts/keypad.dart';
import 'package:auramath/ui/core/theme/app_theme.dart';
import 'package:auramath/ui/features/pairing/views/get_code_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/app_harness.dart';
import '../../../helpers/shots.dart';
import 'pairing_helpers.dart';

const _redeem = 'POST /api/devices/redeem';
const _children = 'GET /api/children';
const _paired = {'token': 'device-token', 'deviceId': 'dev-1'};

Future<void> _type(WidgetTester tester, String code) async {
  for (final d in code.split('')) {
    await tester.tap(
      find.descendant(of: find.byType(Keypad), matching: find.text(d)),
    );
  }
  await tester.tap(find.bySemanticsLabel('Check'));
  await tester.pumpAndSettle();
}

void main() {
  late FakeServer server;

  Future<Widget> screen(WidgetTester tester) async {
    final (deps, s) = (await tester.runAsync(testDeps))!;
    server = s;
    return GetCodeScreen(account: deps.account, family: deps.family);
  }

  testWidgets('fits every size', (tester) async {
    await shotAllSizes(tester, 'pairing_get_code', await screen(tester));
    expect(find.text('Type your code'), findsOneWidget);
  });

  testWidgets('sends the six digits, leading zero kept, and with one child '
      'asks "is this you?"', (tester) async {
    final s = await screen(tester);
    server
      ..on(_redeem, _paired)
      ..on(_children, familyJson(['Sam']));
    await tester.pumpWidget(shotApp(s));
    await _type(tester, '012345');
    expect(server.calls.first.$1, _redeem);
    expect(server.calls.first.$2, {'code': '012345', 'label': "Child's phone"});
    expect(
      find.text('went to ${Paths.pairIsThisYou}?id=c0&name=Sam'),
      findsOneWidget,
    );
  });

  testWidgets('with several children asks which one', (tester) async {
    final s = await screen(tester);
    server
      ..on(_redeem, _paired)
      ..on(_children, familyJson(['Sam', 'Ari']));
    await tester.pumpWidget(shotApp(s));
    await _type(tester, '482715');
    expect(find.text('went to ${Paths.pairWhichChild}'), findsOneWidget);
  });

  testWidgets('a wrong code goes to CodeWrong', (tester) async {
    final s = await screen(tester);
    server.on(_redeem, {'error': 'no'}, status: 400);
    await tester.pumpWidget(shotApp(s));
    await _type(tester, '111111');
    expect(find.text('went to ${Paths.pairWrong}'), findsOneWidget);
  });

  testWidgets('too many tries says wait', (tester) async {
    final s = await screen(tester);
    server.on(_redeem, {'error': 'no'}, status: 429);
    await tester.pumpWidget(shotApp(s));
    await _type(tester, '111111');
    expect(find.text('went to ${Paths.pairWrong}?tooMany=1'), findsOneWidget);
  });

  testWidgets('a short code is wrong without asking the server', (
    tester,
  ) async {
    final s = await screen(tester);
    await tester.pumpWidget(shotApp(s));
    await _type(tester, '123');
    expect(server.calls, isEmpty);
    expect(find.text('went to ${Paths.pairWrong}'), findsOneWidget);
  });

  testWidgets('offline shows a message and tries the same code again', (
    tester,
  ) async {
    final s = await screen(tester);
    server.routes[_redeem] = (_) => throw const SocketException('down');
    await tester.pumpWidget(shotApp(s));
    await _type(tester, '482715');
    expect(find.textContaining("Can't reach the internet"), findsOneWidget);

    server
      ..on(_redeem, _paired)
      ..on(_children, familyJson(['Sam']));
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(server.calls.last.$1, _children);
    expect(server.calls[1].$2['code'], '482715');
    expect(
      find.textContaining('went to ${Paths.pairIsThisYou}'),
      findsOneWidget,
    );
  });

  testWidgets('a server failure shows its message', (tester) async {
    final s = await screen(tester);
    server.on(_redeem, {'error': 'pairing is down'}, status: 503);
    await tester.pumpWidget(shotApp(s));
    await _type(tester, '482715');
    expect(find.text("That didn't work: pairing is down"), findsOneWidget);
  });

  testWidgets('pairs end to end on the real router', (tester) async {
    final (deps, server) = (await tester.runAsync(testDeps))!;
    server
      ..on(_redeem, _paired)
      ..on(_children, familyJson(['Sam']));
    await tester.pumpWidget(
      MaterialApp.router(
        theme: buildAuraTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: buildRouter(deps, initialLocation: Paths.open),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text("I'm a kid"));
    await tester.pumpAndSettle();
    await _type(tester, '482715');
    expect(deps.account.role, Role.device);
    expect(find.text('Is this you?'), findsOneWidget);

    await tester.tap(find.text("Yes, that's me!"));
    await tester.pumpAndSettle();
    expect(deps.account.childId, 'c0');
    expect(find.text("You're in, Sam!"), findsOneWidget);
  });
}
