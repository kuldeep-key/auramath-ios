import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../data/repositories/casebook_repository.dart';
import '../theme/tokens.dart';
import 'bar.dart';
import 'brace.dart';
import 'gap_segment.dart';

/// A number with its unit, as the lesson board writes it ("186 cm"); a
/// cost in dollars as money ("$12"); no unit, the number alone.
String amount(int value, String? unit) => switch (unit) {
  null || '' => '$value',
  'dollars' => '\$$value',
  final u => '$value $u',
};

/// A solved case's final board, still (REW-15, Figma CB2 1043:11315): the
/// child's two bars as they committed them, lying across as on the lesson
/// board, each with the number put on it above; the difference on the
/// shorter bar (the lesson's [GapSegment]) and the total in the bracket on
/// the right ([AcrossBrace]). With the case's [bars] (the server's bar
/// model) each bar also carries its thing's name and picture and every
/// number its unit, the gap and the amount across both as the lesson ended;
/// a generated story's bars have numbers but no names. Without [bars] (an
/// older server, or numbers not in the log) only the drawing's own shapes
/// and numbers.
class CaseBoard extends StatelessWidget {
  const CaseBoard({
    super.key,
    required this.drawing,
    this.bars,
    this.pictureOf,
  });

  final CaseDrawing drawing;
  final CaseBars? bars;

  /// The picture for a bar's name, null for none.
  final String? Function(String label)? pictureOf;

  static const _barH = 52.0;
  static const _totalW = 64.0;

  int? _value(String object) =>
      drawing.pieces.where((p) => p.object == object).firstOrNull?.value;

  bool _placed(String object) =>
      drawing.pieces.any((p) => p.object == object && p.target != 'none');

  @override
  Widget build(BuildContext context) {
    final m = bars;
    final a = math.max(drawing.barA, 0.1), b = math.max(drawing.barB, 0.1);
    final long = math.max(a, b);
    final across = m?.acrossBoth;
    final total = across != null || _placed('total');
    final gap = m != null || _placed('difference');
    String said(int? v) => v == null ? '?' : '$v';
    final gapLabel = m != null
        ? amount(m.gap.value, m.unit)
        : said(_value('difference'));
    final totalLabel = switch ((across, m?.unit)) {
      (final t?, 'dollars') => amount(t.value, 'dollars'),
      (final t?, final u?) when u.isNotEmpty => '${t.value}\n$u',
      (final t?, _) => '${t.value}',
      (null, _) => said(_value('total')),
    };
    // widths by flex, not measured: the page asks this card its height
    // before laying it out (no LayoutBuilder here)
    int flex(double units) => math.max(1, (units / long * 1000).round());
    Widget head(String piece, CaseBar? bar) {
      final value = bar != null ? amount(bar.value, m?.unit) : _value(piece);
      final label = bar?.label;
      if (label == null) {
        return value == null
            ? const SizedBox.shrink()
            : Text(
                '$value',
                key: Key('caseValue-$piece'),
                style: AuraText.barValue.copyWith(fontSize: 20),
              );
      }
      final pic = pictureOf?.call(label);
      return Row(
        spacing: 8,
        children: [
          if (pic != null)
            ExcludeSemantics(
              child: Text(
                pic,
                style: const TextStyle(fontSize: 22, height: 1.1),
              ),
            ),
          Flexible(
            child: Text(
              label[0].toUpperCase() + label.substring(1),
              key: Key('caseLabel-$piece'),
              style: AuraText.barName.copyWith(fontSize: 17),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '$value',
            key: Key('caseValue-$piece'),
            style: AuraText.barValue.copyWith(fontSize: 20),
          ),
        ],
      );
    }

    Widget row(double length, Color color, String piece, CaseBar? bar) {
      final rest = long - length;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          head(piece, bar),
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
                        ? GapSegment(key: const Key('caseGap'), label: gapLabel)
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
                row(a, AuraColors.yellow, 'label_a', m?.barA),
                row(b, AuraColors.blue, 'label_b', m?.barB),
              ],
            ),
          ),
          if (total) ...[
            const SizedBox(width: 8),
            SizedBox(
              key: const Key('caseTotal'),
              width: _totalW,
              child: AcrossBrace(label: totalLabel),
            ),
          ],
        ],
      ),
    );
  }
}
