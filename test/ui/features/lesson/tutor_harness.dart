import 'package:auramath/data/services/fake_api.dart';
import 'package:auramath/l10n/app_localizations.dart';
import 'package:auramath/ui/features/lesson/view_models/lesson_view_model.dart';
import 'package:auramath/ui/features/lesson/view_models/sitting.dart';
import 'package:auramath/ui/features/lesson/views/lesson_flow.dart';
import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

/// A lesson on the bundled pack and policy, drawn by [LessonFlow] on a
/// 390 x 844 phone, for the tutor's help tests.
class TutorLesson {
  TutorLesson(this.tester, this.vm, this.api, this.voice);

  final WidgetTester tester;
  final LessonViewModel vm;
  final FakeApi api;
  final FakeVoice voice;

  /// What `onFinished` was last called with.
  String? finishedWith;
  int homes = 0;

  List<String> get names => [for (final e in api.received) e.name];

  Future<void> tap(Finder f) async {
    await tester.runAsync(() async {
      await tester.tap(f);
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pumpAndSettle();
  }

  /// Sends [inputs] straight to the lesson, as the board's taps would.
  Future<void> send(List<LessonInput> inputs) async {
    for (final i in inputs) {
      await tester.runAsync(() => vm.send(i));
    }
    await tester.pumpAndSettle();
  }

  Future<void> type(String digits) async {
    for (final d in digits.split('')) {
      await tap(find.text(d).last);
    }
    await tap(find.byIcon(Icons.check_rounded));
  }
}

const toSizeB = <LessonInput>[Started(), BarADrawn(), BarBPlaced()];
const toFindB = <LessonInput>[
  ...toSizeB,
  BarBSized(Relation.shorter),
  PieceDropped(Piece.gap, Target.gapSlot),
  PieceDropped(Piece.total, Target.totalSlot),
  OpChosen(Op.subtract),
];

Future<TutorLesson> pumpLesson(
  WidgetTester tester, {
  String problemId = 'lemon',
  Pack? pack,
  double textScale = 1,
  Size size = const Size(390, 844),
  String? childId,
  int Function()? nowMs,
  ThemeData? theme,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final (sessions, db, api) =
      await tester.runAsync(memorySessions) ?? (throw StateError('no db'));
  addTearDown(() => tester.runAsync(db.close));
  final voice = FakeVoice();
  final vm = LessonViewModel(
    pack: pack ?? samplePack(),
    problemId: problemId,
    sessionId: 's1',
    sessions: sessions,
    voice: voice,
    openSession: sessions.open,
    sitting: Sitting(capMs: 30 * 60 * 1000),
    tickEvery: null,
    nowMs: nowMs,
  )..childId = childId;
  addTearDown(vm.dispose);
  await tester.runAsync(vm.start);
  late final TutorLesson lesson;
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: LessonFlow(
        vm: vm,
        onHome: () => lesson.homes++,
        onFinished: (next) => lesson.finishedWith = next,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return lesson = TutorLesson(tester, vm, api, voice);
}
