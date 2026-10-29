import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// The coach's line. Figma: Prototype parts › Speech bubble.
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({super.key, required this.text, this.big = false});

  final String text;

  /// The voice is resting: the words show big instead (NoVoice 659:39).
  final bool big;

  @override
  Widget build(BuildContext context) => Container(
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
      child: Text(
        text,
        style: big ? AuraText.bubble.copyWith(fontSize: 26) : AuraText.bubble,
      ),
    ),
  );
}
