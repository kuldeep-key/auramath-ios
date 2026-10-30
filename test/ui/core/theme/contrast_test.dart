import 'package:auramath/ui/core/theme/contrast.dart';
import 'package:auramath/ui/core/theme/tokens.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('contrastRatio of black on white is 21', () {
    expect(
      contrastRatio(const Color(0xFF000000), const Color(0xFFFFFFFF)),
      closeTo(21, 0.01),
    );
  });

  const body = [
    ('ink on white', AuraColors.ink, AuraColors.white),
    ('mute on white', AuraColors.mute, AuraColors.white),
    ('blueInk on blueTint', AuraColors.blueInk, AuraColors.blueTint),
    ('ink on yellowTint', AuraColors.ink, AuraColors.yellowTint),
  ];
  for (final (name, fg, bg) in body) {
    test('body text $name meets 4.5', () {
      expect(contrastRatio(fg, bg), greaterThanOrEqualTo(4.5));
    });
  }

  const largeBold = [
    ('white on blue', AuraColors.white, AuraColors.blue),
    ('yellowFg on yellow', AuraColors.yellowFg, AuraColors.yellow),
    ('navy on white', AuraColors.navy, AuraColors.white),
  ];
  for (final (name, fg, bg) in largeBold) {
    test('large bold text $name meets 3.0', () {
      expect(contrastRatio(fg, bg), greaterThanOrEqualTo(3.0));
    });
  }
}
