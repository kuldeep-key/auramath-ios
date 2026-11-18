import 'package:auramath/data/repositories/casebook_repository.dart';
import 'package:auramath/data/services/api.dart';
import 'package:auramath/data/services/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../helpers/app_harness.dart';
import '../ui/features/child_home/casebook_samples.dart';

void main() {
  (CasebookRepository, FakeServer) repo() {
    final server = FakeServer();
    final client = ApiClient(
      baseUrl: 'http://test',
      bearer: () => 't',
      client: server.client,
    );
    return (CasebookRepository(client), server);
  }

  test(
    'REW-15: the days, newest first, each with its badges and cases',
    () async {
      final (r, server) = repo();
      server.on('GET /api/children/c1/casebook', sampleCasebook);
      final got = await r.days('c1');
      expect(got.world, 'detective');
      final days = got.days!;
      expect(days.map((d) => d.date), [
        DateTime(2026, 11, 18),
        DateTime(2026, 11, 16),
      ]);
      expect(days[0].cases.single.sticker.object, 'lemon tree');
      expect(days[1].cases.map((c) => c.problemId), ['tree', 'mango']);
      expect(days[1].sessionBadges.single.name, 'Checked it');
    },
  );

  test('REW-15: the casebook switched off on the server is null', () async {
    final (r, server) = repo();
    server.on('GET /api/children/c1/casebook', {
      'world': 'detective',
      'days': null,
    });
    expect((await r.days('c1')).days, isNull);
  });

  test(
    'REW-15: offline or refused, the day view throws for ErrChild',
    () async {
      final (r, server) = repo();
      server.routes['GET /api/children/c1/casebook'] = (_) =>
          throw http.ClientException('offline');
      await expectLater(
        r.days('c1'),
        throwsA(isA<ApiException>().having((e) => e.offline, 'offline', true)),
      );
      server.on('GET /api/children/c1/casebook', {}, status: 403);
      await expectLater(r.days('c1'), throwsA(isA<ApiException>()));
    },
  );

  test('REW-15: one case, its drawing rebuilt from the log', () async {
    final (r, server) = repo();
    server.on('GET /api/children/c1/casebook/cases/lemon', sampleCase);
    final v = (await r.caseOf('c1', 'lemon'))!;
    expect(v.entry.name, 'Tree Word Problem');
    expect(v.date, DateTime(2026, 11, 18));
    expect(v.drawing!.barA, 18.6);
    expect(v.drawing!.pieces.map((p) => (p.object, p.value)), [
      ('label_a', 186),
      ('difference', 107),
      ('total', 265),
    ]);
    expect(v.sessionBadge!.name, 'All by myself');
    expect(v.badges.single.name, 'Seedling Path');
  });

  test('REW-15: a case with nothing placed has no drawing', () async {
    final (r, server) = repo();
    server.on('GET /api/children/c1/casebook/cases/lemon', {
      ...sampleCase,
      'drawing': null,
      'sessionBadge': null,
    });
    final v = (await r.caseOf('c1', 'lemon'))!;
    expect(v.drawing, isNull);
    expect(v.sessionBadge, isNull);
  });

  test(
    'REW-12: a case not in this casebook (404) is null; offline throws',
    () async {
      final (r, server) = repo();
      expect(await r.caseOf('c1', 'nope'), isNull);
      server.routes['GET /api/children/c1/casebook/cases/lemon'] = (_) =>
          throw http.ClientException('offline');
      await expectLater(r.caseOf('c1', 'lemon'), throwsA(isA<ApiException>()));
    },
  );
}
