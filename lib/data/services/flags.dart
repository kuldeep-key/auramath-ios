import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'api.dart';
import 'api_client.dart';
import 'key_store.dart';

/// The server's feature flags (`GET /api/flags`), which gate every
/// provisional screen. Asked again at most once a minute; until the first
/// answer, the last one this phone saw, else the bundled defaults
/// (`assets/spec/app-config.yaml`). A flag the server doesn't name is off.
class Flags extends ChangeNotifier {
  Flags(
    this._client,
    this._store, {
    required Map<String, Object?> defaults,
    DateTime Function()? now,
  }) : _values = defaults,
       _now = now ?? DateTime.now;

  final ApiClient _client;
  final KeyStore _store;
  final DateTime Function() _now;
  Map<String, Object?> _values;
  DateTime? _fetched;

  static const maxAge = Duration(seconds: 60);

  bool on(String name) => _values[name] == true;

  /// The ages read-aloud starts on for (the grown-up can change it).
  List<int> get readAloudAges => [
    for (final a in _values['read_aloud_default_on_ages'] as List? ?? [])
      a as int,
  ];

  /// The flags this phone last saw, if any.
  Future<void> load() async {
    final saved = await _store.read('flags');
    if (saved == null) return;
    _values = (jsonDecode(saved) as Map).cast<String, Object?>();
    notifyListeners();
  }

  /// Asks the server, unless it answered in the last minute. Offline or
  /// refused, the flags stay as they were (logged, not thrown: no screen
  /// waits on them).
  Future<void> refresh() async {
    if (_fetched != null && _now().difference(_fetched!) < maxAge) return;
    try {
      final j = await _client.get('/api/flags') as Map<String, Object?>;
      _fetched = _now();
      _values = (j['flags']! as Map).cast<String, Object?>();
      await _store.write('flags', jsonEncode(_values));
      notifyListeners();
    } on ApiException catch (e) {
      debugPrint('flags not refreshed: $e');
    }
  }
}
