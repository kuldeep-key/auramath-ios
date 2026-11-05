/// Checks one comparison problem with the phone's own rules, for the content
/// pipeline: `dart compile exe bin/auramath_check.dart`, then pipe a problem
/// JSON in. Prints the answers and every mistake route's number.
///
/// Exit codes: 0 ok, 1 two routes collide (do not ship), 2 bad input.
library;

import 'dart:convert';
import 'dart:io';

import 'package:auramath_engine/auramath_engine.dart';

Future<void> main() async {
  final ComparisonProblem p;
  try {
    final text = await stdin.transform(utf8.decoder).join();
    p = ComparisonProblem.fromJson(jsonDecode(text) as Map<String, Object?>);
  } on Object catch (e) {
    stderr.writeln('auramath_check: bad problem JSON: $e');
    exit(2);
  }
  final collision = hasCollision(p);
  stdout.writeln(
    jsonEncode({
      'bValue': p.bValue,
      'total': p.total,
      'routes': {
        for (final e in findBRoutes(p).entries) '${e.key}': e.value.name,
      },
      'collision': collision,
    }),
  );
  exit(collision ? 1 : 0);
}
