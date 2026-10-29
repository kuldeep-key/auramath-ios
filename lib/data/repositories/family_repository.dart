import '../services/api_client.dart';

/// A child in the family, as `/api/children` lists them. Never a gender.
class Child {
  const Child({required this.id, required this.name, this.schoolYear});

  factory Child.fromJson(Map<String, Object?> j) => Child(
    id: j['id']! as String,
    name: j['displayName']! as String,
    schoolYear:
        (j['profile'] as Map<String, Object?>?)?['schoolYear'] as String?,
  );

  final String id;
  final String name;
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
    if (state['consented'] == true) return;
    await _client.post('/api/parent/consent', {
      'noticeVersion': state['currentVersion'],
    });
  }
}
