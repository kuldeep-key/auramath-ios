import 'package:auramath/data/models/lesson_event.dart';
import 'package:auramath/data/repositories/session_repository.dart';
import 'package:auramath/data/services/fake_api.dart';
import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';
import 'helpers.dart';

/// AUR-34: on a paired phone lessons go with the child's device token,
/// even with a grown-up signed in on it, and events name the paired
/// device from pairing on, without a restart.
void main() {
  test("a paired phone's lessons use its device token; a grown-up's "
      'phone, the grown-up\'s', () async {
    final (paired, _) = await testDeps(
      stored: {...pairedChildPhone, 'parentToken': 'parent-token'},
    );
    expect(paired.account.bearer, 'parent-token', reason: 'the record');
    expect(paired.account.lessonBearer, 'device-token');
    final (parent, _) = await testDeps(stored: parentPhone);
    expect(parent.account.lessonBearer, 'parent-token');
  });

  test("a 401 on a lesson with the device token is the phone's removal; "
      'the grown-up stays signed in', () async {
    final (deps, _) = await testDeps(
      stored: {...pairedChildPhone, 'parentToken': 'parent-token'},
    );
    deps.account.lessonUnauthorized();
    expect(deps.account.removed, isTrue);
    expect(deps.account.bearer, 'parent-token');
  });

  test('events name the paired device once paired, no restart', () async {
    final (deps, server) = await testDeps(stored: parentPhone);
    server.on('POST /api/devices/redeem', {
      'token': 'device-token',
      'deviceId': 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
    });
    final api = FakeApi();
    final repo = SessionRepository(
      db: await memoryOutbox(),
      api: api,
      identity: testIdentity,
      deviceId: () => deps.account.deviceRef,
    );
    final before = deps.account.deviceRef;
    await repo.open();
    await repo.record('s1', 0, const [
      SpecEvent('session_started', {'launch_source': 'child_opened'}),
    ]);
    await deps.account.redeemPairing('123456', label: 'Mira');
    await repo.record('s1', 1, const [
      SpecEvent('session_ended', {'reason': 'finished'}),
    ]);
    expect(
      [for (final e in api.received) e.deviceId],
      [before, 'dv_aaaaaaaabbbbccccddddeeeeeeeeeeee'],
    );
    expect(api.received.every((LessonEvent e) => e.deviceId != ''), isTrue);
    repo.dispose();
  });
}
