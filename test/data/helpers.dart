import 'dart:convert';
import 'dart:io';

import 'package:auramath/data/models/lesson_event.dart';
import 'package:auramath/data/services/outbox_db.dart';
import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_schema/json_schema.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// A fresh in-memory outbox, run in the test isolate so fake_async controls
/// every await. The in-memory database is shared between opens, so the
/// previous test's one is deleted first.
Future<OutboxDb> memoryOutbox() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;
  await databaseFactory.deleteDatabase(inMemoryDatabasePath);
  return OutboxDb.open(inMemoryDatabasePath);
}

/// The child the fake server names for every session.
const testChildRef = 'ch_test1234';

/// The envelope a test build writes.
const testIdentity = (
  deviceId: 'dv_test1234',
  appVersion: '0.1.0',
  isDemo: true,
);

/// A saved event with a made-up payload, for outbox plumbing tests.
LessonEvent ev(String session, int seq, [String name = 'step_entered']) =>
    LessonEvent(
      eventId: '00000000-0000-4000-8000-${seq.toString().padLeft(12, '0')}',
      sessionId: session,
      seq: seq,
      at: 1791400000000 + seq,
      name: name,
      childRef: testChildRef,
      deviceId: testIdentity.deviceId,
      appVersion: testIdentity.appVersion,
      payload: const {'step_id': 'draw_known_bar'},
    );

/// The spec events a lesson writes for [inputs], from `problem_shown` on.
List<SpecEvent> lessonEvents(
  Pack pack,
  ComparisonProblem p,
  List<LessonInput> inputs,
) {
  var s = initialState();
  final out = [problemShown(p)];
  for (final i in inputs) {
    final r = step(pack, p, s, i);
    out.addAll(eventsFor(p, s, i, r, (stepMs: 0, problemMs: 0, readingMs: 0)));
    s = r.state;
  }
  return out;
}

/// The backend's event contract (spec pack v0.3.0), kept beside the engine.
final _schema = JsonSchema.create(
  jsonDecode(
    File(
      'packages/auramath_engine/test/contract/events.schema.json',
    ).readAsStringSync(),
  ),
);

/// Fails the test unless every event passes the backend's schema.
void expectContract(Iterable<LessonEvent> events) {
  for (final e in events) {
    final r = _schema.validate(e.toJson());
    expect(r.isValid, isTrue, reason: '${e.name}: ${r.errors}');
  }
}

extension WithPayload on LessonEvent {
  LessonEvent withPayload(Map<String, Object?> payload) => LessonEvent(
    eventId: eventId,
    sessionId: sessionId,
    seq: seq,
    at: at,
    name: name,
    childRef: childRef,
    deviceId: deviceId,
    appVersion: appVersion,
    payload: payload,
  );
}
