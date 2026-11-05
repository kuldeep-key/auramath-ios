import 'package:flutter/material.dart';

import '../motion/motion.dart';
import '../theme/tokens.dart';

/// The coach's line. Figma: Prototype parts › Speech bubble. Each new line
/// comes in word by word, as the prototype's: every word rises 6 px and
/// fades in (320 ms, springy), 45 ms after the one before.
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({super.key, required this.text, this.big = false});

  final String text;

  /// The voice is resting: the words show big instead (NoVoice 659:39).
  final bool big;

  static const _word = 320, _stagger = 45;

  @override
  Widget build(BuildContext context) {
    final style = big ? AuraText.bubbleBig : AuraText.bubble;
    final words = text.split(' ');
    final total = (words.length - 1) * _stagger + _word;
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: AuraColors.white,
        borderRadius: BorderRadius.circular(AuraRadii.bubble),
        border: Border.all(color: AuraColors.line, width: 2),
        boxShadow: const [
          BoxShadow(color: AuraColors.line, offset: Offset(0, 4)),
        ],
      ),
      child: Semantics(
        liveRegion: true,
        child: Entrance(
          key: ValueKey(text),
          duration: Duration(milliseconds: total),
          builder: (context, t, _) {
            // settled: the plain line, as it reads to every reader
            if (t >= 1) return Text(text, style: style);
            final ms = t * total;
            return Text.rich(
              TextSpan(
                children: [
                  for (final (i, w) in words.indexed) ...[
                    if (i > 0) const TextSpan(text: ' '),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.baseline,
                      baseline: TextBaseline.alphabetic,
                      child: _Word(
                        w,
                        style,
                        ((ms - i * _stagger) / _word).clamp(0.0, 1.0),
                      ),
                    ),
                  ],
                ],
              ),
              style: style,
            );
          },
        ),
      ),
    );
  }
}

class _Word extends StatelessWidget {
  const _Word(this.word, this.style, this.t);

  final String word;
  final TextStyle style;
  final double t;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: t,
    child: Transform.translate(
      offset: Offset(0, 6 * (1 - AuraCurves.spring.transform(t))),
      child: Text(word, style: style),
    ),
  );
}
