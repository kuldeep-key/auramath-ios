import 'package:auramath/data/models/lesson_event.dart';
import 'package:auramath/ui/features/lesson/view_models/lesson_view_model.dart';
import 'package:auramath/ui/features/lesson/view_models/sitting.dart';
import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../data/helpers.dart' show expectContract;
import 'fakes.dart';

/// Every line read aloud is logged as `read_aloud_played`: its target, how
/// it started and whether a child cut it short, never its words (NFR-08,
/// TTR-03).
void main() {
  Future<(LessonViewModel, FakeVoice, List<LessonEvent> Function())> makeVm({
    bool readAloud = true,
    int Function()? nowMs,
  }) async {
    final (sessions, _, api) = await memorySessions();
    final voice = FakeVoice();
    final vm = LessonViewModel(
      pack: samplePack(),
      problemId: 'lemon',
      sessionId: 's1',
      sessions: sessions,
      voice: voice,
      nowMs: nowMs ?? () => 0,
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
    final reads = log().where((e) => e.name == 'read_aloud_played');
    // as it shows, the tutor speaks it; then the child asked (TTR-03)
    expect(
      [for (final e in reads) e.payload],
      [
        {'target': 'question', 'trigger': 'auto', 'stopped_early': false},
        {'target': 'question', 'trigger': 'tap', 'stopped_early': false},
      ],
    );
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
    expect(reads, hasLength(2));
    for (final read in reads) {
      expect(read, containsPair('target', 'hint'));
      expect(read, containsPair('trigger', 'auto'));
      expect(read, containsPair('stopped_early', false));
    }
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
    expect(log().last.payload, containsPair('trigger', 'tap'));
    expect(log().last.payload, containsPair('target', 'hint'));
  });

  test('TTR-03: a child action stops the line at once: stopped_early, '
      'logged before what the action wrote', () async {
    final (vm, voice, log) = await makeVm();
    voice.holdLines = true;
    vm.autoReadQuestion();
    await pumpEventQueue();
    // still playing: not logged yet
    expect(log().map((e) => e.name), isNot(contains('read_aloud_played')));
    await vm.send(const Started());
    await pumpEventQueue();
    expect(voice.stops, greaterThan(0));
    final names = [for (final e in log()) e.name];
    final read = names.indexOf('read_aloud_played');
    expect(read, 2);
    expect(names[read + 1], 'step_entered');
    expect(log()[read].payload, {
      'target': 'question',
      'trigger': 'auto',
      'stopped_early': true,
    });
    expectContract(log());
  });

  test("TTR-03: the coach's library line is named by its line_id", () async {
    final (vm, _, log) = await makeVm();
    await vm.send(const Started());
    await vm.send(const HintTaken());
    await pumpEventQueue();
    final ids = [
      for (final e in log())
        if (e.name == 'read_aloud_played') e.payload['line_id'],
    ];
    expect(ids.whereType<String>(), isNotEmpty);
    expect(
      ids.whereType<String>().every((id) => id.startsWith('line.')),
      isTrue,
    );
  });

  test('TUT-07: the quiet timer starts when the tutor stops talking, not '
      'when the board shows', () async {
    var now = 0;
    final (vm, voice, log) = await makeVm(nowMs: () => now);
    voice.holdLines = true;
    await vm.send(const Started());
    // the step's line plays on for 20 s: no pulse, though the board showed
    for (now = 1000; now <= 20000; now += 1000) {
      await vm.tick();
    }
    expect(log().map((e) => e.name), isNot(contains('idle_prompt_shown')));
    now = 20000;
    await voice.stop(); // the line ends at 20 s
    now = 34000;
    await vm.tick();
    expect(log().map((e) => e.name), isNot(contains('idle_prompt_shown')));
    now = 35000;
    await vm.tick();
    await pumpEventQueue();
    final pulse = log().lastWhere((e) => e.name == 'idle_prompt_shown');
    expect(pulse.payload['level'], 'help_pulse');
    expect(pulse.payload['after_ms'], 15000);
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
