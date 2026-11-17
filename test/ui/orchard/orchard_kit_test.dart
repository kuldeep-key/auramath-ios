import 'package:auramath/ui/features/child_home/views/orchard/mini_svg.dart';
import 'package:auramath/ui/features/child_home/views/orchard/orchard_kit.dart';
import 'package:flutter_test/flutter_test.dart';

/// The prototype's generator (orchard.html K2): the same stop always gets
/// the same land, the first five are the catalogue's, and the map says
/// nothing but the stop names and the approved words.
void main() {
  const words = OrchardWords(
    explored: 'Explored',
    here: 'You are here',
    next: 'Next stop',
    lookBack: 'Look back',
  );
  OrchardScene scene(int lo, int here, List<OrchardStop> stops) =>
      orchardSVG(lo: lo, here: here, stops: stops, bloom: 2, words: words);

  test('the first five lands are the catalogue kit', () {
    expect(
      [for (var i = 0; i < 5; i++) oland(i).fam],
      ['garden', 'nursery', 'orchard', 'wood', 'hill'],
    );
    expect(oland(3).ent, 'stream');
  });

  test('a land is the same every time, and no family repeats within '
      'seven stops', () {
    final a = [for (var i = 0; i < 40; i++) oland(i).fam];
    final b = [for (var i = 0; i < 40; i++) omake(i).fam];
    expect(b.sublist(0, 5), a.sublist(0, 5));
    for (var i = 5; i < 40; i++) {
      final recent = a.sublist(i - 7 < 0 ? 0 : i - 7, i);
      expect(recent, isNot(contains(a[i])), reason: 'land $i');
    }
  });

  test('the hash and the seeded random match the prototype', () {
    // from orchard.html's oh() and mkr() in Chrome
    expect(oh(0, 0), 0.4295620475895703);
    expect(oh(5, 11), 0.5438602946233004);
    expect(oh(123, 61), 0.8569655495230108);
    final r = mkr(98);
    expect([r(), r()], [0.793029229525956, 0.44226064274192817]);
  });

  test('the map: geometry, signs, fog, and no numbers in its words', () {
    final s = scene(0, 2, const [
      OrchardStop('Seedling Path', 'explored'),
      OrchardStop('Sapling Row', 'explored'),
      OrchardStop('Orchard Gate', 'here'),
      OrchardStop('Old Oak Bridge', 'next'),
    ]);
    expect(s.height, opBOT + 3 * opSTEP + opTOP);
    expect(s.geom.P.map((p) => p[0]), [128, 266, 116, 272]);
    final texts = RegExp(
      r'<text[^>]*>([^<]*)</text>',
    ).allMatches(s.svg).map((m) => m.group(1)).toList();
    expect(texts, [
      'Seedling Path',
      'Explored',
      'Sapling Row',
      'Explored',
      'Orchard Gate',
      'You are here',
      'Old Oak Bridge',
      'Next stop',
    ]);
    expect(s.svg, contains('url(#ofog)'));
    expect(s.svg, isNot(contains('Look back')), reason: 'nothing folded');
    expect(MiniSvg.parse(s.svg).pathOf('opath'), isNotNull);
  });

  test('far along: Look back, and a land past the catalogue', () {
    final s = scene(9, 12, const [
      OrchardStop('A', 'earned'),
      OrchardStop('B', 'earned'),
      OrchardStop('C', 'earned'),
      OrchardStop('D', 'here'),
      OrchardStop('E', 'next'),
    ]);
    expect(s.svg, contains('Look back'));
    expect('<g class="medal">'.allMatches(s.svg).length, 3);
  });
}
