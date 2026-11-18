import 'package:auramath/data/services/fake_api.dart';
import 'package:auramath/l10n/app_localizations.dart';
import 'package:auramath/ui/features/lesson/view_models/lesson_view_model.dart';
import 'package:auramath/ui/features/lesson/view_models/sitting.dart';
import 'package:auramath/ui/features/lesson/views/solved_view.dart';
import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../data/helpers.dart' show expectContract;
import 'fakes.dart';

/// @AI-08: three faces after a case from age 7; never at 6; the rating is
/// logged and changes nothing.
void main() {
  const solve = <LessonInput>[
    Started(),
    BarADrawn(),
    BarBPlaced(),
    BarBSized(Relation.shorter),
    PieceDropped(Piece.gap, Target.gapSlot),
    PieceDropped(Piece.total, Target.totalSlot),
    OpChosen(Op.subtract),
    NumberEntered(79),
    NumberEntered(265),
  ];

  Future<(LessonViewModel, FakeApi)> solved(int age, {bool flag = true}) async {
    final (sessions, _, api) = await memorySessions();
    final vm =
        LessonViewModel(
            pack: samplePack(),
            problemId: 'lemon',
            sessionId: 's1',
            sessions: sessions,
            voice: FakeVoice(),
            openSession: sessions.open,
            sitting: Sitting(capMs: 30 * 60 * 1000),
            tickEvery: null,
          )
          ..selfRating = flag
          ..childAge = age;
    for (final i in solve) {
      await vm.send(i);
    }
    await pumpEventQueue();
    return (vm, api);
  }

  List<String> names(FakeApi api) => [for (final e in api.received) e.name];

  test('Mia, 7: the faces, then self_rating_given in the open session '
      '(REW-01: it ends at Home); the next case is the one it was without a '
      'rating', () async {
    final (vm, api) = await solved(7);
    expect(vm.offerRating, isTrue);
    expect(names(api), isNot(contains('session_ended')));
    final next = vm.nextProblemId;
    await vm.rate('easy');
    await pumpEventQueue();
    expect(vm.rating, 'easy');
    expect(names(api).last, 'self_rating_given');
    expect(names(api), isNot(contains('session_ended')));
    expect(
      api.received.firstWhere((e) => e.name == 'self_rating_given').payload,
      {'problem_id': 'lemon', 'rating': 'easy'},
    );
    final seqs = api.received.map((e) => e.seq).toList();
    expect(seqs, List.generate(seqs.length, (i) => i));
    expect(vm.nextProblemId, next);
    final (unrated, _) = await solved(7, flag: false);
    expect(unrated.nextProblemId, next);
    expectContract(api.received);
    vm.dispose();
    unrated.dispose();
  });

  test('Ana, 6: no faces; the session stays open for the next case', () async {
    final (vm, api) = await solved(6);
    expect(vm.offerRating, isFalse);
    expect(names(api), contains('problem_completed'));
    expect(names(api), isNot(contains('session_ended')));
    vm.dispose();
  });

  test('a second tap changes nothing; no tap gives no rating', () async {
    final (vm, api) = await solved(9);
    await vm.rate('tricky');
    await vm.rate('easy');
    expect(vm.rating, 'tricky');
    expect(names(api).where((n) => n == 'self_rating_given'), hasLength(1));

    final (skipped, api2) = await solved(9);
    skipped.skipRating();
    await pumpEventQueue();
    expect(names(api2), isNot(contains('self_rating_given')));
    expect(names(api2), isNot(contains('session_ended')));
    vm.dispose();
    skipped.dispose();
  });

  testWidgets('Rate after "case cracked": big faces, any answer, then the '
      'next case 350 ms after a face; Skip gives none', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Future<(LessonViewModel, FakeApi, List<String>)> pump() async {
      final (vm, api) =
          await tester.runAsync(() => solved(8)) ?? (throw StateError('no vm'));
      final finished = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ListenableBuilder(
              listenable: vm,
              builder: (_, _) => SolvedView(
                key: ValueKey(vm),
                vm: vm..showBadges = false,
                onFinished: finished.add,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 2));
      return (vm, api, finished);
    }

    final (vm, api, finished) = await pump();
    addTearDown(vm.dispose);
    expect(find.text('How was that one?'), findsNothing, reason: 'Y2 first');
    await tester.tap(find.text('Next'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('How was that one?'), findsOneWidget);
    expect(find.text('Any answer is fine.'), findsOneWidget);
    for (final label in ['Easy', 'OK', 'Tricky']) {
      final size = tester.getSize(
        find
            .ancestor(of: find.text(label), matching: find.byType(Semantics))
            .first,
      );
      expect(size.height, greaterThanOrEqualTo(56), reason: label);
      expect(size.width, greaterThanOrEqualTo(56), reason: label);
    }
    await tester.tap(find.text('Tricky'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(finished, isEmpty, reason: 'the face presses in first');
    await tester.pump(const Duration(milliseconds: 60));
    expect(finished, [vm.nextProblemId]);
    await tester.runAsync(pumpEventQueue);
    expect(api.received.any((e) => e.name == 'self_rating_given'), isTrue);

    final (vm2, api2, finished2) = await pump();
    addTearDown(vm2.dispose);
    await tester.tap(find.text('Next'));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byKey(const Key('rateSkip')));
    await tester.pump();
    expect(finished2, [vm2.nextProblemId]);
    await tester.runAsync(pumpEventQueue);
    expect(api2.received.any((e) => e.name == 'self_rating_given'), isFalse);
    expect(api2.received.any((e) => e.name == 'session_ended'), isFalse);
  });
}
