import 'package:auramath/data/services/flags.dart';
import 'package:auramath/data/services/key_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'api_client_test.dart' show clientFor;

void main() {
  test("the server's flags replace the defaults, kept for next launch, "
      'asked at most once a minute', () async {
    var calls = 0;
    var answer = 200;
    var now = DateTime(2026);
    final store = MemoryKeyStore();
    final client = clientFor((_) async {
      calls++;
      return http.Response(
        '{"version":"v","flags":{"trail":true,'
        '"read_aloud_default_on_ages":[6,7]}}',
        answer,
      );
    });
    final flags = Flags(
      client,
      store,
      defaults: {'trail': false, 'quick_sums': true},
      now: () => now,
    );
    expect(flags.on('trail'), isFalse);
    expect(flags.on('quick_sums'), isTrue);

    await flags.refresh();
    expect(flags.on('trail'), isTrue);
    expect(flags.on('quick_sums'), isFalse); // not named: off
    expect(flags.readAloudAges, [6, 7]);

    await flags.refresh();
    expect(calls, 1);

    now = now.add(const Duration(minutes: 2));
    answer = 503;
    await flags.refresh(); // refused: stays as it was
    expect(calls, 2);
    expect(flags.on('trail'), isTrue);

    final next = Flags(client, store, defaults: const {});
    await next.load();
    expect(next.on('trail'), isTrue);
  });
}
