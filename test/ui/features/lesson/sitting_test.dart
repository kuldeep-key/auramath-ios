import 'package:auramath/data/services/fake_api.dart';
import 'package:auramath/data/services/key_store.dart';
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
  late FakeApi api;

  setUp(() async {
    now = 0;
    final (sessions, outbox, fake) = await memorySessions();
    db = outbox;
    api = fake;
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
    // the ended session isn't appended to: a new one carries the case on
    expect(await vm.sessions.whereNext(pack), (
      problemId: 'lemon',
      resumeSessionId: null,
      startedOn: null,
      carryFrom: 's1',
    ));
  });

  Future<LessonViewModel> carryOn() async {
    final next = (await vm.sessions.whereNext(pack))!;
    final later = LessonViewModel(
      pack: pack,
      problemId: next.problemId,
      sessions: vm.sessions,
      voice: FakeVoice(),
      sitting: Sitting(capMs: 30 * minute),
      nowMs: () => now,
      openSession: vm.sessions.open,
      tickEvery: null,
    )..carryFrom = next.carryFrom;
    await later.start();
    return later;
  }

  test('a case carried on in a side lesson reopens that side lesson, and '
      'the board takes no move until it is rebuilt', () async {
    await vm.send(const SideLessonChosen(SideLesson.readRelation));
    expect(vm.state.step, LessonStep.sideLesson);
    await spend(30 * minute);
    await vm.callItADay();
    final next = (await vm.sessions.whereNext(pack))!;
    final later = LessonViewModel(
      pack: pack,
      problemId: next.problemId,
      sessions: vm.sessions,
      voice: FakeVoice(),
      sitting: Sitting(capMs: 30 * minute),
      nowMs: () => now,
      openSession: vm.sessions.open,
      tickEvery: null,
    )..carryFrom = next.carryFrom;
    addTearDown(later.dispose);
    final readies = <bool>[];
    later.addListener(() => readies.add(later.ready));
    await later.start();
    expect(later.state.step, LessonStep.sideLesson);
    expect(later.sideLesson, SideLesson.readRelation);
    // ready once, at the end: no move lands on the fresh board first
    expect(readies.indexOf(true), readies.length - 1);
  });

  test('@SES-01 the next lesson carries the case on at the same step, in '
      "the server's continuation of the ended session", () async {
    await vm.send(const BarADrawn());
    await vm.send(const BarBPlaced());
    await spend(30 * minute);
    await vm.callItADay();
    final s1 = await db.forSession('s1');
    final opened = [...api.sessions];
    final later = await carryOn();
    // the server opened it for the work posted after the time_up end
    expect(api.continuations, {'s1': 'c-s1'});
    expect(later.sessionId, 'c-s1');
    expect(api.sessions, opened, reason: 'no new session is opened');
    expect(later.state.step, LessonStep.sizeB);
    expect(later.state.barA, isTrue);
    // its events follow on from the ended one's: resumed, then its own start
    final c = await db.forSession('c-s1');
    expect(c.map((e) => e.name).take(3), [
      'session_resumed',
      'session_started',
      'problem_shown',
    ]);
    expect(c.first.seq, s1.last.seq + 1);
    expect(
      [for (final e in c) e.seq],
      [for (var i = 0; i < c.length; i++) s1.last.seq + 1 + i],
    );
    // nothing more is written to the ended one
    await later.send(const BarBSized(Relation.shorter));
    expect((await db.forSession('s1')).length, s1.length);
    expect(later.state.step, LessonStep.placeGap);
    // problems and decisions go to the continuation, never the ended one
    expect(api.decisions.map((d) => d.$1), everyElement('c-s1'));
    // and a resume of it still has the whole board
    expect((await vm.sessions.whereNext(pack))?.resumeSessionId, 'c-s1');
    final (:events, lastSeq: _) = await vm.sessions.resume('c-s1');
    expect(
      replay(pack, later.problem, inputsFrom(pack, later.problem, events)),
      later.state,
    );
    later.dispose();
  });

  test(
    '@SES-01 nothing more goes into a session after Call it a day',
    () async {
      await vm.send(const BarADrawn());
      await spend(30 * minute);
      await vm.callItADay();
      final n = (await db.forSession('s1')).length;
      await vm.paused();
      await vm.send(const BarBPlaced());
      expect((await db.forSession('s1')).length, n);
      expect(api.continuations, isEmpty);
    },
  );

  test('@SES-01 a server without continuations: a new session carries the '
      'case on, as before', () async {
    api.continues = false;
    await vm.send(const BarADrawn());
    await vm.send(const BarBPlaced());
    await spend(30 * minute);
    await vm.callItADay();
    final later = await carryOn();
    expect(later.sessionId, api.sessions.last);
    expect(later.sessionId, isNot('s1'));
    expect(api.continuations, isEmpty);
    expect(later.state.step, LessonStep.sizeB);
    later.dispose();
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

  test('after finishing one past the cap, the next lesson stops at once, '
      'with nothing to finish', () async {
    await spend(30 * minute);
    vm.finishThisOne();
    final (sessions, _, _) = await memorySessions();
    final next = LessonViewModel(
      pack: pack,
      problemId: 'lemon',
      sessions: sessions,
      voice: FakeVoice(),
      sitting: sitting,
      nowMs: () => now,
      openSession: sessions.open,
      tickEvery: null,
    );
    addTearDown(next.dispose);
    await next.start();
    now += 1000;
    await next.tick();
    expect(next.timeUp, isTrue);
    expect(next.canFinish, isFalse);
  });

  test("the day's time outlives the app; a new day starts again", () async {
    final store = MemoryKeyStore();
    var clock = DateTime(2026, 11, 5, 9).millisecondsSinceEpoch;
    final today = Sitting(capMs: 30 * minute, store: store, nowMs: () => clock);
    today.activeMs = 20 * minute;
    await today.save();

    final relaunched = Sitting(
      capMs: 30 * minute,
      store: store,
      nowMs: () => clock,
    );
    await relaunched.load();
    expect(relaunched.activeMs, 20 * minute);

    clock = DateTime(2026, 11, 6, 9).millisecondsSinceEpoch;
    expect(relaunched.activeMs, 0);
  });

  test('time with the phone locked does not count', () async {
    await vm.paused();
    expect(await lastEvent(), 'session_paused');
    now += 40 * minute;
    await vm.resumed();
    expect(await lastEvent(), 'session_resumed');
    await spend(minute);
    expect(vm.timeUp, isFalse);
  });

  test('time waiting for the internet does not count (SES-04)', () async {
    api.failNext = 1000; // every send fails: the lesson stays paused
    vm.sessions.online.value = false;
    await spend(40 * minute);
    expect(vm.online, isFalse);
    expect(vm.timeUp, isFalse);
    api.failNext = 0;
    vm.sessions.online.value = true;
    await spend(29 * minute);
    expect(vm.timeUp, isFalse);
    await spend(minute);
    expect(vm.timeUp, isTrue);
  });

  test('with app-config clock_pauses_while_offline false, it does', () async {
    vm.clockPausesOffline = false;
    api.failNext = 1000;
    vm.sessions.online.value = false;
    await spend(30 * minute);
    expect(vm.timeUp, isTrue);
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

  test('leaving this one ends the session, and next time is a new case '
      '(SES-06)', () async {
    await vm.send(const BarADrawn());
    vm.askBreak();
    await vm.leaveProblem();
    expect(vm.askingBreak, isFalse);
    final events = await db.forSession('s1');
    final left = events[events.length - 2];
    expect(left.name, 'problem_left');
    expect(left.payload, {'problem_id': 'lemon', 'step_id': 'size_second_bar'});
    expect(events.last.payload, {'reason': 'left'});
    final next = await vm.sessions.whereNext(pack);
    expect(next?.resumeSessionId, isNull);
    expect(next?.problemId, pack.problems['lemon']!.next.fast);
  });

  test("the grown-up's time each day only shortens the cap", () {
    final sitting = Sitting(capMs: 30 * 60 * 1000);
    sitting.useMinutes(15);
    expect(sitting.capMs, 15 * 60 * 1000);
    sitting.useMinutes(45); // never past app-config's 30
    expect(sitting.capMs, 30 * 60 * 1000);
  });
}
