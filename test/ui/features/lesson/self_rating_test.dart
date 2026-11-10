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

  test('Mia, 7: the faces, then self_rating_given before the session ends; '
      'the next case is the one it was without a rating', () async {
    final (vm, api) = await solved(7);
    expect(vm.offerRating, isTrue);
    expect(names(api), isNot(contains('session_ended')));
    final next = vm.nextProblemId;
    await vm.rate('easy');
    await pumpEventQueue();
    expect(vm.rating, 'easy');
    expect(names(api).skip(names(api).length - 2), [
      'self_rating_given',
      'session_ended',
    ]);
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

  test('Ana, 6: no faces, and the session ends at once', () async {
    final (vm, api) = await solved(6);
    expect(vm.offerRating, isFalse);
    expect(names(api).last, 'session_ended');
    vm.dispose();
  });

  test('a second tap changes nothing; no tap still ends the session', () async {
    final (vm, api) = await solved(9);
    await vm.rate('tricky');
    await vm.rate('easy');
    expect(vm.rating, 'tricky');
    expect(names(api).where((n) => n == 'self_rating_given'), hasLength(1));

    final (skipped, api2) = await solved(9);
    skipped.skipRating();
    await pumpEventQueue();
    expect(names(api2).last, 'session_ended');
    expect(names(api2), isNot(contains('self_rating_given')));
    vm.dispose();
    skipped.dispose();
  });

  testWidgets('the faces on "case cracked": big targets, a kind line about '
      'checking, and Next without a face', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final (vm, api) =
        await tester.runAsync(() => solved(8)) ?? (throw StateError('no vm'));
    addTearDown(vm.dispose);
    String? finished;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ListenableBuilder(
            listenable: vm,
            builder: (_, _) => SolvedView(
              vm: vm..showBadges = false,
              onFinished: (n) => finished = n,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('How was this case?'), findsOneWidget);
    for (final label in ['Easy', 'OK', 'Tricky']) {
      final size = tester.getSize(
        find.ancestor(of: find.text(label), matching: find.byType(InkWell)),
      );
      expect(size.height, greaterThanOrEqualTo(56), reason: label);
      expect(size.width, greaterThanOrEqualTo(56), reason: label);
    }
    await tester.runAsync(() async {
      await tester.tap(find.text('Tricky'));
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pump();
    expect(
      find.text(
        'Tricky cases take care. Checking each bar helped you crack it.',
      ),
      findsOneWidget,
    );
    expect(find.text('Easy'), findsNothing);
    await tester.tap(find.text('Next'));
    expect(finished, vm.nextProblemId);
    expect(api.received.any((e) => e.name == 'self_rating_given'), isTrue);
  });
}
