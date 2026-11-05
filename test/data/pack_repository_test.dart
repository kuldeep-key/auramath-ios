import 'dart:io';

import 'package:auramath/data/repositories/pack_repository.dart';
import 'package:auramath/data/services/pack_source.dart';
import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter_test/flutter_test.dart';

class FilePackSource implements PackSource {
  FilePackSource({this.policy});

  /// Replaces the bundled policy file's text when set.
  final String? policy;

  @override
  Future<String> read() => File('assets/sample_pack/pack.json').readAsString();

  @override
  Future<String> readPolicy() async =>
      policy ?? File('assets/spec/policy.yaml').readAsStringSync();
}

void main() {
  test('sample pack loads 4 problems with no route collisions', () async {
    final pack = await PackRepository(source: FilePackSource()).load();
    expect(pack.version, 'sample-1');
    expect(pack.problems.keys, ['lemon', 'shorter', 'mango', 'easier']);
    for (final p in pack.problems.values) {
      expect(hasCollision(p), isFalse, reason: p.id);
    }
    expect(pack.hintLineIds, hasLength(6));
  });

  test('every next problem in the sample pack exists', () async {
    final pack = await PackRepository(source: FilePackSource()).load();
    for (final p in pack.problems.values) {
      for (final id in [p.next.fast, p.next.helped, p.next.easier]) {
        expect(pack.problems, contains(id), reason: '${p.id} → $id');
      }
    }
  });

  test(
    "the quiet timers come from Julia's policy file, not the pack",
    () async {
      final edited = File('assets/spec/policy.yaml')
          .readAsStringSync()
          .replaceFirst('help_pulse_after_s: 15', 'help_pulse_after_s: 20');
      final pack = await PackRepository(
        source: FilePackSource(policy: edited),
      ).load();
      expect(pack.timers.pulseMs, 20000);
      expect(pack.timers.glowMs, 25000);
    },
  );
}
