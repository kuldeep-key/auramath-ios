import '../services/api_client.dart';

typedef SetupOption = ({String id, String label});

/// The setup lists the server takes (`/api/setup/options`), in its order.
/// The screens keep their own wording for the ids they know.
class SetupOptions {
  const SetupOptions({
    required this.ages,
    required this.schoolYears,
    required this.goals,
    required this.canDo,
  });

  factory SetupOptions.fromJson(Map<String, Object?> j) {
    List<SetupOption> list(String key) => [
      for (final o in j[key]! as List)
        (
          id: (o as Map<String, Object?>)['id']! as String,
          label: o['label']! as String,
        ),
    ];
    return SetupOptions(
      ages: [for (final a in j['ages']! as List) a as int],
      schoolYears: list('schoolYears'),
      goals: list('goals'),
      // "I'm not sure" is its own way on, not a can-do choice
      canDo: list('canDo').where((o) => o.id != 'not_sure').toList(),
    );
  }

  final List<int> ages;
  final List<SetupOption> schoolYears;
  final List<SetupOption> goals;
  final List<SetupOption> canDo;
}

/// [ours] in the server's order and only the ids it takes; an id we have
/// no wording for shows the server's label ([unknown]). No server list:
/// [ours] as it is.
List<T> inServerOrder<T>(
  List<T> ours,
  String Function(T) idOf,
  List<SetupOption>? server,
  T Function(SetupOption) unknown,
) {
  if (server == null) return ours;
  final byId = {for (final o in ours) idOf(o): o};
  return [for (final s in server) byId[s.id] ?? unknown(s)];
}

/// Setup's own calls: the one-time code a child's phone types to join the
/// family (DEV-02), the family's phones, to see when it has joined, and
/// the setup lists.
class SetupRepository {
  SetupRepository(this._client);

  final ApiClient _client;

  /// `GET /api/setup/options` (no sign-in needed).
  Future<SetupOptions> options() async => SetupOptions.fromJson(
    await _client.get('/api/setup/options') as Map<String, Object?>,
  );

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
