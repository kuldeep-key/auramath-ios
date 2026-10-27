import 'package:auramath/l10n/app_localizations.dart';
import 'package:auramath/ui/core/board/bar_board.dart';
import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final lemon = ComparisonProblem.fromJson({
  'id': 'lemon',
  'a': {'name': 'Lemon tree', 'pic': '🍋', 'value': 186},
  'b': {'name': 'Fig tree', 'pic': '🌳'},
  'diff': 107,
  'big': 'a',
  'unit': 'cm',
  'ask': 'total',
  'text': 't',
  'say': 's',
  'next': {'fast': 'shorter', 'helped': 'mango', 'easier': 'easier'},
});

const drawA = LessonState(step: LessonStep.drawA);
const placeB = LessonState(step: LessonStep.placeB, barA: true);
const sizeB = LessonState(step: LessonStep.sizeB, barA: true, barB: true);
const placeGap = LessonState(step: LessonStep.placeGap, barA: true, barB: true);

void main() {
  late List<LessonInput> inputs;

  Future<void> pumpBoard(WidgetTester tester, LessonState state) async {
    inputs = [];
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            height: 540,
            child: BarBoard(problem: lemon, state: state, onInput: inputs.add),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('tap slot A draws bar A', (tester) async {
    await pumpBoard(tester, drawA);
    await tester.tap(find.byKey(const Key('slotA')));
    expect(inputs.single, isA<BarADrawn>());
  });

  testWidgets('drag the Bar piece onto slot A draws bar A', (tester) async {
    await pumpBoard(tester, drawA);
    final from = tester.getCenter(find.byKey(const Key('piece')));
    final to = tester.getCenter(find.byKey(const Key('slotA')));
    await tester.dragFrom(from, to - from);
    await tester.pumpAndSettle();
    expect(inputs.single, isA<BarADrawn>());
  });

  testWidgets('tap Bar piece then slot B places B', (tester) async {
    await pumpBoard(tester, placeB);
    await tester.tap(find.byKey(const Key('piece')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('slotB')));
    expect(inputs.single, isA<BarBPlaced>());
  });

  testWidgets('Shorter chip sizes B shorter', (tester) async {
    await pumpBoard(tester, sizeB);
    await tester.tap(find.text('Shorter'));
    expect((inputs.single as BarBSized).rel, Relation.shorter);
  });

  testWidgets('drag bar B handle down reports shorter', (tester) async {
    await pumpBoard(tester, sizeB);
    await tester.drag(find.byKey(const Key('handleB')), const Offset(0, 150));
    await tester.pumpAndSettle();
    expect((inputs.single as BarBSized).rel, Relation.shorter);
  });

  testWidgets('a tiny drag on the handle reports same height', (tester) async {
    await pumpBoard(tester, sizeB);
    await tester.drag(find.byKey(const Key('handleB')), const Offset(0, 8));
    await tester.pumpAndSettle();
    expect((inputs.single as BarBSized).rel, Relation.same);
  });

  testWidgets('tap Gap piece then bar B reports gap on barB', (tester) async {
    await pumpBoard(tester, placeGap);
    await tester.tap(find.byKey(const Key('piece')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('barB')));
    final drop = inputs.single as PieceDropped;
    expect((drop.piece, drop.target), (Piece.gap, Target.barB));
  });

  testWidgets('tapping a target with no piece picked does nothing', (
    tester,
  ) async {
    await pumpBoard(tester, placeGap);
    await tester.tap(find.byKey(const Key('gapSlot')));
    expect(inputs, isEmpty);
  });

  testWidgets('undo button sends Undo', (tester) async {
    await pumpBoard(tester, placeGap);
    await tester.tap(find.byKey(const Key('undo')));
    expect(inputs.single, isA<Undo>());
  });
}
