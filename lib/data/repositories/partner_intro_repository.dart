import '../services/key_store.dart';

/// Whether each child on this phone has met the case partner (AI-07): the
/// scene shows once per child, before their first lesson.
class PartnerIntroRepository {
  PartnerIntroRepository(this._store);

  final KeyStore _store;

  /// The children who met the partner, one per line, in one key so that
  /// sign-out and erase clear it at once (DEV-06). A phone with no child
  /// chosen yet counts as one.
  static const _key = 'partner_met';

  Future<Set<String>> _met() async =>
      (await _store.read(_key))?.split('\n').toSet() ?? {};

  String _id(String? childId) => childId ?? 'this_phone';

  Future<bool> met(String? childId) async =>
      (await _met()).contains(_id(childId));

  Future<void> markMet(String? childId) async =>
      _store.write(_key, {...await _met(), _id(childId)}.join('\n'));

  /// No child on this phone has met the partner (DEV-06).
  Future<void> forget() => _store.write(_key, null);

  /// The partner's lines as the content serves them (policy `lines.pack`
  /// ids starting `line.intro.`, in order, but the reminder said at
  /// breaks), else [drafts]. A served line with a slot the app can't fill
  /// isn't used.
  static List<String> lines(
    Map<String, String> policyLines,
    List<String> drafts,
  ) {
    final served = [
      for (final MapEntry(:key, :value) in policyLines.entries)
        if (key.startsWith('line.intro.') &&
            key != 'line.intro.reminder' &&
            !value.contains('{'))
          value,
    ];
    return served.isEmpty ? drafts : served;
  }
}
