import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/ribbon.dart';
import '../../../core/theme/tokens.dart';

/// "How can I help?": a hint, show me how, or something easier. Figma: H0
/// (M1-help).
class HelpSheet extends StatelessWidget {
  const HelpSheet({super.key, required this.onClose, required this.onChoose});

  final VoidCallback onClose;
  final ValueChanged<LessonInput> onChoose;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return _Sheet(
      onClose: onClose,
      children: [
        const Portrait(size: 88),
        const SizedBox(height: 12),
        Text(l.howCanIHelp, style: AuraText.title, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          l.pickOne,
          style: AuraText.body.copyWith(color: AuraColors.mute),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        for (final (label, icon, input) in [
          (l.aHint, Icons.lightbulb_outline_rounded, const HintTaken()),
          (
            l.showMeHow,
            Icons.play_circle_outline_rounded,
            const ShowMeHowTaken(),
          ),
          (l.anEasierOne, Icons.arrow_downward_rounded, const EasierTaken()),
        ]) ...[
          AuraButton(
            label: label,
            icon: icon,
            color: AuraButtonColor.white,
            onPressed: () => onChoose(input),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

/// A bottom sheet drawn over a dimmed screen, inside the lesson's own stack.
class _Sheet extends StatelessWidget {
  const _Sheet({required this.onClose, required this.children});

  final VoidCallback onClose;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: GestureDetector(
          onTap: onClose,
          child: const ColoredBox(color: AuraColors.scrim),
        ),
      ),
      Align(
        alignment: Alignment.bottomCenter,
        child: AuraSheetBody(children: children),
      ),
    ],
  );
}

/// The white rounded body of a lesson sheet, with its grab handle.
class AuraSheetBody extends StatelessWidget {
  const AuraSheetBody({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.all(12),
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
    decoration: BoxDecoration(
      color: AuraColors.white,
      borderRadius: BorderRadius.circular(28),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 5,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AuraColors.line,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        ...children,
      ],
    ),
  );
}
