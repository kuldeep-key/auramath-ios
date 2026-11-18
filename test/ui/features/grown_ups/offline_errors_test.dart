import 'dart:io';

import 'package:auramath/data/repositories/recent_notes_repository.dart';
import 'package:auramath/data/repositories/report_email_repository.dart';
import 'package:auramath/data/services/api.dart';
import 'package:auramath/l10n/app_localizations_en.dart';
import 'package:auramath/routing/paths.dart';
import 'package:auramath/ui/features/grown_ups/views/email_frequency_screen.dart';
import 'package:auramath/ui/features/grown_ups/views/family_screen.dart';
import 'package:auramath/ui/features/grown_ups/views/grown_up_home_screen.dart';
import 'package:auramath/ui/features/grown_ups/views/invite_screen.dart';
import 'package:auramath/ui/features/grown_ups/views/parts.dart';
import 'package:auramath/ui/features/grown_ups/views/passcode_screen.dart';
import 'package:auramath/ui/features/grown_ups/views/recent_notes_screen.dart';
import 'package:auramath/ui/features/grown_ups/views/rights_screen.dart';
import 'package:auramath/ui/features/grown_ups/views/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../../helpers/shots.dart';
import 'gu_fakes.dart';

/// PAR-14: a Family area screen that can't reach the server says so in
/// plain words, never the exception's text (QA Section C, 18 Nov).
void main() {
  const offline = "Can't connect right now. Please check the internet.";
  const wrong =
      "That didn't work just now. Please give it a moment, then have "
      'another go.';

  /// The server goes away: every route the family has fails as a dropped
  /// connection does on a phone.
  void goOffline(Gu g) {
    for (final route in [...g.server.routes.keys]) {
      g.server.routes[route] = (_) => throw http.ClientException(
        'SocketException: Connection refused (OS Error: Connection '
        'refused, errno = 61), address = localhost, port = 8090',
        Uri.parse('http://localhost:8090$route'),
      );
    }
  }

  /// None of the transport's words reach the screen.
  void noDetail() {
    for (final raw in [
      'Exception',
      'SocketException',
      'Connection refused',
      'localhost',
      "Can't reach the server",
      'HTTP ',
    ]) {
      expect(find.textContaining(raw), findsNothing, reason: raw);
    }
  }

  final screens = <String, Widget Function(Gu g)>{
    'Family area home': (g) => GrownUpHomeScreen(
      account: g.deps.account,
      family: g.deps.family,
      repo: g.repo,
    ),
    'Family': (g) => FamilyScreen(family: g.deps.family, repo: g.repo),
    'Settings': (g) => SettingsScreen(
      family: g.deps.family,
      repo: g.repo,
      email: ReportEmailRepository(g.deps.client),
      settings: g.settings,
    ),
    'How often': (g) =>
        EmailFrequencyScreen(email: ReportEmailRepository(g.deps.client)),
    'Recent notes': (g) => RecentNotesScreen(
      childId: 'child-1',
      family: g.deps.family,
      notes: RecentNotesRepository(g.deps.client, g.repo),
    ),
    'Passcode': (g) => PasscodeScreen(
      account: g.deps.account,
      family: g.deps.family,
      repo: g.repo,
      deviceLock: g.deps.deviceLock,
    ),
    'Rights': (g) => RightsScreen(
      repo: g.repo,
      family: g.deps.family,
      deletePath: Paths.deleteAccount,
    ),
  };

  for (final MapEntry(key: name, value: screen) in screens.entries) {
    testWidgets('$name, opened offline: plain words, no exception text', (
      tester,
    ) async {
      final g = await Gu.make(tester);
      goOffline(g);
      await tester.pumpWidget(shotApp(screen(g)));
      await tester.pumpAndSettle();
      expect(find.textContaining(offline), findsWidgets);
      noDetail();
    });
  }

  testWidgets('offline at every size (1.3x on the smallest phone)', (
    tester,
  ) async {
    final g = await Gu.make(tester);
    goOffline(g);
    await shotAllSizes(
      tester,
      'grown_ups_offline',
      screens['Family area home']!(g),
    );
    expect(find.text(offline), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    noDetail();
  });

  testWidgets('back online, Try again loads the page', (tester) async {
    final g = await Gu.make(tester);
    final screen = FamilyScreen(family: g.deps.family, repo: g.repo);
    goOffline(g);
    await tester.pumpWidget(shotApp(screen));
    await tester.pumpAndSettle();
    expect(find.text(offline), findsOneWidget);
    g.seed();
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text(offline), findsNothing);
    expect(find.text('priya@gmail.com (you)'), findsOneWidget);
  });

  testWidgets('a send offline (Invite): plain words under the field', (
    tester,
  ) async {
    final g = await Gu.make(tester);
    g.server.routes['POST /api/parent/invites'] = (_) =>
        throw const SocketException('Connection refused');
    await tester.pumpWidget(shotApp(InviteScreen(repo: g.repo)));
    await tester.enterText(find.byType(TextField), 'raj@example.com');
    await tester.tap(find.text('Send invite'));
    await tester.pumpAndSettle();
    expect(find.text(offline), findsOneWidget);
    expect(find.text('Invite sent'), findsNothing);
    noDetail();
  });

  testWidgets('an answer with no reason in it: plain words, no status line', (
    tester,
  ) async {
    final g = await Gu.make(tester);
    g.server.raw['GET /api/children'] = http.Response(
      '<html>Bad gateway</html>',
      502,
    );
    await tester.pumpWidget(shotApp(screens['Family']!(g)));
    await tester.pumpAndSettle();
    expect(find.text(wrong), findsOneWidget);
    expect(find.textContaining('JSON'), findsNothing);
    expect(find.textContaining('gateway'), findsNothing);
    noDetail();
  });

  group('ErrorNote.message', () {
    final l = AppLocalizationsEn();

    test('unreached: plain words, the detail kept for the log', () {
      const e = ApiException.unreachable(SocketException('Connection refused'));
      expect(ErrorNote.message(e, l), offline);
      expect('$e', contains('Connection refused'));
      // copied on without its cause, it is still the plain words
      expect(ErrorNote.message(ApiException(e.message), l), offline);
    });

    test("the server's or the app's own reason is said as it is", () {
      expect(
        ErrorNote.message(
          const ApiException(
            'that grown-up is already in this family',
            status: 409,
          ),
          l,
        ),
        'that grown-up is already in this family',
      );
      expect(
        ErrorNote.message(const ApiException('down', status: 503), l),
        'down',
      );
      // the app's own words, with no status
      expect(
        ErrorNote.message(
          const ApiException("Some lesson work hasn't reached Auramath yet."),
          l,
        ),
        "Some lesson work hasn't reached Auramath yet.",
      );
      expect(
        ErrorNote.message('Couldn\'t check your consent', l),
        "Couldn't check your consent",
      );
    });

    test('a status line, not-JSON, or another error: plain words', () {
      expect(
        ErrorNote.message(const ApiException('HTTP 502', status: 502), l),
        wrong,
      );
      expect(
        ErrorNote.message(
          const ApiException(
            'The server sent something that is not JSON',
            status: 200,
          ),
          l,
        ),
        wrong,
      );
      expect(
        ErrorNote.message(const FormatException('Unexpected character'), l),
        wrong,
      );
    });
  });
}
