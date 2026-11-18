import 'package:auramath/data/repositories/casebook_repository.dart';
import 'package:auramath/routing/paths.dart';
import 'package:auramath/ui/core/board/bar.dart';
import 'package:auramath/ui/features/child_home/views/case_screen.dart';
import 'package:auramath/ui/features/child_home/views/casebook_screen.dart';
import 'package:auramath/ui/features/child_home/views/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'casebook_samples.dart';
import 'helpers.dart';

void main() {
  final days = CasebookRepository.daysFrom(sampleCasebook).days!;
  final view = CasebookRepository.caseFrom(sampleCase)!;
  final today = DateTime(2026, 11, 18, 9);
  const pictures = {'lemon tree': '🍋', 'fig tree': '🌳', 'mango tree': '🥭'};

  /// No number about the child anywhere on [tester]'s screen (REW-03): only
  /// the drawing's own numbers may show, passed as [allowed].
  void noCounts(WidgetTester tester, {Set<String> allowed = const {}}) {
    for (final t in tester.widgetList<Text>(find.byType(Text))) {
      final s = t.data ?? t.textSpan?.toPlainText() ?? '';
      if (allowed.contains(s)) continue;
      expect(s, isNot(matches(RegExp(r'\d'))), reason: 'a number: "$s"');
      expect(s, isNot(contains(' of ')), reason: 'a count: "$s"');
    }
  }

  testWidgets('CB1 fits every size, with cases and with none', (tester) async {
    await shots(
      tester,
      'child_home_casebook',
      CasebookScreen(days: days, today: today, pictures: pictures),
    );
    await shots(
      tester,
      'child_home_casebook_none',
      CasebookScreen(days: const [], today: today),
    );
  });

  testWidgets('REW-15: three solved cases on two days: three entries under '
      'two days, each with its sticker, and no count', (tester) async {
    await show(
      tester,
      CasebookScreen(days: days, today: today, pictures: pictures),
    );
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Last time · badge: Checked it'), findsOneWidget);
    expect(find.text('Tree Word Problem'), findsNWidgets(2));
    expect(find.text('Mango Word Problem'), findsOneWidget);
    expect(find.byType(StickerArt), findsNWidgets(3));
    expect(find.text('🍋'), findsOneWidget);
    expect(find.text('🌳'), findsOneWidget);
    expect(find.text('🥭'), findsOneWidget);
    noCounts(tester);
  });

  testWidgets('REW-15: older days go by their date; a day not today never '
      'says Today', (tester) async {
    await show(
      tester,
      CasebookScreen(days: days, today: DateTime(2026, 11, 20)),
    );
    expect(find.text('Today'), findsNothing);
    expect(find.text('Last time'), findsOneWidget);
    expect(
      find.text('Monday, November 16 · badge: Checked it'),
      findsOneWidget,
    );
  });

  testWidgets('REW-15: a case opens its own view; Back home goes home', (
    tester,
  ) async {
    await show(tester, CasebookScreen(days: days, today: today));
    await tapAndSettle(tester, find.byKey(const Key('case-mango')));
    expect(find.text('went to ${Paths.casebookCase('mango')}'), findsOneWidget);
    await show(tester, CasebookScreen(days: days, today: today));
    await tapAndSettle(tester, find.text('Back home'));
    expect(find.text('went to ${Paths.home}'), findsOneWidget);
  });

  testWidgets('REW-15: nothing solved yet: one warm line, no outlines', (
    tester,
  ) async {
    await show(tester, CasebookScreen(days: const [], today: today));
    expect(find.text('Your solved cases will live here.'), findsOneWidget);
    expect(find.byType(StickerArt), findsNothing);
  });

  testWidgets('a sticker the pack has no picture for goes by its words', (
    tester,
  ) async {
    expect(StickerArt.pictureOf('lemon tree', const {}), '🍋');
    expect(StickerArt.pictureOf('Big ROCKET', const {}), '🚀');
    expect(StickerArt.pictureOf('lemon tree', const {'lemon tree': 'L'}), 'L');
    expect(StickerArt.pictureOf('kite', const {}), '🔍');
  });

  testWidgets('CB2 fits every size, with a drawing and with none', (
    tester,
  ) async {
    await shots(
      tester,
      'child_home_case',
      CaseScreen(view: view, pictures: pictures),
    );
    final head = CasebookRepository.caseFrom({
      ...sampleCase,
      'drawing': null,
      'badges': <Object?>[],
    })!;
    await shots(tester, 'child_home_case_in_head', CaseScreen(view: head));
  });

  testWidgets('REW-15: the case shows the child\'s own bars with the '
      'drawing\'s numbers, its sticker and its badges', (tester) async {
    await show(tester, CaseScreen(view: view, pictures: pictures));
    expect(find.text('Tree Word Problem'), findsOneWidget);
    expect(find.text('YOUR DRAWING'), findsOneWidget);
    // the lesson board's own parts
    expect(find.byType(Bar), findsNWidgets(2));
    expect(find.byKey(const Key('caseGap')), findsOneWidget);
    expect(find.byKey(const Key('caseTotal')), findsOneWidget);
    expect(find.text('186'), findsOneWidget);
    expect(find.text('107'), findsOneWidget);
    expect(find.text('265'), findsOneWidget);
    // A is drawn longer than B, as the child drew it
    final bars = tester.widgetList<Bar>(find.byType(Bar)).toList();
    final wA = tester.getSize(find.byWidget(bars[0])).width;
    final wB = tester.getSize(find.byWidget(bars[1])).width;
    expect(wA / wB, closeTo(18.6 / 7.9, 0.05));
    expect(find.text('Case cracked!'), findsOneWidget);
    expect(find.text('Lemon tree'), findsOneWidget);
    expect(find.text('All by myself'), findsOneWidget);
    expect(find.text('Seedling Path'), findsOneWidget);
    noCounts(tester, allowed: {'186', '107', '265'});
  });

  testWidgets('REW-15: a case solved with nothing placed says so', (
    tester,
  ) async {
    final head = CasebookRepository.caseFrom({...sampleCase, 'drawing': null})!;
    await show(tester, CaseScreen(view: head));
    expect(find.byType(Bar), findsNothing);
    expect(find.text('You solved this one in your head.'), findsOneWidget);
  });

  testWidgets('CB2 Back goes back to the casebook', (tester) async {
    await show(tester, CaseScreen(view: view));
    await tapAndSettle(tester, find.text('Back'));
    expect(find.text('went to ${Paths.casebook}'), findsOneWidget);
  });

  testWidgets('Home: the casebook tile only while its switch is on', (
    tester,
  ) async {
    const off = HomeScreen(name: 'Mira', grownUps: Paths.kids);
    await show(tester, off);
    expect(find.text('My casebook'), findsNothing);
    expect(find.text('My trail'), findsOneWidget);

    const on = HomeScreen(name: 'Mira', grownUps: Paths.kids, casebook: true);
    await shots(tester, 'child_home_home_casebook', on);
    await show(tester, on);
    expect(find.text('My trail'), findsOneWidget);
    expect(find.text('My badges'), findsOneWidget);
    await tapAndSettle(tester, find.text('My casebook'));
    expect(find.text('went to ${Paths.casebook}'), findsOneWidget);

    // alone, it is still a whole Home
    await show(
      tester,
      const HomeScreen(
        name: 'Mira',
        grownUps: Paths.kids,
        trail: false,
        badges: false,
        casebook: true,
      ),
    );
    expect(find.text('My casebook'), findsOneWidget);
  });
}
