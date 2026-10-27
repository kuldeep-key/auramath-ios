import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/aura_card.dart';
import '../../../core/parts/lesson_header.dart';
import '../../../core/theme/tokens.dart';
import '../view_models/lesson_view_model.dart';

/// A short lesson on the one skill a wrong answer showed, then back to the
/// problem. Figma: T1. The interactive place-value board comes later.
class SideLessonView extends StatelessWidget {
  const SideLessonView({super.key, required this.vm, required this.onHome});

  final LessonViewModel vm;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final kind = vm.sideLesson ?? SideLesson.takeAcrossTen;
    final line = vm.pack.lines['side.${kind.name}'] ?? '';
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LessonHeader(line: line, onSpeak: vm.sayAgain, onHome: onHome),
          const SizedBox(height: 16),
          Expanded(
            child: AuraCard(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      switch (kind) {
                        SideLesson.takeAcrossTen => l.sideTakeAcrossTen,
                        SideLesson.addWithCarry => l.sideAddWithCarry,
                      },
                      style: AuraText.title,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      line,
                      style: AuraText.story,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          AuraButton(
            label: l.backToProblem,
            color: AuraButtonColor.blue,
            onPressed: () => vm.send(const SideLessonDone()),
          ),
        ],
      ),
    );
  }
}
