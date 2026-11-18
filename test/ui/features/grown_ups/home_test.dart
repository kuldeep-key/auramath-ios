import 'dart:io';

import 'package:auramath/data/repositories/recent_notes_repository.dart';
import 'package:auramath/data/services/sound_effects.dart';
import 'package:auramath/data/repositories/report_email_repository.dart';
import 'package:auramath/routing/paths.dart';
import 'package:auramath/ui/features/grown_ups/views/email_frequency_screen.dart';
import 'package:auramath/ui/features/grown_ups/views/forgot_passcode_screen.dart';
import 'package:auramath/ui/features/grown_ups/views/grown_up_home_screen.dart';
import 'package:auramath/ui/features/grown_ups/views/parts.dart';
import 'package:auramath/ui/features/grown_ups/views/recent_notes_screen.dart';
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
        find.text(
          'Sign in again and set a new one. We will email a link to '
          'p•••@gmail.com.',
        ),
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
      await tester.tap(find.text('Email me a sign-in link'));
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
      await tester.tap(find.text('Email me a sign-in link'));
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
      ('Sign in with Apple', 'fresh-apple'),
      ('Sign in with Google', 'fresh-google'),
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
      await tester.ensureVisible(find.text('Sign in with Apple'));
      await tester.tap(find.text('Sign in with Apple'));
      await tester.pumpAndSettle();
      expect(
        find.text("Apple sign-in isn't switched on for this server yet."),
        findsOneWidget,
      );
      expect(g.store.values['passcodeReset'], isNull);
      expect(find.textContaining('went to'), findsNothing);
    });
  });

  group('Recent notes (PAR-12)', () {
    Widget screen(Gu g) => RecentNotesScreen(
      childId: 'child-1',
      family: g.deps.family,
      notes: RecentNotesRepository(g.deps.client, g.repo),
    );

    testWidgets('the last-five route: at every size, newest first', (
      tester,
    ) async {
      final g = await Gu.make(tester);
      g.server.on('GET /api/family/notes', {
        'notes': [
          for (var i = 0; i < 7; i++)
            {
              'sessionId': 's$i',
              'endedAt': DateTime(2026, 11, 10 - i).millisecondsSinceEpoch,
              'sentences': [
                {'text': 'Note $i.'},
              ],
            },
        ],
      });
      await shotAllSizes(tester, 'grown_ups_recent_notes', screen(g));
      expect(find.text("Aarav's notes"), findsOneWidget);
      expect(find.text('Note 0.'), findsOneWidget);
      expect(find.text('Note 4.'), findsOneWidget);
      expect(find.text('Note 5.'), findsNothing); // five at most
      expect(
        g.server.urls
            .lastWhere((u) => u.path == '/api/family/notes')
            .queryParameters,
        {'childId': 'child-1', 'limit': '5'},
      );
    });

    testWidgets('no last-five route yet: built from progress and summaries', (
      tester,
    ) async {
      final g = await Gu.make(tester);
      await tester.pumpWidget(shotApp(screen(g)));
      await tester.pumpAndSettle();
      expect(
        find.text('Practised comparing two bars. Did the second one alone.'),
        findsOneWidget,
      );
      expect(g.calls, contains('GET /api/sessions/s1/summary'));
    });

    testWidgets('none yet says so', (tester) async {
      final g = await Gu.make(tester);
      g.server.on('GET /api/family/notes', <Object>[]);
      await tester.pumpWidget(shotApp(screen(g)));
      await tester.pumpAndSettle();
      expect(find.textContaining('No notes yet'), findsOneWidget);
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
      expect(find.textContaining('1 session this week'), findsOneWidget);
      expect(find.textContaining('No sessions this week'), findsOneWidget);
      // the prototype's hub: This family's rows
      for (final row in [
        'Settings',
        'Phones and family',
        'Your data and rights',
        'Sign out of this phone',
        'Add a child',
      ]) {
        expect(find.text(row), findsOneWidget);
      }
      expect(find.text('Back to Aarav'), findsOneWidget);
    });

    testWidgets('a child opens where they are; progress is by email: no '
        'book, month or plan (D-39)', (tester) async {
      final g = await Gu.make(tester);
      await tester.pumpWidget(shotApp(screen(g)));
      await tester.pumpAndSettle();
      expect(find.textContaining('progress'), findsNothing);
      expect(find.text('Plan'), findsNothing);
      await tester.tap(find.text('Maya'));
      await tester.pumpAndSettle();
      expect(find.text('went to ${Paths.learning('child-2')}'), findsOneWidget);
    });

    testWidgets('no Recent notes while recent_notes_in_app is off', (
      tester,
    ) async {
      final g = await Gu.make(tester);
      await tester.pumpWidget(shotApp(screen(g)));
      await tester.pumpAndSettle();
      expect(find.text('Recent notes'), findsNothing);
    });

    testWidgets('flag on: each child links to their recent notes (PAR-12)', (
      tester,
    ) async {
      final g = await Gu.make(tester);
      await shotAllSizes(
        tester,
        'grown_ups_home_notes',
        GrownUpHomeScreen(
          account: g.deps.account,
          family: g.deps.family,
          repo: g.repo,
          recentNotes: true,
        ),
      );
      expect(find.text('Recent notes'), findsNWidgets(2));
      await tester.tap(find.text('Recent notes').first);
      await tester.pumpAndSettle();
      expect(find.text('went to ${Paths.notes('child-1')}'), findsOneWidget);
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

    for (final (row, path) in [
      ('Settings', Paths.settings),
      ('Phones and family', Paths.family),
      ('Your data and rights', Paths.rights),
      ('Sign out of this phone', Paths.signOut),
    ]) {
      testWidgets('$row opens $path', (tester) async {
        final g = await Gu.make(tester);
        await tester.pumpWidget(shotApp(screen(g)));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text(row));
        await tester.pumpAndSettle();
        await tester.tap(find.text(row));
        await tester.pumpAndSettle();
        expect(find.text('went to $path'), findsOneWidget);
      });
    }

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
      await tester.tap(find.text('Your data and rights').first);
      await tester.pumpAndSettle();
      expect(find.text('went to ${Paths.rights}'), findsOneWidget);
    });

    testWidgets("a child's new name shows here at once (childrenChanged)", (
      tester,
    ) async {
      final g = await Gu.make(tester);
      await tester.pumpWidget(shotApp(screen(g)));
      await tester.pumpAndSettle();
      expect(find.text('Aarav'), findsOneWidget);
      g.server
        ..on('PATCH /api/children/child-1', {
          'id': 'child-1',
          'displayName': 'Ari',
        })
        ..on('GET /api/children', {
          'children': [
            {'id': 'child-1', 'displayName': 'Ari', 'schoolYear': 'year_2'},
            {'id': 'child-2', 'displayName': 'Maya', 'schoolYear': 'year_1'},
          ],
        });
      // saved from another screen (Edit), with this one underneath
      await tester.runAsync(
        () => g.deps.family.editChild('child-1', {'displayName': 'Ari'}),
      );
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(find.text('Ari'), findsOneWidget);
      expect(find.text('Aarav'), findsNothing);
      expect(find.text('Back to Ari'), findsOneWidget);
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
      ('After each session', 'each'),
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
      settings: g.settings,
    );

    /// The row [label] in [child]'s settings card.
    Finder inCard(String childId, String label) => find.descendant(
      of: find.byKey(ValueKey('settings-$childId')),
      matching: find.text(label),
    );

    testWidgets('at every size, without Membership, plan or pad choice', (
      tester,
    ) async {
      final g = await Gu.make(tester);
      await shotAllSizes(tester, 'grown_ups_settings', screen(g));
      expect(find.text('Membership'), findsNothing);
      expect(find.text("Aarav's plan"), findsNothing);
      expect(find.text('Number pad'), findsNothing); // ours only (D-41)
      expect(find.text('Bigger number pad'), findsOneWidget);
      // read-aloud for each child, the bigger pad and the report email;
      // the family rows moved to the Family area
      expect(find.byType(AuraSwitch), findsNWidgets(4));
      expect(find.text('Sign out'), findsNothing);
    });

    testWidgets("each child's settings come from the server (PAR-05)", (
      tester,
    ) async {
      final g = await Gu.make(tester);
      await tester.pumpWidget(shotApp(screen(g)));
      await tester.pumpAndSettle();
      // Aarav's from the list of children, Maya's asked for on its own
      expect(find.text('AARAV'), findsOneWidget);
      expect(find.text('MAYA'), findsOneWidget);
      expect(inCard('child-1', '15 min'), findsOneWidget);
      expect(inCard('child-2', 'No limit'), findsOneWidget);
      expect(g.calls, contains('GET /api/children/child-2/settings'));
      expect(g.calls, isNot(contains('GET /api/children/child-1/settings')));
      // both kept on this phone for when the server can't be reached
      expect(g.store.values['childSettings.child-1'], contains('15'));
      expect(g.store.values['childSettings.child-2'], isNotNull);
    });

    testWidgets('a time each day is saved on the server, per child', (
      tester,
    ) async {
      final g = await Gu.make(tester);
      g.server.on('PUT /api/children/child-2/settings', {
        'childId': 'child-2',
        'dailyLimitMinutes': 20,
        'dailyLimitIsDefault': false,
        'readAloud': true,
        'readAloudIsDefault': true,
      });
      await tester.pumpWidget(shotApp(screen(g)));
      await tester.pumpAndSettle();
      // Time each day opens the picker sheet (the prototype's `pick`)
      await tester.tap(inCard('child-2', 'Time each day'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('auraSheet')), findsOneWidget);
      await tester.tap(find.text('20 minutes'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('auraSheet')), findsNothing);
      expect(g.bodyOf('PUT /api/children/child-2/settings'), {
        'dailyLimitMinutes': 20,
      });
      expect(find.text('Saved'), findsOneWidget);
      expect(inCard('child-2', '20 min'), findsOneWidget);
      expect(inCard('child-1', '15 min'), findsOneWidget);
      // nothing about the time is kept as the phone's own any more
      expect(g.store.values['lesson.minutes'], isNull);
    });

    testWidgets('no limit is sent as null', (tester) async {
      final g = await Gu.make(tester);
      g.server.on('PUT /api/children/child-1/settings', {
        'childId': 'child-1',
        'dailyLimitMinutes': null,
        'dailyLimitIsDefault': false,
        'readAloud': true,
        'readAloudIsDefault': true,
      });
      await tester.pumpWidget(shotApp(screen(g)));
      await tester.pumpAndSettle();
      await tester.tap(inCard('child-1', 'Time each day'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('No limit').last);
      await tester.pumpAndSettle();
      final body = g.bodyOf('PUT /api/children/child-1/settings');
      expect(body, {'dailyLimitMinutes': null});
      expect(inCard('child-1', 'No limit'), findsOneWidget);
    });

    testWidgets('read aloud is saved on the server', (tester) async {
      final g = await Gu.make(tester);
      g.server.on('PUT /api/children/child-1/settings', {
        'childId': 'child-1',
        'dailyLimitMinutes': 15,
        'dailyLimitIsDefault': false,
        'readAloud': false,
        'readAloudIsDefault': false,
      });
      addTearDown(() => AuraSound.soundOn.value = true);
      await tester.pumpWidget(shotApp(screen(g)));
      await tester.pumpAndSettle();
      await tester.tap(inCard('child-1', 'Read aloud'));
      await tester.pumpAndSettle();
      expect(g.bodyOf('PUT /api/children/child-1/settings'), {
        'readAloud': false,
      });
      final sw = find.descendant(
        of: find.byKey(const ValueKey('settings-child-1')),
        matching: find.byType(AuraSwitch),
      );
      expect(tester.widget<AuraSwitch>(sw).value, isFalse);
      expect(find.text('Saved'), findsOneWidget);
      expect(g.store.values['lesson.readAloud'], isNull);
    });

    testWidgets('offline, a change goes back and says so', (tester) async {
      final g = await Gu.make(tester);
      g.server.routes['PUT /api/children/child-1/settings'] = (_) =>
          throw const SocketException('offline');
      await tester.pumpWidget(shotApp(screen(g)));
      await tester.pumpAndSettle();
      await tester.tap(inCard('child-1', 'Read aloud'));
      await tester.pumpAndSettle();
      final sw = find.descendant(
        of: find.byKey(const ValueKey('settings-child-1')),
        matching: find.byType(AuraSwitch),
      );
      expect(tester.widget<AuraSwitch>(sw).value, isTrue);
      expect(
        find.text('Not saved. Check the internet, then change it again.'),
        findsOneWidget,
      );
      expect(find.text('Saved'), findsNothing);
      // an error, so not the tick that says Saved
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets('opened offline, it shows the settings this phone kept '
        '(PAR-05)', (tester) async {
      final g = await Gu.make(tester);
      await tester.pumpWidget(shotApp(screen(g)));
      await tester.pumpAndSettle();
      // the server goes away; Settings is opened again
      g.server.routes['GET /api/children'] = (_) =>
          throw const SocketException('offline');
      g.server.routes['GET /api/children/child-2/settings'] = (_) =>
          throw const SocketException('offline');
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(shotApp(screen(g)));
      await tester.pumpAndSettle();
      expect(find.textContaining("Can't reach the server"), findsNothing);
      expect(find.text('AARAV'), findsOneWidget);
      expect(find.text('MAYA'), findsOneWidget);
      expect(inCard('child-1', '15 min'), findsOneWidget);
      expect(inCard('child-2', 'No limit'), findsOneWidget);
    });

    testWidgets('opened offline with nothing kept, it says so with Try '
        'again', (tester) async {
      final g = await Gu.make(tester);
      g.server.routes['GET /api/children'] = (_) =>
          throw const SocketException('offline');
      await tester.pumpWidget(shotApp(screen(g)));
      await tester.pumpAndSettle();
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('a refused change goes back too', (tester) async {
      final g = await Gu.make(tester);
      g.server.on('PUT /api/children/child-1/settings', {
        'error': 'dailyLimitMinutes is whole minutes from 5 to 240',
      }, status: 400);
      await tester.pumpWidget(shotApp(screen(g)));
      await tester.pumpAndSettle();
      await tester.tap(inCard('child-1', 'Time each day'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('30 minutes'));
      await tester.pumpAndSettle();
      expect(inCard('child-1', '15 min'), findsOneWidget);
      expect(
        find.text("That didn't save. Please change it again."),
        findsOneWidget,
      );
    });

    testWidgets('the bigger pad stays on this phone', (tester) async {
      final g = await Gu.make(tester);
      await tester.pumpWidget(shotApp(screen(g)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bigger number pad'));
      await tester.pumpAndSettle();
      expect(g.store.values['lesson.biggerPad'], '1');
      final prefs = await tester.runAsync(g.repo.loadPrefs);
      expect(prefs!.biggerPad, isTrue);
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
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Report email'));
      await tester.pumpAndSettle();
      expect(find.text('Every email also has a link to stop them.'), findsOne);
      g.server.on('GET /api/family/settings/reports', {'frequency': 'off'});
      await tester.tap(find.text('Report email'));
      await tester.pumpAndSettle();
      expect(g.bodyOf('PUT /api/family/settings/reports'), {
        'frequency': 'off',
      });
      final sw = find.descendant(
        of: find.ancestor(
          of: find.text('Report email'),
          matching: find.byType(KvRow),
        ),
        matching: find.byType(AuraSwitch),
      );
      expect(tester.widget<AuraSwitch>(sw).value, isFalse);
    });

    testWidgets('report email off: turning it on asks first (Notify)', (
      tester,
    ) async {
      final g = await Gu.make(tester);
      g.server.on('GET /api/family/settings/reports', {'frequency': 'off'});
      await tester.pumpWidget(shotApp(screen(g)));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Report email'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Report email'));
      await tester.pumpAndSettle();
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
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('How often'));
      await tester.pumpAndSettle();
      expect(find.text('Once a week'), findsOneWidget);
      await tester.tap(find.text('How often'));
      await tester.pumpAndSettle();
      expect(find.text('went to ${Paths.emailFrequency}'), findsOneWidget);
    });
  });
}
