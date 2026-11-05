import 'package:auramath/data/repositories/account_repository.dart';
import 'package:auramath/deps.dart';
import 'package:auramath/ui/features/setup/setup_paths.dart';
import 'package:auramath/ui/features/setup/views/check_email_screen.dart';
import 'package:auramath/ui/features/setup/views/save_place_screen.dart';
import 'package:auramath/ui/features/setup/views/sign_in_screen.dart';
import 'package:auramath/ui/features/setup/views/verify_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/app_harness.dart';
import '../../../helpers/shots.dart';
import 'setup_test_helpers.dart';

/// A server that can do everything, and a grown-up who finished setup.
Future<(Deps, FakeServer)> ready(WidgetTester tester) async {
  final (deps, server) = await setupDeps(tester);
  deps.account.draft
    ..name = 'Aarav'
    ..age = 7
    ..schoolYear = 'Year 2'
    ..startingPoint = 'not_sure'
    ..agreed = true;
  server
    ..on('GET /api/auth/config', {
      'googleClientId': 'google-server-id',
      'appleSignIn': true,
      'emailLink': true,
    })
    ..on('POST /api/auth/apple', {'token': 'parent-token'})
    ..on('POST /api/auth/google', {'token': 'parent-token'})
    ..on('POST /api/auth/email-link', {
      'devLink': 'http://localhost:8080/parent#m=tok123',
    }, status: 202)
    ..on('POST /api/auth/email-link/verify', {'token': 'parent-token'})
    ..on('GET /api/parent/consent', {'currentVersion': 'v3'})
    ..on('POST /api/parent/consent', {}, status: 201)
    ..on('POST /api/children', {'id': 'child-9', 'displayName': 'Aarav'});
  return (deps, server);
}

Future<void> brandAssets(WidgetTester tester) async {
  await loadSystemFontStandIn(tester);
  await precacheAssets(tester, ['assets/images/google_g.png']);
}

const readyPath = 'went to /setup/ready?child=child-9&name=Aarav';

void main() {
  group('SavePlace (643:235)', () {
    testWidgets('fits every size', (tester) async {
      final (deps, _) = await ready(tester);
      await brandAssets(tester);
      await shotAllSizes(tester, 'setup_save', SavePlaceScreen(deps: deps));
    });

    testWidgets('Apple signs in, agrees, adds the child, goes to Ready', (
      tester,
    ) async {
      final (deps, server) = await ready(tester);
      await show(tester, SavePlaceScreen(deps: deps));
      expect(find.text("Save Aarav's place"), findsOneWidget);
      await tapAndWait(tester, find.text('Continue with Apple'));

      expect(called(server), [
        'GET /api/auth/config',
        'POST /api/auth/apple',
        'GET /api/parent/consent',
        'POST /api/parent/consent',
        'POST /api/children',
      ]);
      expect(server.calls[3].$2, {'noticeVersion': 'v3'});
      expect(server.calls[4].$2, {
        'displayName': 'Aarav',
        'age': 7,
        'schoolYear': 'Year 2',
        'startingPoint': 'not_sure',
      });
      expect(deps.account.role, Role.parent);
      expect(deps.account.draft.name, isNull);
      expect(find.text(readyPath), findsOneWidget);
    });

    testWidgets('Apple switched off says so and stays', (tester) async {
      final (deps, server) = await ready(tester);
      server.on('GET /api/auth/config', {'appleSignIn': false});
      await show(tester, SavePlaceScreen(deps: deps));
      await tapAndWait(tester, find.text('Continue with Apple'));
      expect(
        find.text("Apple sign-in isn't switched on for this server yet."),
        findsOneWidget,
      );
      expect(called(server), ['GET /api/auth/config']);
    });

    testWidgets('Google switched off says so', (tester) async {
      final (deps, server) = await ready(tester);
      server.on('GET /api/auth/config', {'googleClientId': ''});
      await show(tester, SavePlaceScreen(deps: deps));
      await tapAndWait(tester, find.text('Continue with Google'));
      expect(
        find.text("Google sign-in isn't switched on for this server yet"),
        findsOneWidget,
      );
    });

    testWidgets("the dev server's name rule shows, the draft is kept", (
      tester,
    ) async {
      final (deps, server) = await ready(tester);
      server.on('POST /api/children', {
        'error': 'synthetic names only until legal review clears',
      }, status: 400);
      await show(tester, SavePlaceScreen(deps: deps));
      await tapAndWait(tester, find.text('Continue with Google'));
      expect(
        find.text('synthetic names only until legal review clears'),
        findsOneWidget,
      );
      expect(deps.account.draft.name, 'Aarav');
      expect(find.textContaining('went to'), findsNothing);
    });

    testWidgets('Use my email sends a link and opens CheckEmail', (
      tester,
    ) async {
      final (deps, server) = await ready(tester);
      await show(tester, SavePlaceScreen(deps: deps));
      await tapAndWait(tester, find.text('Use my email'));
      await tester.enterText(find.byType(TextField), 'sam@example.com');
      await tapAndWait(tester, find.text('Email me a link'));
      expect(server.calls.last.$2, {'email': 'sam@example.com'});
      expect(
        find.text(
          'went to /setup/check-email?email=sam%40example.com&dev=tok123',
        ),
        findsOneWidget,
      );
    });

    testWidgets("a server that can't send email says so", (tester) async {
      final (deps, server) = await ready(tester);
      server.on('POST /api/auth/email-link', {
        'error': 'this deployment cannot send email',
      }, status: 501);
      await show(tester, SavePlaceScreen(deps: deps));
      await tapAndWait(tester, find.text('Use my email'));
      await tester.enterText(find.byType(TextField), 'sam@example.com');
      await tapAndWait(tester, find.text('Email me a link'));
      expect(find.text('this deployment cannot send email'), findsOneWidget);
    });
  });

  group('SignIn (653:2)', () {
    testWidgets('fits every size', (tester) async {
      final (deps, _) = await ready(tester);
      await brandAssets(tester);
      await shotAllSizes(tester, 'setup_sign_in', SignInScreen(deps: deps));
    });

    testWidgets('Google signs in and goes to the children', (tester) async {
      final (deps, server) = await ready(tester);
      await show(tester, SignInScreen(deps: deps));
      await tapAndWait(tester, find.text('Continue with Google'));
      expect(called(server), ['GET /api/auth/config', 'POST /api/auth/google']);
      expect(find.text('went to /kids'), findsOneWidget);
    });

    testWidgets('an address is needed before sending', (tester) async {
      final (deps, server) = await ready(tester);
      await show(tester, SignInScreen(deps: deps));
      await tapAndWait(tester, find.text('Email me a link'));
      expect(
        find.text('Type the email address to send the link to.'),
        findsOneWidget,
      );
      expect(server.calls, isEmpty);
    });
  });

  group('CheckEmail (653:144)', () {
    Widget screen(Deps deps, {bool fromSetup = true, String? token}) =>
        CheckEmailScreen(
          deps: deps,
          fromSetup: fromSetup,
          devToken: 'tok123',
          token: token,
        );

    testWidgets('fits every size', (tester) async {
      final (deps, _) = await ready(tester);
      await shotAllSizes(tester, 'setup_check_email', screen(deps));
    });

    testWidgets('the dev link signs in and finishes setup', (tester) async {
      final (deps, server) = await ready(tester);
      await show(tester, screen(deps));
      await tapAndWait(tester, find.text('Open the link (dev only)'));
      expect(server.calls.first.$1, 'POST /api/auth/email-link/verify');
      expect(server.calls.first.$2, {'token': 'tok123'});
      expect(called(server), contains('POST /api/children'));
      expect(find.text(readyPath), findsOneWidget);
    });

    testWidgets('from SignIn it goes to the children', (tester) async {
      final (deps, server) = await ready(tester);
      await show(tester, screen(deps, fromSetup: false));
      await tapAndWait(tester, find.text('Open the link (dev only)'));
      expect(called(server), ['POST /api/auth/email-link/verify']);
      expect(find.text('went to /kids'), findsOneWidget);
    });

    testWidgets('a used link says so', (tester) async {
      final (deps, server) = await ready(tester);
      server.on('POST /api/auth/email-link/verify', {
        'error': 'that link has been used already, or has expired',
      }, status: 410);
      await show(tester, screen(deps));
      await tapAndWait(tester, find.text('Open the link (dev only)'));
      expect(
        find.text('that link has been used already, or has expired'),
        findsOneWidget,
      );
    });

    testWidgets('I tapped the link, before it opened here, explains', (
      tester,
    ) async {
      final (deps, server) = await ready(tester);
      await show(tester, screen(deps));
      await tapAndWait(tester, find.text('I tapped the link'));
      expect(
        find.textContaining("hasn't opened on this phone"),
        findsOneWidget,
      );
      expect(server.calls, isEmpty);
    });

    testWidgets('a link handed back from /auth/verify is followed', (
      tester,
    ) async {
      final (deps, server) = await ready(tester);
      await show(tester, screen(deps, token: 'tok9'));
      await settle(tester);
      expect(server.calls.first.$2, {'token': 'tok9'});
      expect(find.text(readyPath), findsOneWidget);
    });
  });

  group('/auth/verify', () {
    testWidgets('signs in and goes to the children', (tester) async {
      final (deps, server) = await ready(tester);
      deps.account.draft.agreed = false;
      await show(tester, VerifyScreen(deps: deps, token: 'tok5'));
      await settle(tester);
      expect(server.calls.single.$2, {'token': 'tok5'});
      expect(find.text('went to /kids'), findsOneWidget);
    });

    testWidgets('mid-setup it hands the link back to setup', (tester) async {
      final (deps, server) = await ready(tester);
      await show(tester, VerifyScreen(deps: deps, token: 'tok5'));
      await settle(tester);
      expect(server.calls, isEmpty);
      expect(find.text('went to /setup/check-email?m=tok5'), findsOneWidget);
    });

    testWidgets('a used link says so, with a way back', (tester) async {
      final (deps, server) = await ready(tester);
      deps.account.draft.agreed = false;
      server.on('POST /api/auth/email-link/verify', {
        'error': 'that link has been used already, or has expired',
      }, status: 410);
      await show(tester, VerifyScreen(deps: deps, token: 'tok5'));
      await settle(tester);
      expect(
        find.text('that link has been used already, or has expired'),
        findsOneWidget,
      );
      await tapAndWait(tester, find.text('Back to sign in'));
      expect(find.text('went to /sign-in'), findsOneWidget);
    });
  });

  test('linkToken reads m= from a fragment or a query', () {
    expect(linkToken('http://x/parent#m=abc'), 'abc');
    expect(linkToken('auramath://auth/verify?m=abc&x=1'), 'abc');
    expect(linkToken('http://x/parent#k=abc'), isNull);
  });
}
