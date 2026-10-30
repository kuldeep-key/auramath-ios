import 'dart:async';

import 'package:auramath/data/services/api.dart';
import 'package:auramath/data/services/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

ApiClient clientFor(
  Future<http.Response> Function(http.Request) handler, {
  void Function()? onUnauthorized,
}) => ApiClient(
  baseUrl: 'http://test',
  bearer: () => 'tok',
  client: MockClient(handler),
  onUnauthorized: onUnauthorized,
  timeout: const Duration(milliseconds: 50),
);

void main() {
  test(
    'sends the bearer token and JSON, and returns the JSON answer',
    () async {
      late http.Request seen;
      final c = clientFor((r) async {
        seen = r;
        return http.Response('{"ok":true}', 200);
      });
      expect(await c.post('/api/x', {'a': 1}), {'ok': true});
      expect(seen.headers['Authorization'], 'Bearer tok');
      expect(seen.body, '{"a":1}');
    },
  );

  test("a non-2xx answer throws with the server's own message", () async {
    final c = clientFor((_) async => http.Response('{"error":"no"}', 409));
    await expectLater(
      c.get('/api/x'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.status, 'status', 409)
            .having((e) => e.message, 'message', 'no'),
      ),
    );
  });

  test('no answer is an offline ApiException, never a hang', () async {
    final c = clientFor((_) => Completer<http.Response>().future);
    await expectLater(
      c.get('/api/x'),
      throwsA(isA<ApiException>().having((e) => e.offline, 'offline', true)),
    );
  });

  test('a 401 tells the account', () async {
    var told = false;
    final c = clientFor(
      (_) async => http.Response('{"error":"who"}', 401),
      onUnauthorized: () => told = true,
    );
    await expectLater(c.get('/api/x'), throwsA(isA<ApiException>()));
    expect(told, isTrue);
  });

  test('events the server refuses are an error, not dropped', () async {
    final api = HttpApi(
      clientFor(
        (_) async => http.Response(
          '{"added":0,"total":0,"rejected":[{"name":"x","reasons":["bad"]}]}',
          200,
        ),
      ),
    );
    await expectLater(
      api.sendEvents('s', const []),
      throwsA(isA<ApiException>().having((e) => e.status, 'status', 422)),
    );
  });

  test("resume reads the record's own event shape", () async {
    // as /api/sessions/resumable answered on the dev backend, 29 Oct
    final api = HttpApi(
      clientFor(
        (_) async => http.Response(
          '{"session":{"id":"sess-1","endedAt":null},'
          '"events":[{"seq":0,"at":5,"name":"session_started","detail":"",'
          '"eventId":"e-0","childRef":"ch_abc12345","deviceId":"dv_abc12345",'
          '"appVersion":"0.1.0","payload":{"is_demo":false},"receivedAt":6},'
          '{"seq":1,"at":7,"name":"step_satisfied","detail":"old web event"}],'
          '"resume":{"sameDevice":false,"startedOn":{"label":"Phone A"}}}',
          200,
        ),
      ),
    );
    final open = await api.resumable(childId: 'c1');
    expect(open!.events.single.sessionId, 'sess-1');
    expect(open.events.single.childRef, 'ch_abc12345');
    expect(open.sameDevice, isFalse);
    expect(open.startedOn, 'Phone A');
  });

  test('no unfinished case on the server: nothing to resume', () async {
    final api = HttpApi(
      clientFor(
        (_) async =>
            http.Response('{"session":null,"events":[],"resume":null}', 200),
      ),
    );
    expect(await api.resumable(), isNull);
  });
}
