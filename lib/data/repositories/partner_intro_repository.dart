import '../services/key_store.dart';

/// Whether each child on this phone has met the case partner (AI-07): the
/// scene shows once per child, before their first lesson.
class PartnerIntroRepository {
  PartnerIntroRepository(this._store);

  final KeyStore _store;

  /// Each child's own; a phone with no child chosen yet keeps one for itself.
  String _key(String? childId) => 'partner_met.${childId ?? 'this_phone'}';

  Future<bool> met(String? childId) async =>
      await _store.read(_key(childId)) != null;

  Future<void> markMet(String? childId) => _store.write(_key(childId), '1');

  /// The partner's lines as the content serves them (policy `lines.pack`
  /// ids starting `line.intro.`, in order), else [drafts]. A served line
  /// with a slot the app can't fill isn't used.
  static List<String> lines(
    Map<String, String> policyLines,
    List<String> drafts,
  ) {
    final served = [
      for (final MapEntry(:key, :value) in policyLines.entries)
        if (key.startsWith('line.intro.') && !value.contains('{')) value,
    ];
    return served.isEmpty ? drafts : served;
  }
}
