import 'package:auramath/ui/features/lesson/view_models/lesson_view_model.dart';
import 'package:auramath/ui/features/lesson/view_models/sitting.dart';
import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

/// REW-01, SES-05: a sitting is one session. The cases a child does in a
/// row go on in it, with one session_started and seqs that follow on, and
/// it ends once, when the child goes Home; a case left on a break keeps
/// its paused session for later, and the next case opens a new one.
void main() {
  final pack = samplePack();

  test('two cases in a row are one session with one session_started; Home '
      'ends it once, as finished, last', () async {
    final (sessions, db, _) = await memorySessions();
    LessonViewModel lesson(String problemId) => LessonViewModel(
      pack: pack,
      problemId: problemId,
      sessions: sessions,
      voice: FakeVoice(),
      nowMs: () => 0,
      openSession: () => sessions.openOrGoOn(childId: 'kid'),
      sitting: Sitting(capMs: 30 * 60 * 1000),
      tickEvery: null,
    );

    final first = lesson('lemon');
    await first.start();
    await first.send(const Started());
    await first.send(const KnowIt(265));
    expect(first.state.step, LessonStep.solved);
    first.dispose();

    final second = lesson('shorter');
    await second.start();
    expect(second.sessionId, first.sessionId);
    second.dispose();

    final log = await db.forSession(first.sessionId);
    expect(log.where((e) => e.name == 'session_started'), hasLength(1));
    expect(log.where((e) => e.name == 'problem_shown'), hasLength(2));
    expect(log.where((e) => e.name == 'session_ended'), isEmpty);
    expect(
      [for (final e in log) e.seq],
      [for (var i = 0; i < log.length; i++) i],
    );

    await sessions.endSitting('kid');
    await sessions.endSitting('kid');
    final ended = await db.forSession(first.sessionId);
    expect(ended.where((e) => e.name == 'session_ended'), hasLength(1));
    expect(ended.last.name, 'session_ended');
    expect(ended.last.payload['reason'], 'finished');
    expect(ended.last.seq, log.length);
    expect(sessions.lastStop.value?.sessionId, first.sessionId);

    // the next lesson after Home is a new session
    expect(await sessions.openOrGoOn(childId: 'kid'), isNot(first.sessionId));
  });

  test('a break keeps the case for later: Home leaves the paused session as '
      'it is, and the next case opens a new one', () async {
    final (sessions, db, _) = await memorySessions();
    final vm = LessonViewModel(
      pack: pack,
      problemId: 'lemon',
      sessions: sessions,
      voice: FakeVoice(),
      nowMs: () => 0,
      openSession: () => sessions.openOrGoOn(childId: 'kid'),
      sitting: Sitting(capMs: 30 * 60 * 1000),
      tickEvery: null,
    );
    await vm.start();
    await vm.send(const Started());
    await vm.leave(); // "Take a break?" then Go home
    vm.dispose();
    await sessions.endSitting('kid');
    final log = await db.forSession(vm.sessionId);
    expect(log.last.name, 'session_paused');
    expect(log.where((e) => e.name == 'session_ended'), isEmpty);
    expect(await sessions.openOrGoOn(childId: 'kid'), isNot(vm.sessionId));
  });

  test('REW-11: a medal earned in the second case of a sitting is due '
      'at the end of that case, from the open session', () async {
    final (sessions, _, api) = await memorySessions();
    LessonViewModel lesson(String problemId) => LessonViewModel(
      pack: pack,
      problemId: problemId,
      sessions: sessions,
      voice: FakeVoice(),
      nowMs: () => 0,
      openSession: () => sessions.openOrGoOn(childId: 'kid'),
      sitting: Sitting(capMs: 30 * 60 * 1000),
      tickEvery: null,
    );
    final first = lesson('lemon');
    await first.start();
    await first.send(const Started());
    await first.send(const KnowIt(265));
    first.dispose();
    await sessions.syncNow();
    expect(sessions.awardsDue('kid'), isEmpty);

    api.awards = const [
      (
        badgeId: 'stop.orchard.l2',
        kind: 'skill_mastered',
        name: 'Sapling Row',
        problemId: 'lemon',
        celebration: 'big',
        queued: false,
        alsoLand: null,
      ),
    ];
    final second = lesson('lemon');
    await second.start();
    await second.send(const Started());
    await second.send(const KnowIt(265));
    second.dispose();
    await sessions.syncNow();
    expect(sessions.lastStop.value, isNull, reason: 'the sitting is open');
    expect(
      [for (final a in sessions.awardsDue('kid')) a.badgeId],
      ['stop.orchard.l2'],
    );
    expect(sessions.awardsDue('other'), isEmpty);
  });

  test('two children on one phone each have their own sitting', () async {
    final (sessions, _, _) = await memorySessions();
    final a = await sessions.openOrGoOn(childId: 'ada');
    final b = await sessions.openOrGoOn(childId: 'bo');
    expect(a, isNot(b));
    expect(await sessions.openOrGoOn(childId: 'ada'), a);
    await sessions.endSitting('ada');
    expect(await sessions.openOrGoOn(childId: 'bo'), b);
  });
}
