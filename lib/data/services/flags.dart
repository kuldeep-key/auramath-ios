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
    this.overrides = const {},
    DateTime Function()? now,
  }) : _values = defaults,
       _now = now ?? DateTime.now;

  final ApiClient _client;
  final KeyStore _store;
  final DateTime Function() _now;
  Map<String, Object?> _values;
  DateTime? _fetched;

  /// A dev build's own switches (`FLAGS` in env), over whatever the server
  /// says: screens behind flags that are off on dev can still be tried.
  final Map<String, bool> overrides;

  static const maxAge = Duration(seconds: 60);

  bool on(String name) => overrides[name] ?? _values[name] == true;

  /// `FLAGS=trail,mastery_badges,-read_aloud`: names to switch on, and
  /// with a `-` off.
  static Map<String, bool> parseOverrides(String s) => {
    for (final n in s.split(',').map((n) => n.trim()).where((n) => n != ''))
      n.startsWith('-') ? n.substring(1) : n: !n.startsWith('-'),
  };

  /// The ages read-aloud starts on for (the grown-up can change it).
  List<int> get readAloudAges => [
    for (final a in _values['read_aloud_default_on_ages'] as List? ?? [])
      a as int,
  ];

  /// `self_rating_min_age` (AI-08): the youngest child offered the faces.
  int get selfRatingMinAge => _values['self_rating_min_age'] as int? ?? 7;

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
