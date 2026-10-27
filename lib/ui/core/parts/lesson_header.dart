import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'speech_bubble.dart';

/// Speak button, the coach's line, and home. Figma: Prototype parts ›
/// Lesson header.
class LessonHeader extends StatelessWidget {
  const LessonHeader({
    super.key,
    required this.line,
    required this.onSpeak,
    required this.onHome,
  });

  final String line;
  final VoidCallback onSpeak;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      _SquareButton(
        icon: Icons.volume_up_rounded,
        fill: AuraColors.blue,
        fg: AuraColors.white,
        label: 'Say it again',
        onTap: onSpeak,
      ),
      const SizedBox(width: 8),
      Expanded(child: SpeechBubble(text: line)),
      const SizedBox(width: 8),
      _SquareButton(
        icon: Icons.home_rounded,
        fill: AuraColors.white,
        fg: AuraColors.navy,
        label: 'Home',
        onTap: onHome,
      ),
    ],
  );
}

class _SquareButton extends StatelessWidget {
  const _SquareButton({
    required this.icon,
    required this.fill,
    required this.fg,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color fill;
  final Color fg;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AuraColors.navy, width: 3),
          boxShadow: const [
            BoxShadow(color: AuraColors.navy, offset: Offset(0, 4)),
          ],
        ),
        child: Icon(icon, color: fg),
      ),
    ),
  );
}
