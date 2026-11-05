import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

import '../services/api.dart';
import '../services/api_client.dart';
import '../services/key_store.dart';

/// A grown-up in the family (`GET /api/parent/members`). The first
/// parent (the owner) has no member [id].
class Member {
  const Member({
    required this.email,
    required this.owner,
    required this.you,
    this.id,
    this.invitedBy,
  });

  factory Member.fromJson(Map<String, Object?> j) => Member(
    id: j['id'] as String?,
    email: j['email'] as String? ?? '',
    owner: j['role'] == 'owner',
    you: j['you'] == true,
    invitedBy: j['invitedBy'] as String?,
  );

  final String? id;
  final String email;
  final bool owner;
  final bool you;

  /// The member id of whoever invited them; null when the owner did.
  final String? invitedBy;
}

/// An invitation not yet accepted (`GET /api/parent/invites`).
class Invite {
  const Invite({required this.email, this.id = '', this.invitedBy});

  final String id;
  final String email;

  /// The member id of whoever sent it; null when the owner did.
  final String? invitedBy;

  /// Only the ones still waiting: not accepted, cancelled or expired.
  static List<Invite> open(List<Object?> rows, int nowMs) => [
    for (final r in rows.cast<Map<String, Object?>>())
      if (r['acceptedAt'] == null &&
          r['revokedAt'] == null &&
          (r['expiresAt'] as int? ?? 0) > nowMs)
        Invite(
          id: r['id'] as String? ?? '',
          email: r['email'] as String? ?? '',
          invitedBy: r['invitedBy'] as String?,
        ),
  ];
}

/// Who may remove whom, as the server allows it (family.py, L9): the
/// owner may remove any invited grown-up and cancel any invitation; an
/// invited grown-up only the ones they invited themselves. Nobody removes
/// the owner or themselves here.
class FamilyRules {
  FamilyRules(List<Member> members)
    : _me = members.where((m) => m.you).firstOrNull;

  final Member? _me;

  /// The owner, or a grown-up the server gave no `you` (an older server).
  bool get _owner => _me == null || _me.owner;

  bool canRemove(Member m) =>
      !m.owner && !m.you && m.id != null && (_owner || m.invitedBy == _me!.id);

  bool canCancel(Invite i) => _owner || i.invitedBy == _me!.id;
}

/// A signed-in browser or phone on the grown-up's credential
/// (`GET /api/parent/browsers`). [you] is this phone.
class Browser {
  const Browser({
    required this.id,
    required this.label,
    required this.you,
    this.lastSeenAt,
  });

  factory Browser.fromJson(Map<String, Object?> j) => Browser(
    id: j['id']! as String,
    label: j['label'] as String? ?? '',
    you: j['you'] == true,
    lastSeenAt: j['lastSeenAt'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(j['lastSeenAt']! as int),
  );

  final String id;
  final String label;
  final bool you;
  final DateTime? lastSeenAt;
}

/// One level change in the child's learning memory, oldest first.
typedef LevelChange = ({String from, String to, String reason});

/// Where a child is in one question type (`GET /api/children/{id}/learning`):
/// the level and how it got there. The server never sends a score, and
/// the grown-up area shows no number that judges the child.
class LearningType {
  const LearningType({
    required this.id,
    required this.level,
    required this.changes,
  });

  final String id;
  final String? level;
  final List<LevelChange> changes;

  static List<LearningType> fromJson(Map<String, Object?> j) => [
    for (final MapEntry(:key, :value)
        in (j['questionTypes'] as Map? ?? {}).cast<String, Map>().entries)
      LearningType(
        id: key,
        level: value['level'] as String?,
        changes: [
          for (final c in (value['levelChanges'] as List? ?? []).cast<Map>())
            (
              from: c['from'] as String? ?? '',
              to: c['to'] as String? ?? '',
              reason: c['reason'] as String? ?? '',
            ),
        ],
      ),
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
    this.readAloud,
    this.biggerPad = false,
  });

  static const minuteChoices = [10, 15, 20, 30];

  final int minutes;

  /// Null until the grown-up chooses: then it's on for the ages the flag
  /// `read_aloud_default_on_ages` names (NFR-06).
  final bool? readAloud;

  /// The lesson always uses the app's own pad (D-41); this makes its keys
  /// bigger still.
  final bool biggerPad;

  LessonPrefs copyWith({int? minutes, bool? readAloud, bool? biggerPad}) =>
      LessonPrefs(
        minutes: minutes ?? this.minutes,
        readAloud: readAloud ?? this.readAloud,
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

  /// Cancels an invitation not yet accepted: its link stops working.
  Future<void> cancelInvite(String id) =>
      _client.delete('/api/parent/invites/$id');

  /// Removes an invited grown-up: their browsers sign out at once.
  Future<void> removeMember(String id) =>
      _client.delete('/api/parent/members/$id');

  /// Where the grown-ups are signed in. The owner sees every grown-up's;
  /// an invited grown-up sees their own.
  Future<List<Browser>> browsers() async => [
    for (final b in (await _get('/api/parent/browsers'))['browsers']! as List)
      Browser.fromJson(b as Map<String, Object?>),
  ];

  /// Signs one browser out (204).
  Future<void> removeBrowser(String id) =>
      _client.delete('/api/parent/browsers/$id');

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

  /// Where the child is, per question type, and their level changes.
  Future<List<LearningType>> learning(String childId) async =>
      LearningType.fromJson(await _get('/api/children/$childId/learning'));

  Future<ChildPlan> plan(String childId) async =>
      ChildPlan.fromJson(await _get('/api/children/$childId/plan'));

  /// The session's note, its sentences in the server's order (practised,
  /// did alone, help needed, next). Empty when the server has none for it
  /// (its 404: no events, or a rehearsal).
  Future<List<String>> summary(String sessionId) async {
    try {
      final j = await _get('/api/sessions/$sessionId/summary');
      return [
        for (final s in (j['sentences'] as List? ?? []).cast<Map>())
          s['text']! as String,
      ];
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
    Future<bool?> flag(String key) async => switch (await _store.read(key)) {
      '1' => true,
      '0' => false,
      _ => null,
    };
    return LessonPrefs(
      minutes: minutes ?? d.minutes,
      readAloud: await flag('lesson.readAloud'),
      biggerPad: await flag('lesson.biggerPad') ?? d.biggerPad,
    );
  }

  Future<void> savePrefs(LessonPrefs p) async {
    String? b(bool? v) => v == null ? null : (v ? '1' : '0');
    await _store.write('lesson.minutes', '${p.minutes}');
    await _store.write('lesson.readAloud', b(p.readAloud));
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
