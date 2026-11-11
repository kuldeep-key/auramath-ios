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

  /// A weight story: its lines use the policy's mass variants.
  static bool isMass(ComparisonProblem p) => const {'g', 'kg'}.contains(p.unit);
}
