import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'api.dart';
import 'api_client.dart';

/// The teaching content the server serves (`GET /api/content/bundle`): the
/// spec pack's files, parsed. Kept on the phone with its ETag; a new copy
/// is used from the next launch, so a lesson never changes rules midway.
/// Until there is one, the copy bundled with the app (`assets/spec`).
class ContentBundle {
  ContentBundle(this._client, this._file);

  final ApiClient _client;
  final File _file;
  Map<String, Object?>? _saved;

  Future<void> load() async {
    if (!await _file.exists()) return;
    _saved = (jsonDecode(await _file.readAsString()) as Map)
        .cast<String, Object?>();
  }

  /// The served copy of a spec file (`policy.yaml`, `app-config.yaml`) as
  /// text the YAML readers take (JSON is YAML), or null when none is held.
  String? yamlOf(String name) {
    final files = _saved?['files'] as Map?;
    final key = files?.keys.where((k) => '$k'.endsWith(name)).firstOrNull;
    return key == null ? null : jsonEncode(files![key]);
  }

  /// The bundle's `praise` (TUT-12): the finish screen's lines by policy
  /// id (`line.praise.solved`, `line.praise.solved-short`), as the server
  /// serves them; empty until a copy is held.
  Map<String, String> get praise => {
    for (final MapEntry(:key, :value)
        in ((_saved?['praise'] as Map?) ?? const {}).entries)
      if (value is String) '$key': value,
  };

  /// Asks for a newer copy (needs a token). 304 keeps this one; a failure
  /// is logged and keeps it too: no screen waits on content.
  Future<void> refresh() async {
    try {
      final r = await _client.getIfChanged(
        '/api/content/bundle',
        etag: _saved?['etag'] as String?,
      );
      if (r == null) return;
      final json = r.json! as Map;
      _saved = {
        'etag': r.etag,
        'files': json['files'],
        'praise': ?json['praise'],
      };
      await _file.writeAsString(jsonEncode(_saved));
    } on ApiException catch (e) {
      debugPrint('content bundle not refreshed: $e');
    }
  }
}
