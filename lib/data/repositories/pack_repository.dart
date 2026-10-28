import 'dart:convert';

import 'package:auramath_engine/auramath_engine.dart';

import '../services/pack_source.dart';

class PackRepository {
  PackRepository({required this._source});

  final PackSource _source;

  /// The pack, with the quiet timers taken from Julia's policy file so a
  /// change to her timings is a content edit (PLAT-03).
  Future<Pack> load() async {
    final pack = Pack.fromJson(
      jsonDecode(await _source.read()) as Map<String, Object?>,
    );
    final policy = Policy.fromYaml(await _source.readPolicy());
    return pack.copyWith(timers: policy.timers);
  }
}
