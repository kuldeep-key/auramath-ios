import 'dart:io';

import 'package:auramath/data/services/content_bundle.dart';
import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'api_client_test.dart' show clientFor;

void main() {
  test('kept with its ETag; a 304 keeps it; its files read as YAML', () async {
    final dir = await Directory.systemTemp.createTemp('bundle');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/content_bundle.json');
    final sent = <String?>[];
    var status = 200;
    final client = clientFor((req) async {
      sent.add(req.headers['If-None-Match']);
      return status == 304
          ? http.Response('', 304)
          : http.Response(
              '{"files":{"content/app-config.yaml":'
              '{"session":{"cap_minutes":20},"flags":{"trail":true}}},'
              '"praise":{"line.praise.solved":"You solved the {problem_name}!"},'
              '"contentVersions":{"scoring":"0.4.0","template.cmp":"0.4.0"}}',
              200,
              headers: {'etag': '"v1"'},
            );
    });

    final bundle = ContentBundle(client, file);
    await bundle.load();
    expect(bundle.yamlOf('app-config.yaml'), isNull); // the bundled copy
    await bundle.refresh();
    final config = AppConfig.fromYaml(bundle.yamlOf('app-config.yaml')!);
    expect(config.sessionCapMinutes, 20);
    expect(config.flags['trail'], isTrue);

    status = 304;
    final next = ContentBundle(client, file);
    await next.load();
    await next.refresh();
    expect(sent, [null, '"v1"']);
    expect(next.yamlOf('app-config.yaml'), isNotNull);
    // TUT-12: the finish line as the server serves it
    expect(next.praise, {
      'line.praise.solved': 'You solved the {problem_name}!',
    });
    // PLAT-04: the server's versions, kept with the copy
    expect(next.contentVersions, {'scoring': '0.4.0', 'template.cmp': '0.4.0'});
  });
}
