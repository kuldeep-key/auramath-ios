import 'package:flutter/foundation.dart';
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
  final ValueNotifier<bool> resting = ValueNotifier(false);

  @override
  final ValueNotifier<bool> speaking = ValueNotifier(false);

  @override
  Future<void> say(String text) async => said.add(text);

  @override
  Future<void> stop() async {}
}

Pack samplePack() => Pack.fromJson(
  jsonDecode(File('assets/sample_pack/pack.json').readAsStringSync())
      as Map<String, Object?>,
);

/// Sessions over an in-memory outbox and a fake server, with the first
/// session (`s1`) already opened, as the lesson route does before a lesson.
/// With [withTemplate], Julia's bundled template draws left cases.
Future<(SessionRepository, OutboxDb, FakeApi)> memorySessions({
  bool withTemplate = false,
}) async {
  final api = FakeApi();
  final db = await memoryOutbox();
  final sessions = SessionRepository(
    db: db,
    api: api,
    identity: testIdentity,
    nowMs: () => 1791400000000,
    template: withTemplate
        ? ComparisonTemplate.fromYaml(
            File('assets/spec/comparison-two-step.yaml').readAsStringSync(),
          )
        : null,
  );
  await sessions.open();
  return (sessions, db, api);
}

/// `problems/next` as the dev server answered it (integration guide, 4 Nov).
Map<String, Object?> served({
  String id = 'g_1',
  String level = 'L4',
  String relation = 'taller',
  int a = 186,
  int d = 107,
}) => {
  'problemId': id,
  'templateId': 'cmp.comparison',
  'templateVersion': '0.3.0',
  'storyId': 'lemon-fig',
  'relation': relation,
  'level': level,
  'variant': 'standard',
  'numbers': {'A': a, 'D': d},
  'story': {
    'a': 'lemon tree',
    'b': 'fig tree',
    'kind': 'tree',
    'plural': 'trees',
    'unit': 'cm',
    'quantity': 'height',
  },
  'questionText':
      'The lemon tree is $a cm tall. It is $d cm $relation than the fig '
      'tree. What is the total height of the two trees?',
  'expected': {'B': relation == 'taller' ? a - d : a + d, 'total': 0},
  'hints': <Object>[],
  'source': 'code',
};
