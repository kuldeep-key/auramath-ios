import 'dart:convert';

import 'package:auramath_engine/auramath_engine.dart';

import '../services/pack_source.dart';

class PackRepository {
  PackRepository({required this._source});

  final PackSource _source;

  /// The pack, with Julia's teaching values taken from her policy file (the
  /// quiet timers, the hint ladder, the line library) so a change to them
  /// is a content edit (PLAT-03).
  Future<Pack> load() async {
    final pack = Pack.fromJson(
      jsonDecode(await _source.read()) as Map<String, Object?>,
    );
    return withPolicy(
      pack,
      Policy.fromYaml(await _source.readPolicy()),
      ComparisonTemplate.fromYaml(await _source.readTemplate()),
    );
  }

  /// [pack] taught by [policy]; hints start where [template]'s steps say.
  static Pack withPolicy(
    Pack pack,
    Policy policy, [
    ComparisonTemplate? template,
  ]) => pack.copyWith(
    timers: policy.timers,
    maxSideLessons: policy.maxSideLessons,
    noProgressMs: policy.noProgressMs,
    practiceSums: policy.practiceSums,
    questionButtons: policy.questionButtons,
    policyLines: policy.lines,
    hintLadder: policy.hintLadder,
    hintStart: template?.hintStart,
    quietLines: policy.quietLines,
  );
}
