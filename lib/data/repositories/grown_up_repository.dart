import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

import '../services/api.dart';
import '../services/api_client.dart';
import '../services/key_store.dart';

/// A grown-up in the family (`GET /api/parent/members`).
class Member {
  const Member({required this.email, required this.owner, required this.you});

  factory Member.fromJson(Map<String, Object?> j) => Member(
    email: j['email'] as String? ?? '',
    owner: j['role'] == 'owner',
    you: j['you'] == true,
  );

  final String email;
  final bool owner;
  final bool you;
}

/// An invitation not yet accepted (`GET /api/parent/invites`).
class Invite {
  const Invite({required this.email});

  final String email;

  /// Only the ones still waiting: not accepted, cancelled or expired.
  static List<Invite> open(List<Object?> rows, int nowMs) => [
    for (final r in rows.cast<Map<String, Object?>>())
      if (r['acceptedAt'] == null &&
          r['revokedAt'] == null &&
          (r['expiresAt'] as int? ?? 0) > nowMs)
        Invite(email: r['email'] as String? ?? ''),
  ];
}

/// A paired child's phone (`GET /api/devices`).
class Device {
  const Device({required this.id, required this.label});

  factory Device.fromJson(Map<String, Object?> j) =>
      Device(id: j['id']! as String, label: j['label'] as String? ?? '');

  final String id;
  final String label;
}

/// One lesson from `/api/children/{id}/progress`. Rehearsals, demos and
/// tests are left out, like the backend's own reports.
class Lesson {
  const Lesson({required this.id, required this.startedAt, this.endedAt});

  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;

  /// Whole minutes, or null while unfinished.
  int? get minutes => endedAt == null
      ? null
      : (endedAt!.difference(startedAt).inSeconds / 60).round();

  static List<Lesson> fromProgress(Map<String, Object?> j) {
    DateTime at(Object? ms) => DateTime.fromMillisecondsSinceEpoch(ms! as int);
    return [
      for (final s
          in (j['sessions'] as List? ?? []).cast<Map<String, Object?>>())
        if (s['kind'] == 'lesson' &&
            s['seeded'] != true &&
            s['isDemo'] != true &&
            s['isTest'] != true)
          Lesson(
            id: s['id']! as String,
            startedAt: at(s['startedAt']),
            endedAt: s['endedAt'] == null ? null : at(s['endedAt']),
          ),
    ]..sort((a, b) => b.startedAt.compareTo(a.startedAt));
  }
}

/// `/api/children/{id}/plan`: what the server says comes next.
class ChildPlan {
  const ChildPlan({
    this.next,
    this.checkDue,
    this.checkDueNow = false,
    this.awayDays,
  });

  factory ChildPlan.fromJson(Map<String, Object?> j) {
    final next = j['next'] as Map<String, Object?>?;
    final check = j['check'] as Map<String, Object?>?;
    final away = j['away'] as Map<String, Object?>?;
    return ChildPlan(
      next: next?['text'] as String?,
      checkDue: check == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(check['dueAt']! as int),
      checkDueNow: check?['due'] == true,
      awayDays: away?['days'] as int?,
    );
  }

  final String? next;
  final DateTime? checkDue;
  final bool checkDueNow;
  final int? awayDays;
}

/// An export of everything held about the family (ACC-09).
class ExportJob {
  const ExportJob({required this.id, required this.status, this.error});

  factory ExportJob.fromJson(Map<String, Object?> j) => ExportJob(
    id: j['jobId']! as String,
    status: j['status']! as String,
    error: j['error'] as String?,
  );

  final String id;

  /// `pending`, `ready`, `failed` or `expired`.
  final String status;
  final String? error;

  bool get done => status != 'pending';
}

/// This phone's lesson settings (Settings 652:75). Kept on the phone, not
/// the account: a shared phone and a child's own phone can differ. The
/// lesson reads them through [loadPrefs].
class LessonPrefs {
  const LessonPrefs({
    this.minutes = 15,
    this.readAloud = true,
    this.phonePad = true,
    this.biggerPad = false,
  });

  static const minuteChoices = [10, 15, 20, 30];

  final int minutes;
  final bool readAloud;

  /// The phone's own number pad, or the app's drawn one.
  final bool phonePad;
  final bool biggerPad;

  LessonPrefs copyWith({
    int? minutes,
    bool? readAloud,
    bool? phonePad,
    bool? biggerPad,
  }) => LessonPrefs(
    minutes: minutes ?? this.minutes,
    readAloud: readAloud ?? this.readAloud,
    phonePad: phonePad ?? this.phonePad,
    biggerPad: biggerPad ?? this.biggerPad,
  );
}

/// The grown-up area's own calls: the family, phones, reports, the plan,
/// the two rights, and this phone's lesson settings.
class GrownUpRepository {
  GrownUpRepository(this._client, this._store);

  final ApiClient _client;
  final KeyStore _store;

  Future<Map<String, Object?>> _get(String path) async =>
      await _client.get(path) as Map<String, Object?>;

  // ------------------------------------------------------------ family

  Future<List<Member>> members() async => [
    for (final m in (await _get('/api/parent/members'))['members']! as List)
      if ((m as Map<String, Object?>)['revokedAt'] == null) Member.fromJson(m),
  ];

  Future<List<Invite>> invites() async => Invite.open(
    (await _get('/api/parent/invites'))['invites']! as List,
    DateTime.now().millisecondsSinceEpoch,
  );

  Future<void> invite(String email) =>
      _client.post('/api/parent/invites', {'email': email});

  Future<List<Device>> devices() async => [
    for (final d in (await _get('/api/devices'))['devices']! as List)
      Device.fromJson(d as Map<String, Object?>),
  ];

  Future<void> removeDevice(String id) => _client.delete('/api/devices/$id');

  /// A fresh six-digit code for a child's phone (DEV-02).
  Future<({String code, DateTime expiresAt})> pairingCode() async {
    final j =
        await _client.post('/api/devices/pairing') as Map<String, Object?>;
    return (
      code: j['code']! as String,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(j['expiresAt']! as int),
    );
  }

  // ----------------------------------------------------------- the child

  Future<List<Lesson>> lessons(String childId) async =>
      Lesson.fromProgress(await _get('/api/children/$childId/progress'));

  Future<ChildPlan> plan(String childId) async =>
      ChildPlan.fromJson(await _get('/api/children/$childId/plan'));

  /// The session's summary sentences. Empty when the server has none for
  /// it (its 404: no events, or a rehearsal).
  Future<List<String>> summary(String sessionId) async {
    try {
      final j = await _get('/api/sessions/$sessionId/summary');
      return [for (final l in j['lines'] as List? ?? []) l as String];
    } on ApiException catch (e) {
      if (e.status == 404) return const [];
      rethrow;
    }
  }

  /// `each_session`, `weekly` or `off` (PAR-06). This is the report email:
  /// there is no push service.
  Future<void> setReportFrequency(String frequency) =>
      _client.put('/api/family/settings/reports', {'frequency': frequency});

  // ------------------------------------------------------- the two rights

  Future<ExportJob> startExport() async => ExportJob.fromJson(
    await _client.post('/api/parent/export-jobs') as Map<String, Object?>,
  );

  Future<ExportJob> exportStatus(String id) async =>
      ExportJob.fromJson(await _get('/api/parent/export-jobs/$id'));

  /// Saves a ready export into the app's documents folder and returns the
  /// file. The download needs the parent token, so it can't be a link.
  Future<File> saveExport(String id) async {
    final json = await _client.get('/api/parent/export-jobs/$id/download');
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/auramath-export-$id.json');
    return file.writeAsString(jsonEncode(json));
  }

  /// Erases the whole family, children, lessons and phones (ACC-09).
  Future<void> erase() => _client.post('/api/parent/erase');

  // --------------------------------------------- this phone's lesson prefs

  Future<LessonPrefs> loadPrefs() async {
    const d = LessonPrefs();
    final minutes = int.tryParse(await _store.read('lesson.minutes') ?? '');
    Future<bool> flag(String key, bool fallback) async =>
        switch (await _store.read(key)) {
          '1' => true,
          '0' => false,
          _ => fallback,
        };
    return LessonPrefs(
      minutes: minutes ?? d.minutes,
      readAloud: await flag('lesson.readAloud', d.readAloud),
      phonePad: await flag('lesson.phonePad', d.phonePad),
      biggerPad: await flag('lesson.biggerPad', d.biggerPad),
    );
  }

  Future<void> savePrefs(LessonPrefs p) async {
    String b(bool v) => v ? '1' : '0';
    await _store.write('lesson.minutes', '${p.minutes}');
    await _store.write('lesson.readAloud', b(p.readAloud));
    await _store.write('lesson.phonePad', b(p.phonePad));
    await _store.write('lesson.biggerPad', b(p.biggerPad));
  }

  // ---------------------------------------------- forgot the passcode

  /// Remembers that a sign-in link was sent to reset the passcode, and
  /// which credential asked, so only a *fresh* sign-in may choose a new one.
  Future<void> startPasscodeReset(String? bearer) =>
      _store.write('passcodeReset', _hash(bearer));

  /// True once the grown-up has signed in again since asking.
  Future<bool> passcodeResetReady(String? bearer) async {
    final asked = await _store.read('passcodeReset');
    return asked != null && asked != _hash(bearer);
  }

  Future<void> endPasscodeReset() => _store.write('passcodeReset', null);

  static String _hash(String? s) =>
      sha256.convert(utf8.encode(s ?? '')).toString();
}
