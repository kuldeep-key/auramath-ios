import '../services/api_client.dart';

/// Setup's own calls: the one-time code a child's phone types to join the
/// family (DEV-02), and the family's phones, to see when it has joined.
class SetupRepository {
  SetupRepository(this._client);

  final ApiClient _client;

  /// `POST /api/devices/pairing` (parent): a fresh code, single use.
  Future<({String code, DateTime expiresAt})> newPairingCode() async {
    final j =
        await _client.post('/api/devices/pairing') as Map<String, Object?>;
    return (
      code: j['code']! as String,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(j['expiresAt']! as int),
    );
  }

  /// `GET /api/devices` (parent): the ids of the family's paired phones.
  Future<Set<String>> deviceIds() async {
    final j = await _client.get('/api/devices') as Map<String, Object?>;
    return {
      for (final d in j['devices']! as List)
        (d as Map<String, Object?>)['id']! as String,
    };
  }
}
