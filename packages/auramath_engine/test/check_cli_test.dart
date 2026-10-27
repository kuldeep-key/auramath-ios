import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import 'fixtures.dart';

Future<(int, String)> check(String stdinText) async {
  final p = await Process.start('dart', ['run', 'bin/auramath_check.dart']);
  p.stdin.write(stdinText);
  await p.stdin.close();
  final out = await p.stdout.transform(utf8.decoder).join();
  return (await p.exitCode, out);
}

void main() {
  test('lemon prints answers and routes, exit 0', () async {
    final (code, out) = await check(
      jsonEncode(problemJson('lemon', a: 186, diff: 107)),
    );
    expect(code, 0);
    expect(jsonDecode(out), {
      'bValue': 79,
      'total': 265,
      'routes': {
        '81': 'regrouping',
        '293': 'oppositeOp',
        '107': 'gapAsHeight',
        '97': 'swappedDigits',
      },
      'collision': false,
    });
  });

  test('a colliding problem exits 1', () async {
    final (code, out) = await check(
      jsonEncode(problemJson('x', a: 11, diff: 1)),
    );
    expect(code, 1);
    expect((jsonDecode(out) as Map)['collision'], isTrue);
  });

  test('bad input exits 2', () async {
    final (code, _) = await check('not json');
    expect(code, 2);
  });
}
