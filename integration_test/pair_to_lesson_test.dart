import 'dart:convert';

import 'package:auramath/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';

/// A child's own phone, end to end against a dev backend: the grown-up's
/// side (family, consent, child, a pairing code) is made over HTTP; the
/// phone pairs with the code, and its lesson reaches the server.
///
/// Fresh install and empty keychain first (see setup_to_lesson_test.dart).
const _api = 'http://localhost:8080';

Future<Object?> _call(
  String method,
  String path, {
  String? token,
  Object? body,
}) async {
  final r = http.Request(method, Uri.parse('$_api$path'))
    ..headers.addAll({
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });
  if (body != null) r.body = jsonEncode(body);
  final res = await http.Response.fromStream(await r.send());
  expect(
    res.statusCode,
    inInclusiveRange(200, 299),
    reason: '$path ${res.body}',
  );
  return res.body.isEmpty ? null : jsonDecode(res.body);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("a child's phone pairs and its lesson reaches the server", (
    tester,
  ) async {
    final email = 'pair+${DateTime.now().millisecondsSinceEpoch}@example.com';
    final family =
        await _call(
              'POST',
              '/api/admin/parents',
              token: 'demo-operator-token',
              body: {'email': email},
            )
            as Map;
    final parent = family['token'] as String;
    // the operator's invitation records the family's consent
    await _call(
      'POST',
      '/api/children',
      token: parent,
      body: {'displayName': 'Ava'},
    );
    final code =
        (await _call('POST', '/api/devices/pairing', token: parent)
                as Map)['code']
            as String;

    await app.main();

    Future<void> see(Finder f, {int seconds = 15}) async {
      for (var i = 0; i < seconds * 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (f.evaluate().isNotEmpty) return;
      }
      fail('never saw $f');
    }

    Future<void> tap(Finder f) async {
      await see(f);
      await tester.ensureVisible(f.last);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(f.last);
      await tester.pump(const Duration(milliseconds: 700));
    }

    await tap(find.text("I'm a kid"));
    await see(find.text('Type your code'));
    for (final d in code.split('')) {
      await tap(find.text(d).last);
    }
    await tap(find.byIcon(Icons.check_rounded));
    await see(find.text('Is this you?'));
    expect(find.text('Ava'), findsWidgets);
    await tap(find.text("Yes, that's me!"));
    await tap(find.text("Let's go"));

    await tap(find.text('Keep going'));
    await tap(find.text("Got it, let's draw"));
    await see(find.text('Drag a bar up here.'));
    await tap(find.byKey(const Key('slotA')));
    await tester.pump(const Duration(seconds: 2)); // let the sends land

    // the grown-up's view of the record: this phone's lesson is there
    final sessions =
        await _call('GET', '/api/sessions?limit=1', token: parent) as Map;
    final latest = (sessions['sessions'] as List).single as Map;
    final events =
        await _call(
              'GET',
              '/api/sessions/${latest['id']}/events',
              token: parent,
            )
            as Map;
    final names = [
      for (final e in events['events'] as List) (e as Map)['name'],
    ];
    expect(names, containsAllInOrder(['session_started', 'problem_shown']));
    final devices = await _call('GET', '/api/devices', token: parent) as Map;
    expect((devices['devices'] as List).length, 1);
  });
}
