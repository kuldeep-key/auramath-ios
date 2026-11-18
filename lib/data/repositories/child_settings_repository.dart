import 'dart:convert';

import '../models/child_settings.dart';
import '../services/api.dart';
import '../services/api_client.dart';
import '../services/key_store.dart';

/// PAR-05: each child's time per day and read-aloud, from the server, so
/// every family phone has the same. The last answer is kept on the phone
/// for when the server can't be reached; the server's is the one that
/// counts whenever it answers.
class ChildSettingsRepository {
  ChildSettingsRepository(this._client, this._store);

  final ApiClient _client;
  final KeyStore _store;

  static String _key(String childId) => 'childSettings.$childId';
  static String _path(String childId) => '/api/children/$childId/settings';

  /// `GET /api/children/{id}/settings` (a parent's or the child's phone),
  /// with what is left of today. Offline, the kept copy (no [today]);
  /// with none kept, the [ApiException].
  Future<ChildSettings> load(String childId) async {
    try {
      final s = ChildSettings.fromJson(
        await _client.get(_path(childId)),
        childId: childId,
      );
      if (s == null) throw _noSettings;
      await remember(s);
      return s;
    } on ApiException catch (e) {
      if (!e.offline) rethrow;
      return await cached(childId) ?? (throw e);
    }
  }

  /// The settings last read on this phone, if any.
  Future<ChildSettings?> cached(String childId) async {
    final raw = await _store.read(_key(childId));
    if (raw == null) return null;
    try {
      return ChildSettings.fromJson(jsonDecode(raw), childId: childId);
    } on FormatException {
      return null;
    }
  }

  /// Keeps [s] for offline (the list of children and a lesson's start
  /// carry them too).
  Future<void> remember(ChildSettings s) =>
      _store.write(_key(s.childId), jsonEncode(s.toJson()));

  static const _childrenKey = 'childSettings.children';

  /// Keeps the children Settings last showed (ids and first names only),
  /// so Settings can show their kept settings when the server can't be
  /// reached.
  Future<void> rememberChildren(List<({String id, String name})> kids) =>
      _store.write(
        _childrenKey,
        jsonEncode([
          for (final k in kids) {'id': k.id, 'name': k.name},
        ]),
      );

  /// The children Settings last showed on this phone; empty when none.
  Future<List<({String id, String name})>> cachedChildren() async {
    final raw = await _store.read(_childrenKey);
    if (raw == null) return const [];
    try {
      return [
        for (final k in (jsonDecode(raw) as List).whereType<Map>())
          if (k['id'] is String && k['name'] is String)
            (id: k['id'] as String, name: k['name'] as String),
      ];
    } on FormatException {
      return const [];
    }
  }

  /// `PUT /api/children/{id}/settings`, the parent's token only: only the
  /// fields given change. [dailyLimitMinutes] null is no limit;
  /// [readAloud] null is back to the default.
  Future<ChildSettings> save(
    String childId, {
    Object? dailyLimitMinutes = _keep,
    Object? readAloud = _keep,
  }) async {
    final s = ChildSettings.fromJson(
      await _client.put(_path(childId), {
        if (!identical(dailyLimitMinutes, _keep))
          'dailyLimitMinutes': dailyLimitMinutes,
        if (!identical(readAloud, _keep)) 'readAloud': readAloud,
      }),
      childId: childId,
    );
    if (s == null) throw _noSettings;
    await remember(s);
    return s;
  }

  /// SES-01: what is left of the child's day now; null when the server
  /// can't say (offline, an older server): then the lesson's start asks.
  Future<DailyTime?> today(String childId) async {
    try {
      return (await load(childId)).today;
    } on ApiException {
      return null;
    }
  }
}

const _keep = Object();

/// The server answered, but not with settings: not offline, so neither
/// the kept copy stands in for it nor "can't reach the server" is said.
const _noSettings = ApiException('No settings in the answer', status: 502);
