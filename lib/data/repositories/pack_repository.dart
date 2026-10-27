import 'dart:convert';

import 'package:auramath_engine/auramath_engine.dart';

import '../services/pack_source.dart';

class PackRepository {
  PackRepository({required this._source});

  final PackSource _source;

  Future<Pack> load() async =>
      Pack.fromJson(jsonDecode(await _source.read()) as Map<String, Object?>);
}
