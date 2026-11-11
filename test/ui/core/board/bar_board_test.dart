import 'package:auramath/l10n/app_localizations.dart';
import 'package:auramath/ui/core/board/bar_board.dart';
import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final lemon = ComparisonProblem.fromJson({
  'id': 'lemon',
  'template': {'id': 'cmp.comparison', 'version': '0.3.0'},
  'story': 'lemon-fig',
  'level': 'L4',
  'variant': 'standard',
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
const placeGap = LessonState(
  step: LessonStep.placeGap,
  barA: true,
  barB: true,
  bSized: true,
);

/// The gap dropped on the fig bar (Figma W1, W2).
const gapOnFig = LessonState(
  step: LessonStep.placeGap,
  barA: true,
  barB: true,
  bSized: true,
  misplaced: Target.barB,
);

void main() {
  late List<LessonInput> inputs;

  Future<void> pumpBoard(
    WidgetTester tester,
    LessonState state, {
    bool showHand = false,
  }) async {
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
            child: BarBoard(
              problem: lemon,
              state: state,
              onInput: inputs.add,
              showHand: showHand,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the quiet-child hand runs its whole sweep without breaking', (
    tester,
  ) async {
    await pumpBoard(tester, drawA, showHand: true);
    // every frame of the 2 s sweep, including the one at exactly 85%
    for (var ms = 0; ms <= 2000; ms += 10) {
      await tester.pump(const Duration(milliseconds: 10));
    }
    expect(tester.takeException(), isNull);
  });

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

  testWidgets('size chips are big tray buttons with a size picture', (
    tester,
  ) async {
    await pumpBoard(tester, sizeB);
    for (final k in ['sizeShorter', 'sizeTaller']) {
      final chip = find.byKey(Key(k));
      expect(tester.getSize(chip).height, greaterThanOrEqualTo(56));
      expect(
        find.descendant(of: chip, matching: find.byKey(const Key('sizePic'))),
        findsOneWidget,
      );
    }
    expect(
      tester.getSemantics(find.byKey(const Key('sizeTaller'))),
      matchesSemantics(label: 'Taller', isButton: true, hasTapAction: true),
    );
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

  group('a wrong drop stays and wobbles (LES-07)', () {
    testWidgets('the gap sits on the fig bar, not in the tray', (tester) async {
      await pumpBoard(tester, gapOnFig);
      expect(find.byKey(const Key('misplaced')), findsOneWidget);
      expect(find.byKey(const Key('piece')), findsNothing);
      // over bar B
      final piece = tester.getCenter(find.byKey(const Key('misplaced')));
      final bar = tester.getRect(find.byKey(const Key('barB')));
      expect(piece.dx, closeTo(bar.center.dx, 1));
    });

    testWidgets('a tap takes it back, as an undo (LES-15)', (tester) async {
      await pumpBoard(tester, gapOnFig);
      await tester.tap(find.byKey(const Key('misplaced')));
      expect(inputs.single, isA<Undo>());
    });

    testWidgets('dragged on to the gap, it is placed there', (tester) async {
      await pumpBoard(tester, gapOnFig);
      final from = tester.getCenter(find.byKey(const Key('misplaced')));
      final to = tester.getCenter(find.byKey(const Key('gapSlot')));
      await tester.dragFrom(from, to - from);
      await tester.pumpAndSettle();
      final drop = inputs.single as PieceDropped;
      expect(drop.target, Target.gapSlot);
    });
  });
}
