import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/theme/tokens.dart';
import '../view_models/lesson_view_model.dart';
import 'help_sheet.dart';

/// The last hint rung, H1-6 (TUT-06, Julia's J13): an everyday comparison,
/// a grown-up and a child side by side, not bars, with the policy line
/// ("Think of a grown-up and you. Who is taller?"), then back to the step.
///
/// DRAFT for Design: no Figma frame, and the art is Material's person
/// figures until Apoorv draws a parent and a child.
class EverydayExampleSheet extends StatelessWidget {
  const EverydayExampleSheet({super.key, required this.vm});

  final LessonViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AuraSheet(
      onClose: vm.closeEveryday,
      children: [
        Semantics(
          label: l.lessonEverydayPicture,
          image: true,
          child: SizedBox(
            key: const Key('everydayPicture'),
            height: 170,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _Figure(
                  icon: Icons.man_rounded,
                  size: 160,
                  label: l.lessonGrownUp,
                ),
                const SizedBox(width: 8),
                _Figure(icon: Icons.boy_rounded, size: 96, label: l.lessonYou),
              ],
            ),
          ),
        ),
        Container(height: 4, color: AuraColors.line),
        const SizedBox(height: 12),
        Text(
          vm.coachText,
          style: AuraText.sheetTitle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        AuraButton(
          label: l.backToProblem,
          color: AuraButtonColor.blue,
          onPressed: vm.closeEveryday,
        ),
      ],
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.icon, required this.size, required this.label});

  final IconData icon;
  final double size;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      Icon(icon, size: size - 24, color: AuraColors.navy),
      Text(label, style: AuraText.small),
    ],
  );
}
