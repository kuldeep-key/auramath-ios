import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/ribbon.dart';
import '../../../core/theme/tokens.dart';
import '../view_models/lesson_view_model.dart';
import 'help_sheet.dart';

/// The prompt a tutor decision opens over the board ([LessonViewModel.prompt]).
// Draft: no Figma frames yet; built from the Help me sheet's look.
class TutorPromptSheet extends StatelessWidget {
  const TutorPromptSheet({super.key, required this.vm});

  final LessonViewModel vm;

  @override
  Widget build(BuildContext context) => switch (vm.prompt) {
    TutorPrompt.readAgain => _ReadAgain(vm: vm),
    TutorPrompt.seenBefore => _SeenBefore(vm: vm),
    null => const SizedBox.shrink(),
  };
}

/// "Let's read it again" (AI-09): the question lit up, read aloud as it
/// opens, and again on a tap.
class _ReadAgain extends StatelessWidget {
  const _ReadAgain({required this.vm});

  final LessonViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AuraSheet(
      onClose: vm.closePrompt,
      children: [
        const Portrait(size: 72),
        const SizedBox(height: 12),
        Text(
          l.lessonReadAgainTitle,
          style: AuraText.sheetTitle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        // the question, highlighted
        Container(
          key: const Key('readAgainQuestion'),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AuraColors.yellowTint,
            borderRadius: BorderRadius.circular(AuraRadii.small),
            border: Border.all(color: AuraColors.yellow, width: 3),
          ),
          child: Text(vm.problem.text, style: AuraText.sheetLine),
        ),
        const SizedBox(height: 16),
        AuraButton(
          label: l.hearItAgain,
          icon: Icons.volume_up_rounded,
          color: AuraButtonColor.white,
          onPressed: vm.readQuestion,
        ),
        const SizedBox(height: 10),
        AuraButton(
          label: l.lessonReadAgainBack,
          color: AuraButtonColor.blue,
          onPressed: vm.closePrompt,
        ),
      ],
    );
  }
}

/// "You've solved one like this" (AI-10), with a peek at that case when
/// the decision names one this phone has.
class _SeenBefore extends StatelessWidget {
  const _SeenBefore({required this.vm});

  final LessonViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final seen = vm.seenCase;
    return AuraSheet(
      onClose: vm.closePrompt,
      children: [
        const Portrait(size: 72),
        const SizedBox(height: 12),
        Text(
          l.lessonSeenBeforeTitle,
          style: AuraText.sheetTitle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          seen == null ? l.lessonSeenBeforeNoCase : l.lessonSeenBeforeLinked,
          style: AuraText.sheetLine,
          textAlign: TextAlign.center,
        ),
        if (seen != null) ...[
          const SizedBox(height: 12),
          // the earlier case: its two things and its question
          Container(
            key: const Key('seenBeforePeek'),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AuraColors.blueTint,
              borderRadius: BorderRadius.circular(AuraRadii.small),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${seen.a.pic} ${seen.b.pic}',
                  style: const TextStyle(fontSize: 32),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(seen.text, style: AuraText.small),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        AuraButton(
          label: l.lessonSeenBeforeBack,
          color: AuraButtonColor.blue,
          onPressed: vm.closePrompt,
        ),
      ],
    );
  }
}
