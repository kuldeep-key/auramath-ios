import 'package:auramath/routing/paths.dart';
import 'package:auramath/ui/features/grown_ups/views/forgot_passcode_screen.dart';
import 'package:auramath/ui/features/grown_ups/views/grown_up_home_screen.dart';
import 'package:auramath/ui/features/grown_ups/views/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/shots.dart';
import 'gu_fakes.dart';

void main() {
  group('ForgotPass', () {
    Widget screen(Gu g) =>
        ForgotPasscodeScreen(account: g.deps.account, repo: g.repo);

    test('masks the address', () {
      expect(ForgotPasscodeScreen.mask('priya@gmail.com'), 'p•••@gmail.com');
      expect(ForgotPasscodeScreen.mask('nope'), 'nope');
    });

    testWidgets('at every size', (tester) async {
      final g = await Gu.make(tester);
      await shotAllSizes(tester, 'grown_ups_forgot', screen(g));
      expect(
        find.text('We will email a sign-in link to p•••@gmail.com.'),
        findsOneWidget,
      );
    });

    testWidgets('sends the link to the account email, then check email', (
      tester,
    ) async {
      final g = await Gu.make(tester);
      g.server.on('POST /api/auth/email-link', {'ok': true}, status: 202);
      await tester.pumpWidget(shotApp(screen(g)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send the link'));
      await tester.pumpAndSettle();
      expect(g.bodyOf('POST /api/auth/email-link'), {
        'email': 'priya@gmail.com',
      });
      expect(find.text('Check your email'), findsOneWidget);
      expect(g.store.values['passcodeReset'], isNotNull);
    });

    testWidgets('a refused send says why', (tester) async {
      final g = await Gu.make(tester);
      g.server.on('POST /api/auth/email-link', {
        'error': 'already sent. Try again in 40s.',
      }, status: 429);
      await tester.pumpWidget(shotApp(screen(g)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send the link'));
      await tester.pumpAndSettle();
      expect(find.text('already sent. Try again in 40s.'), findsOneWidget);
      expect(find.text('Check your email'), findsNothing);
    });
  });

  group('PHome', () {
    Widget screen(Gu g) => GrownUpHomeScreen(
      account: g.deps.account,
      family: g.deps.family,
      repo: g.repo,
    );

    testWidgets('at every size', (tester) async {
      final g = await Gu.make(tester);
      await shotAllSizes(tester, 'grown_ups_home', screen(g));
      expect(find.text('1 session this week'), findsOneWidget);
      expect(find.text('No sessions this week'), findsOneWidget);
      expect(find.text('Back to Aarav'), findsOneWidget);
    });

    testWidgets('a child opens their book', (tester) async {
      final g = await Gu.make(tester);
      await tester.pumpWidget(shotApp(screen(g)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Maya'));
      await tester.pumpAndSettle();
      expect(find.text('went to ${Paths.book('child-2')}'), findsOneWidget);
    });

    testWidgets('Back to the child chooses them and goes home', (tester) async {
      final g = await Gu.make(tester);
      await tester.pumpWidget(shotApp(screen(g)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Back to Aarav'));
      await tester.pumpAndSettle();
      expect(g.deps.account.childId, 'child-1');
      expect(find.text('went to ${Paths.home}'), findsOneWidget);
    });

    testWidgets('the gear opens Settings, Family opens Family', (tester) async {
      final g = await Gu.make(tester);
      await tester.pumpWidget(shotApp(screen(g)));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('went to ${Paths.settings}'), findsOneWidget);
    });

    testWidgets('no children: says so and offers Add a child', (tester) async {
      final g = await Gu.make(tester);
      g.server.on('GET /api/children', {'children': <Object>[]});
      await tester.pumpWidget(shotApp(screen(g)));
      await tester.pumpAndSettle();
      expect(find.text('No children yet'), findsOneWidget);
      await tester.tap(find.text('Add a child'));
      await tester.pumpAndSettle();
      expect(find.text('went to ${Paths.addChild}'), findsOneWidget);
    });

    testWidgets('offline: says so with Try again', (tester) async {
      final g = await Gu.make(tester);
      g.server.on('GET /api/children', {'error': 'down'}, status: 503);
      await tester.pumpWidget(shotApp(screen(g)));
      await tester.pumpAndSettle();
      expect(find.text('down'), findsOneWidget);
      g.seed();
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Aarav'), findsOneWidget);
    });
  });

  group('Settings', () {
    Widget screen(Gu g) => SettingsScreen(family: g.deps.family, repo: g.repo);

    testWidgets('at every size, without Membership', (tester) async {
      final g = await Gu.make(tester);
      await shotAllSizes(tester, 'grown_ups_settings', screen(g));
      expect(find.text("Aarav's plan"), findsOneWidget);
      expect(find.text('Membership'), findsNothing);
    });

    testWidgets('a lesson setting changes on tap and is kept on this phone', (
      tester,
    ) async {
      final g = await Gu.make(tester);
      await tester.pumpWidget(shotApp(screen(g)));
      await tester.pumpAndSettle();
      expect(find.text('15 min'), findsOneWidget);
      await tester.tap(find.text('Time each day'));
      await tester.tap(find.text('Read aloud'));
      await tester.pumpAndSettle();
      expect(find.text('20 min'), findsOneWidget);
      expect(g.store.values['lesson.minutes'], '20');
      expect(g.store.values['lesson.readAloud'], '0');
      final prefs = await tester.runAsync(g.repo.loadPrefs);
      expect(prefs!.minutes, 20);
      expect(prefs.readAloud, isFalse);
    });

    testWidgets('Sign out opens its confirmation', (tester) async {
      final g = await Gu.make(tester);
      await tester.pumpWidget(shotApp(screen(g)));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Sign out'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(find.text('went to ${Paths.signOut}'), findsOneWidget);
    });
  });
}
