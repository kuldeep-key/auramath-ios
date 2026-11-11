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

  test('sends each, weekly and off as the backend names them, once each; '
      'reads back the each_session it stored', () async {
    final (deps, server) = await testDeps();
    final repo = ReportEmailRepository(deps.client);
    server
      ..on('PUT /api/family/settings/reports', null, status: 204)
      ..on('GET /api/family/settings/reports', {'frequency': 'each_session'});
    for (final f in ReportFrequency.values) {
      await repo.setFrequency(f);
    }
    expect(
      [
        for (final (c, b) in server.calls)
          if (c == 'PUT /api/family/settings/reports') b['frequency'],
      ],
      ['each', 'weekly', 'off'],
    );
    expect(await repo.frequency(), ReportFrequency.each);
  });
}
