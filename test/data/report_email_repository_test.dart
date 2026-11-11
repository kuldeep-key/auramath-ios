import 'package:auramath/data/repositories/report_email_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

void main() {
  test('reads the server loosely', () {
    for (final (json, want) in [
      ({'frequency': 'each_session'}, ReportFrequency.each),
      ({'frequency': 'each'}, ReportFrequency.each),
      ({'frequency': 'weekly'}, ReportFrequency.weekly),
      ({'frequency': 'off'}, ReportFrequency.off),
      ({'enabled': false}, ReportFrequency.off),
      ({'frequency': 'hourly'}, null),
    ]) {
      expect(ReportFrequency.parse(json), want, reason: '$json');
    }
  });

  test('sends each_session; a server that refuses it gets each', () async {
    final (deps, server) = await testDeps();
    final repo = ReportEmailRepository(deps.client);
    server.routes['PUT /api/family/settings/reports'] = (body) =>
        body['frequency'] == 'each_session'
        ? (422, {'error': 'frequency: not one of off, each, weekly'})
        : (204, null);
    await repo.setFrequency(ReportFrequency.each);
    expect(
      [
        for (final (c, b) in server.calls)
          if (c == 'PUT /api/family/settings/reports') b['frequency'],
      ],
      ['each_session', 'each'],
    );
  });
}
