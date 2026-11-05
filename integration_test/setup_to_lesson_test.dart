import 'dart:convert';

import 'package:auramath/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';

/// The whole online-first path on a real build, against a dev backend:
/// a grown-up sets up on a fresh phone with an emailed link, hands the
/// phone to the child, and the child's lesson reaches the server.
///
/// Needs the backend on this Mac (`make dev` in auramath-backend) and a
/// fresh install with an empty keychain:
/// `xcrun simctl uninstall <id> net.auramath.app && xcrun simctl keychain <id> reset`
/// `flutter test integration_test/setup_to_lesson_test.dart -d <id> --dart-define-from-file=env/dev.json`
const _api = 'http://localhost:8080';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a grown-up sets up, hands over, the lesson reaches the server', (
    tester,
  ) async {
    // The dev server only lets in invited families (AUTH_MODE=allowlist):
    // the operator invites this one.
    final email = 'e2e+${DateTime.now().millisecondsSinceEpoch}@example.com';
    final invited = await http.post(
      Uri.parse('$_api/api/admin/parents'),
      headers: {
        'Authorization': 'Bearer demo-operator-token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'email': email}),
    );
    expect(invited.statusCode, 200, reason: invited.body);
    final parentToken = (jsonDecode(invited.body) as Map)['token'] as String;

    await app.main();

    /// Real network and real timers: pump until [f] shows up.
    Future<void> see(Finder f, {int seconds = 15}) async {
      for (var i = 0; i < seconds * 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (f.evaluate().isNotEmpty) return;
      }
      fail('never saw $f');
    }

    Future<void> tap(Finder f) async {
      await see(f);
      // the screen on top is last in the tree while a page slides in
      await tester.ensureVisible(f.last); // long lists scroll
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(f.last);
      await tester.pump(const Duration(milliseconds: 700));
    }

    Future<void> keypad(String digits) async {
      for (final d in digits.split('')) {
        await tap(find.text(d).last);
      }
    }

    // a fresh phone
    await tap(find.text("I'm a grown-up"));
    await tap(find.text('Get started'));
    await see(find.text("Your child's first name"));
    await tester.enterText(find.byType(TextField), 'Sam');
    await tap(find.text('Continue'));
    await tap(find.text('7'));
    await tap(find.text('Continue'));
    await see(find.text('Which school year is Sam in?'));
    await tap(find.text('Continue'));
    await tap(find.text("I'm not sure")); // opens No problem
    await see(find.text('No problem'));
    await tap(find.text('Continue'));
    await tap(find.text('Catch up'));
    await tap(find.text('Continue'));
    await tap(find.text('I agree'));

    // save the place with an emailed link (dev shows the link itself)
    await tap(find.text('Use my email'));
    await see(find.byType(TextField));
    await tester.enterText(find.byType(TextField), email);
    await tap(find.text('Email me a link'));
    await tap(find.text('Open the link (dev only)'));

    // consent, the child saved, then the passcode and hand-over
    await see(find.text('All set!'), seconds: 20);
    await tap(find.text('Hand over to Sam'));
    await tap(find.text('Use a passcode'));
    await see(find.text('Choose a passcode'));
    await keypad('2468');
    await see(find.text('Type it again'));
    await keypad('2468');

    // the child's phone now: Keep going opens a lesson the server made
    await tap(find.text('Keep going'));
    await tap(find.text("Got it, let's draw"));
    await see(find.text('Drag a bar up here.'));
    await tap(find.byKey(const Key('slotA')));
    await tester.pump(const Duration(seconds: 2)); // let the sends land

    final sessions = await http.get(
      Uri.parse('$_api/api/sessions?limit=1'),
      headers: {'Authorization': 'Bearer $parentToken'},
    );
    final latest =
        ((jsonDecode(sessions.body) as Map)['sessions'] as List).single as Map;
    final events = await http.get(
      Uri.parse('$_api/api/sessions/${latest['id']}/events'),
      headers: {'Authorization': 'Bearer $parentToken'},
    );
    final names = [
      for (final e in (jsonDecode(events.body) as Map)['events'] as List)
        (e as Map)['name'],
    ];
    expect(names, containsAllInOrder(['session_started', 'problem_shown']));
    expect(names.length, greaterThanOrEqualTo(4), reason: '$names');
  });
}
