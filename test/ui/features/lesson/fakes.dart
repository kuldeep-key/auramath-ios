import 'dart:convert';
import 'dart:io';

import 'package:auramath/data/repositories/session_repository.dart';
import 'package:auramath/data/services/fake_api.dart';
import 'package:auramath/data/services/outbox_db.dart';
import 'package:auramath/data/services/voice.dart';
import 'package:auramath_engine/auramath_engine.dart';

import '../../../data/helpers.dart';

class FakeVoice implements Voice {
  final List<String> said = [];

  @override
  Future<void> say(String text) async => said.add(text);

  @override
  Future<void> stop() async {}
}

Pack samplePack() => Pack.fromJson(
  jsonDecode(File('assets/sample_pack/pack.json').readAsStringSync())
      as Map<String, Object?>,
);

Future<(SessionRepository, OutboxDb, FakeApi)> memorySessions() async {
  final api = FakeApi();
  final db = await memoryOutbox();
  return (SessionRepository(db: db, api: api, nowMs: () => 1), db, api);
}
