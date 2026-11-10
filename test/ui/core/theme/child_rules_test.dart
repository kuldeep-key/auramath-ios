import 'dart:convert';
import 'dart:io';

import 'package:auramath/ui/core/parts/aura_button.dart';
import 'package:auramath/ui/core/parts/keypad.dart';
import 'package:auramath/ui/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Rules every child screen keeps, checked where they live: 56 pt targets
/// (NFR-02), nothing red (NFR-03), no scores or ranks (REW-03).
void main() {
  /// Red: a strong colour within a few degrees of pure red. The coral the
  /// design uses for a field to fix (hue about 12°) is not.
  bool isRed(Color c) {
    final hsv = HSVColor.fromColor(c);
    return (hsv.hue < 8 || hsv.hue > 340) &&
        hsv.saturation > 0.5 &&
        hsv.value > 0.3;
  }

  test('no colour in the palette or the theme is red (NFR-03)', () {
    final tokens = File('lib/ui/core/theme/tokens.dart').readAsStringSync();
    final colors = [
      for (final m in RegExp(r'0x([0-9A-Fa-f]{8})').allMatches(tokens))
        Color(int.parse(m[1]!, radix: 16)),
    ];
    expect(colors, isNotEmpty);
    expect(colors.where(isRed), isEmpty);
    final scheme = buildAuraTheme().colorScheme;
    expect(isRed(scheme.error), isFalse, reason: 'Material error red');
  });

  testWidgets("keypad keys and buttons are 56 pt or more (NFR-02)", (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AuraButton(label: 'Next', onPressed: () {}),
              Keypad(onChanged: (_) {}, onCheck: (_) {}),
            ],
          ),
        ),
      ),
    );
    for (final f in [
      for (final d in '0123456789'.split('')) find.text(d),
      find.byIcon(Icons.check_rounded),
      find.text('Next'),
    ]) {
      final tap = find.ancestor(of: f, matching: find.byType(Semantics)).first;
      final size = tester.getSize(tap);
      expect(size.height, greaterThanOrEqualTo(56), reason: '$f');
      expect(size.width, greaterThanOrEqualTo(56), reason: '$f');
    }
  });

  test('no child copy keeps score (REW-03)', () {
    final arb =
        jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
            as Map<String, Object?>;
    final score = RegExp(
      r'\d+\s*(of|out of|/)\s*\d+|\bscore|\bpoints?\b|\d+\s*%|\brank',
      caseSensitive: false,
    );
    final child = {
      for (final MapEntry(:key, :value) in arb.entries)
        if (!key.startsWith('@') &&
            (key.startsWith('kid') ||
                key.startsWith('lesson') ||
                key.startsWith('timeUp') ||
                key.startsWith('kept')))
          key: '$value',
    };
    expect(child, isNotEmpty);
    expect({
      for (final MapEntry(:key, :value) in child.entries)
        // "No score." says there isn't one
        if (score.hasMatch(value.replaceAll('No score.', ''))) key: value,
    }, isEmpty);
  });

  test('draft child copy avoids policy forbidden_phrases, and AI-07\'s: '
      'no friend, no feelings, no guilt', () {
    final policy = File('assets/spec/policy.yaml').readAsStringSync();
    final list = RegExp(
      r'forbidden_phrases:[^\n]*\n((?:\s+- "[^"]+"\n)+)',
    ).firstMatch(policy)![1]!;
    final forbidden = [
      for (final m in RegExp(r'"([^"]+)"').allMatches(list)) m[1]!,
      // AI-07 (spec ai_and_online.feature @AI-07)
      'friend', 'i missed you', 'i love', 'miss you', 'sad without',
    ];
    expect(forbidden, containsAll(['great job', 'try again', 'wrong']));
    final arb =
        jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
            as Map<String, Object?>;
    final drafts = {
      for (final MapEntry(:key, :value) in arb.entries)
        if (!key.startsWith('@') &&
            '${(arb['@$key'] as Map?)?['description']}'.startsWith('DRAFT'))
          key: '$value'.toLowerCase(),
    };
    expect(drafts, isNotEmpty);
    expect({
      for (final MapEntry(:key, :value) in drafts.entries)
        for (final f in forbidden)
          if (value.contains(f)) key: f,
    }, isEmpty);
  });
}
