/// SES-01 with PAR-05: what is left of the child's day, as the server
/// counts it on every family phone (`dailyTime`, and `today` on the
/// settings GET). Never shown to the child as a number (SES-02).
typedef DailyTime = ({
  /// The grown-up's time per day; null: no limit.
  int? limitMinutes,
  int usedMs,

  /// Null: no limit.
  int? leftMs,

  /// What a lesson opened now may run: the smaller of the session cap and
  /// [leftMs].
  int capMs,

  /// Nothing is left today: "That's today's time!", and no lesson opens.
  bool timesUp,
  String day,
  String timeZone,
});

int? _int(Object? v) => v is int ? v : (v is num ? v.toInt() : null);

/// The server's [DailyTime], or null when it sent none (an older server).
DailyTime? dailyTimeFromJson(Object? j) {
  if (j is! Map) return null;
  final cap = _int(j['capMs']);
  if (cap == null) return null;
  return (
    limitMinutes: _int(j['limitMinutes']),
    usedMs: _int(j['usedMs']) ?? 0,
    leftMs: _int(j['leftMs']),
    capMs: cap,
    timesUp: j['timesUp'] == true,
    day: j['day'] as String? ?? '',
    timeZone: j['timeZone'] as String? ?? '',
  );
}

/// PAR-05: a child's time per day and read-aloud, kept on the server so a
/// change on one family phone reaches the others (`GET/PUT
/// /api/children/{id}/settings`, each child of `GET /api/children`, and
/// the `POST /api/sessions` answer).
class ChildSettings {
  const ChildSettings({
    required this.childId,
    this.dailyLimitMinutes,
    this.dailyLimitIsDefault = true,
    this.readAloud = true,
    this.readAloudIsDefault = true,
    this.today,
  });

  /// Null when [j] isn't settings.
  static ChildSettings? fromJson(Object? j, {String? childId}) {
    if (j is! Map) return null;
    final id = j['childId'] as String? ?? childId;
    if (id == null) return null;
    return ChildSettings(
      childId: id,
      dailyLimitMinutes: _int(j['dailyLimitMinutes']),
      dailyLimitIsDefault: j['dailyLimitIsDefault'] != false,
      readAloud: j['readAloud'] != false,
      readAloudIsDefault: j['readAloudIsDefault'] != false,
      today: dailyTimeFromJson(j['today']),
    );
  }

  final String childId;

  /// Minutes a day; null: no limit.
  final int? dailyLimitMinutes;
  final bool dailyLimitIsDefault;

  /// The server's answer already has the `read_aloud` flag and the age
  /// default folded in (TTR-03, D-59).
  final bool readAloud;
  final bool readAloudIsDefault;

  /// What is left of the day when it was read; never cached (it is
  /// stale the moment the child plays).
  final DailyTime? today;

  /// For the phone's cache: everything but [today].
  Map<String, Object?> toJson() => {
    'childId': childId,
    'dailyLimitMinutes': dailyLimitMinutes,
    'dailyLimitIsDefault': dailyLimitIsDefault,
    'readAloud': readAloud,
    'readAloudIsDefault': readAloudIsDefault,
  };

  /// The lengths the Family area offers, in minutes; the server takes
  /// 5 to 240, or null for no limit.
  static const minuteChoices = [10, 15, 20, 30];
}
