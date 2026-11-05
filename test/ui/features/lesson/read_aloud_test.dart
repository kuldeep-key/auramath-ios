import 'package:auramath/data/models/lesson_event.dart';
import 'package:auramath/ui/features/lesson/view_models/lesson_view_model.dart';
import 'package:auramath/ui/features/lesson/view_models/sitting.dart';
import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../data/helpers.dart' show expectContract;
import 'fakes.dart';

/// Every line read aloud is logged as `read_aloud_played`, its target only
/// (NFR-08).
void main() {
  Future<(LessonViewModel, FakeVoice, List<LessonEvent> Function())> makeVm({
    bool readAloud = true,
  }) async {
    final (sessions, _, api) = await memorySessions();
    final voice = FakeVoice();
    final vm = LessonViewModel(
      pack: samplePack(),
      problemId: 'lemon',
      sessionId: 's1',
      sessions: sessions,
      voice: voice,
      nowMs: () => 0,
      openSession: sessions.open,
      sitting: Sitting(capMs: 30 * 60 * 1000),
      tickEvery: null,
    )..readAloud = readAloud;
    addTearDown(() {
      vm.dispose();
      expectContract(api.received);
    });
    await vm.start();
    return (vm, voice, () => api.received);
  }

  test('the question, tapped or as it shows, is logged as the question; '
      'never its words', () async {
    final (vm, voice, log) = await makeVm();
    vm.autoReadQuestion();
    vm.readQuestion();
    await pumpEventQueue();
    expect(voice.said, hasLength(2));
    expect(
      [for (final e in log()) e.name],
      [
        'session_started',
        'problem_shown',
        'read_aloud_played',
        'read_aloud_played',
      ],
    );
    expect(log().last.payload, {'target': 'question'});
  });

  test("a step's line follows the step's own events, in one unbroken run "
      'of seqs', () async {
    final (sessions, db, api) = await memorySessions();
    final vm = LessonViewModel(
      pack: samplePack(),
      problemId: 'lemon',
      sessionId: 's1',
      sessions: sessions,
      voice: FakeVoice(),
      nowMs: () => 0,
      openSession: sessions.open,
      sitting: Sitting(capMs: 30 * 60 * 1000),
      tickEvery: null,
    );
    addTearDown(vm.dispose);
    await vm.start();
    await vm.send(const Started());
    await vm.send(const BarADrawn());
    final log = await db.forSession('s1');
    expect([for (final e in log) e.seq], List.generate(log.length, (i) => i));
    expect(vm.recorded, log.length);
    final reads = [
      for (final e in log)
        if (e.name == 'read_aloud_played') e.payload,
    ];
    expect(reads, [
      {'target': 'hint'},
      {'target': 'hint'},
    ]);
    // each step's line comes last in its batch
    expect(log.last.name, 'read_aloud_played');
    expectContract(api.received);
  });

  test('read-aloud off: a line shown on its own is not read, nor logged; '
      'the speak button still is', () async {
    final (vm, voice, log) = await makeVm(readAloud: false);
    vm.autoReadQuestion();
    await vm.send(const Started());
    expect(voice.said, isEmpty);
    expect(log().map((e) => e.name), isNot(contains('read_aloud_played')));
    vm.sayAgain();
    await pumpEventQueue();
    expect(log().last.name, 'read_aloud_played');
    expect(log().last.payload, {'target': 'hint'});
  });

  test(
    "the phone's voice resting: nothing is heard, so nothing is logged",
    () async {
      final (vm, voice, log) = await makeVm();
      voice.resting.value = true;
      vm.readQuestion();
      await pumpEventQueue();
      expect(log().map((e) => e.name), isNot(contains('read_aloud_played')));
    },
  );
}
