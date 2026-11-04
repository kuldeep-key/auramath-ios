import '../services/api.dart';
import '../services/api_client.dart';

/// A child in the family, as `/api/children` lists them. Never a gender.
class Child {
  const Child({
    required this.id,
    required this.name,
    this.age,
    this.schoolYear,
  });

  factory Child.fromJson(Map<String, Object?> j) => Child(
    id: j['id']! as String,
    name: j['displayName']! as String,
    age: j['age'] as int?,
    schoolYear: j['schoolYear'] as String?,
  );

  final String id;
  final String name;

  /// Sets read-aloud's default (flag `read_aloud_default_on_ages`).
  final int? age;

  /// A `/api/setup/options` year id, e.g. `year_2`.
  final String? schoolYear;
}

/// The family's children and consent: what setup and the child picker need.
/// The grown-up area adds its own calls in its feature.
class FamilyRepository {
  FamilyRepository(this._client);

  final ApiClient _client;

  /// Parent or child phone (`require_family`).
  Future<List<Child>> children() async {
    final j = await _client.get('/api/children') as Map<String, Object?>;
    return [
      for (final c in j['children']! as List)
        Child.fromJson(c as Map<String, Object?>),
    ];
  }

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
