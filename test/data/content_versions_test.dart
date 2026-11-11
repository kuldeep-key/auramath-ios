import 'dart:io';

import 'package:auramath/data/services/content_versions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, String> bundled() => {
    for (final n in ['app-config', 'policy', 'skill-map'])
      '$n.yaml': File('assets/spec/$n.yaml').readAsStringSync(),
  };

  test('bundled only: the three files and the line library', () {
    final v = contentVersions(served: (_) => null, bundled: bundled());
    expect(v.keys, containsAll(['app-config', 'policy', 'skill-map']));
    expect(v['line-library'], v['policy']);
    expect(v.containsKey('arithmetic'), isFalse);
    expect(v.containsKey('scoring'), isFalse);
  });

  test('served: arithmetic, scoring and the lines own version', () {
    final served = {
      'arithmetic.yaml': '{"version":"0.3.1","levels":[]}',
      'scoring.yaml': '{"version":"0.4.0"}',
      'policy.yaml': '{"version":"0.4.0","lines":{"version":"0.4.2"}}',
    };
    final v = contentVersions(served: (n) => served[n], bundled: bundled());
    expect(v['arithmetic'], '0.3.1');
    expect(v['scoring'], '0.4.0');
    expect(v['policy'], '0.4.0');
    expect(v['line-library'], '0.4.2');
  });

  test('a version that is not x.y.z, or a broken file, is left out', () {
    final v = contentVersions(
      served: (n) => switch (n) {
        'scoring.yaml' => '{"version":"draft"}',
        'arithmetic.yaml' => '{: nope',
        _ => null,
      },
      bundled: const {},
    );
    expect(v, isEmpty);
  });

  test("the bundle's contentVersions fill the server-held keys only", () {
    final v = contentVersions(
      served: (_) => null,
      bundled: bundled(),
      held: {
        'arithmetic': '0.3.1',
        'scoring': '0.4.0',
        'line-library': '9.9.9',
        'policy': '9.9.9',
        'template.comparison-two-step': 'draft',
      },
    );
    expect(v['arithmetic'], '0.3.1');
    expect(v['scoring'], '0.4.0');
    // the phone's own reading wins
    expect(v['line-library'], v['policy']);
    expect(v['policy'], isNot('9.9.9'));
    expect(v.containsKey('template.comparison-two-step'), isFalse);
  });
}
