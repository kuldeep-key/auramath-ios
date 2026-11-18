import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../data/repositories/casebook_repository.dart';
import '../theme/tokens.dart';
import 'bar.dart';
import 'brace.dart';
import 'gap_segment.dart';

/// A solved case's final board, still (REW-15, Figma CB2 1043:11315): the
/// child's two bars as they committed them, lying across as on the lesson
/// board, each with the number put on it above; the difference on the
/// shorter bar (the lesson's [GapSegment]) and the total in the bracket on
/// the right ([AcrossBrace]). Only the drawing's own shapes and numbers:
/// the server sends no story words and no unit with it.
class CaseBoard extends StatelessWidget {
  const CaseBoard({super.key, required this.drawing});

  final CaseDrawing drawing;

  static const _barH = 52.0;
  static const _totalW = 64.0;

  int? _value(String object) =>
      drawing.pieces.where((p) => p.object == object).firstOrNull?.value;

  bool _placed(String object) =>
      drawing.pieces.any((p) => p.object == object && p.target != 'none');

  @override
  Widget build(BuildContext context) {
    final a = math.max(drawing.barA, 0.1), b = math.max(drawing.barB, 0.1);
    final long = math.max(a, b);
    final total = _placed('total');
    final gap = _placed('difference');
    String said(int? v) => v == null ? '?' : '$v';
    // widths by flex, not measured: the page asks this card its height
    // before laying it out (no LayoutBuilder here)
    int flex(double units) => math.max(1, (units / long * 1000).round());
    Widget row(double length, Color color, String label) {
      final value = _value(label);
      final rest = long - length;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          if (value != null)
            Text('$value', style: AuraText.barValue.copyWith(fontSize: 20)),
          SizedBox(
            height: _barH,
            child: Row(
              children: [
                Expanded(
                  flex: flex(length),
                  child: Bar(color: color, across: true),
                ),
                if (rest / long > 0.01)
                  Expanded(
                    flex: flex(rest),
                    child: gap
                        ? GapSegment(
                            key: const Key('caseGap'),
                            label: said(_value('difference')),
                          )
                        : const SizedBox(),
                  ),
              ],
            ),
          ),
        ],
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 14,
              children: [
                row(a, AuraColors.yellow, 'label_a'),
                row(b, AuraColors.blue, 'label_b'),
              ],
            ),
          ),
          if (total) ...[
            const SizedBox(width: 8),
            SizedBox(
              key: const Key('caseTotal'),
              width: _totalW,
              child: AcrossBrace(label: said(_value('total'))),
            ),
          ],
        ],
      ),
    );
  }
}
