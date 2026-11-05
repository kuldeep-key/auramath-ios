import 'package:auramath/data/repositories/setup_repository.dart';
import 'package:auramath/ui/features/setup/views/join_code_screen.dart';
import 'package:auramath/ui/features/setup/views/lock_screen.dart';
import 'package:auramath/ui/features/setup/views/passcode_screen.dart';
import 'package:auramath/ui/features/setup/views/ready_screen.dart';
import 'package:auramath/ui/features/setup/views/setup_parts.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/app_harness.dart';
import '../../../helpers/shots.dart';
import 'setup_test_helpers.dart';

const child = 'child-9';

void main() {
  group('Ready (644:2)', () {
    const screen = ReadyScreen(childId: child, name: 'Aarav');

    testWidgets('fits every size', (tester) async {
      await precacheAssets(tester, [kidBoy]);
      await shotAllSizes(tester, 'setup_ready', screen);
    });

    testWidgets('Hand over opens Lock with the child', (tester) async {
      await show(tester, screen);
      await tapAndWait(tester, find.text('Hand over to Aarav'));
      expect(
        find.text('went to /setup/lock?child=child-9&name=Aarav'),
        findsOneWidget,
      );
    });

    testWidgets('their own phone opens JoinCode', (tester) async {
      await show(tester, screen);
      await tapAndWait(tester, find.text('Aarav has their own phone'));
      expect(
        find.text('went to /setup/join-code?child=child-9&name=Aarav'),
        findsOneWidget,
      );
    });
  });

  group('Lock (644:20)', () {
    const passcodePath = 'went to /setup/passcode?child=child-9&name=Aarav';

    testWidgets('fits every size', (tester) async {
      final (deps, _) = await setupDeps(tester, stored: parentPhone);
      await shotAllSizes(
        tester,
        'setup_lock',
        LockScreen(deps: deps, childId: child, name: 'Aarav'),
      );
    });

    testWidgets('Face ID turns it on, then a passcode is chosen', (
      tester,
    ) async {
      final (deps, _) = await setupDeps(tester, stored: parentPhone);
      await show(tester, LockScreen(deps: deps, childId: child, name: 'Aarav'));
      await tapAndWait(tester, find.text('Use Face ID'));
      expect(deps.account.useFaceId, isTrue);
      expect(find.text(passcodePath), findsOneWidget);
    });

    testWidgets('Face ID failing says so and stays', (tester) async {
      final (deps, _) = await setupDeps(tester, stored: parentPhone);
      (deps.deviceLock as FakeDeviceLock).passes = false;
      await show(tester, LockScreen(deps: deps, childId: child, name: 'Aarav'));
      await tapAndWait(tester, find.text('Use Face ID'));
      expect(deps.account.useFaceId, isFalse);
      expect(
        find.text("Face ID didn't work. You can use a passcode instead."),
        findsOneWidget,
      );
    });

    testWidgets('no Face ID on the phone says so', (tester) async {
      final (deps, _) = await setupDeps(tester, stored: parentPhone);
      (deps.deviceLock as FakeDeviceLock).has = false;
      await show(tester, LockScreen(deps: deps, childId: child, name: 'Aarav'));
      await tapAndWait(tester, find.text('Use Face ID'));
      expect(find.textContaining("Face ID isn't set up"), findsOneWidget);
    });

    testWidgets('Use a passcode opens Choose a passcode', (tester) async {
      final (deps, _) = await setupDeps(tester, stored: parentPhone);
      await show(tester, LockScreen(deps: deps, childId: child, name: 'Aarav'));
      await tapAndWait(tester, find.text('Use a passcode'));
      expect(find.text(passcodePath), findsOneWidget);
    });
  });

  group('Choose a passcode (not in Figma)', () {
    Future<void> type(WidgetTester tester, String digits) async {
      for (final d in digits.split('')) {
        await tapAndWait(tester, find.text(d));
      }
    }

    testWidgets('fits every size', (tester) async {
      final (deps, server) = await setupDeps(tester, stored: parentPhone);
      server.on('GET /api/family/passcode', {'set': false, 'length': 4});
      await shotAllSizes(
        tester,
        'setup_passcode',
        PasscodeScreen(deps: deps, childId: child, name: 'Aarav'),
      );
    });

    testWidgets('twice the same, saved, child chosen, handed over', (
      tester,
    ) async {
      final (deps, server) = await setupDeps(tester, stored: parentPhone);
      server
        ..on('GET /api/family/passcode', {'set': false, 'length': 4})
        ..on('PUT /api/family/passcode', null, status: 204);
      await show(
        tester,
        PasscodeScreen(deps: deps, childId: child, name: 'Aarav'),
      );
      await settle(tester);
      expect(find.text('Choose a passcode'), findsOneWidget);
      await type(tester, '0123');
      expect(find.text('Type it again'), findsOneWidget);
      await type(tester, '0123');
      expect(server.calls.last.$2, {'passcode': '0123'});
      expect(deps.account.childId, child);
      expect(find.text('went to /home'), findsOneWidget);
    });

    testWidgets("two that don't match start again", (tester) async {
      final (deps, server) = await setupDeps(tester, stored: parentPhone);
      server.on('GET /api/family/passcode', {'set': false, 'length': 4});
      await show(
        tester,
        PasscodeScreen(deps: deps, childId: child, name: 'Aarav'),
      );
      await settle(tester);
      await type(tester, '1234');
      await type(tester, '4321');
      expect(
        find.text("Those didn't match. Choose a passcode again."),
        findsOneWidget,
      );
      expect(find.text('Choose a passcode'), findsOneWidget);
      expect(called(server), ['GET /api/family/passcode']);
    });

    testWidgets('a server refusal shows and starts again', (tester) async {
      final (deps, server) = await setupDeps(tester, stored: parentPhone);
      server
        ..on('GET /api/family/passcode', {'set': false, 'length': 4})
        ..on('PUT /api/family/passcode', {
          'error': 'the passcode is 4 digits',
        }, status: 400);
      await show(
        tester,
        PasscodeScreen(deps: deps, childId: child, name: 'Aarav'),
      );
      await settle(tester);
      await type(tester, '1234');
      await type(tester, '1234');
      expect(find.text('the passcode is 4 digits'), findsOneWidget);
      expect(deps.account.childId, isNull);
    });

    testWidgets('a family passcode already set is kept', (tester) async {
      final (deps, server) = await setupDeps(tester, stored: parentPhone);
      server.on('GET /api/family/passcode', {'set': true, 'length': 4});
      await show(
        tester,
        PasscodeScreen(deps: deps, childId: child, name: 'Aarav'),
      );
      await settle(tester);
      expect(find.text('Your family has a passcode'), findsOneWidget);
      await tapAndWait(tester, find.text('Hand over to Aarav'));
      expect(deps.account.childId, child);
      expect(find.text('went to /home'), findsOneWidget);
    });

    testWidgets('offline shows the error and Try again', (tester) async {
      final (deps, server) = await setupDeps(tester, stored: parentPhone);
      server.on('GET /api/family/passcode', {'error': 'down'}, status: 503);
      await show(
        tester,
        PasscodeScreen(deps: deps, childId: child, name: 'Aarav'),
      );
      await settle(tester);
      expect(find.text('down'), findsOneWidget);
      server.on('GET /api/family/passcode', {'set': false, 'length': 4});
      await tapAndWait(tester, find.text('Try again'));
      expect(find.text('Choose a passcode'), findsOneWidget);
    });
  });

  group('JoinCode (644:75)', () {
    final now = DateTime(2026, 10, 29, 9);

    Future<(JoinCodeScreen, FakeServer)> joinCode(WidgetTester tester) async {
      final (deps, server) = await setupDeps(tester, stored: parentPhone);
      server
        ..on('GET /api/devices', {'devices': []})
        ..on('POST /api/devices/pairing', {
          'code': '482715',
          'expiresAt': now
              .add(const Duration(minutes: 9, seconds: 59))
              .millisecondsSinceEpoch,
        });
      return (
        JoinCodeScreen(
          repo: SetupRepository(deps.client),
          name: 'Aarav',
          now: () => now,
        ),
        server,
      );
    }

    testWidgets('fits every size', (tester) async {
      final (screen, _) = await joinCode(tester);
      await shotAllSizes(tester, 'setup_join_code', screen);
    });

    testWidgets('shows the code and how long it works', (tester) async {
      final (screen, server) = await joinCode(tester);
      await show(tester, screen);
      await settle(tester);
      expect(called(server), ['GET /api/devices', 'POST /api/devices/pairing']);
      expect(find.text('Works once, for 9:59'), findsOneWidget);
      expect(find.text("Join Aarav's phone"), findsOneWidget);
    });

    testWidgets('moves on when a new phone joins', (tester) async {
      final (screen, server) = await joinCode(tester);
      await show(tester, screen);
      await settle(tester);
      server.on('GET /api/devices', {
        'devices': [
          {'id': 'dev-1', 'label': 'tablet'},
        ],
      });
      await tester.pump(const Duration(seconds: 3));
      await settle(tester);
      expect(find.text('went to /kids'), findsOneWidget);
    });

    testWidgets('Show a new code asks for another', (tester) async {
      final (screen, server) = await joinCode(tester);
      await show(tester, screen);
      await settle(tester);
      await tapAndWait(tester, find.text('Show a new code'));
      expect(
        called(server).where((c) => c == 'POST /api/devices/pairing').length,
        2,
      );
    });

    testWidgets('a failed code shows the error', (tester) async {
      final (screen, server) = await joinCode(tester);
      server.on('POST /api/devices/pairing', {
        'error': 'no pairing code is free right now; try again',
      }, status: 503);
      await show(tester, screen);
      await settle(tester);
      expect(
        find.text('no pairing code is free right now; try again'),
        findsOneWidget,
      );
      expect(find.text('Try again'), findsOneWidget);
    });
  });
}
