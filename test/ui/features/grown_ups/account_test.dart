import 'package:auramath/data/repositories/account_repository.dart';
import 'package:auramath/routing/paths.dart';
import 'package:auramath/ui/features/grown_ups/views/add_child_screen.dart';
import 'package:auramath/ui/features/grown_ups/views/leave_screens.dart';
import 'package:auramath/ui/features/grown_ups/views/notify_screen.dart';
import 'package:auramath/ui/features/grown_ups/views/rights_screen.dart';
import 'package:auramath_engine/auramath_engine.dart' show SpecEvent;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/shots.dart';
import '../lesson/fakes.dart' show memorySessions;
import 'gu_fakes.dart';

const _step = SpecEvent('step_entered', {'step_id': 'draw_known_bar'});

/// Taps, letting the outbox's SQLite finish in real time.
Future<void> _tapReal(WidgetTester tester, Finder f) async {
  await tester.runAsync(() async {
    await tester.tap(f);
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });
  await tester.pumpAndSettle();
}

void main() {
  group('AddChild', () {
    Widget screen(Gu g) => AddChildScreen(family: g.deps.family);

    testWidgets('at every size', (tester) async {
      final g = await Gu.make(tester);
      await shotAllSizes(tester, 'grown_ups_add_child', screen(g));
      expect(find.text('First name'), findsOneWidget);
    });

    testWidgets('records consent if needed, then adds the child', (
      tester,
    ) async {
      final g = await Gu.make(tester);
      g.server
        ..on('GET /api/parent/consent', {
          'consented': false,
          'currentVersion': 'v1',
        })
        ..on('POST /api/parent/consent', {'consented': true}, status: 201)
        ..on('POST /api/children', {'id': 'child-3', 'displayName': 'Zoe'});
      await tester.pumpWidget(shotApp(screen(g)));
      await tester.enterText(find.byType(TextField).first, ' Zoe ');
      await tester.enterText(find.byType(TextField).last, 'Year 3');
      await tester.tap(find.text('I agree, continue'));
      await tester.pumpAndSettle();
      expect(g.bodyOf('POST /api/parent/consent'), {'noticeVersion': 'v1'});
      expect(g.bodyOf('POST /api/children'), {
        'displayName': 'Zoe',
        'schoolYear': 'Year 3',
      });
      expect(find.text('went to ${Paths.grownUps}'), findsOneWidget);
    });

    testWidgets('a name is needed; a refusal shows the reason', (tester) async {
      final g = await Gu.make(tester);
      g.server
        ..on('GET /api/parent/consent', {
          'consentAt': 1,
          'consentWithdrawnAt': null,
          'currentVersion': 'v1',
          'stale': false,
        })
        ..on('POST /api/children', {
          'error': 'synthetic names only until legal review clears',
        }, status: 400);
      await tester.pumpWidget(shotApp(screen(g)));
      await tester.tap(find.text('I agree, continue'));
      await tester.pumpAndSettle();
      expect(find.text('Type a first name.'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'Zoë');
      await tester.tap(find.text('I agree, continue'));
      await tester.pumpAndSettle();
      expect(
        find.text('synthetic names only until legal review clears'),
        findsOneWidget,
      );
    });
  });

  group('Notify', () {
    Widget screen(Gu g) => NotifyScreen(family: g.deps.family, repo: g.repo);

    testWidgets('at every size: an email, not a push', (tester) async {
      final g = await Gu.make(tester);
      await shotAllSizes(tester, 'grown_ups_notify', screen(g));
      expect(find.text('An email after each session'), findsOneWidget);
    });

    testWidgets('Yes please turns on the email after each session', (
      tester,
    ) async {
      final g = await Gu.make(tester);
      g.server.on('PUT /api/family/settings/reports', null, status: 204);
      await tester.pumpWidget(shotApp(screen(g)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes please'));
      await tester.pumpAndSettle();
      expect(g.bodyOf('PUT /api/family/settings/reports'), {
        'frequency': 'each_session',
      });
      expect(find.text('went to ${Paths.grownUps}'), findsOneWidget);
    });

    testWidgets('Not now changes nothing', (tester) async {
      final g = await Gu.make(tester);
      await tester.pumpWidget(shotApp(screen(g)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(g.calls, isNot(contains('PUT /api/family/settings/reports')));
    });
  });

  group('SignOut', () {
    testWidgets('at every size; sends, keeps no child data, goes to Open', (
      tester,
    ) async {
      final g = await Gu.make(tester);
      final sessions = g.deps.sessions;
      await tester.runAsync(() async {
        await g.deps.account.chooseChild('child-1');
        await sessions.record('s1', 1, const [_step]);
      });
      await shotAllSizes(
        tester,
        'grown_ups_sign_out',
        SignOutScreen(account: g.deps.account, sessions: sessions),
      );
      await _tapReal(tester, find.text('Sign out'));
      expect(g.deps.account.role, Role.none);
      expect(g.deps.account.childId, isNull);
      expect(await tester.runAsync(g.deps.outbox.all), isEmpty);
      expect(find.text('went to ${Paths.open}'), findsOneWidget);
    });

    testWidgets('unsent work: stays signed in and says why', (tester) async {
      final g = await Gu.make(tester);
      final (sessions, outbox, api) = (await tester.runAsync(memorySessions))!;
      await tester.runAsync(() async {
        api.failNext = 99;
        await sessions.record('s1', 1, const [_step]);
      });
      await tester.pumpWidget(
        shotApp(SignOutScreen(account: g.deps.account, sessions: sessions)),
      );
      await _tapReal(tester, find.text('Sign out'));
      expect(
        find.textContaining("hasn't reached Auramath yet"),
        findsOneWidget,
      );
      expect(g.deps.account.role, Role.parent);
      expect(await tester.runAsync(outbox.unsent), hasLength(1));
      sessions.dispose();
    });
  });

  group('Rights', () {
    Widget screen(Gu g) => RightsScreen(
      repo: g.repo,
      deletePath: '${Paths.rights}/delete',
      poll: const Duration(milliseconds: 100),
    );

    testWidgets('at every size', (tester) async {
      final g = await Gu.make(tester);
      await shotAllSizes(tester, 'grown_ups_rights', screen(g));
      expect(find.text('What we keep'), findsOneWidget);
    });

    testWidgets('the export starts, is polled, and says when ready', (
      tester,
    ) async {
      final g = await Gu.make(tester);
      g.server
        ..on('POST /api/parent/export-jobs', {
          'jobId': 'exp_1',
          'status': 'pending',
        }, status: 202)
        ..on('GET /api/parent/export-jobs/exp_1', {
          'jobId': 'exp_1',
          'status': 'ready',
        });
      await tester.pumpWidget(shotApp(screen(g)));
      await tester.tap(find.text('Download everything'));
      await tester.pump();
      expect(find.text('Getting it ready…'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump();
      expect(find.text('Ready. Tap to save it on this phone.'), findsOneWidget);
    });

    testWidgets('a failed export says so', (tester) async {
      final g = await Gu.make(tester);
      g.server.on('POST /api/parent/export-jobs', {
        'jobId': 'exp_1',
        'status': 'failed',
        'error': 'the export failed',
      }, status: 202);
      await tester.pumpWidget(shotApp(screen(g)));
      await tester.tap(find.text('Download everything'));
      await tester.pumpAndSettle();
      expect(find.text('The export failed. Tap to try again.'), findsOneWidget);
    });

    testWidgets('Delete opens its own confirmation', (tester) async {
      final g = await Gu.make(tester);
      await tester.pumpWidget(shotApp(screen(g)));
      await tester.tap(find.text('Delete the family account'));
      await tester.pumpAndSettle();
      expect(find.text('went to ${Paths.rights}/delete'), findsOneWidget);
    });

    testWidgets('confirming erases, forgets the lessons, signs out', (
      tester,
    ) async {
      final g = await Gu.make(tester);
      g.server.on('POST /api/parent/erase', {'erased': {}});
      await tester.runAsync(
        () => g.deps.sessions.record('s1', 1, const [_step]),
      );
      final delete = DeleteAccountScreen(
        account: g.deps.account,
        repo: g.repo,
        sessions: g.deps.sessions,
      );
      await shotAllSizes(tester, 'grown_ups_delete_account', delete);
      expect(find.textContaining("can't be undone"), findsOneWidget);
      await _tapReal(tester, find.text('Delete everything'));
      expect(g.calls, contains('POST /api/parent/erase'));
      expect(g.deps.account.role, Role.none);
      expect(await tester.runAsync(g.deps.outbox.all), isEmpty);
      expect(find.text('went to ${Paths.open}'), findsOneWidget);
    });

    testWidgets('a failed erase keeps the account and says why', (
      tester,
    ) async {
      final g = await Gu.make(tester);
      g.server.on('POST /api/parent/erase', {'error': 'down'}, status: 503);
      await tester.pumpWidget(
        shotApp(
          DeleteAccountScreen(
            account: g.deps.account,
            repo: g.repo,
            sessions: g.deps.sessions,
          ),
        ),
      );
      await tester.tap(find.text('Delete everything'));
      await tester.pumpAndSettle();
      expect(find.text('down'), findsOneWidget);
      expect(g.deps.account.role, Role.parent);
    });
  });
}
