import 'package:flutter/material.dart';

import '../../../core/motion/motion.dart';
import '../../../core/parts/ribbon.dart';
import '../../../core/theme/tokens.dart';

/// The case partner's small "let me think" while the tutor's decision is
/// late (NFR-05). Draws over nothing it blocks: taps pass through.
// Draft: no Figma frame yet; a small pill under the coach's line.
class ThinkingCue extends StatelessWidget {
  const ThinkingCue({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Semantics(
      liveRegion: true,
      label: text,
      excludeSemantics: true,
      child: Center(
        child: Material(
          color: AuraColors.white,
          elevation: 3,
          borderRadius: BorderRadius.circular(AuraRadii.bubble),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 14, 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Portrait(size: 32),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    text,
                    style: AuraText.small,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                for (var i = 0; i < 3; i++)
                  Loop(
                    period: const Duration(milliseconds: 900),
                    delay: Duration(milliseconds: 150 * i),
                    builder: (context, t, child) =>
                        Opacity(opacity: 0.3 + 0.7 * halfway(t), child: child),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2),
                      child: CircleAvatar(
                        radius: 3,
                        backgroundColor: AuraColors.blue,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
