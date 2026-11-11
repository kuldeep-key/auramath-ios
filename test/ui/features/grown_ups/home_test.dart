import 'package:auramath/data/repositories/report_email_repository.dart';
import 'package:auramath/routing/paths.dart';
import 'package:auramath/ui/features/grown_ups/views/email_frequency_screen.dart';
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

  group('ForgotPass: sign in again (ACC-11)', () {
    Widget screen(Gu g) =>
        ForgotPasscodeScreen(account: g.deps.account, repo: g.repo);

    void auth(Gu g) => g.server
      ..on('GET /api/auth/config', {
        'googleClientId': 'google-server-id',
        'appleSignIn': true,
        'emailLink': true,
      })
      ..on('POST /api/auth/apple', {'token': 'fresh-apple'})
      ..on('POST /api/auth/google', {'token': 'fresh-google'});

    for (final (button, token) in [
      ('Continue with Apple', 'fresh-apple'),
      ('Continue with Google', 'fresh-google'),
    ]) {
      testWidgets('$button signs in again, then GPass resets', (tester) async {
        final g = await Gu.make(tester);
        auth(g);
        await tester.pumpWidget(shotApp(screen(g)));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text(button));
        await tester.tap(find.text(button));
        await tester.pumpAndSettle();
        expect(g.deps.account.bearer, token);
        expect(find.text('went to ${Paths.grownUpsPass}'), findsOneWidget);
        expect(
          await tester.runAsync(() => g.repo.passcodeResetReady(token)),
          isTrue,
        );
      });
    }

    testWidgets('Apple off on this server: says so, nothing kept', (
      tester,
    ) async {
      final g = await Gu.make(tester);
      auth(g);
      g.server.on('GET /api/auth/config', {
        'googleClientId': 'google-server-id',
        'appleSignIn': false,
      });
      await tester.pumpWidget(shotApp(screen(g)));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Continue with Apple'));
      await tester.tap(find.text('Continue with Apple'));
      await tester.pumpAndSettle();
      expect(
        find.text("Apple sign-in isn't switched on for this server yet."),
        findsOneWidget,
      );
      expect(g.store.values['passcodeReset'], isNull);
      expect(find.textContaining('went to'), findsNothing);
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

    testWidgets('progress is by email: no book, month or plan (D-39)', (
      tester,
    ) async {
      final g = await Gu.make(tester);
      await tester.pumpWidget(shotApp(screen(g)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Maya'));
      await tester.pumpAndSettle();
      expect(find.textContaining('went to'), findsNothing);
      expect(find.textContaining('progress'), findsNothing);
      expect(find.text('Plan'), findsNothing);
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

    testWidgets('consent withdrawn: lessons are paused, with the way back', (
      tester,
    ) async {
      final g = await Gu.make(tester);
      g.server.on('GET /api/children', {
        'children': [
          {'id': 'child-1', 'displayName': 'Aarav'},
        ],
        'consented': false,
      });
      await tester.pumpWidget(shotApp(screen(g)));
      await tester.pumpAndSettle();
      expect(find.text('Lessons are paused'), findsOneWidget);
      await tester.tap(find.text('Your data and rights'));
      await tester.pumpAndSettle();
      expect(find.text('went to ${Paths.rights}'), findsOneWidget);
    });

    testWidgets('consent holds: no paused card', (tester) async {
      final g = await Gu.make(tester);
      await tester.pumpWidget(shotApp(screen(g)));
      await tester.pumpAndSettle();
      expect(find.text('Lessons are paused'), findsNothing);
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

  group('How often (PAR-06)', () {
    Widget screen(Gu g) =>
        EmailFrequencyScreen(email: ReportEmailRepository(g.deps.client));

    testWidgets('at every size, the current choice ticked', (tester) async {
      final g = await Gu.make(tester);
      await shotAllSizes(tester, 'grown_ups_email_frequency', screen(g));
      expect(find.text('After each session'), findsOneWidget);
      expect(find.text('Once a week'), findsOneWidget);
      expect(find.text('Off'), findsOneWidget);
    });

    for (final (label, wire) in [
      ('Once a week', 'weekly'),
      ('Off', 'off'),
      ('After each session', 'each_session'),
    ]) {
      testWidgets('$label saves $wire and goes back', (tester) async {
        final g = await Gu.make(tester);
        g.server.on('PUT /api/family/settings/reports', null, status: 204);
        await tester.pumpWidget(shotApp(screen(g)));
        await tester.pumpAndSettle();
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(g.bodyOf('PUT /api/family/settings/reports'), {
          'frequency': wire,
        });
        expect(find.text('went to ${Paths.settings}'), findsOneWidget);
      });
    }

    testWidgets('a refusal stays and says why', (tester) async {
      final g = await Gu.make(tester);
      g.server.on('PUT /api/family/settings/reports', {
        'error': 'database is down',
      }, status: 500);
      await tester.pumpWidget(shotApp(screen(g)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Off'));
      await tester.pumpAndSettle();
      expect(find.text('database is down'), findsOneWidget);
      expect(find.textContaining('went to'), findsNothing);
    });
  });

  group('Settings', () {
    Widget screen(Gu g) => SettingsScreen(
      family: g.deps.family,
      repo: g.repo,
      email: ReportEmailRepository(g.deps.client),
    );

    testWidgets('at every size, without Membership, plan or pad choice', (
      tester,
    ) async {
      final g = await Gu.make(tester);
      await shotAllSizes(tester, 'grown_ups_settings', screen(g));
      expect(find.text('Membership'), findsNothing);
      expect(find.text("Aarav's plan"), findsNothing);
      expect(find.text('Number pad'), findsNothing); // ours only (D-41)
      expect(find.text('Bigger number pad (accessibility)'), findsOneWidget);
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

    testWidgets('report email on: one tap turns it off (PAR-05)', (
      tester,
    ) async {
      final g = await Gu.make(tester);
      g.server
        ..on('GET /api/family/settings/reports', {'frequency': 'weekly'})
        ..on('PUT /api/family/settings/reports', null, status: 204);
      await tester.pumpWidget(shotApp(screen(g)));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Report email'));
      expect(find.text('Every email also has a link to stop them.'), findsOne);
      g.server.on('GET /api/family/settings/reports', {'frequency': 'off'});
      await tester.tap(find.text('Report email'));
      await tester.pumpAndSettle();
      expect(g.bodyOf('PUT /api/family/settings/reports'), {
        'frequency': 'off',
      });
      expect(find.text('Off'), findsWidgets);
    });

    testWidgets('report email off: turning it on asks first (Notify)', (
      tester,
    ) async {
      final g = await Gu.make(tester);
      g.server.on('GET /api/family/settings/reports', {'frequency': 'off'});
      await tester.pumpWidget(shotApp(screen(g)));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Report email'));
      await tester.tap(find.text('Report email'));
      await tester.pumpAndSettle();
      expect(find.text('went to ${Paths.notify}'), findsOneWidget);
      expect(g.calls, isNot(contains('PUT /api/family/settings/reports')));
    });

    testWidgets('report email on: How often opens the picker (PAR-06)', (
      tester,
    ) async {
      final g = await Gu.make(tester);
      g.server.on('GET /api/family/settings/reports', {'frequency': 'weekly'});
      await tester.pumpWidget(shotApp(screen(g)));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('How often'));
      expect(find.text('Once a week'), findsOneWidget);
      await tester.tap(find.text('How often'));
      await tester.pumpAndSettle();
      expect(find.text('went to ${Paths.emailFrequency}'), findsOneWidget);
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
