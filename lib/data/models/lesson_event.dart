import 'package:auramath_engine/auramath_engine.dart';

/// Which phone and build is writing events: the envelope fields that don't
/// change per session. The `child_ref` comes from the server with each
/// session (online-first).
typedef Identity = ({String deviceId, String appVersion, bool isDemo});

/// One saved event in the backend's contract
/// (`auramath-backend/spec/contracts/events.schema.json`): the engine's
/// [SpecEvent] wrapped in its envelope.
class LessonEvent {
  const LessonEvent({
    required this.eventId,
    required this.sessionId,
    required this.seq,
    required this.at,
    required this.name,
    required this.childRef,
    required this.deviceId,
    required this.appVersion,
    required this.payload,
  });

  factory LessonEvent.fromJson(Map<String, Object?> j) => LessonEvent(
    eventId: j['event_id']! as String,
    sessionId: j['session_id']! as String,
    seq: j['seq']! as int,
    at: j['at']! as int,
    name: j['name']! as String,
    childRef: j['child_ref']! as String,
    deviceId: j['device_id']! as String,
    appVersion: j['app_version']! as String,
    payload: j['payload']! as Map<String, Object?>,
  );

  final String eventId;
  final String sessionId;

  /// From 0, in order, per session.
  final int seq;

  /// Epoch milliseconds when it happened.
  final int at;
  final String name;
  final String childRef;
  final String deviceId;
  final String appVersion;
  final Map<String, Object?> payload;

  SpecEvent get spec => SpecEvent(name, payload);

  Map<String, Object?> toJson() => {
    'event_id': eventId,
    'session_id': sessionId,
    'seq': seq,
    'at': at,
    'name': name,
    'child_ref': childRef,
    'device_id': deviceId,
    'app_version': appVersion,
    'payload': payload,
  };
}
