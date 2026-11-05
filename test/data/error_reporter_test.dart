import 'dart:convert';

import 'package:auramath/data/services/error_reporter.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'api_client_test.dart' show clientFor;

void main() {
  test('held until a token, then sent 20 a call, 6 min apart', () {
    fakeAsync((clock) {
      final calls = <List<Object?>>[];
      var token = false;
      var status = 201;
      final r = ErrorReporter(
        clientFor((req) async {
          calls.add((jsonDecode(req.body) as Map)['errors'] as List);
          return http.Response('{}', status);
        }),
        hasToken: () => token,
        appVersion: '0.2.0',
        platform: 'ios',
        osVersion: '18.2',
        now: () => clock.getClock(DateTime(2026)).now(),
      );
      for (var i = 0; i < 25; i++) {
        r.report('error', 'e$i');
      }
      clock.elapse(const Duration(minutes: 1));
      expect(calls, isEmpty); // no token yet

      token = true;
      r.schedule();
      clock.elapse(const Duration(seconds: 11));
      expect(calls.single.length, ErrorReporter.perCall);
      expect((calls.single.first! as Map)['message'], 'e0');

      clock.elapse(const Duration(minutes: 5));
      expect(calls, hasLength(1)); // waits out the gap
      status = 429;
      clock.elapse(const Duration(minutes: 1));
      expect(calls, hasLength(2));
      expect(r.pending, hasLength(5)); // a refusal keeps them

      status = 201;
      clock.elapse(const Duration(minutes: 7));
      expect(r.pending, isEmpty);
      r.dispose();
    });
  });
}
