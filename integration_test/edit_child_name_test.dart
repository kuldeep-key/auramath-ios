import 'dart:convert';

import 'package:auramath/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';

/// AUR-121, on a real build against a dev backend: a grown-up renames the
/// child in the grown-up area and goes back; Who's learning and the child's
/// Home show the new name at once, without opening the app again.
///
/// Same setup as setup_to_lesson_test.dart: `make dev` in auramath-backend,
/// a fresh install and an empty keychain, then
/// `flutter test integration_test/edit_child_name_test.dart -d <id> --dart-define-from-file=env/dev.json`
const _api = 'http://localhost:8080';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'a renamed child shows the new name when the grown-up goes back',
    (tester) async {
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

      app.main();
      await tester.pump(const Duration(seconds: 2));

      Future<void> see(Finder f, {int seconds = 15}) async {
        for (var i = 0; i < seconds * 10; i++) {
          await tester.pump(const Duration(milliseconds: 100));
          if (f.evaluate().isNotEmpty) return;
        }
        final shown = [
          for (final e in find.byType(Text).evaluate())
            ?(e.widget as Text).data,
        ];
        // the app reports errors itself; say it where the runner shows it
        // ignore: avoid_print
        print('E2E never saw $f; on screen: $shown');
        fail('never saw $f; on screen: $shown');
      }

      Future<void> tap(Finder f) async {
        await see(f);
        await tester.ensureVisible(f.last);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(f.last);
        await tester.pump(const Duration(milliseconds: 700));
      }

      Future<void> keypad(String digits) async {
        for (final d in digits.split('')) {
          await tap(find.text(d).last);
        }
      }

      // the top bar's back, or the grown-up home's close
      Future<void> back() async {
        final b = find.byTooltip('Back');
        await tap(b.evaluate().isNotEmpty ? b : find.byTooltip('Close'));
      }

      // set up a family with Sam, as a fresh phone does
      await tap(find.text("I'm a grown-up"));
      await tap(find.text('Get started'));
      await see(find.text("Your child's first name"));
      await tester.enterText(find.byType(TextField), 'Sam');
      await tap(find.text('Continue'));
      await tap(find.text('7'));
      await tap(find.text('Continue'));
      await see(find.text('Which school year is Sam in?'));
      await tap(find.text('Continue'));
      await tap(find.text("I'm not sure"));
      await see(find.text('No problem'));
      await tap(find.text('Continue'));
      await tap(find.text('Catch up'));
      await tap(find.text('Continue'));
      await tap(find.text('I agree'));
      await tap(find.text('Use my email'));
      await see(find.byType(TextField));
      await tester.enterText(find.byType(TextField), email);
      await tap(find.text('Email me a link'));
      await tap(find.text('Open the link (dev only)'));
      await see(find.text('All set!'), seconds: 20);
      await tap(find.text('Hand over to Sam'));
      await tap(find.text('Use a passcode'));
      await see(find.text('Choose a passcode'));
      await keypad('2468');
      await see(find.text('Type it again'));
      await keypad('2468');

      // the child's Home > For grown-ups > Who's learning > Grown-ups, then
      // the passcode
      await see(find.text('Keep going'), seconds: 20);
      await tap(find.byTooltip('For grown-ups'));
      await see(find.text("Who's learning today?"));
      expect(find.text('Sam'), findsOneWidget);
      await tap(find.text('Grown-ups'));
      await see(find.text('Enter your passcode.'));
      await keypad('2468');

      // Family > Sam > Change Sam's details: rename to Ava and save
      await tap(find.text('Family'));
      await tap(find.text('Sam'));
      await tap(find.text("Change Sam's details"));
      await see(find.text("Sam's details"));
      await tester.enterText(find.byType(TextField).first, 'Ava');
      await tap(find.text('Save'));

      // back out of the grown-up area: every screen on the way says Ava
      await see(find.text("Change Ava's details"));
      await back(); // Family
      await see(find.text('Ava'));
      await back(); // grown-up home
      await see(find.text('Back to Ava'));
      await back(); // Who's learning
      await see(find.text("Who's learning today?"));
      await see(find.text('Ava'));
      expect(find.text('Sam'), findsNothing);
    },
  );
}
