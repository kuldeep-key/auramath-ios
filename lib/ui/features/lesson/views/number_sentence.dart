import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/motion/motion.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/theme/tokens.dart';

/// The number sentence step (LES-06, Figma J36): the child puts the two
/// numbers and the ? in the boxes and picks + or −; any equivalent form
/// counts (186 − 107 = ?, 107 + ? = 186, ...). Sends the sentence as the
/// template writes it (`D+box=A`). DRAFT design for Apoorv: J36's builder
/// isn't drawn; tiles fill the first empty box, a tap on a box empties it.
class SentenceBuilder extends StatefulWidget {
  const SentenceBuilder({
    super.key,
    required this.problem,
    required this.onSentence,
    this.wobbles = 0,
  });

  final ComparisonProblem problem;
  final ValueChanged<SentenceEntered> onSentence;
  final int wobbles;

  @override
  State<SentenceBuilder> createState() => _SentenceBuilderState();
}

class _SentenceBuilderState extends State<SentenceBuilder> {
  /// The three boxes, left to right: `A`, `D` or `box`.
  final _boxes = List<String?>.filled(3, null);
  String _op = '+';

  String _show(String symbol) => switch (symbol) {
    'A' => '${widget.problem.aValue}',
    'D' => '${widget.problem.diff}',
    _ => '?',
  };

  void _put(String symbol) {
    final i = _boxes.indexOf(null);
    if (i < 0 || _boxes.contains(symbol)) return;
    setState(() => _boxes[i] = symbol);
  }

  void _check() {
    if (_boxes.contains(null)) return;
    final [a, b, c] = _boxes;
    widget.onSentence(SentenceEntered('$a${_op == '+' ? '+' : '-'}$b=$c'));
    setState(() => _boxes.fillRange(0, 3, null));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    Widget box(int i) => Semantics(
      button: true,
      label: _boxes[i] == null ? l.lessonSentenceBox : _show(_boxes[i]!),
      excludeSemantics: true,
      child: GestureDetector(
        key: Key('sentenceBox$i'),
        onTap: () => setState(() => _boxes[i] = null),
        child: Container(
          constraints: const BoxConstraints(minWidth: 64, minHeight: 56),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: _boxes[i] == null ? AuraColors.white : AuraColors.blueTint,
            borderRadius: BorderRadius.circular(AuraRadii.small),
            border: Border.all(color: AuraColors.blue, width: 3),
          ),
          child: Text(
            _boxes[i] == null ? '' : _show(_boxes[i]!),
            style: AuraText.title.copyWith(fontSize: 26),
          ),
        ),
      ),
    );
    Widget tile(String symbol) => Semantics(
      button: true,
      label: _show(symbol),
      excludeSemantics: true,
      child: GestureDetector(
        key: Key('sentenceTile-$symbol'),
        onTap: () => _put(symbol),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _boxes.contains(symbol) ? 0.35 : 1,
          child: Container(
            constraints: const BoxConstraints(minWidth: 72, minHeight: 56),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AuraColors.yellowTint,
              borderRadius: BorderRadius.circular(AuraRadii.small),
              border: Border.all(color: AuraColors.yellow, width: 3),
            ),
            child: Text(_show(symbol), style: AuraText.title),
          ),
        ),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wobbly(
          count: widget.wobbles,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              children: [
                box(0),
                const SizedBox(width: 6),
                Semantics(
                  button: true,
                  label: _op == '+'
                      ? l.lessonSentenceAdd
                      : l.lessonSentenceTake,
                  excludeSemantics: true,
                  child: GestureDetector(
                    key: const Key('sentenceOp'),
                    onTap: () => setState(() => _op = _op == '+' ? '−' : '+'),
                    child: Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AuraColors.navy,
                        borderRadius: BorderRadius.circular(AuraRadii.small),
                      ),
                      child: Text(
                        _op,
                        style: AuraText.title.copyWith(
                          color: AuraColors.white,
                          fontSize: 28,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                box(1),
                const SizedBox(width: 6),
                Text('=', style: AuraText.title.copyWith(fontSize: 28)),
                const SizedBox(width: 6),
                box(2),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 10,
          children: [
            for (final s in const ['A', 'D', 'box']) tile(s),
          ],
        ),
        const SizedBox(height: 12),
        AuraButton(
          label: l.lessonSentenceCheck,
          color: AuraButtonColor.blue,
          onPressed: _check,
        ),
      ],
    );
  }
}
