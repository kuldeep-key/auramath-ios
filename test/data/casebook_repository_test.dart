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

  test('REW-15: a piece dropped off the board is not drawn; the bars\' '
      'numbers win over a label piece', () {
    final v = CasebookRepository.caseFrom({
      ...sampleCase,
      'drawing': {
        'barA': 18.6,
        'barB': 7.9,
        'pieces': [
          {'object': 'label_a', 'target': 'bar_a', 'value': 180},
          {'object': 'total', 'target': 'none', 'value': 265},
          {'object': 'difference', 'target': 'gap', 'value': 107},
        ],
      },
      'bars': {
        'barA': {'value': 186},
        'barB': {'value': 79},
      },
    })!;
    expect(v.drawing!.pieces.map((p) => (p.object, p.value)), [
      ('difference', 107),
      ('label_a', 186),
      ('label_b', 79),
    ]);
  });

  test('REW-15: an older server\'s case has no subject, story or bars', () {
    final c = CasebookRepository.caseFrom(sampleCase)!.entry;
    expect(c.sticker.subject, isNull);
    expect(c.story, isNull);
    expect(c.bars, isNull);
    final day = CasebookRepository.daysFrom(sampleCasebook).days!.first;
    expect(day.cases.single.bars, isNull);
  });

  test('REW-15: a case carries its sticker subject, story and bar model, '
      'in the day view and the case', () async {
    final (r, server) = repo();
    server.on('GET /api/children/c1/casebook/cases/lemon', sampleLabelledCase);
    server.on('GET /api/children/c1/casebook', {
      'world': 'detective',
      'days': [
        {
          'date': '2026-11-18',
          'sessionBadges': <Object?>[],
          'cases': [sampleLabelledCase],
        },
      ],
    });
    final listed = (await r.days('c1')).days!.single.cases.single;
    final c = (await r.caseOf('c1', 'lemon'))!.entry;
    for (final e in [listed, c]) {
      expect(e.sticker.subject, 'tree');
      expect(e.story, (
        storyId: 'lemon-fig',
        a: 'lemon tree',
        b: 'fig tree',
        kind: 'tree',
        unit: 'cm',
        quantity: 'height',
      ));
      final b = e.bars!;
      expect(b.relation, 'shorter');
      expect(b.unit, 'cm');
      expect(b.barA, (label: 'lemon tree', value: 186, given: true));
      expect(b.barB, (label: 'fig tree', value: 79, given: false));
      expect(b.gap, (value: 107, given: true));
      expect(b.acrossBoth, (value: 265, given: false));
    }
  });

  test('REW-15: a generated story: no story, bars without names; a bar '
      'model missing a bar is none', () {
    final g = CasebookRepository.caseFrom(sampleGeneratedCase)!.entry;
    expect(g.story, isNull);
    expect(g.bars!.barA.label, isNull);
    expect(g.bars!.unit, isNull);
    expect(g.bars!.acrossBoth, isNull);
    final broken = CasebookRepository.caseFrom({
      ...sampleLabelledCase,
      'bars': {
        'relation': 'taller',
        'barA': {'label': 'x', 'value': 3, 'given': true},
        'gap': {'value': 1, 'given': true},
      },
    })!.entry;
    expect(broken.bars, isNull);
    expect(broken.story, isNotNull);
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
