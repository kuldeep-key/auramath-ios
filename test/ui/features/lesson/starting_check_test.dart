import 'package:auramath/data/services/api.dart';
import 'package:auramath/data/services/fake_api.dart';
import 'package:auramath/l10n/app_localizations.dart';
import 'package:auramath/ui/features/lesson/view_models/lesson_view_model.dart';
import 'package:auramath/ui/features/lesson/view_models/sitting.dart';
import 'package:auramath/ui/features/lesson/views/lesson_flow.dart';
import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../data/helpers.dart' show expectContract;
import 'fakes.dart';

/// A new child's four starting sums before the first case (SKL-07).
void main() {
  /// `/arithmetic {purpose: starting_check}`'s items, as the server worked
  /// them (age 9: A5, A6, A9, A10).
  final sums = [
    {
      'level': 'A5',
      'skill': 'arith.addsub-2d-regroup',
      'op': 'add',
      'a': 38,
      'b': 45,
      'answer': 83,
      'text': '38 + 45 = ?',
    },
    {
      'level': 'A6',
      'skill': 'arith.addsub-2d-regroup',
      'op': 'sub',
      'a': 72,
      'b': 35,
      'answer': 37,
      'text': '72 - 35 = ?',
    },
    {
      'level': 'A9',
      'skill': 'arith.add-3d-regroup',
      'op': 'add',
      'a': 268,
      'b': 145,
      'answer': 413,
      'text': '268 + 145 = ?',
    },
    {
      'level': 'A10',
      'skill': 'arith.sub-3d-regroup',
      'op': 'sub',
      'a': 532,
      'b': 278,
      'answer': 254,
      'text': '532 - 278 = ?',
    },
  ];

  Future<(LessonViewModel, FakeApi)> makeVm({bool due = true}) async {
    final pack = samplePack();
    final (sessions, _, api) = await memorySessions(withTemplate: true);
    api
      ..startingCheckDue = due
      ..startingSums.addAll(sums)
      ..placedAt = 'L3'
      ..problems.add(served(level: 'L3'));
    final vm = LessonViewModel(
      pack: pack,
      problemId: LessonViewModel.newProblem,
      sessions: sessions,
      voice: FakeVoice(),
      nowMs: () => 0,
      openSession: sessions.open,
      nextProblem: (s, {level}) => sessions.nextProblem(pack, s, level: level),
      sitting: Sitting(capMs: 30 * 60 * 1000),
      tickEvery: null,
    )..childId = 'c1';
    return (vm, api);
  }

  test('due: the four sums come first; the result places the child, and '
      'the case is asked at that level', () async {
    final (vm, api) = await makeVm();
    addTearDown(vm.dispose);
    await vm.start();
    expect(vm.inStartingCheck, isTrue);
    expect(vm.ready, isFalse);
    expect(vm.startingSums.first.text, '38 + 45 = ?');
    expect(api.asked, isEmpty, reason: 'no case before the sums');

    for (final v in [83, 37, 400, 254]) {
      await vm.answerStarting(v);
    }
    expect(vm.inStartingCheck, isFalse);
    expect(api.startingChecks, [('c1', 3)]);
    expect(api.asked.single.$2, 'L3');
    expect(vm.ready, isTrue);

    final log = api.received.where((e) => e.sessionId == vm.sessionId);
    expect(
      [for (final e in log) e.name],
      [
        ...List.filled(4, 'placement_answered'),
        'session_started',
        'problem_shown',
      ],
    );
    expect([for (final e in log) e.seq], [0, 1, 2, 3, 4, 5]);
    expect(log.elementAt(2).payload, {
      'item_id': 'start-3',
      'value': 400,
      'correct': false,
      'ms_from_item_start': 0,
    });
    expectContract(api.received);
  });

  test('not due: straight to the case, no sums asked', () async {
    final (vm, api) = await makeVm(due: false);
    addTearDown(vm.dispose);
    await vm.start();
    expect(vm.inStartingCheck, isFalse);
    expect(vm.ready, isTrue);
    expect(api.startingChecks, isEmpty);
    expect(api.asked.single.$2, isNull);
  });

  test(
    'a server with no starting sums: the case starts at its own level',
    () async {
      final (vm, api) = await makeVm();
      api.startingSums.clear();
      addTearDown(vm.dispose);
      await vm.start();
      expect(vm.ready, isTrue);
      expect(api.startingChecks, isEmpty);
    },
  );

  test(
    'a quiet tick during the sums does nothing: there is no case yet',
    () async {
      final (vm, api) = await makeVm();
      addTearDown(vm.dispose);
      await vm.start();
      expect(vm.inStartingCheck, isTrue);
      final before = api.received.length;
      await vm.send(const QuietFor(60000)); // threw on `_p!` before
      expect(api.received.length, before);
    },
  );

  test(
    'a refused result (5xx) still starts the case, and is reported',
    () async {
      final (vm, api) = await makeVm();
      addTearDown(vm.dispose);
      api.startingRefused = const ApiException('down', status: 503);
      failedReports.clear();
      await vm.start();
      for (final s in sums) {
        await vm.answerStarting(s['answer']! as int);
      }
      expect(vm.ready, isTrue);
      expect(failedReports.single, contains('starting check not sent'));
    },
  );

  test("sums the server can't give (404, 429, 5xx) skip the check, and are "
      'reported', () async {
    final (vm, api) = await makeVm();
    addTearDown(vm.dispose);
    api.startingSums.clear(); // the fake answers 404 with no sums
    failedReports.clear();
    await vm.start();
    expect(vm.ready, isTrue);
    expect(failedReports.single, contains('starting sums not fetched'));
  });

  test('the next sum is ready before its answer reaches the server', () async {
    final (vm, api) = await makeVm();
    addTearDown(vm.dispose);
    await vm.start();
    api.failNext = 1; // the upload waits on a retry; the sum shouldn't
    final answering = vm.answerStarting(83);
    expect(vm.startingAt, 1);
    await answering.timeout(const Duration(milliseconds: 200));
    expect(vm.inStartingCheck, isTrue);
  });

  test('offline as the result is sent: "need the internet", and Try again '
      'sends it', () async {
    final (vm, api) = await makeVm();
    addTearDown(vm.dispose);
    await vm.start();
    for (final v in [83, 37, 413]) {
      await vm.answerStarting(v);
    }
    api.failNext = 2; // the answer's send, then the result's
    await vm.answerStarting(254);
    expect(vm.startError?.offline, isTrue);
    await vm.start();
    expect(api.startingChecks, [('c1', 4)]);
    expect(vm.ready, isTrue);
  });

  testWidgets('typed on the number pad, with no score, then the case', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final (vm, api) =
        await tester.runAsync(makeVm) ?? (throw StateError('no db'));
    addTearDown(vm.dispose);
    await tester.runAsync(vm.start);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: LessonFlow(vm: vm, onHome: () {}, onFinished: (_) {}),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('38 + 45 = ?'), findsOneWidget);
    expect(
      find.text("Let's warm up with a few sums. No rush!"),
      findsOneWidget,
    );

    Future<void> type(String digits) async {
      for (final d in digits.split('')) {
        await tester.tap(find.text(d).last);
        await tester.pump();
      }
      await tester.runAsync(() async {
        await tester.tap(find.byIcon(Icons.check_rounded));
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
      await tester.pumpAndSettle();
    }

    await type('83');
    expect(find.text('72 - 35 = ?'), findsOneWidget);
    expect(find.text("Here's another sum."), findsOneWidget);
    await type('1');
    await type('413');
    await type('254');
    expect(api.startingChecks, [('c1', 3)]);
    // the case's question, at the placed level
    expect(find.textContaining('The lemon tree is 186 cm tall'), findsWidgets);
  });
}
