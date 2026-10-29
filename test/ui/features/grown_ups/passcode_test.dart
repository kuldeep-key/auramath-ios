import 'package:auramath/routing/paths.dart';
import 'package:auramath/ui/features/grown_ups/views/passcode_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/shots.dart';
import 'gu_fakes.dart';

void main() {
  Widget screen(Gu g, {String? to}) => PasscodeScreen(
    account: g.deps.account,
    family: g.deps.family,
    repo: g.repo,
    deviceLock: g.deps.deviceLock,
    to: to,
  );

  Future<void> type(WidgetTester tester, String digits) async {
    for (final d in digits.split('')) {
      await tester.tap(find.text(d).last);
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  void passcodeIs(Gu g, String code) =>
      g.server.routes['POST /api/family/passcode/check'] = (body) =>
          body['passcode'] == code
          ? (200, {'ok': true})
          : (403, {'error': "that passcode didn't match"});

  testWidgets('GPass at every size', (tester) async {
    final g = await Gu.make(tester);
    await shotAllSizes(tester, 'grown_ups_pass', screen(g));
    expect(find.text('Grown-ups only'), findsOneWidget);
    expect(find.text('Forgot passcode?'), findsOneWidget);
  });

  testWidgets('the right passcode unlocks and goes where it was asked', (
    tester,
  ) async {
    final g = await Gu.make(tester);
    passcodeIs(g, '1234');
    await tester.pumpWidget(shotApp(screen(g, to: Paths.family)));
    await tester.pumpAndSettle();
    await type(tester, '1234');
    expect(g.bodyOf('POST /api/family/passcode/check'), {'passcode': '1234'});
    expect(g.deps.account.grownUpsUnlocked, isTrue);
    expect(find.text('went to ${Paths.family}'), findsOneWidget);
  });

  testWidgets('a wrong passcode clears and says so', (tester) async {
    final g = await Gu.make(tester);
    passcodeIs(g, '1234');
    await tester.pumpWidget(shotApp(screen(g)));
    await tester.pumpAndSettle();
    await type(tester, '9999');
    expect(find.text("That's not the passcode. Try again."), findsOneWidget);
    expect(g.deps.account.grownUpsUnlocked, isFalse);
  });

  testWidgets('too many tries shows the wait', (tester) async {
    final g = await Gu.make(tester);
    g.server.on('POST /api/family/passcode/check', {
      'error': 'too many tries',
    }, status: 429);
    await tester.pumpWidget(shotApp(screen(g)));
    await tester.pumpAndSettle();
    await type(tester, '1111');
    expect(find.textContaining('Too many tries.'), findsOneWidget);
  });

  testWidgets('Face ID first when the grown-up chose it', (tester) async {
    final g = await Gu.make(tester);
    await tester.runAsync(() => g.deps.account.setUseFaceId(true));
    await tester.pumpWidget(shotApp(screen(g)));
    await tester.pumpAndSettle();
    expect(g.deps.account.grownUpsUnlocked, isTrue);
    expect(find.text('went to ${Paths.grownUps}'), findsOneWidget);
  });

  testWidgets('with none set, choose one by typing it twice', (tester) async {
    final g = await Gu.make(tester);
    g.server
      ..on('GET /api/family/passcode', {
        'set': false,
        'length': 4,
        'lockedUntil': null,
      })
      ..on('PUT /api/family/passcode', null, status: 204);
    await tester.pumpWidget(shotApp(screen(g)));
    await tester.pumpAndSettle();
    expect(find.text('Choose a passcode'), findsOneWidget);
    await type(tester, '2468');
    expect(find.text('Type it again'), findsOneWidget);
    await type(tester, '2468');
    expect(g.bodyOf('PUT /api/family/passcode'), {'passcode': '2468'});
    expect(find.text('went to ${Paths.grownUps}'), findsOneWidget);
  });

  testWidgets('after forgot + a fresh sign-in it asks for a new one', (
    tester,
  ) async {
    final g = await Gu.make(tester);
    // asked with an older credential
    await tester.runAsync(() => g.repo.startPasscodeReset('old-token'));
    g.server.on('PUT /api/family/passcode', {
      'error': "that passcode didn't match",
    }, status: 403);
    await tester.pumpWidget(shotApp(screen(g)));
    await tester.pumpAndSettle();
    expect(find.text('Choose a new passcode'), findsOneWidget);
    await type(tester, '1357');
    await type(tester, '1357');
    // the backend still wants the old one: said plainly, not faked
    expect(
      find.textContaining('still asks for the old passcode'),
      findsOneWidget,
    );
    expect(g.deps.account.grownUpsUnlocked, isFalse);
  });

  testWidgets('Forgot passcode? opens ForgotPass', (tester) async {
    final g = await Gu.make(tester);
    await tester.pumpWidget(shotApp(screen(g)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Forgot passcode?'));
    await tester.pumpAndSettle();
    expect(find.text('went to ${Paths.forgotPasscode}'), findsOneWidget);
  });

  testWidgets('a failed load says why and can retry', (tester) async {
    final g = await Gu.make(tester);
    g.server.on('GET /api/family/passcode', {'error': 'boom'}, status: 500);
    await tester.pumpWidget(shotApp(screen(g)));
    await tester.pumpAndSettle();
    expect(find.text('boom'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });
}
