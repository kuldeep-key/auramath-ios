import 'dart:convert';

import 'package:auramath/data/repositories/account_repository.dart';
import 'package:auramath/data/repositories/family_repository.dart';
import 'package:auramath/data/repositories/session_repository.dart';
import 'package:auramath/data/services/api_client.dart';
import 'package:auramath/data/services/device_lock.dart';
import 'package:auramath/data/services/key_store.dart';
import 'package:auramath/data/services/social_sign_in.dart';
import 'package:auramath/deps.dart';
import 'package:auramath/ui/features/lesson/view_models/sitting.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../ui/features/lesson/fakes.dart';

/// A stand-in backend: `'POST /api/devices/redeem'` → handler. Unknown
/// routes answer 404 like the real one. Every request is kept in [calls].
class FakeServer {
  final Map<String, (int, Object?) Function(Map<String, Object?> body)> routes =
      {};
  final List<(String, Map<String, Object?>)> calls = [];

  void on(String route, Object? json, {int status = 200}) =>
      routes[route] = (_) => (status, json);

  late final http.Client client = MockClient((req) async {
    final key = '${req.method} ${req.url.path}';
    final body = req.body.isEmpty
        ? <String, Object?>{}
        : jsonDecode(req.body) as Map<String, Object?>;
    calls.add((key, body));
    final handler = routes[key];
    final (status, json) = handler == null
        ? (404, {'error': 'no route $key'})
        : handler(body);
    return http.Response(json == null ? '' : jsonEncode(json), status);
  });
}

class FakeSocial implements SocialSignIn {
  String? googleToken = 'google-id-token';
  ({String idToken, String nonce})? appleResult = (
    idToken: 'apple-id-token',
    nonce: 'n',
  );

  @override
  Future<({String idToken, String nonce})?> apple() async => appleResult;

  @override
  Future<String?> google({required String serverClientId}) async => googleToken;

  @override
  Future<void> signOut() async {}
}

class FakeDeviceLock implements DeviceLock {
  bool has = true;
  bool passes = true;

  @override
  Future<bool> available() async => has;

  @override
  Future<bool> unlock(String reason) async => passes;
}

/// Everything a screen needs, with nothing real behind it. Call inside
/// `tester.runAsync` (the outbox is SQLite in memory).
Future<(Deps, FakeServer)> testDeps({
  Map<String, String> stored = const {},
}) async {
  final server = FakeServer();
  final store = MemoryKeyStore()..values.addAll(stored);
  final account = AccountRepository(
    store: store,
    social: FakeSocial(),
    newId: () => '00000000-0000-0000-0000-000000000001',
  );
  final client = ApiClient(
    baseUrl: 'http://test',
    bearer: () => account.bearer,
    client: server.client,
    onUnauthorized: account.unauthorized,
  );
  account.client = client;
  await account.load();
  final (SessionRepository sessions, outbox, _) = await memorySessions();
  return (
    Deps(
      account: account,
      family: FamilyRepository(client),
      client: client,
      sessions: sessions,
      pack: samplePack(),
      voice: FakeVoice(),
      sitting: Sitting(capMs: 30 * 60 * 1000),
      deviceLock: FakeDeviceLock(),
      outbox: outbox,
      store: store,
    ),
    server,
  );
}

/// Stored values for a child's own paired phone with a child chosen.
const pairedChildPhone = {
  'deviceToken': 'device-token',
  'deviceId': '11111111-2222-3333-4444-555555555555',
  'childId': 'child-1',
};

/// Stored values for a grown-up's phone, signed in.
const parentPhone = {'parentToken': 'parent-token'};
