import '../services/api.dart';
import '../services/api_client.dart';

/// A child in the family, as `/api/children` lists them. Never a gender.
class Child {
  const Child({
    required this.id,
    required this.name,
    this.age,
    this.schoolYear,
    this.avatar,
  });

  factory Child.fromJson(Map<String, Object?> j) => Child(
    id: j['id']! as String,
    name: j['displayName']! as String,
    age: j['age'] as int?,
    schoolYear: j['schoolYear'] as String?,
    avatar: j['avatar'] as String?,
  );

  final String id;
  final String name;

  /// Sets read-aloud's default (flag `read_aloud_default_on_ages`).
  final int? age;

  /// A `/api/setup/options` year id, e.g. `year_2`.
  final String? schoolYear;

  /// The avatar id the child chose (ACC-12), if any.
  final String? avatar;
}

/// Whether the family's consent holds now (`GET /api/parent/consents`).
/// Withdrawn, lessons can't start and no child can be added until a
/// grown-up agrees again (ACC-03); what is kept stays until it's deleted.
class ConsentState {
  const ConsentState({required this.consented, this.withdrawnAt});

  factory ConsentState.fromJson(Map<String, Object?> j) => ConsentState(
    consented: j['consented'] == true,
    withdrawnAt: j['consentWithdrawnAt'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(j['consentWithdrawnAt']! as int),
  );

  final bool consented;

  /// Set once a grown-up withdrew it, until they agree again.
  final DateTime? withdrawnAt;

  bool get withdrawn => withdrawnAt != null;
}

/// The family's children and consent: what setup and the child picker need.
/// The grown-up area adds its own calls in its feature.
class FamilyRepository {
  FamilyRepository(this._client);

  final ApiClient _client;

  /// Parent or child phone (`require_family`).
  Future<List<Child>> children() async => (await family()).children;

  /// The children, and whether the family's consent holds (false once it
  /// is withdrawn: lessons are paused). An older server that doesn't say
  /// counts as consented.
  Future<({List<Child> children, bool consented})> family() async {
    final j = await _client.get('/api/children') as Map<String, Object?>;
    return (
      children: [
        for (final c in j['children']! as List)
          Child.fromJson(c as Map<String, Object?>),
      ],
      consented: j['consented'] != false,
    );
  }

  /// Parent only (ACC-14): only the fields in [changes] change
  /// (`displayName`, `age`, `schoolYear`, `avatar`). 400 for a name or answer the
  /// server refuses, 409 when another child already has the name.
  Future<Child> editChild(String id, Map<String, Object?> changes) async =>
      Child.fromJson(
        await _client.patch('/api/children/$id', changes)
            as Map<String, Object?>,
      );

  /// Parent only. Needs consent first (403 otherwise).
  Future<Child> addChild(Map<String, Object?> body) async => Child.fromJson(
    await _client.post('/api/children', body) as Map<String, Object?>,
  );

  /// Agrees to the notice version the server serves now (ACC-03).
  Future<void> giveConsent() async {
    final state =
        await _client.get('/api/parent/consent') as Map<String, Object?>;
    final current =
        state['consentAt'] != null &&
        state['consentWithdrawnAt'] == null &&
        state['stale'] != true;
    if (current) return;
    await _client.post('/api/parent/consent', {
      'noticeVersion': state['currentVersion'],
    });
  }

  Future<ConsentState> consent() async => ConsentState.fromJson(
    await _client.get('/api/parent/consents') as Map<String, Object?>,
  );

  /// Withdraws the family's consent (ACC-03): new lessons and new children
  /// stop at once, on every phone. [giveConsent] lifts it.
  Future<ConsentState> withdrawConsent() async => ConsentState.fromJson(
    await _client.post('/api/parent/consent/withdraw') as Map<String, Object?>,
  );

  /// The family's IANA time zone (`Australia/Sydney`): when the weekly note
  /// goes out.
  Future<void> setTimeZone(String zone) =>
      _client.put('/api/family/settings/time-zone', {'timeZone': zone});

  // ------------------------------------------- the grown-up passcode

  /// `{set, length, lockedUntil}`: whether one is set, how many digits.
  Future<({bool set, int length, int? lockedUntil})> passcodeStatus() async {
    final j = await _client.get('/api/family/passcode') as Map<String, Object?>;
    return (
      set: j['set'] == true,
      length: j['length']! as int,
      lockedUntil: j['lockedUntil'] as int?,
    );
  }

  /// Sets or changes it; [current] is required once one is set.
  Future<void> setPasscode(String passcode, {String? current}) => _client.put(
    '/api/family/passcode',
    {'passcode': passcode, 'current': ?current},
  );

  /// A forgotten passcode replaced without the old one: allowed within 10
  /// min of a fresh sign-in, else 403 (sign in again).
  Future<void> resetPasscode(String passcode) =>
      _client.post('/api/family/passcode/reset', {'passcode': passcode});

  /// True if right, false if wrong (the server's 403). Throws 429 while
  /// locked after too many tries, 404 when none is set.
  Future<bool> checkPasscode(String passcode) async {
    try {
      await _client.post('/api/family/passcode/check', {'passcode': passcode});
      return true;
    } on ApiException catch (e) {
      if (e.status == 403) return false;
      rethrow;
    }
  }
}
