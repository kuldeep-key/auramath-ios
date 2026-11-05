import 'package:auramath/data/repositories/family_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

void main() {
  Future<(FamilyRepository, FakeServer)> family(
    Map<String, Object?> consent,
  ) async {
    final (deps, server) = await testDeps(stored: parentPhone);
    server.on('GET /api/parent/consent', consent);
    server.on('POST /api/parent/consent', {'consented': true}, status: 201);
    return (deps.family, server);
  }

  bool posted(FakeServer s) =>
      s.calls.any((c) => c.$1 == 'POST /api/parent/consent');

  test('a current consent is not recorded again', () async {
    final (repo, server) = await family({
      'consentAt': 1,
      'consentWithdrawnAt': null,
      'currentVersion': 'v2',
      'stale': false,
    });
    await repo.giveConsent();
    expect(posted(server), isFalse);
  });

  test('no, withdrawn or old consent: agree to the current notice', () async {
    for (final state in [
      {'consentAt': null, 'consentWithdrawnAt': null, 'stale': true},
      {'consentAt': 1, 'consentWithdrawnAt': 2, 'stale': false},
      {'consentAt': 1, 'consentWithdrawnAt': null, 'stale': true},
    ]) {
      final (repo, server) = await family({...state, 'currentVersion': 'v2'});
      await repo.giveConsent();
      final call = server.calls.last;
      expect(call.$1, 'POST /api/parent/consent', reason: '$state');
      expect(call.$2['noticeVersion'], 'v2');
    }
  });
}
