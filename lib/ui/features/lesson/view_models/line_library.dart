import 'package:auramath_engine/auramath_engine.dart';

/// Replaces each `{key}` in a line with its slot value; an unknown key is
/// left as it is.
String fillSlots(String template, Map<String, String> slots) => template
    .replaceAllMapped(RegExp(r'\{(\w+)\}'), (m) => slots[m[1]] ?? m[0]!);

/// The words of every line the child sees (TUT-11): Julia's policy line
/// library (`lines.pack`) wherever it has the line, with its weight words
/// for a weight story; the pack's own text only for lines the library
/// doesn't hold yet. With `model_rewording` off nothing is phrased live.
class LineLibrary {
  LineLibrary(this._pack);

  final Pack _pack;

  /// The library id a line id stands for: a policy id as it is, a pack id
  /// through the pack's `library`.
  String libraryId(String id) => _pack.libraryIds[id] ?? id;

  /// Whether the line shown for [id] is Julia's library line.
  bool fromLibrary(String id) => _pack.policyLines.containsKey(libraryId(id));

  /// The line's words, unfilled; empty when no one holds it.
  String raw(String id, {bool mass = false}) {
    final lib = libraryId(id);
    return (mass ? _pack.policyMassLines[lib] : null) ??
        _pack.policyLines[lib] ??
        _pack.lines[id] ??
        '';
  }

  /// The line for problem [p], its slots filled.
  String line(String id, ComparisonProblem p, [Map<String, String>? slots]) =>
      fillSlots(raw(id, mass: isMass(p)), {
        ...lineSlots(p),
        ...policySlots(p),
        ...?slots,
      });

  /// Every version of the line, its own first (TUT-14). A weight story
  /// keeps its one mass line: the drafted versions use height words.
  List<String> versions(String id, {bool mass = false}) {
    final first = raw(id, mass: mass);
    if (mass && _pack.policyMassLines.containsKey(libraryId(id))) {
      return [first];
    }
    final more =
        _pack.lineVersions[libraryId(id)] ?? _pack.lineVersions[id] ?? const [];
    return [first, ...more.where((v) => v != first)];
  }

  /// The version last shown of each line, by library id.
  final _last = <String, int>{};

  /// The line for [p], in its next version: the versions take turns, so
  /// the same one is never shown twice in a row (TUT-14).
  String next(String id, ComparisonProblem p, [Map<String, String>? slots]) {
    final mass = isMass(p);
    final all = versions(id, mass: mass);
    final key = libraryId(id);
    final at = _last[key] == null ? 0 : (_last[key]! + 1) % all.length;
    _last[key] = at;
    return fillSlots(all[at], {...lineSlots(p), ...policySlots(p), ...?slots});
  }

  /// A weight story: its lines use the policy's mass variants.
  static bool isMass(ComparisonProblem p) => const {'g', 'kg'}.contains(p.unit);
}
