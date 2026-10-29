import 'package:auramath/data/services/outbox_db.dart';
import 'package:auramath/ui/features/lesson/view_models/lesson_view_model.dart';
import 'package:auramath/ui/features/lesson/view_models/sitting.dart';
import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

/// SES-01 time's up with the work kept, SES-02 no clock, SES-03 pause.
void main() {
  final pack = samplePack();
  const minute = 60 * 1000;
  var now = 0;
  late OutboxDb db;
  late LessonViewModel vm;
  late Sitting sitting;

  setUp(() async {
    now = 0;
    final (sessions, outbox, _) = await memorySessions();
    db = outbox;
    sitting = Sitting(capMs: 30 * minute);
    vm = LessonViewModel(
      pack: pack,
      problemId: 'lemon',
      sessionId: 's1',
      sessions: sessions,
      voice: FakeVoice(),
      sitting: sitting,
      nowMs: () => now,
      openSession: sessions.open,
      tickEvery: null,
    );
    await vm.start();
    await vm.send(const Started());
  });
  tearDown(() => vm.dispose());

  Future<void> spend(int ms) async {
    for (var left = ms; left > 0; left -= minute) {
      now += left < minute ? left : minute;
      await vm.tick();
    }
  }

  Future<String> lastEvent() async => (await db.forSession('s1')).last.name;

  test('time is up after 30 minutes of lesson, not before', () async {
    await spend(29 * minute);
    expect(vm.timeUp, isFalse);
    await spend(minute);
    expect(vm.timeUp, isTrue);
  });

  test('call it a day ends the session as time_up, keeping the work', () async {
    await vm.send(const BarADrawn());
    await spend(30 * minute);
    await vm.callItADay();
    final ended = (await db.forSession('s1')).last;
    expect(ended.name, 'session_ended');
    expect(ended.payload['reason'], 'time_up');
    expect(await vm.sessions.whereNext(pack), (
      problemId: 'lemon',
      resumeSessionId: 's1',
      startedOn: null,
    ));
  });

  test(
    'finish this one lets the child carry on, then the sitting ends',
    () async {
      await spend(30 * minute);
      vm.finishThisOne();
      expect(vm.timeUp, isFalse);
      expect(sitting.over, isTrue);
      await spend(minute);
      expect(vm.timeUp, isFalse);
    },
  );

  test('time with the phone locked does not count', () async {
    await vm.paused();
    expect(await lastEvent(), 'session_paused');
    now += 40 * minute;
    await vm.resumed();
    expect(await lastEvent(), 'session_resumed');
    await spend(minute);
    expect(vm.timeUp, isFalse);
  });

  test('home asks to take a break; going home saves the pause', () async {
    vm.askBreak();
    expect(vm.askingBreak, isTrue);
    vm.keepGoing();
    expect(vm.askingBreak, isFalse);
    vm.askBreak();
    await vm.leave();
    final paused = (await db.forSession('s1')).last;
    expect(paused.name, 'session_paused');
    expect(paused.payload['reason'], 'child');
  });
}
