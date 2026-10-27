import 'package:auramath_engine/auramath_engine.dart';

/// One saved child input, in the backend's wire shape
/// (`auramath-backend/auramath/api/schemas.py` `EventIn`).
class LessonEvent {
  const LessonEvent({
    required this.sessionId,
    required this.seq,
    required this.at,
    required this.name,
    this.detail = '',
    required this.data,
  });

  factory LessonEvent.fromInput({
    required String sessionId,
    required int seq,
    required int at,
    required String packVersion,
    required String problemId,
    required LessonInput input,
  }) {
    final json = inputToJson(input);
    return LessonEvent(
      sessionId: sessionId,
      seq: seq,
      at: at,
      name: json['type']! as String,
      data: {
        for (final e in json.entries)
          if (e.key != 'type') e.key: e.value,
        'packVersion': packVersion,
        'problemId': problemId,
        'schemaVersion': schemaVersion,
      },
    );
  }

  /// Bumped when the shape of [data] changes; old versions stay readable.
  static const schemaVersion = 1;

  final String sessionId;
  final int seq;

  /// Epoch milliseconds when the child did it.
  final int at;
  final String name;
  final String detail;

  /// Flat: strings, numbers and booleans only.
  final Map<String, Object?> data;

  LessonInput get input => inputFromJson({...data, 'type': name});

  Map<String, Object?> toJson() => {
    'seq': seq,
    'at': at,
    'name': name,
    'detail': detail,
    'data': data,
  };
}
